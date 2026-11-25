import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'session.dart';

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}

class ApiClient {
  static const String _configuredBaseUrl =
      String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _configuredBaseUrl.replaceFirst(RegExp(r'/$'), '');
    }
    return kIsWeb
        ? 'http://localhost:3000/api/v1'
        : 'http://10.0.2.2:3000/api/v1';
  }

  static Future<Map<String, String>> _buildHeaders({
    bool withAuth = true,
    bool json = true,
  }) async {
    final headers = <String, String>{'Accept': 'application/json'};
    if (json) headers['Content-Type'] = 'application/json';
    if (withAuth) {
      final token = await Session.getAccessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  static Future<dynamic> get(String path, {bool withAuth = true}) {
    return _sendRequest(
      () async => http.get(
        Uri.parse('$baseUrl$path'),
        headers: await _buildHeaders(withAuth: withAuth),
      ),
      withAuth: withAuth,
    );
  }

  static Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    bool withAuth = true,
  }) {
    return _sendRequest(
      () async => http.post(
        Uri.parse('$baseUrl$path'),
        headers: await _buildHeaders(withAuth: withAuth),
        body: body == null ? null : jsonEncode(body),
      ),
      withAuth: withAuth,
    );
  }

  static Future<dynamic> patch(
    String path, {
    Map<String, dynamic>? body,
    bool withAuth = true,
  }) {
    return _sendRequest(
      () async => http.patch(
        Uri.parse('$baseUrl$path'),
        headers: await _buildHeaders(withAuth: withAuth),
        body: body == null ? null : jsonEncode(body),
      ),
      withAuth: withAuth,
    );
  }

  static Future<dynamic> delete(String path, {bool withAuth = true}) {
    return _sendRequest(
      () async => http.delete(
        Uri.parse('$baseUrl$path'),
        headers: await _buildHeaders(withAuth: withAuth),
      ),
      withAuth: withAuth,
    );
  }

  /// Upload multipart; `fileField` harus sesuai nama field FileInterceptor di NestJS.
  static Future<dynamic> uploadFile(
    String path, {
    required XFile file,
    String fileField = 'file',
    Map<String, String> fields = const {},
    bool withAuth = true,
  }) {
    return _sendRequest(
      () async {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('$baseUrl$path'),
        );
        request.headers.addAll(
          await _buildHeaders(withAuth: withAuth, json: false),
        );
        request.fields.addAll(fields);
        request.files.add(
          http.MultipartFile.fromBytes(
            fileField,
            await file.readAsBytes(),
            filename: file.name,
          ),
        );
        final streamed = await request.send();
        return http.Response.fromStream(streamed);
      },
      withAuth: withAuth,
    );
  }

  static Future<bool>? _refreshInFlight;

  static Future<dynamic> _sendRequest(
    Future<http.Response> Function() requestFn, {
    required bool withAuth,
    bool isRetry = false,
  }) async {
    final accessTokenAtStart =
        withAuth ? await Session.getAccessToken() : null;
    late final http.Response response;
    try {
      response = await requestFn();
    } on TimeoutException {
      throw ApiException('Permintaan ke server melewati batas waktu', 0);
    } on http.ClientException {
      throw ApiException('Koneksi ke server gagal', 0);
    }

    if (response.statusCode == 401 && withAuth && !isRetry) {
      // Jika request lain sudah memperbarui access token, jangan lakukan
      // refresh kedua menggunakan refresh token yang sudah dirotasi.
      final currentAccessToken = await Session.getAccessToken();
      if (accessTokenAtStart != null &&
          currentAccessToken != null &&
          currentAccessToken != accessTokenAtStart) {
        return _sendRequest(requestFn, withAuth: withAuth, isRetry: true);
      }

      final refreshFuture = _refreshInFlight ??= _tryRefreshToken();
      final refreshed = await refreshFuture;
      if (identical(_refreshInFlight, refreshFuture)) {
        _refreshInFlight = null;
      }
      if (refreshed) {
        return _sendRequest(requestFn, withAuth: withAuth, isRetry: true);
      }
      await Session.clear();
      throw ApiException('Sesi berakhir, silakan login kembali', 401);
    }

    dynamic decoded;
    if (response.body.trim().isNotEmpty) {
      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        decoded = response.body;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
        return decoded['data'];
      }
      return decoded;
    }

    final rawMessage =
        decoded is Map<String, dynamic> ? decoded['message'] : null;
    final errorMessage = rawMessage is List
        ? rawMessage.join(', ')
        : (rawMessage?.toString() ??
            (decoded is String && decoded.isNotEmpty
                ? decoded
                : 'Terjadi kesalahan pada server'));
    throw ApiException(errorMessage, response.statusCode);
  }

  static Future<bool> _tryRefreshToken() async {
    final refreshToken = await Session.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return false;
      }

      final decoded = jsonDecode(response.body);
      final data = decoded is Map<String, dynamic>
          ? (decoded['data'] ?? decoded)
          : null;
      if (data is! Map<String, dynamic> ||
          data['accessToken'] is! String ||
          data['refreshToken'] is! String) {
        return false;
      }

      await Session.updateTokens(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
