import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lost_in_egypt/core/models/solo_plan.dart';
import 'package:lost_in_egypt/core/models/weather_context.dart';
import 'package:lost_in_egypt/core/services/ai_storyteller_service.dart';
import 'package:lost_in_egypt/core/services/story_cache_service.dart';
import 'package:lost_in_egypt/core/services/solo_plan_service.dart';
import 'package:lost_in_egypt/core/services/weather_service.dart';
import 'package:lost_in_egypt/feature/home/tabs/home/data/models/map_item_models.dart';
import 'package:lost_in_egypt/feature/home/tabs/map/data/datasources/map_focus_service.dart';
import '../../../../../../../theme/theme.dart';

class ActiveTourScreen extends StatefulWidget {
  final SavedPlan plan;

  const ActiveTourScreen({super.key, required this.plan});

  @override
  State<ActiveTourScreen> createState() => _ActiveTourScreenState();
}

class _ActiveTourScreenState extends State<ActiveTourScreen>
    with TickerProviderStateMixin {
  late SavedPlan _plan;
  late final AnimationController _progressCtrl;
  late final AnimationController _pulseCtrl;
  bool _completing = false;
  bool _ending = false;

  WeatherContext? _weather;

  Duration _elapsed = Duration.zero;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _plan = widget.plan;

    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
      value: _plan.progress,
    );

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    if (_plan.startedAt != null) {
      _elapsed = DateTime.now().difference(_plan.startedAt!);
      _timer = Timer.periodic(const Duration(minutes: 1), (_) {
        if (mounted && _plan.startedAt != null) {
          setState(
              () => _elapsed = DateTime.now().difference(_plan.startedAt!));
        }
      });
    }

    _loadWeather();
    _showOnboardingIfNeeded();
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    _pulseCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // ── Weather ───────────────────────────────────────────────────────────────

  Future<void> _loadWeather() async {
    double? lat;
    double? lng;

    // Try GPS first
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.whileInUse ||
          perm == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 4),
        );
        lat = pos.latitude;
        lng = pos.longitude;
      }
    } catch (_) {}

    // Fall back to first stop with coords
    if (lat == null) {
      for (final day in _plan.days) {
        for (final stop in day.stops) {
          if (stop.hasCoordinates) {
            lat = stop.lat;
            lng = stop.lng;
            break;
          }
        }
        if (lat != null) break;
      }
    }

    if (lat == null || lng == null) return;

    final weather = await WeatherService.getWeather(lat, lng);
    if (mounted && weather != null) {
      setState(() => _weather = weather);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<void> _showOnboardingIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('tour_onboarding_seen') ?? false;
    if (seen || !mounted) return;
    await prefs.setBool('tour_onboarding_seen', true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => const _TourOnboardingSheet(),
      );
    });
  }

  String get _elapsedLabel {
    final h = _elapsed.inHours;
    final m = _elapsed.inMinutes % 60;
    if (h == 0) return '${m}m';
    return '${h}h ${m}m';
  }

  void _navigateToStop(SavedPlanStop stop) {
    if (!stop.hasCoordinates) return;
    final model = PlaceModel(
      id: '${_plan.id}_${stop.name.toLowerCase().replaceAll(' ', '_')}',
      title: stop.name,
      category: stop.placeType,
      coordinate: GeoPoint(stop.lat!, stop.lng!),
      imagePath: '',
      locationAddress: stop.name,
      rating: 0,
      price: 0,
      duration: stop.estimatedDuration,
      weather: '',
      description: stop.notes ?? '',
    );
    MapFocusService.instance.triggerTourStop(model, _plan);
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  void _viewFullRoute() {
    final stops = _plan.days
        .expand((d) => d.stops)
        .where((s) => s.hasCoordinates)
        .map((s) => PlaceModel(
              id: '${_plan.id}_${s.name.toLowerCase().replaceAll(' ', '_')}',
              title: s.name,
              category: s.placeType,
              coordinate: GeoPoint(s.lat!, s.lng!),
              imagePath: '',
              locationAddress: s.name,
              rating: 0,
              price: 0,
              duration: s.estimatedDuration,
              weather: '',
              description: s.notes ?? '',
            ))
        .toList();
    if (stops.isEmpty) return;
    MapFocusService.instance.triggerViewRoute(stops);
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  Future<void> _toggleStop(
      int dayIndex, int stopIndex, bool completed) async {
    setState(() => _completing = true);
    try {
      await SoloPlanService.instance.markStopCompleted(
        planId: _plan.id,
        dayIndex: dayIndex,
        stopIndex: stopIndex,
        completed: completed,
      );
      final updatedDays = List<SavedPlanDay>.from(_plan.days);
      updatedDays[dayIndex] =
          updatedDays[dayIndex].copyWithStop(stopIndex, completed);

      final allDone =
          updatedDays.every((d) => d.stops.every((s) => s.completed));

      setState(() {
        _plan = _plan.copyWith(
          days: updatedDays,
          status: allDone ? SoloPlanStatus.completed : _plan.status,
          completedAt: allDone ? DateTime.now() : null,
        );
      });
      _progressCtrl.animateTo(_plan.progress);

      if (allDone && mounted) _showCompletionDialog();
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }

  Future<void> _endTour() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End Tour?'),
        content: const Text(
            'This will mark the tour as completed. You can still view it in My Plans.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('End Tour',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _ending = true);
    try {
      await SoloPlanService.instance.endTour(_plan.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Tour ended. Find it under Completed in My Plans.'),
          backgroundColor: AppColors.lightPrimaryButton,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _ending = false);
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _TourCompleteDialog(
        planTitle: _plan.title,
        stopsCompleted: _plan.totalStops,
        onDone: () {
          Navigator.pop(ctx);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showStorySheet(BuildContext context, String stopName, Color gold) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StorySheet(stopName: stopName, gold: gold),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textColor = isDark ? AppColors.darkText : AppColors.lightBox;
    final cardColor =
        isDark ? AppColors.darkPatternOverlay : const Color(0xFFFFFEF0);
    final gold = AppColors.lightPrimaryButton;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.chevron_left_rounded, color: textColor, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _plan.title,
          style: TextStyle(
            fontFamily: 'Marcellus',
            color: textColor,
            fontSize: 17,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.map_outlined, color: gold),
            tooltip: 'View full route',
            onPressed: _viewFullRoute,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Weather banner ────────────────────────────────────────────────
          if (_weather != null)
            _WeatherBanner(weather: _weather!, gold: gold, textColor: textColor),

          // ── Progress header ───────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: gold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: gold.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (_, _) => Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: gold.withValues(
                              alpha: 0.5 + _pulseCtrl.value * 0.5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Tour in Progress',
                      style: TextStyle(
                        color: gold,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _elapsedLabel,
                      style: TextStyle(
                          color: textColor.withValues(alpha: 0.5),
                          fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: AnimatedBuilder(
                        animation: _progressCtrl,
                        builder: (_, _) => ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _progressCtrl.value,
                            minHeight: 8,
                            backgroundColor: gold.withValues(alpha: 0.15),
                            valueColor: AlwaysStoppedAnimation<Color>(gold),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${_plan.completedStops}/${_plan.totalStops} stops',
                      style: TextStyle(
                        color: gold,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                if (_plan.nextIncompleteStop != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.arrow_forward_ios_rounded,
                          size: 12, color: textColor.withValues(alpha: 0.5)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Next: ${_plan.nextIncompleteStop!.name}',
                          style: TextStyle(
                            fontSize: 13,
                            color: textColor.withValues(alpha: 0.7),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_plan.nextIncompleteStop!.hasCoordinates)
                        GestureDetector(
                          onTap: () =>
                              _navigateToStop(_plan.nextIncompleteStop!),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: gold,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.navigation_rounded,
                                    size: 12, color: Colors.white),
                                SizedBox(width: 4),
                                Text(
                                  'Go',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Stop list ─────────────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              children: _plan.days.asMap().entries.expand((dayEntry) {
                final dayIdx = dayEntry.key;
                final day = dayEntry.value;
                return [
                  // Inter-city transit card (only when this day travels to a
                  // different city than the previous one).
                  if (day.transit != null)
                    _TransitBanner(
                      transit: day.transit!,
                      gold: gold,
                      textColor: textColor,
                      cardColor: cardColor,
                    ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, top: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: gold.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        day.label,
                        style: TextStyle(
                          fontFamily: 'Marcellus',
                          fontWeight: FontWeight.w700,
                          color: gold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  ...day.stops.asMap().entries.map((stopEntry) {
                    final stopIdx = stopEntry.key;
                    final stop = stopEntry.value;
                    final isNextUp = identical(stop, _plan.nextIncompleteStop);
                    return _StopTile(
                      stop: stop,
                      cardColor: cardColor,
                      textColor: textColor,
                      gold: gold,
                      isNextUp: isNextUp,
                      onToggle: _completing
                          ? null
                          : (v) => _toggleStop(dayIdx, stopIdx, v),
                      onNavigate: stop.hasCoordinates
                          ? () => _navigateToStop(stop)
                          : null,
                      onHearStory: () =>
                          _showStorySheet(context, stop.name, gold),
                    );
                  }),
                ];
              }).toList(),
            ),
          ),
        ],
      ),

      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
            20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
        color: bgColor,
        child: ElevatedButton.icon(
          onPressed: _ending ? null : _endTour,
          icon: _ending
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.stop_circle_outlined,
                  size: 18, color: Colors.white),
          label: const Text(
            'End Tour',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
        ),
      ),
    );
  }
}

// ── Weather banner ────────────────────────────────────────────────────────────

class _WeatherBanner extends StatelessWidget {
  final WeatherContext weather;
  final Color gold;
  final Color textColor;

  const _WeatherBanner(
      {required this.weather, required this.gold, required this.textColor});

  @override
  Widget build(BuildContext context) {
    final color = weather.isOutdoorAdvisory
        ? weather.severityColor
        : const Color(0xFF2E7D32);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(weather.conditionIcon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${weather.tempDisplay}  •  ${weather.conditionLabel}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                if (weather.isOutdoorAdvisory) ...[
                  const SizedBox(height: 2),
                  Text(
                    weather.advisoryText,
                    style: TextStyle(
                      fontSize: 11,
                      color: color.withValues(alpha: 0.85),
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            weather.feelsLikeDisplay,
            style: TextStyle(
              fontSize: 11,
              color: textColor.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stop tile (expandable with description + AI story) ────────────────────────

class _StopTile extends StatefulWidget {
  final SavedPlanStop stop;
  final Color cardColor;
  final Color textColor;
  final Color gold;
  final bool isNextUp;
  final void Function(bool)? onToggle;
  final VoidCallback? onNavigate;
  final VoidCallback onHearStory;

  const _StopTile({
    required this.stop,
    required this.cardColor,
    required this.textColor,
    required this.gold,
    required this.isNextUp,
    required this.onToggle,
    required this.onNavigate,
    required this.onHearStory,
  });

  @override
  State<_StopTile> createState() => _StopTileState();
}

class _StopTileState extends State<_StopTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final stop = widget.stop;
    final gold = widget.gold;
    final textColor = widget.textColor;
    final hasDetails = (stop.notes != null && stop.notes!.isNotEmpty);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: stop.completed
            ? gold.withValues(alpha: 0.08)
            : widget.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: stop.completed
            ? Border.all(color: gold.withValues(alpha: 0.3))
            : widget.isNextUp
                ? Border.all(color: gold.withValues(alpha: 0.55), width: 1.5)
                : null,
        boxShadow: widget.isNextUp && !stop.completed
            ? [
                BoxShadow(
                  color: gold.withValues(alpha: 0.18),
                  blurRadius: 10,
                  spreadRadius: 0.5,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Main row ──────────────────────────────────────────────────────
          InkWell(
            onTap: hasDetails ? () => setState(() => _expanded = !_expanded) : null,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Checkbox
                  GestureDetector(
                    onTap: widget.onToggle == null
                        ? null
                        : () => widget.onToggle!(!stop.completed),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: stop.completed ? gold : Colors.transparent,
                        border: Border.all(
                          color: stop.completed
                              ? gold
                              : textColor.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: stop.completed
                          ? const Icon(Icons.check_rounded,
                              size: 16, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Name + duration
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                stop.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: stop.completed
                                      ? textColor.withValues(alpha: 0.45)
                                      : textColor,
                                  decoration: stop.completed
                                      ? TextDecoration.lineThrough
                                      : null,
                                  fontFamily: 'Marcellus',
                                ),
                              ),
                            ),
                            if (widget.isNextUp && !stop.completed) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: gold,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'Up next',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          stop.estimatedDuration,
                          style: TextStyle(
                            fontSize: 12,
                            color: textColor.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Nav button
                  if (widget.onNavigate != null)
                    IconButton(
                      icon: Icon(Icons.navigation_rounded, color: gold, size: 20),
                      tooltip: 'Navigate here',
                      onPressed: widget.onNavigate,
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(6),
                    ),
                  // Expand chevron
                  if (hasDetails)
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: textColor.withValues(alpha: 0.4),
                      size: 20,
                    ),
                ],
              ),
            ),
          ),

          // ── Expandable details ────────────────────────────────────────────
          if (_expanded && hasDetails)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(color: textColor.withValues(alpha: 0.1), height: 1),
                  const SizedBox(height: 10),
                  Text(
                    stop.notes!,
                    style: TextStyle(
                      fontSize: 13,
                      color: textColor.withValues(alpha: 0.7),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // AI Story button
                  GestureDetector(
                    onTap: widget.onHearStory,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: gold.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: gold.withValues(alpha: 0.3), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_stories_outlined,
                              size: 15, color: gold),
                          const SizedBox(width: 6),
                          Text(
                            'Hear the Story',
                            style: TextStyle(
                              fontSize: 13,
                              color: gold,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── First-time tour onboarding sheet ─────────────────────────────────────────

class _TourOnboardingSheet extends StatelessWidget {
  const _TourOnboardingSheet();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkBox : Colors.white;
    final textColor = isDark ? AppColors.darkText : AppColors.lightBox;
    final gold = AppColors.lightPrimaryButton;

    const features = [
      (Icons.map_outlined, 'View on Map',
          'Tap the map icon (top-right) to see your stops on the map and navigate to any one.'),
      (Icons.check_circle_outline_rounded, 'Track Progress',
          'Check off each stop as you visit it. Your progress saves automatically.'),
      (Icons.auto_stories_outlined, 'AI Stories',
          'Expand any stop and tap "Hear the Story" for an AI-generated history of that place.'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).padding.bottom + 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: textColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '🗺️ Your Tour Has Started!',
            style: TextStyle(
              fontFamily: 'Marcellus',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Here\'s what you can do',
            style: TextStyle(
              fontSize: 14,
              color: textColor.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          ...features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: gold.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(f.$1, color: gold, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            f.$2,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                              fontFamily: 'Marcellus',
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            f.$3,
                            style: TextStyle(
                              fontSize: 13,
                              color: textColor.withValues(alpha: 0.6),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: gold,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text(
                'Let\'s Go!',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  fontFamily: 'Marcellus',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tour completion dialog ────────────────────────────────────────────────────

class _TourCompleteDialog extends StatefulWidget {
  final String planTitle;
  final int stopsCompleted;
  final VoidCallback onDone;

  const _TourCompleteDialog({
    required this.planTitle,
    required this.stopsCompleted,
    required this.onDone,
  });

  @override
  State<_TourCompleteDialog> createState() => _TourCompleteDialogState();
}

class _TourCompleteDialogState extends State<_TourCompleteDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkBox : Colors.white;
    final textColor = isDark ? AppColors.darkText : AppColors.lightBox;
    final gold = AppColors.lightPrimaryButton;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: FadeTransition(
        opacity: _fade,
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: gold.withValues(alpha: 0.25),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Glowing trophy icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        gold.withValues(alpha: 0.35),
                        gold.withValues(alpha: 0.05),
                      ],
                    ),
                    border: Border.all(color: gold, width: 2),
                  ),
                  child: Icon(Icons.emoji_events_rounded,
                      size: 40, color: gold),
                ),
                const SizedBox(height: 20),
                Text(
                  'Tour Complete!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Marcellus',
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.planTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: gold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: gold.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: gold.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.place_rounded, size: 18, color: gold),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.stopsCompleted} stops explored',
                        style: TextStyle(
                          fontSize: 14,
                          color: gold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'You\'ve experienced the heart of Egypt.\nGreat exploring! 🌟',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: textColor.withValues(alpha: 0.6),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: widget.onDone,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: gold,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Marcellus',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Inter-city transit banner ────────────────────────────────────────────────

class _TransitBanner extends StatelessWidget {
  final SavedPlanTransit transit;
  final Color gold;
  final Color textColor;
  final Color cardColor;

  const _TransitBanner({
    required this.transit,
    required this.gold,
    required this.textColor,
    required this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: gold.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: gold.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.alt_route_rounded, size: 16, color: gold),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${transit.from}  →  ${transit.to}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: gold,
                    fontFamily: 'Marcellus',
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            transit.mode,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (transit.duration.isNotEmpty)
                _TransitMiniChip(
                  icon: Icons.schedule_rounded,
                  label: transit.duration,
                  gold: gold,
                ),
              if (transit.approxCost.isNotEmpty)
                _TransitMiniChip(
                  icon: Icons.payments_outlined,
                  label: transit.approxCost,
                  gold: gold,
                ),
            ],
          ),
          if (transit.tip.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline_rounded,
                    size: 14, color: textColor.withValues(alpha: 0.55)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    transit.tip,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: textColor.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TransitMiniChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color gold;

  const _TransitMiniChip({
    required this.icon,
    required this.label,
    required this.gold,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: gold),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: gold,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── AI Story bottom sheet ─────────────────────────────────────────────────────

class _StorySheet extends StatefulWidget {
  final String stopName;
  final Color gold;

  const _StorySheet({required this.stopName, required this.gold});

  @override
  State<_StorySheet> createState() => _StorySheetState();
}

class _StorySheetState extends State<_StorySheet> {
  String? _story;
  bool _loading = true;
  bool _error = false;

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _loadingAudio = false;
  bool _isPlaying = false;
  bool _isPaused = false;
  String? _audioFilePath;

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() { _isPlaying = false; _isPaused = false; });
    });
    _fetchStory();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _fetchStory() async {
    setState(() { _loading = true; _error = false; });
    try {
      final story = await StoryCacheService.instance.getStory(widget.stopName);
      if (mounted) setState(() { _story = story; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = true; _loading = false; });
    }
  }

  Future<void> _handleAudioButton() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
      if (mounted) setState(() { _isPlaying = false; _isPaused = true; });
      return;
    }
    if (_isPaused) {
      await _audioPlayer.resume();
      if (mounted) setState(() { _isPlaying = true; _isPaused = false; });
      return;
    }
    await _startPlayback();
  }

  Future<void> _handleReplay() async {
    await _audioPlayer.stop();
    setState(() { _isPlaying = false; _isPaused = false; });
    await _startPlayback();
  }

  Future<void> _startPlayback() async {
    if (_story == null) return;
    if (_audioFilePath != null) {
      await _audioPlayer.play(DeviceFileSource(_audioFilePath!));
      if (mounted) setState(() { _isPlaying = true; _isPaused = false; });
      return;
    }
    setState(() => _loadingAudio = true);
    try {
      final bytes = await AIStorytellerService.getStoryAudio(_story!);
      if (bytes == null || !mounted) {
        if (mounted) setState(() => _loadingAudio = false);
        return;
      }
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/tour_stop_story.mp3');
      await file.writeAsBytes(bytes);
      _audioFilePath = file.path;
      await _audioPlayer.play(DeviceFileSource(_audioFilePath!));
      if (mounted) setState(() { _isPlaying = true; _isPaused = false; _loadingAudio = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingAudio = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkBox : Colors.white;
    final textColor = isDark ? AppColors.darkText : AppColors.lightBox;
    final gold = widget.gold;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(
              24, 20, 24, MediaQuery.of(context).padding.bottom + 28),
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: textColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.auto_stories_outlined, color: gold, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.stopName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Marcellus',
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_loading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Column(
                    children: [
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 2, color: gold),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Summoning the story…',
                        style: TextStyle(fontSize: 13, color: textColor.withValues(alpha: 0.5)),
                      ),
                    ],
                  ),
                ),
              )
            else if (_error)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Text(
                      'The spirits of history are silent right now.',
                      style: TextStyle(fontSize: 14, color: textColor.withValues(alpha: 0.6)),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _fetchStory,
                      child: Text('Try again', style: TextStyle(color: gold)),
                    ),
                  ],
                ),
              )
            else ...[
              Text(
                _story ?? '',
                style: TextStyle(
                  fontSize: 15,
                  color: textColor.withValues(alpha: 0.85),
                  height: 1.65,
                ),
              ),
              const SizedBox(height: 20),
              // Audio controls
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _loadingAudio ? null : _handleAudioButton,
                      icon: _loadingAudio
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Icon(
                              _isPlaying
                                  ? Icons.pause_rounded
                                  : _isPaused
                                      ? Icons.play_arrow_rounded
                                      : Icons.headphones_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                      label: Text(
                        _loadingAudio
                            ? 'Generating audio…'
                            : _isPlaying
                                ? 'Pause'
                                : _isPaused
                                    ? 'Resume'
                                    : 'Listen',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: gold,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  if (_audioFilePath != null) ...[
                    const SizedBox(width: 10),
                    IconButton.filled(
                      onPressed: _loadingAudio ? null : _handleReplay,
                      icon: const Icon(Icons.replay_rounded),
                      tooltip: 'Replay from start',
                      style: IconButton.styleFrom(
                        backgroundColor: gold.withValues(alpha: 0.15),
                        foregroundColor: gold,
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
