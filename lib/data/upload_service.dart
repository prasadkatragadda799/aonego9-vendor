import 'dart:typed_data';

import 'api/api_client.dart';

class UploadService {
  static String _mimeFromName(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  static Future<String> uploadImage({
    required Uint8List bytes,
    required String filename,
    String folder = 'misc',
  }) async {
    final data = await ApiClient.uploadImage(
      bytes: bytes,
      filename: filename,
      folder: folder,
      mimeType: _mimeFromName(filename),
    );
    return data['url'] as String;
  }
}
