import 'package:flutter/widgets.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final imageCache = PaintingBinding.instance.imageCache;
  imageCache.maximumSize = 72;
  imageCache.maximumSizeBytes = 64 << 20;
  await WakelockPlus.enable();
  runImmichTvApp();
}
