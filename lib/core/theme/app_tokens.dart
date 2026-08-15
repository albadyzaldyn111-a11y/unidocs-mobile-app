import 'package:flutter/material.dart';

class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

class AppRadius {
  AppRadius._();
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double pill = 999;
}

class AppElevation {
  AppElevation._();
  static const double card = 1;
  static const double dialog = 6;
  static const double bottomSheet = 8;
}

class AppTypography {
  AppTypography._();

  static TextTheme textTheme(Color primaryText, Color secondaryText) {
    return TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: primaryText, height: 1.25),
      headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: primaryText, height: 1.3),
      headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: primaryText, height: 1.3),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: primaryText),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: primaryText, height: 1.5),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: secondaryText, height: 1.5),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: primaryText),
      labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: secondaryText),
    );
  }
}
