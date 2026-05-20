import 'dart:typed_data';

import 'browser_blob_url_stub.dart'
    if (dart.library.js_interop) 'browser_blob_url_web.dart' as impl;

String createBrowserBlobUrl(
  Uint8List bytes, {
  required String mimeType,
}) => impl.createBrowserBlobUrl(bytes, mimeType: mimeType);

void revokeBrowserBlobUrl(String objectUrl) {
  impl.revokeBrowserBlobUrl(objectUrl);
}
