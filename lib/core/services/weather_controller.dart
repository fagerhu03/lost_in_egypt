import 'package:flutter/foundation.dart';

import '../models/weather_context.dart';
import 'weather_service.dart';

/// Global weather state — same singleton pattern as [ThemeController] and
/// [CurrencyController]. Not registered in GetIt.
///
/// Usage:
///   // Fetch (call once after location is determined, e.g. in MapBloc/AuthGate)
///   await WeatherController.refresh(lat, lng);
///
///   // React in UI
///   `ValueListenableBuilder<WeatherContext?>`(
///     valueListenable: WeatherController.weather,
///     builder: (_, weather, __) { ... },
///   )
class WeatherController {
  static final ValueNotifier<WeatherContext?> weather =
      ValueNotifier<WeatherContext?>(null);

  /// Fetches fresh weather for [lat]/[lng] and updates [weather].
  /// Respects the 30-min cache in [WeatherService] — safe to call repeatedly.
  static Future<void> refresh(double lat, double lng) async {
    final context = await WeatherService.getWeather(lat, lng);
    if (context != null) weather.value = context;
  }

  /// Clears the current weather value (e.g. on sign-out).
  static void clear() => weather.value = null;
}
