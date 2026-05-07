import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'app_breakpoints.dart';

class AppScale {
  const AppScale._(this.size);

  static const Size _designSize = Size(1366, 1024);

  final Size size;

  static AppScale of(BuildContext context) =>
      AppScale._(MediaQuery.sizeOf(context));

  double get widthRatio => size.width / _designSize.width;
  double get heightRatio => size.height / _designSize.height;

  double get componentScale =>
      math.min(widthRatio, heightRatio).clamp(0.84, 1.08).toDouble();

  double get typographyScale =>
      ((widthRatio * 0.4) + (heightRatio * 0.6)).clamp(0.9, 1.06).toDouble();

  bool get isCompactWidth => size.width < AppBreakpoints.tablet;
  bool get isTvLayout => size.width >= AppBreakpoints.tv;

  double space(double value, {double? min, double? max}) {
    return _clamp(value * componentScale, min: min, max: max);
  }

  double sizeOf(double value, {double? min, double? max}) {
    return _clamp(value * componentScale, min: min, max: max);
  }

  double text(double value, {double? min, double? max}) {
    return _clamp(value * typographyScale, min: min, max: max);
  }

  double radius(double value, {double? min, double? max}) {
    return _clamp(value * componentScale, min: min, max: max);
  }

  double _clamp(double value, {double? min, double? max}) {
    final lower = min ?? double.negativeInfinity;
    final upper = max ?? double.infinity;
    return value.clamp(lower, upper).toDouble();
  }
}
