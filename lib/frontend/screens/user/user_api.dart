import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
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
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  Future<Map<String, dynamic>> restore() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('staff_access_token');
    if (_token == null) return {};
    try {
      return await getMap('auth/me');
    } catch (_) {
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
      return await getList('inventory/shelf-stock', query: query);
    } on UserApiException {
      final legacy = await getList('inventory/current-stock', query: query);
      return legacy
          .where((item) => _asInt(item['shelf_stock'] ?? item['shelf_quantity']) > 0)
          .map((item) => {
                'product_id': item['id'],
                'product_name': item['name'],
                'image_url': item['image_url'] ?? item['image'],
                'branch': item['branch'] ?? 'Main Branch',
                'shelf_quantity': item['shelf_stock'] ?? item['shelf_quantity'] ?? 0,
                'target_quantity': item['target_shelf_quantity'] ?? item['reorder_level'] ?? 0,
                'updated_by': item['updated_by'],
              })
          .toList();
    }
  }

  int _asInt(dynamic value) => int.tryParse('$value') ?? 0;

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) =>
      _request('POST', path, body: body);

  Future<Map<String, dynamic>> patch(
    String path,
    Map<String, dynamic> body,
  ) => _request('PATCH', path, body: body);

  Future<Map<String, dynamic>> _request(String method, String path,
      {Map<String, dynamic>? body, Map<String, String>? query}) async {
    final value = await _requestRaw(method, path, body: body, query: query);
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.cast<String, dynamic>();
    return {};
  }

  Future<dynamic> _requestRaw(String method, String path,
      {Map<String, dynamic>? body, Map<String, String>? query}) async {
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
        _ => await _client
            .get(uri, headers: _headers)
            .timeout(const Duration(seconds: 30)),
      };
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
          ? (decoded['detail'] ?? decoded.values.firstOrNull ?? 'Request failed').toString()
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
}
