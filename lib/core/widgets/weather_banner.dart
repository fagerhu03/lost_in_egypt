import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lost_in_egypt/l10n/app_localizations.dart';

import '../models/weather_context.dart';
import '../../theme/theme.dart';

class WeatherBanner extends StatefulWidget {
  final WeatherContext weather;
  final VoidCallback? onTap;

  const WeatherBanner({super.key, required this.weather, this.onTap});

  static bool shouldShow(WeatherContext weather) => weather.isOutdoorAdvisory;

  @override
  State<WeatherBanner> createState() => _WeatherBannerState();
}

class _WeatherBannerState extends State<WeatherBanner> {
  bool _dismissed = false;

  @override
  void didUpdateWidget(WeatherBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weather.conditionLabel != widget.weather.conditionLabel) {
      _dismissed = false;
    }
  }

  bool get _isSevere =>
      widget.weather.isSandstorm ||
      widget.weather.isExtremeHeat ||
      widget.weather.isExtremeUV;

  @override
  Widget build(BuildContext context) {
    if (_dismissed || !WeatherBanner.shouldShow(widget.weather)) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l = AppLocalizations.of(context);

    // Two-tone palette tuned to match the cream/gold/deep-blue Egyptian theme.
    // Severe advisories use a deep terracotta that reads as urgent without
    // clashing with the gold accent; standard advisories use the app gold.
    final accent = _isSevere
        ? (isDark ? const Color(0xFFE89364) : const Color(0xFFB8470F))
        : (isDark ? const Color(0xFFE8B824) : AppColors.lightPrimaryButton);

    final surface = isDark ? AppColors.darkPatternOverlay : Colors.white;
    final titleColor = isDark ? AppColors.darkText : AppColors.lightBox;
    final bodyColor = isDark
        ? AppColors.darkText.withValues(alpha: 0.78)
        : AppColors.lightText.withValues(alpha: 0.82);

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
        padding: EdgeInsets.fromLTRB(12.w, 12.h, 6.w, 12.h),
        decoration: BoxDecoration(
          color: surface,
          border: Border.all(color: accent.withValues(alpha: 0.45)),
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: isDark ? 0.10 : 0.14),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: isDark ? 0.18 : 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(widget.weather.conditionIcon, color: accent, size: 18.r),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.weather.conditionLabel,
                          style: TextStyle(
                            color: titleColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 13.sp,
                            fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo'],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        '· ${widget.weather.tempDisplay}  ${widget.weather.feelsLikeDisplay}',
                        style: TextStyle(
                          color: bodyColor,
                          fontSize: 11.sp,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    widget.weather.advisoryText,
                    style: TextStyle(
                      color: bodyColor,
                      fontSize: 12.sp,
                      height: 1.4,
                    ),
                  ),
                  if (widget.onTap != null) ...[
                    SizedBox(height: 4.h),
                    Text(
                      l.weatherTapForForecast,
                      style: TextStyle(
                        color: accent,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.close_rounded, color: bodyColor, size: 18.r),
              padding: EdgeInsetsDirectional.only(start: 4.w),
              constraints: const BoxConstraints(),
              tooltip: l.commonDismiss,
              onPressed: () => setState(() => _dismissed = true),
            ),
          ],
        ),
      ),
    );
  }
}
