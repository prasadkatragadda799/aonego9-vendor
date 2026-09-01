import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Base URL — change to your deployed backend URL in production.
const String kBaseUrl = 'https://aonego9-backend.onrender.com/api/v1';

/// Thin HTTP wrapper that attaches the stored JWT to every request,
/// throws [ApiException] on non-2xx, and decodes JSON automatically.
class ApiClient {
  static const _tokenKey = 'vendor_access_token';
  static const _refreshKey = 'vendor_refresh_token';

  static String? _cachedToken;

  // ── Token persistence ────────────────────────────────────────

  static Future<void> saveTokens(String access, String refresh) async {
    _cachedToken = access;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, access);
    await prefs.setString(_refreshKey, refresh);
  }

  static Future<String?> getAccessToken() async {
    if (_cachedToken != null) return _cachedToken;
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString(_tokenKey);
    return _cachedToken;
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshKey);
  }

  static Future<void> clearTokens() async {
    _cachedToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshKey);
  }

  static Future<bool> isLoggedIn() async => (await getAccessToken()) != null;

  /// GET /health — whether Cloudinary uploads are enabled on the backend.
  static Future<bool> uploadsConfigured() async {
    try {
      final res = await http.get(Uri.parse(kBaseUrl.replaceFirst('/api/v1', '/health')));
      if (res.statusCode != 200) return true;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (body.containsKey('uploads')) return body['uploads'] == true;
      return true;
    } catch (_) {
      return true;
    }
  }

  // ── Request helpers ──────────────────────────────────────────

  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (auth) {
      final token = await getAccessToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static String _formatDetail(dynamic raw, int statusCode) {
    if (raw is String && raw.trim().isNotEmpty) return raw.trim();
    if (raw is List) {
      return raw
          .map((e) => e is Map ? (e['msg'] ?? e.toString()) : e.toString())
          .join('; ');
    }
    if (raw != null) return raw.toString();
    return 'Request failed ($statusCode)';
  }

  static dynamic _decode(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return null;
      return jsonDecode(res.body);
    }
    String detail = 'Request failed (${res.statusCode})';
    try {
      final body = jsonDecode(res.body);
      if (body is Map && body.containsKey('detail')) {
        detail = _formatDetail(body['detail'], res.statusCode);
      }
    } catch (_) {}
    throw ApiException(res.statusCode, detail);
  }

  static Future<void> _clearSessionOnAuthFailure(int statusCode) async {
    if (statusCode == 401) {
      await clearTokens();
    }
  }

  static Future<bool> _refreshAccessToken() async {
    final refresh = await getRefreshToken();
    if (refresh == null || refresh.isEmpty) return false;
    try {
      final res = await http.post(
        Uri.parse('$kBaseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refresh}),
      );
      if (res.statusCode != 200) return false;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      await saveTokens(
        body['access_token'] as String,
        body['refresh_token'] as String,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _ensureAuthForUpload() async {
    if ((await getAccessToken())?.isNotEmpty == true) return;
    if (!await _refreshAccessToken()) {
      throw const ApiException(401, 'Not logged in — sign in again to upload photos');
    }
  }

  static Future<dynamic> get(String path, {bool auth = true}) async {
    final res = await http.get(Uri.parse('$kBaseUrl$path'), headers: await _headers(auth: auth));
    // A public GET must not clear the session on a 401 — an anonymous read
    // failing says nothing about whether the vendor is still signed in.
    if (auth) await _clearSessionOnAuthFailure(res.statusCode);
    return _decode(res);
  }

  static Future<dynamic> post(String path, Map<String, dynamic> body, {bool auth = true}) async {
    final res = await http.post(
      Uri.parse('$kBaseUrl$path'),
      headers: await _headers(auth: auth),
      body: jsonEncode(body),
    );
    await _clearSessionOnAuthFailure(res.statusCode);
    return _decode(res);
  }

  static Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final res = await http.put(
      Uri.parse('$kBaseUrl$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    await _clearSessionOnAuthFailure(res.statusCode);
    return _decode(res);
  }

  static Future<dynamic> patch(String path, [Map<String, dynamic>? body]) async {
    final res = await http.patch(
      Uri.parse('$kBaseUrl$path'),
      headers: await _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
    await _clearSessionOnAuthFailure(res.statusCode);
    return _decode(res);
  }

  static Future<void> delete(String path) async {
    final res = await http.delete(Uri.parse('$kBaseUrl$path'), headers: await _headers());
    await _clearSessionOnAuthFailure(res.statusCode);
    if (res.statusCode >= 300) _decode(res);
  }

  /// POST /api/v1/uploads/image — uploads via JSON base64 on web, multipart elsewhere.
  static Future<Map<String, dynamic>> uploadImage({
    required List<int> bytes,
    required String filename,
    String folder = 'misc',
    String mimeType = 'image/jpeg',
  }) async {
    if (bytes.isEmpty) {
      throw const ApiException(400, 'Selected file is empty — try another image');
    }

    await _ensureAuthForUpload();

    Future<http.Response> sendBase64() async {
      return http.post(
        Uri.parse('$kBaseUrl/uploads/image-base64'),
        headers: await _headers(),
        body: jsonEncode({
          'data': base64Encode(bytes),
          'filename': filename,
          'folder': folder,
          'content_type': mimeType,
        }),
      );
    }

    Future<http.Response> sendMultipart() async {
      final token = await getAccessToken();
      final uri = Uri.parse('$kBaseUrl/uploads/image').replace(queryParameters: {'folder': folder});
      final request = http.MultipartRequest('POST', uri);
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
        contentType: MediaType.parse(mimeType),
      ));
      final streamed = await request.send();
      return http.Response.fromStream(streamed);
    }

    Future<http.Response> send() async {
      if (kIsWeb) {
        final base64Res = await sendBase64();
        if (base64Res.statusCode != 404) return base64Res;
        return sendMultipart();
      }
      return sendMultipart();
    }

    var res = await send();
    if (res.statusCode == 401 && await _refreshAccessToken()) {
      res = await send();
    }
    await _clearSessionOnAuthFailure(res.statusCode);
    return (_decode(res) as Map).cast<String, dynamic>();
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  const ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}
