import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Base URL. Override per deployment without a code change:
///   flutter build web --dart-define=API_BASE_URL=https://api.example.com/api/v1
const String kBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://aonego9-backend.onrender.com/api/v1',
);

/// Thin HTTP wrapper that attaches the stored JWT to every request, refreshes
/// it once on a 401, throws [ApiException] on non-2xx, and decodes JSON.
///
/// Same contract as the user app's client (aonego9-user-main/lib/data/
/// api_client.dart): every request has a deadline, GETs retry once (which
/// also rides out a cold Render instance), writes are never retried because
/// they are not safe to repeat.
class ApiClient {
  static const _tokenKey = 'vendor_access_token';
  static const _refreshKey = 'vendor_refresh_token';

  static String? _cachedToken;

  /// Ticks whenever the session ends (sign-out, or a 401 the refresh token
  /// could not recover). The router listens to it so an expired session is
  /// sent to the sign-in page immediately rather than on the next tap.
  static final ValueNotifier<int> sessionChanges = ValueNotifier(0);

  static const _getTimeout = Duration(seconds: 30);
  static const _writeTimeout = Duration(seconds: 45);
  static const _uploadTimeout = Duration(seconds: 90);

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
    final hadSession = _cachedToken != null;
    _cachedToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshKey);
    if (hadSession) sessionChanges.value++;
  }

  static Future<bool> isLoggedIn() async => (await getAccessToken())?.isNotEmpty == true;

  /// GET /health — whether Cloudinary uploads are enabled on the backend.
  /// Unknown (unreachable, no flag) is treated as enabled so a transient
  /// health failure never hides the upload controls.
  static Future<bool> uploadsConfigured() async {
    try {
      final res = await http
          .get(Uri.parse(kBaseUrl.replaceFirst('/api/v1', '/health')))
          .timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return true;
      final body = jsonDecode(res.body);
      if (body is Map && body.containsKey('uploads')) return body['uploads'] == true;
      return true;
    } catch (_) {
      return true;
    }
  }

  // ── Request helpers ──────────────────────────────────────────

  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (auth) {
      final token = await getAccessToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static String _formatDetail(dynamic raw, int statusCode) {
    if (raw is String && raw.trim().isNotEmpty) return raw.trim();
    if (raw is List) {
      return raw.map((e) {
        if (e is Map) {
          final loc = e['loc'];
          final field = loc is List && loc.isNotEmpty ? '${loc.last}' : '';
          final msg = '${e['msg'] ?? e}';
          return field.isEmpty || field == 'body' ? msg : '$field: $msg';
        }
        return '$e';
      }).join('; ');
    }
    if (raw is Map && raw['message'] != null) return '${raw['message']}';
    if (raw != null) return raw.toString();
    return 'Request failed ($statusCode)';
  }

  static dynamic _decode(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return null;
      try {
        return jsonDecode(res.body);
      } catch (_) {
        return res.body;
      }
    }
    String detail = 'Request failed (${res.statusCode})';
    try {
      final body = jsonDecode(res.body);
      if (body is Map && body.containsKey('detail')) {
        detail = _formatDetail(body['detail'], res.statusCode);
      } else if (body is Map && body['message'] != null) {
        detail = '${body['message']}';
      }
    } catch (_) {}
    throw ApiException(res.statusCode, detail);
  }

  static Future<bool>? _refreshing;

  /// One refresh at a time: a dashboard fires several requests at once, and
  /// each 401 starting its own refresh would rotate the token out from under
  /// the others.
  static Future<bool> _refreshAccessToken() {
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  static Future<bool> _doRefresh() async {
    final refresh = await getRefreshToken();
    if (refresh == null || refresh.isEmpty) return false;
    try {
      final res = await http
          .post(
            Uri.parse('$kBaseUrl/auth/refresh'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refresh_token': refresh}),
          )
          .timeout(_writeTimeout);
      if (res.statusCode != 200) return false;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      await saveTokens(
        body['access_token'] as String,
        (body['refresh_token'] as String?) ?? refresh,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<http.Response> _withAuthRetry(
    Future<http.Response> Function() send, {
    required bool auth,
  }) async {
    var res = await send();
    if (auth && res.statusCode == 401 && await _refreshAccessToken()) {
      res = await send();
    }
    // A public read failing with 401 says nothing about the vendor's session.
    if (auth && res.statusCode == 401) await clearTokens();
    return res;
  }

  static Uri _uri(String path) => Uri.parse('$kBaseUrl$path');

  static Future<dynamic> get(String path, {bool auth = true}) async {
    Future<http.Response> send() async =>
        http.get(_uri(path), headers: await _headers(auth: auth)).timeout(_getTimeout);
    try {
      return _decode(await _withAuthRetry(send, auth: auth));
    } on TimeoutException {
      return _decode(await _withAuthRetry(send, auth: auth));
    } on http.ClientException {
      return _decode(await _withAuthRetry(send, auth: auth));
    }
  }

  static Future<dynamic> post(String path, Map<String, dynamic> body, {bool auth = true}) async {
    Future<http.Response> send() async => http
        .post(_uri(path), headers: await _headers(auth: auth), body: jsonEncode(body))
        .timeout(_writeTimeout);
    return _decode(await _withAuthRetry(send, auth: auth));
  }

  static Future<dynamic> put(String path, Map<String, dynamic> body) async {
    Future<http.Response> send() async =>
        http.put(_uri(path), headers: await _headers(), body: jsonEncode(body)).timeout(_writeTimeout);
    return _decode(await _withAuthRetry(send, auth: true));
  }

  static Future<dynamic> patch(String path, [Map<String, dynamic>? body]) async {
    Future<http.Response> send() async => http
        .patch(_uri(path), headers: await _headers(), body: body != null ? jsonEncode(body) : null)
        .timeout(_writeTimeout);
    return _decode(await _withAuthRetry(send, auth: true));
  }

  static Future<void> delete(String path) async {
    Future<http.Response> send() async =>
        http.delete(_uri(path), headers: await _headers()).timeout(_writeTimeout);
    final res = await _withAuthRetry(send, auth: true);
    if (res.statusCode >= 300) _decode(res);
  }

  /// List endpoints answer either a bare array or a page envelope
  /// (`{items|results|data: [...]}`) depending on the route. Casting straight
  /// to `List` threw on the envelope and the screen silently showed nothing.
  static List<Map<String, dynamic>> asList(dynamic data, [String key = 'items']) {
    final raw = data is List
        ? data
        : data is Map
            ? (data[key] ?? data['items'] ?? data['results'] ?? data['data'] ?? const [])
            : const [];
    return (raw is List ? raw : const [])
        .whereType<Map>()
        .map((m) => m.cast<String, dynamic>())
        .toList();
  }

  /// Every page of a paginated list endpoint (`?page=&page_size=`). The
  /// backend caps a page at 100 rows and defaults to 20, so a plain GET
  /// silently showed only the first 20 bookings / reviews / transactions.
  static Future<List<Map<String, dynamic>>> getAllPages(String path, {int pageSize = 100, int maxPages = 50}) async {
    final out = <Map<String, dynamic>>[];
    for (var page = 1; page <= maxPages; page++) {
      final sep = path.contains('?') ? '&' : '?';
      final data = await get('$path${sep}page=$page&page_size=$pageSize');
      final items = asList(data);
      out.addAll(items);
      final total = data is Map ? (data['total'] as num?)?.toInt() : null;
      if (items.length < pageSize || (total != null && out.length >= total)) break;
    }
    return out;
  }

  /// A JSON object payload, or an empty map for anything else.
  static Map<String, dynamic> asMap(dynamic data) =>
      data is Map ? data.cast<String, dynamic>() : <String, dynamic>{};

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
    if (bytes.length > 10 * 1024 * 1024) {
      throw const ApiException(413, 'That image is over 10 MB — pick a smaller one');
    }
    if ((await getAccessToken())?.isNotEmpty != true && !await _refreshAccessToken()) {
      throw const ApiException(401, 'Not logged in — sign in again to upload photos');
    }

    Future<http.Response> sendBase64() async {
      return http
          .post(
            _uri('/uploads/image-base64'),
            headers: await _headers(),
            body: jsonEncode({
              'data': base64Encode(bytes),
              'filename': filename,
              'folder': folder,
              'content_type': mimeType,
            }),
          )
          .timeout(_uploadTimeout);
    }

    Future<http.Response> sendMultipart() async {
      final token = await getAccessToken();
      final uri = _uri('/uploads/image').replace(queryParameters: {'folder': folder});
      final request = http.MultipartRequest('POST', uri);
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
        contentType: MediaType.parse(mimeType),
      ));
      final streamed = await request.send().timeout(_uploadTimeout);
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

    final res = await _withAuthRetry(send, auth: true);
    return asMap(_decode(res));
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  const ApiException(this.statusCode, this.message);

  /// The route does not exist on this backend deployment (yet).
  bool get isMissingRoute => statusCode == 404 || statusCode == 405 || statusCode == 501;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
