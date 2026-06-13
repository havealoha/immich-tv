import 'package:web/web.dart' as web;

void openExternalUrl(String url) {
  web.window.open(url, '_blank', 'noopener,noreferrer');
}

void pushBrowserPath(String path) {
  final normalizedPath = path.startsWith('/') ? path : '/$path';
  web.window.history.pushState(null, '', normalizedPath);
}
