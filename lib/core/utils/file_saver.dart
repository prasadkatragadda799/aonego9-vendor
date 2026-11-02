import 'dart:convert';

import 'file_saver_io.dart' if (dart.library.html) 'file_saver_web.dart' as platform;

/// Saves a text file for the user: a real download in the browser; on
/// mobile/desktop builds the content goes to the clipboard instead (there is
/// no file picker dependency), and the caller says so.
///
/// Returns true when a file was downloaded, false when it was copied.
Future<bool> saveTextFile(String filename, String content, {String mime = 'text/csv'}) =>
    platform.saveTextFile(filename, content, mime);

/// RFC 4180 CSV with a UTF-8 BOM so Excel opens ₹ and Indic names correctly.
String toCsv(List<String> header, List<List<Object?>> rows) {
  String cell(Object? v) {
    final s = v == null ? '' : '$v';
    final needsQuote = s.contains(',') || s.contains('"') || s.contains('\n') || s.contains('\r');
    final escaped = s.replaceAll('"', '""');
    // Neutralise spreadsheet formula injection from user-entered text.
    final safe = RegExp(r'^[=+\-@]').hasMatch(escaped) ? "'$escaped" : escaped;
    return needsQuote ? '"$safe"' : safe;
  }

  final b = StringBuffer('﻿');
  b.writeln(header.map(cell).join(','));
  for (final r in rows) {
    b.writeln(r.map(cell).join(','));
  }
  return b.toString();
}

/// Bytes for a UTF-8 string — used by the web saver.
List<int> utf8Bytes(String s) => utf8.encode(s);
