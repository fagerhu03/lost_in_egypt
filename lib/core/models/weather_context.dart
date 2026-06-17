import 'package:flutter/material.dart';
import 'package:lost_in_egypt/l10n/app_localizations.dart';

// WMO weather code sets for conditions relevant to Egypt.
// These are the standard WMO 4677 interpretation codes that Open-Meteo returns.
const _sandstormCodes = {30, 31, 32, 33, 34, 35, 98};
const _dustHazeCodes = {6, 7, 8, 9};

/// Canonical weather condition, resolved in flag-priority order. Display text is
/// produced by [weatherConditionLabel] / [weatherAdvisoryText] so the model
/// itself stays locale-agnostic (the deferred model-level localization batch).
enum WeatherCondition {
  sandstorm,
  dustHaze,
  extremeHeat,
  veryHot,
  extremeUV,
  highUV,
  clear,
}

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

  WeatherCondition get condition {
    if (isSandstorm) return WeatherCondition.sandstorm;
    if (isDustHaze) return WeatherCondition.dustHaze;
    if (isExtremeHeat) return WeatherCondition.extremeHeat;
    if (isVeryHot) return WeatherCondition.veryHot;
    if (isExtremeUV) return WeatherCondition.extremeUV;
    if (isHighUV) return WeatherCondition.highUV;
    return WeatherCondition.clear;
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

  WeatherCondition get condition {
    if (isSandstorm) return WeatherCondition.sandstorm;
    if (isDustHaze) return WeatherCondition.dustHaze;
    if (isExtremeHeat) return WeatherCondition.extremeHeat;
    if (isVeryHot) return WeatherCondition.veryHot;
    if (isExtremeUV) return WeatherCondition.extremeUV;
    if (isHighUV) return WeatherCondition.highUV;
    return WeatherCondition.clear;
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

// ── Localized display resolvers ─────────────────────────────────────────────
// Top-level functions (mirroring `mapCategoryLabel` / `eventCategoryLabel`) so
// the model stays free of BuildContext / AppLocalizations.

/// Localized short condition label. [emphasis] selects the stronger
/// current-conditions wording used by [WeatherContext] ("Sandstorm Warning" /
/// "Good Conditions"); the plain forecast-day wording ("Sandstorm" / "Clear")
/// is the default for [DayForecast].
String weatherConditionLabel(
  AppLocalizations l10n,
  WeatherCondition condition, {
  bool emphasis = false,
}) {
  switch (condition) {
    case WeatherCondition.sandstorm:
      return emphasis ? l10n.weatherCondSandstormWarning : l10n.weatherCondSandstorm;
    case WeatherCondition.dustHaze:
      return l10n.weatherCondDustHaze;
    case WeatherCondition.extremeHeat:
      return l10n.weatherCondExtremeHeat;
    case WeatherCondition.veryHot:
      return l10n.weatherCondVeryHot;
    case WeatherCondition.extremeUV:
      return l10n.weatherCondExtremeUV;
    case WeatherCondition.highUV:
      return l10n.weatherCondHighUV;
    case WeatherCondition.clear:
      return emphasis ? l10n.weatherCondGood : l10n.weatherCondClear;
  }
}

/// Localized advisory paragraph for the current weather (interpolates the
/// feels-like temperature / UV index where relevant).
String weatherAdvisoryText(AppLocalizations l10n, WeatherContext w) {
  switch (w.condition) {
    case WeatherCondition.sandstorm:
      return l10n.weatherAdvisorySandstorm;
    case WeatherCondition.dustHaze:
      return l10n.weatherAdvisoryDustHaze;
    case WeatherCondition.extremeHeat:
      return l10n.weatherAdvisoryExtremeHeat(w.feelsLikeC.toStringAsFixed(0));
    case WeatherCondition.veryHot:
      return l10n.weatherAdvisoryVeryHot(w.feelsLikeC.toStringAsFixed(0));
    case WeatherCondition.extremeUV:
      return l10n.weatherAdvisoryExtremeUV(w.uvIndex.toStringAsFixed(0));
    case WeatherCondition.highUV:
      return l10n.weatherAdvisoryHighUV(w.uvIndex.toStringAsFixed(0));
    case WeatherCondition.clear:
      return l10n.weatherAdvisoryGood;
  }
}

/// Localized forecast day label ("Today" / "Tomorrow" / weekday abbreviation).
String weatherDayLabel(AppLocalizations l10n, DayForecast day) {
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final diff = day.date.difference(todayStart).inDays;
  if (diff == 0) return l10n.weatherDayToday;
  if (diff == 1) return l10n.weatherDayTomorrow;
  switch (day.date.weekday) {
    case DateTime.monday:
      return l10n.weekdayMon;
    case DateTime.tuesday:
      return l10n.weekdayTue;
    case DateTime.wednesday:
      return l10n.weekdayWed;
    case DateTime.thursday:
      return l10n.weekdayThu;
    case DateTime.friday:
      return l10n.weekdayFri;
    case DateTime.saturday:
      return l10n.weekdaySat;
    default:
      return l10n.weekdaySun;
  }
}
