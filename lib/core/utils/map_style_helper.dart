import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapStyleHelper {
  static String? _lightStyle;
  static String? _darkStyle;

  static Future<void> applyTheme(
    GoogleMapController controller,
    BuildContext context,
  ) async {
    try {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      if (isDark) {
        _darkStyle ??= await rootBundle.loadString('assets/darkmode_map_style.json');
        await controller.setMapStyle(_darkStyle);
      } else {
        _lightStyle ??= await rootBundle.loadString('assets/map_style.json');
        await controller.setMapStyle(_lightStyle);
      }
    } catch (_) {}
  }
}
