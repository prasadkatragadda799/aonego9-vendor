// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

import 'file_saver.dart' show utf8Bytes;

Future<bool> saveTextFile(String filename, String content, String mime) async {
  final blob = html.Blob([utf8Bytes(content)], '$mime;charset=utf-8');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final a = html.AnchorElement(href: url)
    ..download = filename
    ..style.display = 'none';
  html.document.body?.append(a);
  a.click();
  a.remove();
  html.Url.revokeObjectUrl(url);
  return true;
}
