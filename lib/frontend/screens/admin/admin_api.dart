import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApiException implements Exception {
  const ApiException(this.message, [this.statusCode]);
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}

class AdminApi {
  AdminApi({
    http.Client? client,
    String? baseUrl,
    this.readRetryBaseDelay = const Duration(seconds: 2),
  }) : _client = client ?? http.Client(),
       baseUrl = _canonicalBaseUrl(
         baseUrl ??
             const String.fromEnvironment(
               'API_BASE_URL',
               defaultValue: 'https://bbt-billing-c16x.onrender.com/api',
             ),
       );

  final http.Client _client;
  final Duration readRetryBaseDelay;
  String baseUrl;
  String? _accessToken;

  static String _canonicalBaseUrl(String value) {
    var normalized = value.trim();
    for (final legacyHost in [
      'bbt-billing-api.onrender.com',
      'bbt-billing.onrender.com',
    ]) {
      normalized = normalized.replaceFirst(
        legacyHost,
        'bbt-billing-c16x.onrender.com',
      );
    }
    while (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    if (!normalized.endsWith('/api')) normalized = '$normalized/api';
    return normalized;
  }

  List<String> get _candidateBaseUrls => [baseUrl];

  void setBaseUrl(String value) {
    final normalized = _canonicalBaseUrl(value);
    final uri = Uri.tryParse(normalized);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw const ApiException('Enter a valid backend URL, including https://');
    }
    baseUrl = normalized;
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
  };

  /// Retries idempotent reads when Android or a sleeping Render instance drops
  /// a connection. Writes are deliberately not retried here because the server
  /// may already have applied them before the connection was interrupted.
  Future<http.Response> _get(Uri uri) async {
    Object? lastError;
    for (var attempt = 1; attempt <= 3; attempt++) {
      try {
        final response = await _client
            .get(uri, headers: _headers)
            .timeout(const Duration(seconds: 30));
        if (response.statusCode >= 500 && attempt < 3) {
          await Future<void>.delayed(_readRetryDelay(attempt));
          continue;
        }
        return response;
      } on TimeoutException catch (error) {
        lastError = error;
      } on SocketException catch (error) {
        lastError = error;
      } on http.ClientException catch (error) {
        lastError = error;
      }
      if (attempt < 3) {
        await Future<void>.delayed(_readRetryDelay(attempt));
      }
    }
    throw lastError!;
  }

  Duration _readRetryDelay(int attempt) =>
      Duration(microseconds: readRetryBaseDelay.inMicroseconds * attempt);

  // ── Wake-up / health-check ────────────────────────────────────────────────

