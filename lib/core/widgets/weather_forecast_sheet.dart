import 'package:flutter/material.dart';
import '../models/weather_context.dart';
import '../services/weather_controller.dart';

/// Full 7-day forecast bottom sheet.
///
/// Usage:
///   WeatherForecastSheet.show(context);
class WeatherForecastSheet extends StatelessWidget {
  final WeatherContext weather;

  const WeatherForecastSheet({super.key, required this.weather});

  static void show(BuildContext context) {
    final w = WeatherController.weather.value;
    if (w == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WeatherForecastSheet(weather: w),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF1A2E3B) : Colors.white;
    final onSurface = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final dimText = onSurface.withValues(alpha: 0.55);
    final primary = Theme.of(context).colorScheme.primary;
    final color = weather.severityColor;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // ── Handle ─────────────────────────────────────────────────────
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: onSurface.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // ── Current conditions card ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    border: Border.all(color: color.withValues(alpha: 0.30)),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(weather.conditionIcon, color: color, size: 28),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                weather.conditionLabel,
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 17,
                                  fontFamily: 'Marcellus',
                                ),
                              ),
                              Text(
                                'Egypt conditions right now',
                                style: TextStyle(
                                  color: dimText,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                weather.tempDisplay,
                                style: TextStyle(
                                  color: onSurface,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w300,
                                  fontFamily: 'Marcellus',
                                ),
                              ),
                              Text(
                                weather.feelsLikeDisplay,
                                style: TextStyle(color: dimText, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Stats row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatChip(
                            icon: Icons.wb_sunny_outlined,
                            label: 'UV ${weather.uvIndex.toStringAsFixed(0)}',
                            color: weather.isExtremeUV ? color : dimText,
                          ),
                          _StatChip(
                            icon: Icons.air,
                            label: '${weather.windSpeedKmh.toStringAsFixed(0)} km/h',
                            color: weather.isSandstorm ? color : dimText,
                          ),
                          _StatChip(
                            icon: Icons.water_drop_outlined,
                            label: '${weather.humidityPercent}%',
                            color: dimText,
                          ),
                        ],
                      ),
                      if (weather.isOutdoorAdvisory) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            weather.advisoryText,
                            style: TextStyle(
                              color: color.withValues(alpha: 0.85),
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // ── 7-day header ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Container(
                      width: 3,
                      height: 18,
                      decoration: BoxDecoration(
                        color: primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '7-Day Forecast',
                      style: TextStyle(
                        color: onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        fontFamily: 'Marcellus',
                      ),
                    ),
                  ],
                ),
              ),

              // ── Forecast list ───────────────────────────────────────────
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  itemCount: weather.forecast.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    color: onSurface.withValues(alpha: 0.07),
                    indent: 12,
                    endIndent: 12,
                  ),
                  itemBuilder: (_, i) {
                    final day = weather.forecast[i];
                    final dayColor = day.isOutdoorAdvisory
                        ? day.severityColor
                        : onSurface;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          // Day label
                          SizedBox(
                            width: 68,
                            child: Text(
                              day.dayLabel,
                              style: TextStyle(
                                color: i == 0 ? primary : onSurface,
                                fontWeight: i == 0
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                fontSize: 14,
                                fontFamily: 'Marcellus',
                              ),
                            ),
                          ),
                          // Condition icon + label
                          Icon(
                            day.isSandstorm || day.isDustHaze
                                ? Icons.air
                                : day.isExtremeHeat || day.isVeryHot
                                    ? Icons.thermostat
                                    : Icons.wb_sunny_outlined,
                            color: dayColor.withValues(alpha: 0.7),
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              day.conditionLabel,
                              style: TextStyle(
                                color: dayColor.withValues(alpha: 0.8),
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // UV badge (only when elevated)
                          if (day.isHighUV)
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: day.severityColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'UV ${day.maxUvIndex.toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: day.severityColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          // Temp range
                          Row(
                            children: [
                              Text(
                                '${day.maxTempC.toStringAsFixed(0)}°',
                                style: TextStyle(
                                  color: onSurface,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '/ ${day.minTempC.toStringAsFixed(0)}°',
                                style: TextStyle(
                                  color: dimText,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
