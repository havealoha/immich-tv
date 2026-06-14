import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
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
  unawaited(_enableWakelockIfSupported());
  runImmichTvApp();
}

Future<void> _initializeFirebaseIfSupported() async {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.linux) {
    return;
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    _configureFirestoreIfSupported();
  } catch (error, stackTrace) {
    debugPrint('Firebase initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

void _configureFirestoreIfSupported() {
  if (!kIsWeb) {
    return;
  }

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false,
    webExperimentalForceLongPolling: true,
    webExperimentalLongPollingOptions: WebExperimentalLongPollingOptions(
      timeoutDuration: Duration(seconds: 15),
    ),
  );
}

Future<void> _enableWakelockIfSupported() async {
  try {
    await WakelockPlus.enable();
  } catch (_) {
    // Mobile browsers can reject wake-lock requests during startup. Rendering
    // the app is more important; native platforms can still enable it.
  }
}
