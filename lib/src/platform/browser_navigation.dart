import 'browser_navigation_stub.dart'
    if (dart.library.js_interop) 'browser_navigation_web.dart'
    as impl;

void openExternalUrl(String url) {
  impl.openExternalUrl(url);
}

void pushBrowserPath(String path) {
  impl.pushBrowserPath(path);
}
