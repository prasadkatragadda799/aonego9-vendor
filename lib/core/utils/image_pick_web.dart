import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

import 'image_pick_util.dart';

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

  void onWindowFocus(html.Event _) {
    html.window.removeEventListener('focus', onWindowFocus);
    Future<void>.delayed(const Duration(milliseconds: 500), () {
      if (!completed) finish(null);
    });
  }

  input.onChange.listen((_) {
    html.window.removeEventListener('focus', onWindowFocus);
    final file = input.files?.first;
    if (file == null) {
      finish(null);
      return;
    }
    final reader = html.FileReader();
    reader.onError.listen((_) => finish(null));
    reader.onLoadEnd.listen((_) {
      final result = reader.result;
      if (result is! ByteBuffer) {
        finish(null);
        return;
      }
      final name = file.name.trim().isNotEmpty ? file.name.trim() : 'photo.jpg';
      finish(PickedImageFile(bytes: result.asUint8List(), filename: name));
    });
    reader.readAsArrayBuffer(file);
  });

  html.window.addEventListener('focus', onWindowFocus);
  input.click();

  return completer.future.timeout(
    const Duration(minutes: 2),
    onTimeout: () {
      finish(null);
      return null;
    },
  );
}
