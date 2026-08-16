import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

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

/// Opens the gallery / file chooser. Uses [FilePicker] on web (more reliable
/// inside dialogs and modals than [ImagePicker]).
Future<PickedImageFile?> pickImageFromGallery() async {
  if (kIsWeb) {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return null;
    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) return null;
    final name = file.name.trim().isNotEmpty ? file.name.trim() : 'photo.jpg';
    return PickedImageFile(bytes: bytes, filename: name);
  }

  final picked = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    imageQuality: 85,
  );
  if (picked == null) return null;
  final bytes = await picked.readAsBytes();
  final name = picked.name.trim().isNotEmpty ? picked.name.trim() : 'photo.jpg';
  return PickedImageFile(bytes: bytes, filename: name);
}
