import 'api_client.dart';

String friendlyApiError(Object e) {
  if (e is ApiException) {
    if (e.statusCode == 401) {
      return 'Session expired — please log in again and retry the upload.';
    }
    if (e.statusCode == 503 &&
        (e.message.contains('not configured') || e.message.contains('Cloudinary'))) {
      return 'Image uploads are not configured on the server. Add CLOUDINARY_* env vars on Render, then redeploy.';
    }
    return e.message;
  }
  return e.toString().replaceFirst('Exception: ', '');
}
