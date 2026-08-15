import 'package:flutter/material.dart';

/// Central color tokens. Never hardcode a hex value inside a widget —
/// add it here first so Light/Dark stay consistent across the app.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF1E4B8F); // deep academic blue
  static const Color primaryLight = Color(0xFF3E6EB5);
  static const Color secondary = Color(0xFFB8862E); // muted gold accent

  // Light theme surfaces
  static const Color lightBackground = Color(0xFFF7F8FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightInput = Color(0xFFF0F2F5);
  static const Color lightBorder = Color(0xFFE2E5EA);

  // Dark theme surfaces — layered, not pure black, for clear hierarchy.
  static const Color darkBackground = Color(0xFF14161B);
  static const Color darkSurface = Color(0xFF1C1F26);
  static const Color darkCard = Color(0xFF232630);
  static const Color darkInput = Color(0xFF2A2E38);
  static const Color darkBorder = Color(0xFF343945);

  // Semantic
  static const Color success = Color(0xFF2E9E5B);
  static const Color warning = Color(0xFFC98A1F);
  static const Color danger = Color(0xFFD1483F);
  static const Color info = Color(0xFF3E7BC4);

  // Status chips (file lifecycle)
  static const Color statusPending = warning;
  static const Color statusApproved = success;
  static const Color statusRejected = danger;
  static const Color statusArchived = Color(0xFF8B909C);

  // Text
  static const Color lightTextPrimary = Color(0xFF1A1C21);
  static const Color lightTextSecondary = Color(0xFF5B616E);
  static const Color darkTextPrimary = Color(0xFFF2F3F5);
  static const Color darkTextSecondary = Color(0xFFAAB0BC);
}
