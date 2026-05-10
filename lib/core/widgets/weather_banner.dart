import 'package:flutter/material.dart';

import '../models/weather_context.dart';

/// Dismissable advisory banner shown when current weather conditions warrant a
/// warning (extreme heat, sandstorm, high UV, etc.).
///
/// Wrap in a [ValueListenableBuilder] on [WeatherController.weather] at the
/// call site. Only renders when [WeatherContext.isOutdoorAdvisory] is true.
///
/// Usage:
///   `ValueListenableBuilder<WeatherContext?>`(
///     valueListenable: WeatherController.weather,
///     builder: (_, weather, __) => weather == null
///         ? const SizedBox.shrink()
///         : WeatherBanner(weather: weather, onTap: _openForecastSheet),
///   )
class WeatherBanner extends StatefulWidget {
  final WeatherContext weather;

  /// Optional callback when the banner body is tapped — use to open a full
  /// forecast bottom sheet.
  final VoidCallback? onTap;

  const WeatherBanner({super.key, required this.weather, this.onTap});

  /// Returns true when the banner should be shown for [weather].
  /// Call this before deciding whether to allocate space in the layout.
  static bool shouldShow(WeatherContext weather) => weather.isOutdoorAdvisory;

  @override
  State<WeatherBanner> createState() => _WeatherBannerState();
}

class _WeatherBannerState extends State<WeatherBanner> {
  bool _dismissed = false;

  @override
  void didUpdateWidget(WeatherBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-show the banner if the condition type changes (e.g. sandstorm replaced
    // by extreme heat warning after a refresh).
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
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          border: Border.all(color: color.withValues(alpha: 0.35)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(widget.weather.conditionIcon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
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
                          fontSize: 13,
                          fontFamily: 'Marcellus',
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '· ${widget.weather.tempDisplay}  ${widget.weather.feelsLikeDisplay}',
                        style: TextStyle(
                          color: color.withValues(alpha: 0.75),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.weather.advisoryText,
                    style: TextStyle(
                      color: color.withValues(alpha: 0.85),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  if (widget.onTap != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Tap for 7-day forecast',
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
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
              icon: Icon(Icons.close_rounded, color: color.withValues(alpha: 0.7), size: 18),
              padding: const EdgeInsets.only(left: 4),
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
