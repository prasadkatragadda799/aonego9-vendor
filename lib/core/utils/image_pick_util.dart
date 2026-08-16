import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import 'image_pick_io.dart' if (dart.library.html) 'image_pick_web.dart' as platform;

class PickedImageFile {
  final Uint8List bytes;
  final String filename;

  const PickedImageFile({required this.bytes, required this.filename});

  String get extension {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return 'png';
    if (lower.endsWith('.webp')) return 'webp';
    if (lower.endsWith('.gif')) return 'gif';
    return 'jpg';
  }
}

/// Opens the device gallery / browser file chooser.
Future<PickedImageFile?> pickImageFromGallery() async {
  try {
    return await platform.pickImagePlatform();
  } catch (e) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('pickImageFromGallery failed: $e');
    }
    rethrow;
  }
}
