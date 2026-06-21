import 'package:flutter/material.dart';

/// Breakpoints used across the app to deliver distinct
/// desktop / tablet / mobile UI from one codebase.
class Breakpoints {
  static const double mobile = 640;
  static const double tablet = 1024;
}

enum DeviceType { mobile, tablet, desktop }

class Responsive {
  static DeviceType of(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < Breakpoints.mobile) return DeviceType.mobile;
    if (w < Breakpoints.tablet) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  static bool isMobile(BuildContext c) => of(c) == DeviceType.mobile;
  static bool isTablet(BuildContext c) => of(c) == DeviceType.tablet;
  static bool isDesktop(BuildContext c) => of(c) == DeviceType.desktop;
  static bool isWide(BuildContext c) => of(c) != DeviceType.mobile;
}

/// Picks a value based on the current device type.
T responsiveValue<T>(
  BuildContext context, {
  required T mobile,
  T? tablet,
  required T desktop,
}) {
  switch (Responsive.of(context)) {
    case DeviceType.mobile:
      return mobile;
    case DeviceType.tablet:
      return tablet ?? desktop;
    case DeviceType.desktop:
      return desktop;
  }
}

/// Renders different widget trees per device type.
class ResponsiveLayout extends StatelessWidget {
  final WidgetBuilder mobile;
  final WidgetBuilder? tablet;
  final WidgetBuilder desktop;
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    switch (Responsive.of(context)) {
      case DeviceType.mobile:
        return mobile(context);
      case DeviceType.tablet:
        return (tablet ?? desktop)(context);
      case DeviceType.desktop:
        return desktop(context);
    }
  }
}
