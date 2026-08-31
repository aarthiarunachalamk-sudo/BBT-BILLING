import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserApiException implements Exception {
  const UserApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class UserApi {
  UserApi({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  final String baseUrl = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://bbt-billing-c16x.onrender.com/api',
  ).replaceAll(RegExp(r'/$'), '');
  String? _token;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer ${_token!.replaceFirst(RegExp(r'^Bearer\s+'), '').trim()}',
  };

  Future<Map<String, dynamic>> restore() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('staff_access_token');
    if (_token == null) return {};
    try {
      return await getMap('auth/me');
    } catch (_) {
      if (await _refreshToken()) {
        try { return await getMap('auth/me'); } catch (_) {}
      }
      await clearSession();
      return {};
    }
  }

  Future<Map<String, dynamic>> login(String identifier, String password) async {
    final data = await _request('POST', 'auth/login', body: {
      'username': identifier.trim(),
      'password': password,
    });
    _token = data['access']?.toString();
    if (_token == null) throw const UserApiException('The server did not return an access token.');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('staff_access_token', _token!);
    if (data['refresh'] != null) await prefs.setString('staff_refresh_token', data['refresh'].toString());
    return (data['user'] as Map?)?.cast<String, dynamic>() ?? {};
  }

  Future<void> changePassword({
    required String identifier,
    required String currentPassword,
    required String newPassword,
  }) async {
    await _request('POST', 'auth/change-password', body: {
      'identifier': identifier.trim(),
      'current_password': currentPassword,
      'new_password': newPassword,
    });
  }

  Future<void> clearSession() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('staff_access_token');
    await prefs.remove('staff_refresh_token');
  }

  Future<void> logout() async {
    try {
      await post('auth/logout', const {});
    } finally {
      await clearSession();
    }
  }

  Future<Map<String, dynamic>> getMap(String path, {Map<String, String>? query}) =>
      _request('GET', path, query: query);

  Future<List<Map<String, dynamic>>> getList(String path, {Map<String, String>? query}) async {
    final data = await _requestRaw('GET', path, query: query);
    if (data is List) return data.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    if (data is Map && data['results'] is List) {
      return (data['results'] as List).whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getStoreStock({Map<String, String>? query}) async {
    try {
      return await getList('inventory/store-stock', query: query);
    } on UserApiException {
      // Keep older deployed servers usable until the split-stock migrations
      // have been applied. The returned shape matches StoreStockSerializer.
      final legacy = await getList('inventory/current-stock', query: query);
      return legacy.map((item) => {
        'product_id': item['id'],
        'product_name': item['name'],
        'sku': item['sku'],
        'barcode': item['barcode'],
        'image_url': item['image_url'] ?? item['image'],
        'branch': item['branch'] ?? 'Main Branch',
        'store_quantity': item['store_stock'] ?? item['stock_quantity'] ?? 0,
        'minimum_quantity': item['reorder_level'] ?? 0,
        'updated_by': item['updated_by'],
      }).toList();
    }
  }

  Future<List<Map<String, dynamic>>> getShelfStock({Map<String, String>? query}) async {
    try {
      final current = await getList('inventory/shelf-stock', query: query);
      if (current.isNotEmpty) return current;
      // A freshly deployed split-stock database can have no migrated rows yet.
      // Read the legacy quantities until the migration/backfill is completed.
      return _legacyShelfStock(query: query);
    } on UserApiException {
      return _legacyShelfStock(query: query);
    }
  }

  Future<List<Map<String, dynamic>>> _legacyShelfStock({Map<String, String>? query}) async {
      List<Map<String, dynamic>> legacy;
      try {
        legacy = await getList('inventory/current-stock', query: query);
      } on UserApiException {
        // Older deployments may not expose current-stock either. Products still
        // provide the central catalogue needed to render the shelf table.
        legacy = await getList('products', query: query);
      }
      return legacy.map((item) => {
                'product_id': item['id'],
                'product_name': item['name'],
                'sku': item['sku'],
                'barcode': item['barcode'],
                'image_url': item['image_url'] ?? item['image'],
                'branch': item['branch'] ?? 'Main Branch',
                'shelf_quantity': item['shelf_stock'] ?? item['shelf_quantity'] ?? 0,
                'target_quantity': item['target_shelf_quantity'] ?? item['reorder_level'] ?? 0,
                'updated_by': item['updated_by'],
              })
          .toList();
  }

  int _asInt(dynamic value) => int.tryParse('$value') ?? 0;

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) =>
      _request('POST', path, body: body);

  Future<Map<String, dynamic>> uploadProduct(
    Map<String, dynamic> values, {
    required XFile image,
  }) async {
    final uri = Uri.parse('$baseUrl/products/');
    try {
      final request = http.MultipartRequest('POST', uri);
      if (_token != null) request.headers['Authorization'] = 'Bearer ${_token!.replaceFirst(RegExp(r'^Bearer\s+'), '').trim()}';
      for (final entry in values.entries) {
        if (entry.value != null) {
          request.fields[entry.key] = entry.value is Map || entry.value is List
              ? jsonEncode(entry.value)
              : entry.value.toString();
        }
      }
      final bytes = await image.readAsBytes();
      final contentType = image.mimeType == null ? MediaType('image', 'jpeg') : MediaType.parse(image.mimeType!);
      request.files.add(http.MultipartFile.fromBytes('image', bytes, filename: image.name, contentType: contentType));
      final response = await http.Response.fromStream(
        await _client.send(request).timeout(const Duration(seconds: 45)),
      );
      dynamic decoded;
      try {
        decoded = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);
      } on FormatException {
        throw UserApiException('Server returned an invalid response (HTTP ${response.statusCode}).');
      }
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decoded is Map<String, dynamic> ? decoded : (decoded as Map).cast<String, dynamic>();
      }
      final message = decoded is Map
          ? (decoded['message'] ?? decoded['detail'] ?? _firstErrorValue(decoded) ?? 'Product image upload failed').toString()
          : 'Product image upload failed (${response.statusCode})';
      throw UserApiException(message);
    } on UserApiException {
      rethrow;
    } on TimeoutException {
      throw const UserApiException('Image upload took too long. Please retry.');
    } on SocketException {
      throw const UserApiException('No network connection. Check your internet and retry.');
    } on http.ClientException {
      throw const UserApiException('Unable to upload the product image.');
    }
  }

  Future<Map<String, dynamic>> patch(
    String path,
    Map<String, dynamic> body,
  ) => _request('PATCH', path, body: body);

  Future<void> delete(String path) async {
    await _requestRaw('DELETE', path);
  }

  Future<Map<String, dynamic>> _request(String method, String path,
      {Map<String, dynamic>? body, Map<String, String>? query}) async {
    final value = await _requestRaw(method, path, body: body, query: query);
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.cast<String, dynamic>();
    return {};
  }

  Future<dynamic> _requestRaw(String method, String path,
      {Map<String, dynamic>? body, Map<String, String>? query, bool retried = false}) async {
    final uri = Uri.parse('$baseUrl/${path.replaceAll(RegExp(r'^/|/$'), '')}/')
        .replace(queryParameters: query);
    try {
      final response = switch (method) {
        'POST' => await _client
            .post(uri, headers: _headers, body: jsonEncode(body))
            .timeout(const Duration(seconds: 30)),
        'PATCH' => await _client
            .patch(uri, headers: _headers, body: jsonEncode(body))
            .timeout(const Duration(seconds: 30)),
        'DELETE' => await _client.delete(uri, headers: _headers).timeout(const Duration(seconds: 30)),
        _ => await _client
            .get(uri, headers: _headers)
            .timeout(const Duration(seconds: 30)),
      };
      if (path.contains('move-to-shelf') || path.contains('store-to-shelf')) {
        // Development diagnostics: never print Authorization/token values.
        print('TRANSFER $method ${uri.path} body=${body ?? {}} status=${response.statusCode} response=${response.body}');
      }
      if (response.statusCode == 401 && !path.startsWith('auth/login') && !path.startsWith('auth/refresh')) {
        if (!retried && await _refreshToken()) {
          return _requestRaw(method, path, body: body, query: query, retried: true);
        }
        await clearSession();
        throw const UserApiException('Your session has expired. Please log in again.');
      }
      dynamic decoded;
      try {
        decoded = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);
      } on FormatException {
        throw UserApiException(
          'Server returned an invalid response (HTTP ${response.statusCode}). Please retry or contact the administrator.',
        );
      }
      if (response.statusCode >= 200 && response.statusCode < 300) return decoded;
      final message = decoded is Map
          ? (decoded['message'] ?? decoded['detail'] ?? _firstErrorValue(decoded) ?? 'Request failed').toString()
          : 'Request failed (${response.statusCode})';
      throw UserApiException(message);
    } on UserApiException {
      rethrow;
    } on TimeoutException {
      throw const UserApiException('The server took too long to respond. Please retry.');
    } on SocketException {
      throw const UserApiException('No network connection. Check your internet and retry.');
    } on FormatException {
      throw const UserApiException('The server returned an invalid response.');
    } on http.ClientException {
      throw const UserApiException('Unable to connect to the server.');
    }
  }

  dynamic _firstErrorValue(Map<dynamic, dynamic> data) {
    for (final value in data.values) {
      if (value is String && value.trim().isNotEmpty) return value;
      if (value is List && value.isNotEmpty) return value.first;
    }
    return null;
  }

  Future<bool> _refreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refresh = prefs.getString('staff_refresh_token');
    if (refresh == null || refresh.isEmpty) return false;
    try {
      final response = await _client.post(Uri.parse('$baseUrl/auth/refresh/'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'refresh': refresh})).timeout(const Duration(seconds: 15));
      if (response.statusCode < 200 || response.statusCode >= 300) return false;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final access = data['access']?.toString();
      if (access == null || access.isEmpty) return false;
      _token = access;
      await prefs.setString('staff_access_token', access);
      return true;
    } catch (_) { return false; }
  }
}
