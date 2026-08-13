import 'dart:typed_data';

import 'api/api_client.dart';

class UploadService {
  static Future<String> uploadImage({
    required Uint8List bytes,
    required String filename,
    String folder = 'misc',
  }) async {
    final data = await ApiClient.uploadImage(bytes: bytes, filename: filename, folder: folder);
    return data['url'] as String;
  }
}
