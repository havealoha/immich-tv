import 'package:flutter/material.dart';

import '../../../core/models/saved_profile.dart';

Color profileAvatarColor(SavedProfile profile) {
  const palette = <Color>[
    Color(0xFF4A90E2),
    Color(0xFF2BB3A3),
    Color(0xFFEA7B66),
    Color(0xFFE1A948),
    Color(0xFF8A6DE9),
    Color(0xFF4FB06D),
  ];

  return palette[profile.id.hashCode.abs() % palette.length];
}
