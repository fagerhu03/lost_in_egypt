import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/weather_context.dart';

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

  @override
  Widget build(BuildContext context) {
    if (_dismissed || !WeatherBanner.shouldShow(widget.weather)) {
      return const SizedBox.shrink();
    }

    final color = widget.weather.severityColor;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
        padding: EdgeInsets.fromLTRB(14.w, 10.h, 8.w, 10.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          border: Border.all(color: color.withValues(alpha: 0.35)),
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 1.h),
              child: Icon(widget.weather.conditionIcon, color: color, size: 20.r),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        widget.weather.conditionLabel,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.sp,
                          fontFamily: 'Marcellus',
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        '· ${widget.weather.tempDisplay}  ${widget.weather.feelsLikeDisplay}',
                        style: TextStyle(
                          color: color.withValues(alpha: 0.75),
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    widget.weather.advisoryText,
                    style: TextStyle(
                      color: color.withValues(alpha: 0.85),
                      fontSize: 12.sp,
                      height: 1.4,
                    ),
                  ),
                  if (widget.onTap != null) ...[
                    SizedBox(height: 4.h),
                    Text(
                      'Tap for 7-day forecast',
                      style: TextStyle(
                        color: color,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: color,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.close_rounded, color: color.withValues(alpha: 0.7), size: 18.r),
              padding: EdgeInsets.only(left: 4.w),
              constraints: const BoxConstraints(),
              tooltip: 'Dismiss',
              onPressed: () => setState(() => _dismissed = true),
            ),
          ],
        ),
      ),
    );
  }
}
