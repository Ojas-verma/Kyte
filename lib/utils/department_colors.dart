import 'package:flutter/material.dart';

import 'app_theme.dart';

Color departmentBadgeColor(String department) {
  switch (department.trim().toLowerCase()) {
    case 'engineering':
      return const Color(0xFF4F8CFF);
    case 'product':
      return const Color(0xFFFFB84D);
    case 'operations':
      return const Color(0xFF35C49A);
    case 'marketing':
      return const Color(0xFFEC6AA8);
    case 'hr':
    case 'human resources':
      return const Color(0xFFB68DFF);
    default:
      return AppTheme.accentBlue;
  }
}
