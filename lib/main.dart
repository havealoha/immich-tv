import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final imageCache = PaintingBinding.instance.imageCache;
  imageCache.maximumSize = 72;
  imageCache.maximumSizeBytes = 64 << 20;
  await _initializeFirebaseIfSupported();
  await WakelockPlus.enable();
  runImmichTvApp();
}

Future<void> _initializeFirebaseIfSupported() async {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.linux) {
    return;
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}
