import 'package:flutter/material.dart';

// WMO weather code sets for conditions relevant to Egypt.
// These are the standard WMO 4677 interpretation codes that Open-Meteo returns.
const _sandstormCodes = {30, 31, 32, 33, 34, 35, 98};
const _dustHazeCodes = {6, 7, 8, 9};

// ── Day Forecast ──────────────────────────────────────────────────────────────

class DayForecast {
  final DateTime date;
  final double maxTempC;
  final double minTempC;
  final double maxFeelsLikeC;
  final double maxUvIndex;
  final int wmoCode;

  const DayForecast({
    required this.date,
    required this.maxTempC,
    required this.minTempC,
    required this.maxFeelsLikeC,
    required this.maxUvIndex,
    required this.wmoCode,
  });

  bool get isSandstorm => _sandstormCodes.contains(wmoCode);
  bool get isDustHaze => _dustHazeCodes.contains(wmoCode);
  bool get isExtremeHeat => maxFeelsLikeC >= 38;
  bool get isVeryHot => maxFeelsLikeC >= 33;
  bool get isExtremeUV => maxUvIndex >= 10;
  bool get isHighUV => maxUvIndex >= 6;
  bool get isOutdoorAdvisory =>
      isSandstorm || isDustHaze || isExtremeHeat || isExtremeUV;

  String get dayLabel {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final diff = date.difference(todayStart).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  String get conditionLabel {
    if (isSandstorm) return 'Sandstorm';
    if (isDustHaze) return 'Dust Haze';
    if (isExtremeHeat) return 'Extreme Heat';
    if (isVeryHot) return 'Very Hot';
    if (isExtremeUV) return 'Extreme UV';
    if (isHighUV) return 'High UV';
    return 'Clear';
  }

  Color get severityColor {
    if (isSandstorm) return const Color(0xFFA0522D);
    if (isDustHaze) return const Color(0xFFB8860B);
    if (isExtremeHeat) return const Color(0xFFBF360C);
    if (isVeryHot) return const Color(0xFFE65100);
    if (isExtremeUV) return const Color(0xFFD84315);
    if (isHighUV) return const Color(0xFFF57F17);
    return const Color(0xFF2E7D32);
  }
}

// ── Current Weather Context ───────────────────────────────────────────────────

class WeatherContext {
  final double tempC;
  final double feelsLikeC;
  final double uvIndex;
  final int wmoCode;
  final double windSpeedKmh;
  final int humidityPercent;
  final List<DayForecast> forecast;

  const WeatherContext({
    required this.tempC,
    required this.feelsLikeC,
    required this.uvIndex,
    required this.wmoCode,
    required this.windSpeedKmh,
    required this.humidityPercent,
    required this.forecast,
  });

  // ── Condition flags ────────────────────────────────────────────────────────

  // Khamsin / duststorm: WMO 30–35 (duststorm severity grades) + 98 (with thunder)
  bool get isSandstorm => _sandstormCodes.contains(wmoCode);

  // Dust haze / raised dust: WMO 06–09 — visibility reduced but not a full storm
  bool get isDustHaze => _dustHazeCodes.contains(wmoCode);

  // Feels-like ≥ 38°C — dangerous for prolonged outdoor exposure
  bool get isExtremeHeat => feelsLikeC >= 38;

  // Feels-like 33–37°C — uncomfortable outdoors, especially midday
  bool get isVeryHot => feelsLikeC >= 33 && feelsLikeC < 38;

  // UV ≥ 10: risk of sunburn within minutes; common in Egypt 10am–3pm
  bool get isExtremeUV => uvIndex >= 10;

  // UV 6–9: still high; sunscreen required
  bool get isHighUV => uvIndex >= 6 && uvIndex < 10;

  // True when any condition warrants showing a banner / advisory to the user
  bool get isOutdoorAdvisory =>
      isSandstorm || isDustHaze || isExtremeHeat || isVeryHot || isExtremeUV || isHighUV;

  // ── Display helpers ────────────────────────────────────────────────────────

  String get tempDisplay => '${tempC.toStringAsFixed(0)}°C';
  String get feelsLikeDisplay => 'Feels ${feelsLikeC.toStringAsFixed(0)}°C';

  String get conditionLabel {
    if (isSandstorm) return 'Sandstorm Warning';
    if (isDustHaze) return 'Dust Haze';
    if (isExtremeHeat) return 'Extreme Heat';
    if (isVeryHot) return 'Very Hot';
    if (isExtremeUV) return 'Extreme UV';
    if (isHighUV) return 'High UV';
    return 'Good Conditions';
  }

  String get advisoryText {
    if (isSandstorm) {
      return 'Sandstorm in the area — avoid all outdoor locations. Wear a mask if you must travel.';
    }
    if (isDustHaze) {
      return 'Dust haze reducing visibility. Outdoor visits not ideal; wear sunglasses.';
    }
    if (isExtremeHeat) {
      return 'Feels like ${feelsLikeC.toStringAsFixed(0)}°C. Visit outdoor sites before 9am or after 5pm only. Bring at least 2L of water.';
    }
    if (isVeryHot) {
      return 'Very hot (${feelsLikeC.toStringAsFixed(0)}°C feels-like). Stay hydrated and seek shade often.';
    }
    if (isExtremeUV) {
      return 'UV index ${uvIndex.toStringAsFixed(0)} — extreme. Sunscreen, hat, and sunglasses are essential. Limit midday exposure.';
    }
    if (isHighUV) {
      return 'UV index ${uvIndex.toStringAsFixed(0)} — high. Apply sunscreen SPF 50+ before going outdoors.';
    }
    return 'Great conditions for outdoor exploration today.';
  }

  Color get severityColor {
    if (isSandstorm) return const Color(0xFFA0522D);   // sienna — sand colour
    if (isDustHaze) return const Color(0xFFB8860B);    // dark goldenrod
    if (isExtremeHeat) return const Color(0xFFBF360C); // deep orange-red
    if (isVeryHot) return const Color(0xFFE65100);     // orange
    if (isExtremeUV) return const Color(0xFFD84315);   // orange-red
    if (isHighUV) return const Color(0xFFF57F17);      // amber
    return const Color(0xFF2E7D32);                     // green
  }

  IconData get conditionIcon {
    if (isSandstorm || isDustHaze) return Icons.air;
    if (isExtremeHeat || isVeryHot) return Icons.thermostat;
    if (isExtremeUV || isHighUV) return Icons.wb_sunny;
    return Icons.wb_sunny_outlined;
  }

  // ── Recommendation engine context ──────────────────────────────────────────

  // Serialised form passed as weatherContext to the recommendPlaces Cloud Function.
  // The function uses these booleans to penalise outdoor places.
  Map<String, dynamic> toEngineContext() => {
        'tempC': tempC,
        'feelsLikeC': feelsLikeC,
        'uvIndex': uvIndex,
        'wmoCode': wmoCode,
        'isSandstorm': isSandstorm,
        'isDustHaze': isDustHaze,
        'isExtremeHeat': isExtremeHeat,
        'isVeryHot': isVeryHot,
        'isExtremeUV': isExtremeUV,
        'isHighUV': isHighUV,
      };
}