  /// Pings the health endpoint repeatedly until the server responds or
  /// [maxAttempts] is exhausted.  Returns true when reachable.
  Future<bool> waitForServer({
    int maxAttempts = 3,
    Duration initialDelay = const Duration(seconds: 1),
    void Function(int attempt, int max)? onAttempt,
  }) async {
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      onAttempt?.call(attempt, maxAttempts);
      for (final candidate in _candidateBaseUrls) {
        final origin = candidate.replaceFirst(RegExp(r'/api$'), '');
        try {
          final response = await _client
              .get(Uri.parse('$origin/health/'))
              .timeout(const Duration(seconds: 6));
          if (response.statusCode >= 200 && response.statusCode < 400) {
            baseUrl = candidate;
            return true;
          }
        } catch (_) {
          // Timeout or transient error — keep retrying.
        }
      }
      if (attempt < maxAttempts) {
        await Future<void>.delayed(
          Duration(microseconds: initialDelay.inMicroseconds * attempt),
        );
      }
    }
    return false;
  }

  // ── Auth ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> login(String email, String password) async {
    Object? lastError;
    for (var attempt = 1; attempt <= 2; attempt++) {
      try {
        final response = await _client
            .post(
              Uri.parse('$baseUrl/auth/login/'),
              headers: _headers,
              body: jsonEncode({'username': email, 'password': password}),
            )
            .timeout(const Duration(seconds: 30));
        final data = _decodeMap(response);
        _accessToken = data['access'] as String?;
        return data;
      } on TimeoutException catch (error) {
        lastError = error;
      } on SocketException catch (error) {
        lastError = error;
      } on http.ClientException catch (error) {
        lastError = error;
      }
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    throw lastError!;
  }

  Future<Map<String, dynamic>> changePassword({
    required String identifier,
    required String currentPassword,
    required String newPassword,
  }) async => _decodeMap(
    await _client.post(
      Uri.parse('$baseUrl/auth/change-password/'),
      headers: _headers,
      body: jsonEncode({
        'identifier': identifier,
        'current_password': currentPassword,
        'new_password': newPassword,
      }),
    ),
  );

  Future<void> logout() async {
    try {
      _decodeMap(
        await _client.post(
          Uri.parse('$baseUrl/auth/logout/'),
          headers: _headers,
          body: jsonEncode({}),
        ),
      );
    } finally {
      clearSession();
    }
  }

  // ── Data access ───────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getMap(String path) async =>
      _decodeMap(await _get(Uri.parse('$baseUrl/$path/')));

  Future<List<Map<String, dynamic>>> getList(String path) async {
    final results = <Map<String, dynamic>>[];
    String? url = '$baseUrl/$path/?page_size=200';
    while (url != null) {
      final response = await _get(Uri.parse(url));
      final decoded = _decode(response);
      if (decoded is Map<String, dynamic>) {
        final items = decoded['results'];
        if (items is List) {
          results.addAll(items.cast<Map<String, dynamic>>());
        }
        final next = decoded['next'];
        url = (next is String && next.isNotEmpty) ? next : null;
      } else if (decoded is List) {
        results.addAll((decoded).cast<Map<String, dynamic>>());
        url = null;
      } else {
        url = null;
      }
    }
    return results;
  }

  Future<Map<String, dynamic>> create(
    String path,
    Map<String, dynamic> body,
  ) async => _decodeMap(
    await _client.post(
      Uri.parse('$baseUrl/$path/'),
      headers: _headers,
      body: jsonEncode(body),
    ),
  );

  Future<Map<String, dynamic>> createWithImage(
    String path,
    Map<String, dynamic> body, {
    required Uint8List imageBytes,
    required String imageName,
  }) => _multipart(
    'POST',
    '$baseUrl/$path/',
    body,
    imageBytes: imageBytes,
    imageName: imageName,
  );

  Future<Map<String, dynamic>> updateWithImage(
    String path,
    int id, {
    required Uint8List imageBytes,
    required String imageName,
  }) => _multipart(
    'PATCH',
    '$baseUrl/$path/$id/',
    const {},
    imageBytes: imageBytes,
    imageName: imageName,
  );

  Future<Map<String, dynamic>> _multipart(
    String method,
    String url,
    Map<String, dynamic> body, {
    required Uint8List imageBytes,
    required String imageName,
  }) async {
    final request = http.MultipartRequest(method, Uri.parse(url));
    if (_accessToken != null) {
      request.headers['Authorization'] = 'Bearer $_accessToken';
    }
    for (final entry in body.entries) {
      if (entry.value != null) {
        // Multipart fields are strings. JSONField values (such as product
        // manual_details) must be encoded as valid JSON rather than Dart's
        // Map.toString() output, e.g. `{brand: Acme}`, which Django rejects.
        request.fields[entry.key] = entry.value is Map || entry.value is List
            ? jsonEncode(entry.value)
            : entry.value.toString();
      }
    }
    final ext = imageName.split('.').last.toLowerCase();
    final mime = switch (ext) {
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: imageName,
        contentType: MediaType.parse(mime),
      ),
    );
    final streamed = await _client.send(request);
    return _decodeMap(await http.Response.fromStream(streamed));
  }

  Future<Map<String, dynamic>> update(
    String path,
    int id,
    Map<String, dynamic> body,
  ) async => _decodeMap(
    await _client.patch(
      Uri.parse('$baseUrl/$path/$id/'),
      headers: _headers,
      body: jsonEncode(body),
    ),
  );

  Future<void> delete(String path, int id) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/$path/$id/'),
      headers: _headers,
    );
    _decode(response);
  }

  Future<Map<String, dynamic>> action(
    String path,
    int id,
    String action, [
    Map<String, dynamic> body = const {},
  ]) async => _decodeMap(
    await _client.post(
      Uri.parse('$baseUrl/$path/$id/$action/'),
      headers: _headers,
      body: jsonEncode(body),
    ),
  );

  // ── Response handling ─────────────────────────────────────────────────────

  dynamic _decode(http.Response response) {
    dynamic data = <String, dynamic>{};
    if (response.bodyBytes.isNotEmpty) {
      try {
        data = jsonDecode(utf8.decode(response.bodyBytes));
      } on FormatException {
        data = <String, dynamic>{};
      }
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode >= 500) {
        throw ApiException(
          'Server update in progress. Please retry in a minute.',
          response.statusCode,
        );
      }
      final detail = data is Map
          ? data['detail'] ?? data.values.firstOrNull
          : null;
      throw ApiException(_errorMessage(detail), response.statusCode);
    }
    return data;
  }

  Map<String, dynamic> _decodeMap(http.Response response) =>
      (_decode(response) as Map).cast<String, dynamic>();

  String _errorMessage(dynamic detail) {
    if (detail is List) {
      return detail.map((v) => v.toString()).join(' ');
    }
    if (detail is Map) {
      return detail.values.map(_errorMessage).join(' ');
    }
    return detail?.toString() ?? 'Server request failed';
  }

  void dispose() => _client.close();

  void clearSession() => _accessToken = null;
}
