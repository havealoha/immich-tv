import '../../core/models/server_config.dart';

Future<void> primeBrowserImmichSession({
  required ServerConfig serverConfig,
  required String email,
  required String password,
}) async {}

bool canUseDirectBrowserMediaPlayback(Uri mediaUri) => false;

void markDirectBrowserMediaPlaybackFailure(Uri mediaUri) {}

void resetBrowserImmichSessions() {}
