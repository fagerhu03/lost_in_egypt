import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MapStyleHelper {
  static String? _lightStyle;
  static String? _darkStyle;

  static Future<String?> getStyle(BuildContext context) async {
    try {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      if (isDark) {
        _darkStyle ??= await rootBundle.loadString('assets/darkmode_map_style.json');
        return _darkStyle;
      } else {
        _lightStyle ??= await rootBundle.loadString('assets/map_style.json');
        return _lightStyle;
      }
    } catch (_) {
      return null;
    }
  }
}
