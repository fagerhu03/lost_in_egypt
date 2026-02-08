import 'package:flutter/material.dart';
import 'package:lost_in_egypt/theme/theme.dart';

class AppTheme {
  static ThemeData light = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.lightBackground,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.lightPrimaryButton,
      brightness: Brightness.light,
      background: AppColors.lightBackground,
      surface: const Color(0xFFFFFEF0),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.lightBackground,
      foregroundColor: AppColors.lightText,
      elevation: 0,
    ),
  );

  static ThemeData dark = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.darkBackground,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.darkPrimaryButton,
      brightness: Brightness.dark,
      background: AppColors.darkBackground,
      surface: const Color(0xFF112B36),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkBackground,
      foregroundColor: AppColors.darkText,
      elevation: 0,
    ),
  );
}