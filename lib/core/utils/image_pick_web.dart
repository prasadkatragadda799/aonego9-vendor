import 'dart:async';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

import 'image_pick_util.dart';

Uint8List? _bytesFromReaderResult(dynamic result) {
  if (result is ByteBuffer) return result.asUint8List();
  if (result is Uint8List) return result;
  if (result is String && result.startsWith('data:')) {
    final comma = result.indexOf(',');
    if (comma == -1) return null;
    return base64Decode(result.substring(comma + 1));
  }
  return null;
}

Future<PickedImageFile?> pickImagePlatform() {
  final completer = Completer<PickedImageFile?>();
  final input = html.FileUploadInputElement()
    ..accept = 'image/png,image/jpeg,image/jpg,image/webp,image/gif'
    ..multiple = false;

  var completed = false;
  void finish(PickedImageFile? value) {
    if (completed) return;
    completed = true;
    if (!completer.isCompleted) completer.complete(value);
  }

  input.onChange.listen((_) {
    final file = input.files?.first;
    if (file == null) {
      finish(null);
      return;
    }
    final name = file.name.trim().isNotEmpty ? file.name.trim() : 'photo.jpg';
    final reader = html.FileReader();
    reader.onError.listen((_) => finish(null));
    reader.onLoadEnd.listen((_) {
      final bytes = _bytesFromReaderResult(reader.result);
      if (bytes == null || bytes.isEmpty) {
        finish(null);
        return;
      }
      finish(PickedImageFile(bytes: bytes, filename: name));
    });
    // Data URLs decode reliably across Flutter web targets.
    reader.readAsDataUrl(file);
  });

  input.click();

  return completer.future.timeout(
    const Duration(minutes: 2),
    onTimeout: () {
      finish(null);
      return null;
    },
  );
}
