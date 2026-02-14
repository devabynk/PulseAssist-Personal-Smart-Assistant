import 'package:flutter/material.dart';

class Responsive {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 1200;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1200;

  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  static int gridCrossAxisCount(BuildContext context) {
    if (isDesktop(context)) return 4;
    if (isTablet(context)) return 3;
    return 2;
  }

  static double horizontalPadding(BuildContext context) {
    if (isDesktop(context)) return 48;
    if (isTablet(context)) return 32;
    return 16;
  }

  static double chatBubbleMaxWidth(BuildContext context) {
    final width = screenWidth(context);
    if (isDesktop(context)) return width * 0.4;
    if (isTablet(context)) return width * 0.6;
    return width * 0.75;
  }

  static EdgeInsets screenPadding(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: horizontalPadding(context),
      vertical: 16,
    );
  }

  // Adaptive text sizes
  static double titleFontSize(BuildContext context) {
    if (isDesktop(context)) return 28;
    if (isTablet(context)) return 24;
    return 20;
  }

  static double bodyFontSize(BuildContext context) {
    if (isDesktop(context)) return 18;
    if (isTablet(context)) return 16;
    return 14;
  }
}

// Extension for easy access
extension ResponsiveExtension on BuildContext {
  bool get isMobile => Responsive.isMobile(this);
  bool get isTablet => Responsive.isTablet(this);
  bool get isDesktop => Responsive.isDesktop(this);
  int get gridColumns => Responsive.gridCrossAxisCount(this);
  double get horizontalPadding => Responsive.horizontalPadding(this);
}
