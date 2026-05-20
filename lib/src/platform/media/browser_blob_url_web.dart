import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

String createBrowserBlobUrl(
  Uint8List bytes, {
  required String mimeType,
}) {
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: mimeType),
  );
  return web.URL.createObjectURL(blob);
}

void revokeBrowserBlobUrl(String objectUrl) {
  web.URL.revokeObjectURL(objectUrl);
}
