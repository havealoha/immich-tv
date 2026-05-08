import 'package:flutter/widgets.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final imageCache = PaintingBinding.instance.imageCache;
  imageCache.maximumSize = 72;
  imageCache.maximumSizeBytes = 64 << 20;
  runImmichTvApp();
}
