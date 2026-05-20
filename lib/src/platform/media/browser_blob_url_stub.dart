import 'dart:typed_data';

String createBrowserBlobUrl(
  Uint8List bytes, {
  required String mimeType,
}) {
  throw UnsupportedError('Browser blob URLs are only available on web.');
}

void revokeBrowserBlobUrl(String objectUrl) {}
