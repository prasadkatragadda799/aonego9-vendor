import 'dart:async';

import 'package:http/http.dart' as http;

import 'api_client.dart';

/// One place that turns a failure into a sentence a vendor can act on.
///
/// Screens used to each hand-roll `e.toString().replaceFirst(...)` string
/// mangling, which leaked "ApiException(500):" and Dart exception names into
/// the UI.
String apiErrorMessage(Object e, {String fallback = 'Something went wrong — please try again.'}) {
  if (e is ApiException) {
    switch (e.statusCode) {
      case 401:
        return 'Your session has expired — please sign in again.';
      case 403:
        return e.message.isNotEmpty && !e.message.startsWith('Request failed')
            ? e.message
            : 'Your account does not have access to this yet.';
      case 404:
        return e.message.isNotEmpty && !e.message.startsWith('Request failed') && e.message != 'Not Found'
            ? e.message
            : 'That item no longer exists — refresh and try again.';
      case 408:
      case 504:
        return 'The server took too long to respond — please retry.';
      case 413:
        return e.message;
      case 429:
        return 'Too many attempts — wait a moment and try again.';
    }
    if (e.statusCode >= 500) {
      return 'AOneGo9 is having trouble right now — please try again in a minute.';
    }
    final m = e.message.trim();
    return m.isEmpty || m.startsWith('Request failed') ? fallback : m;
  }
  if (e is TimeoutException) {
    return 'The server took too long to respond. It may be waking up — please retry.';
  }
  if (e is http.ClientException) {
    return "Can't reach AOneGo9 — check your connection and retry.";
  }
  final s = e.toString();
  if (s.contains('SocketException') || s.contains('XMLHttpRequest') || s.contains('Failed host lookup')) {
    return "Can't reach AOneGo9 — check your connection and retry.";
  }
  // Anything else is a programming fault, not something the vendor can act
  // on — never surface a raw Dart exception string.
  return fallback;
}

/// Upload failures carry server-configuration detail the generic mapper
/// would hide, so they get their own wording.
String friendlyApiError(Object e) {
  if (e is ApiException) {
    if (e.statusCode == 401) {
      return 'Session expired — please log in again and retry the upload.';
    }
    if (e.statusCode == 503 &&
        (e.message.contains('PUBLIC_API_BASE_URL') || e.message.contains('not configured'))) {
      return 'Image uploads need PUBLIC_API_BASE_URL on the backend (your Render service URL). Redeploy after setting it.';
    }
    if (e.statusCode == 502 || e.statusCode == 503) {
      return 'Image upload failed on the server — please try again shortly.';
    }
    if (e.statusCode == 400 || e.statusCode == 413 || e.statusCode == 415 || e.statusCode == 422) {
      return e.message;
    }
  }
  return apiErrorMessage(e);
}
