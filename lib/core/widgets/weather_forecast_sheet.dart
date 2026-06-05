import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
                margin: EdgeInsets.only(top: 12.h, bottom: 8.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: onSurface.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),

              // ── Current conditions card ─────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 4.h),
                child: Container(
                  padding: EdgeInsets.all(20.r),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    border: Border.all(color: color.withValues(alpha: 0.30)),
                    borderRadius: BorderRadius.circular(18.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(weather.conditionIcon, color: color, size: 28.r),
                          SizedBox(width: 12.w),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                weather.conditionLabel,
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 17.sp,
                                  fontFamily: 'Marcellus',
                                ),
                              ),
                              Text(
                                'Egypt conditions right now',
                                style: TextStyle(
                                  color: dimText,
                                  fontSize: 12.sp,
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
                                  fontSize: 28.sp,
                                  fontWeight: FontWeight.w300,
                                  fontFamily: 'Marcellus',
                                ),
                              ),
                              Text(
                                weather.feelsLikeDisplay,
                                style: TextStyle(color: dimText, fontSize: 12.sp),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 14.h),
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
                        SizedBox(height: 12.h),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 12.w, vertical: 8.h),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Text(
                            weather.advisoryText,
                            style: TextStyle(
                              color: color.withValues(alpha: 0.85),
                              fontSize: 12.sp,
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
                padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 8.h),
                child: Row(
                  children: [
                    Container(
                      width: 3.w,
                      height: 18.h,
                      decoration: BoxDecoration(
                        color: primary,
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      '7-Day Forecast',
                      style: TextStyle(
                        color: onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 15.sp,
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
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 32.h),
                  itemCount: weather.forecast.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    color: onSurface.withValues(alpha: 0.07),
                    indent: 12.w,
                    endIndent: 12.w,
                  ),
                  itemBuilder: (_, i) {
                    final day = weather.forecast[i];
                    final dayColor = day.isOutdoorAdvisory
                        ? day.severityColor
                        : onSurface;
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      child: Row(
                        children: [
                          // Day label
                          SizedBox(
                            width: 68.w,
                            child: Text(
                              day.dayLabel,
                              style: TextStyle(
                                color: i == 0 ? primary : onSurface,
                                fontWeight: i == 0
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                fontSize: 14.sp,
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
                            size: 18.r,
                          ),
                          SizedBox(width: 6.w),
                          Expanded(
                            child: Text(
                              day.conditionLabel,
                              style: TextStyle(
                                color: dayColor.withValues(alpha: 0.8),
                                fontSize: 13.sp,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // UV badge (only when elevated)
                          if (day.isHighUV)
                            Container(
                              margin: EdgeInsets.only(right: 8.w),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: day.severityColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Text(
                                'UV ${day.maxUvIndex.toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: day.severityColor,
                                  fontSize: 11.sp,
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
                                  fontSize: 14.sp,
                                ),
                              ),
                              SizedBox(width: 2.w),
                              Text(
                                '/ ${day.minTempC.toStringAsFixed(0)}°',
                                style: TextStyle(
                                  color: dimText,
                                  fontSize: 13.sp,
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
        Icon(icon, color: color, size: 15.r),
        SizedBox(width: 4.w),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
