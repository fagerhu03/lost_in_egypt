import 'package:flutter/material.dart';

class ThemeController {
  static final ValueNotifier<ThemeMode> mode =
  ValueNotifier<ThemeMode>(ThemeMode.light);

  static void setDark(bool isDark) {
    mode.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }
}