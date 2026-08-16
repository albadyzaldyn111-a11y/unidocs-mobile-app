import 'package:flutter/material.dart';

/// Central color tokens. Never hardcode a hex value inside a widget —
/// add it here first so Light/Dark stay consistent across the app.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF2563EB); // vibrant academic blue from image
  static const Color primaryLight = Color(0xFF60A5FA);
  static const Color secondary = Color(0xFFFACC15); // bright gold from icon

  // Light theme surfaces
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightInput = Color(0xFFF1F5F9);
  static const Color lightBorder = Color(0xFFE2E8F0);

  // Dark theme surfaces — matches the deep navy/black from the image
  static const Color darkBackground = Color(0xFF0F172A); 
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkInput = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF334155);

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
