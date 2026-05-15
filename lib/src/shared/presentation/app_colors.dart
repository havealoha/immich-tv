import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  // Official Immich logo-inspired colors
  static const immichRed = Color(0xFFFA2921);
  static const immichPink = Color(0xFFED79B5);
  static const immichYellow = Color(0xFFFFB400);
  static const immichBlue = Color(0xFF1E83F7);
  static const immichGreen = Color(0xFF18C249);

  // Dark theme
  static const darkBackground = Color(0xFF0C0C0C);
  static const darkSurface = Color(0xFF111827);
  static const darkSurfaceSoft = Color(0xFF1F2937);
  static const darkBorder = Color(0xFF374151);
  static const darkTextPrimary = Color(0xFFF9FAFB);
  static const darkTextSecondary = Color(0xFFD1D5DB);
  static const darkTextMuted = Color(0xFF9CA3AF);
  static const darkFocus = immichBlue;
  static const darkFocusGlow = Color(0x661E83F7);
  static const darkOverlay = Color(0x99000000);

  // Light theme
  static const lightBackground = Color(0xFFFFFFFF);
  static const lightSurface = Color(0xFFF9FAFB);
  static const lightSurfaceSoft = Color(0xFFF3F4F6);
  static const lightBorder = Color(0xFFE5E7EB);
  static const lightTextPrimary = Color(0xFF111827);
  static const lightTextSecondary = Color(0xFF4B5563);
  static const lightTextMuted = Color(0xFF6B7280);
  static const lightFocus = immichBlue;
  static const lightOverlay = Color(0x66000000);

  // Semantic aliases used across the app
  static const background = darkBackground;
  static const backgroundElevated = darkSurface;
  static const surface = darkSurface;
  static const surfaceMuted = darkSurfaceSoft;
  static const border = darkBorder;
  static const borderStrong = darkBorder;
  static const focus = darkFocus;
  static const focusGlow = darkFocusGlow;
  static const textPrimary = darkTextPrimary;
  static const textSecondary = darkTextSecondary;
  static const textMuted = darkTextMuted;
  static const actionForeground = darkTextPrimary;
  static const error = immichRed;
  static const success = immichGreen;
  static const warning = immichYellow;
  static const info = immichBlue;
  static const accentSecondary = immichPink;
  static const overlay = darkOverlay;
}
