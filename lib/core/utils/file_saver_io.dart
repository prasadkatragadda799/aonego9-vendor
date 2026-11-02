import 'package:flutter/services.dart';

Future<bool> saveTextFile(String filename, String content, String mime) async {
  await Clipboard.setData(ClipboardData(text: content));
  return false;
}
