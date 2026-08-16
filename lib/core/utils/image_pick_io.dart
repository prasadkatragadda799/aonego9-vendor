import 'package:image_picker/image_picker.dart';

import 'image_pick_util.dart';

Future<PickedImageFile?> pickImagePlatform() async {
  final picked = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    imageQuality: 85,
  );
  if (picked == null) return null;
  final bytes = await picked.readAsBytes();
  final name = picked.name.trim().isNotEmpty ? picked.name.trim() : 'photo.jpg';
  return PickedImageFile(bytes: bytes, filename: name);
}
