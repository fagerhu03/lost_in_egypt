import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/weather_context.dart';

/// Fetches current weather + 7-day forecast from Open-Meteo (free, no API key).
///
/// Results are cached for 30 minutes. If the user moves more than 50 km from
/// the last fetch location the cache is invalidated and a fresh call is made.
/// On network failure, the stale cache is returned rather than null so the rest
/// of the app keeps working.
class WeatherService {
  static const _baseUrl = 'https://api.open-meteo.com/v1/forecast';
  static const _cacheDuration = Duration(minutes: 30);
  static const _locationThresholdKm = 50.0;

  static WeatherContext? _cached;
  static DateTime? _cachedAt;
  static double? _cachedLat;
  static double? _cachedLng;

  static bool _isCacheValid(double lat, double lng) {
    if (_cached == null || _cachedAt == null) return false;
    if (DateTime.now().difference(_cachedAt!) > _cacheDuration) return false;
    if (_cachedLat != null && _cachedLng != null) {
      if (_haversineKm(lat, lng, _cachedLat!, _cachedLng!) > _locationThresholdKm) {
        return false;
      }
    }
    return true;
  }

  /// Returns a [WeatherContext] for the given coordinates.
  /// Returns null only if there is no cache and the network call fails.
  static Future<WeatherContext?> getWeather(double lat, double lng) async {
    if (_isCacheValid(lat, lng)) return _cached;

    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'latitude': lat.toStringAsFixed(4),
        'longitude': lng.toStringAsFixed(4),
        'current': [
          'temperature_2m',
          'apparent_temperature',
          'weather_code',
          'uv_index',
          'wind_speed_10m',
          'relative_humidity_2m',
        ].join(','),
        'daily': [
          'temperature_2m_max',
          'temperature_2m_min',
          'apparent_temperature_max',
          'weather_code',
          'uv_index_max',
        ].join(','),
        'forecast_days': '7',
        'timezone': 'auto',
      });

      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        debugPrint('WeatherService: HTTP ${response.statusCode}');
        return _cached;
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final context = _parse(json);

      _cached = context;
      _cachedAt = DateTime.now();
      _cachedLat = lat;
      _cachedLng = lng;

      return context;
    } catch (e) {
      debugPrint('WeatherService: fetch failed — $e');
      return _cached;
    }
  }

  static WeatherContext _parse(Map<String, dynamic> json) {
    final c = json['current'] as Map<String, dynamic>;
    final d = json['daily'] as Map<String, dynamic>;

    return WeatherContext(
      tempC: (c['temperature_2m'] as num).toDouble(),
      feelsLikeC: (c['apparent_temperature'] as num).toDouble(),
      uvIndex: (c['uv_index'] as num?)?.toDouble() ?? 0,
      wmoCode: (c['weather_code'] as num).toInt(),
      windSpeedKmh: (c['wind_speed_10m'] as num).toDouble(),
      humidityPercent: (c['relative_humidity_2m'] as num).toInt(),
      forecast: _parseForecast(d),
    );
  }

  static List<DayForecast> _parseForecast(Map<String, dynamic> d) {
    final dates = d['time'] as List;
    final maxTemps = d['temperature_2m_max'] as List;
    final minTemps = d['temperature_2m_min'] as List;
    final maxFeels = d['apparent_temperature_max'] as List;
    final codes = d['weather_code'] as List;
    final uvMaxes = d['uv_index_max'] as List;

    return List.generate(dates.length, (i) {
      return DayForecast(
        date: DateTime.parse(dates[i] as String),
        maxTempC: (maxTemps[i] as num).toDouble(),
        minTempC: (minTemps[i] as num).toDouble(),
        maxFeelsLikeC: (maxFeels[i] as num).toDouble(),
        wmoCode: (codes[i] as num).toInt(),
        maxUvIndex: (uvMaxes[i] as num?)?.toDouble() ?? 0,
      );
    });
  }

  // Haversine formula — straight-line distance between two lat/lng points in km.
  // Used only for cache invalidation (checking if the user has moved far enough
  // to warrant a fresh weather fetch), so accuracy to ~1 km is sufficient.
  static double _haversineKm(
      double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(_rad(lat1)) *
            math.cos(_rad(lat2)) *
            math.pow(math.sin(dLon / 2), 2);
    return 2 * r * math.asin(math.sqrt(a));
  }

  static double _rad(double deg) => deg * math.pi / 180;
}
