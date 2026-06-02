import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppFocusDecoration {
  const AppFocusDecoration._();

  static const double unfocusedBorderWidth = 1;
  static const double selectedBorderWidth = 2.4;
  static const double focusedBorderWidth = 3.2;

  static BoxDecoration surface({
    required bool isFocused,
    bool isActive = false,
    bool isSelected = false,
    required Color backgroundColor,
    Color? activeBackgroundColor,
    Color? selectedBackgroundColor,
    required BorderRadiusGeometry borderRadius,
    bool glow = true,
  }) {
    return BoxDecoration(
      color: isFocused
          ? (activeBackgroundColor ?? backgroundColor)
          : isSelected
          ? (selectedBackgroundColor ?? activeBackgroundColor ?? backgroundColor)
          : isActive
          ? (activeBackgroundColor ?? backgroundColor)
          : backgroundColor,
      borderRadius: borderRadius,
      border: Border.all(
        color: isFocused || isSelected ? AppColors.focus : AppColors.border,
        width: isFocused
            ? focusedBorderWidth
            : isSelected
            ? selectedBorderWidth
            : unfocusedBorderWidth,
      ),
      boxShadow: glow && isFocused
          ? const [
              BoxShadow(
                color: AppColors.focusGlow,
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ]
          : null,
    );
  }

  static BoxDecoration circle({
    required bool isFocused,
    bool isActive = false,
    Color backgroundColor = Colors.transparent,
    Color? activeBackgroundColor,
  }) {
    return BoxDecoration(
      shape: BoxShape.circle,
      color: isActive ? (activeBackgroundColor ?? backgroundColor) : backgroundColor,
      border: Border.all(
        color: isFocused ? AppColors.focus : AppColors.border,
        width: isFocused ? focusedBorderWidth : unfocusedBorderWidth,
      ),
      boxShadow: isFocused
          ? const [
              BoxShadow(
                color: AppColors.focusGlow,
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ]
          : null,
    );
  }
}
