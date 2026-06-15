import 'package:flutter/material.dart';
import 'package:lost_in_egypt/theme/theme.dart';

class AppTheme {
  /// Primary font family for [locale]. Marcellus is a Latin-only display font,
  /// so Arabic switches the app default to Cairo (which also renders Latin
  /// cleanly). Latin locales keep the branded Marcellus.
  static String fontFamilyFor(Locale locale) =>
      locale.languageCode == 'ar' ? 'Cairo' : 'Marcellus';

  /// Glyph fallback chain. Cairo carries the Arabic glyphs Marcellus lacks, so
  /// any text tagged with the Marcellus family still renders Arabic in Cairo
  /// (on-brand) rather than the system font — even in widgets that hardcode the
  /// family. Applied app-wide via [TextTheme.apply] in `main.dart`.
  static const List<String> fontFallback = ['Cairo'];

  static ThemeData light = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.lightBackground,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.lightPrimaryButton,
      brightness: Brightness.light,
      surface: const Color(0xFFFFFEF0),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.lightBackground,
      foregroundColor: AppColors.lightText,
      elevation: 0,
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      // insetPadding is typed EdgeInsets? (not EdgeInsetsGeometry), so it can't
      // take EdgeInsetsDirectional. Symmetric horizontally, so RTL-safe as-is.
      insetPadding: EdgeInsets.only(bottom: 80, left: 15, right: 15),
    ),
  );

  static ThemeData dark = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.darkBackground,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.darkPrimaryButton,
      brightness: Brightness.dark,
      surface: const Color(0xFF112B36),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkBackground,
      foregroundColor: AppColors.darkText,
      elevation: 0,
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      // insetPadding is typed EdgeInsets? (not EdgeInsetsGeometry), so it can't
      // take EdgeInsetsDirectional. Symmetric horizontally, so RTL-safe as-is.
      insetPadding: EdgeInsets.only(bottom: 80, left: 15, right: 15),
    ),
  );
}