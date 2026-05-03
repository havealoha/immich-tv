import 'app_breakpoints.dart';

enum ViewportClass { phone, tablet, desktop, tv }

class AppViewport {
  const AppViewport._();

  static ViewportClass resolve(double width) {
    if (width >= AppBreakpoints.tv) {
      return ViewportClass.tv;
    }
    if (width >= AppBreakpoints.desktop) {
      return ViewportClass.desktop;
    }
    if (width >= AppBreakpoints.tablet) {
      return ViewportClass.tablet;
    }
    return ViewportClass.phone;
  }
}
