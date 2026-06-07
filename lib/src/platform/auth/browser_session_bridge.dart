import '../../core/models/server_config.dart';
import 'browser_session_bridge_stub.dart'
    if (dart.library.js_interop) 'browser_session_bridge_web.dart' as impl;

Future<void> primeBrowserImmichSession({
  required ServerConfig serverConfig,
  required String email,
  required String password,
}) {
  return impl.primeBrowserImmichSession(
    serverConfig: serverConfig,
    email: email,
    password: password,
  );
}

bool canUseDirectBrowserMediaPlayback(Uri mediaUri) {
  return impl.canUseDirectBrowserMediaPlayback(mediaUri);
}

void markDirectBrowserMediaPlaybackFailure(Uri mediaUri) {
  impl.markDirectBrowserMediaPlaybackFailure(mediaUri);
}

void resetBrowserImmichSessions() {
  impl.resetBrowserImmichSessions();
}
