import 'api_client.dart';

String friendlyApiError(Object e) {
  if (e is ApiException) {
    if (e.statusCode == 401) {
      return 'Session expired — please log in again and retry the upload.';
    }
    if (e.statusCode == 503 && e.message.contains('not configured')) {
      return 'Image uploads are not configured on the server. Add CLOUDINARY_* env vars on Render, then redeploy.';
    }
    if (e.statusCode == 502 || e.statusCode == 503) {
      if (e.message.contains('Cloudinary')) return e.message;
      return 'Image upload failed on the server. Check Cloudinary credentials on Render and redeploy.';
    }
    return e.message;
  }
  return e.toString().replaceFirst('Exception: ', '');
}
