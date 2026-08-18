import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  const ApiException(this.message, [this.statusCode]);
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}

class AdminApi {
  AdminApi({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      baseUrl =
          baseUrl ??
          const String.fromEnvironment(
            'API_BASE_URL',
            defaultValue: 'http://127.0.0.1:8000/api',
          );

  final http.Client _client;
  String baseUrl;
  String? _accessToken;

  void setBaseUrl(String value) {
    var normalized = value.trim();
    while (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    if (!normalized.endsWith('/api')) normalized = '$normalized/api';
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

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/auth/login/'),
      headers: _headers,
      body: jsonEncode({'username': email, 'password': password}),
    );
    final data = _decodeMap(response);
    _accessToken = data['access'] as String?;
    return data;
  }

  Future<Map<String, dynamic>> getMap(String path) async => _decodeMap(
    await _client.get(Uri.parse('$baseUrl/$path/'), headers: _headers),
  );

  Future<List<Map<String, dynamic>>> getList(String path) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/$path/'),
      headers: _headers,
    );
    final decoded = _decode(response);
    final values = decoded is Map<String, dynamic>
        ? decoded['results']
        : decoded;
    return (values as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();
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

  dynamic _decode(http.Response response) {
    final dynamic data = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detail = data is Map
          ? data['detail'] ?? data.values.firstOrNull
          : null;
      throw ApiException(
        detail?.toString() ?? 'Server request failed',
        response.statusCode,
      );
    }
    return data;
  }

  Map<String, dynamic> _decodeMap(http.Response response) =>
      (_decode(response) as Map).cast<String, dynamic>();

  void dispose() => _client.close();

  void clearSession() => _accessToken = null;
}
