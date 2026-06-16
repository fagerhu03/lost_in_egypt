import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lost_in_egypt/core/models/solo_plan.dart';
import 'package:lost_in_egypt/core/models/weather_context.dart';
import 'package:lost_in_egypt/core/di/service_locator.dart';
import 'package:lost_in_egypt/core/services/ai_storyteller_service.dart';
import 'package:lost_in_egypt/core/services/story_cache_service.dart';
import 'package:lost_in_egypt/core/services/solo_plan_service.dart';
import 'package:lost_in_egypt/core/services/weather_service.dart';
import 'package:lost_in_egypt/core/utils/dataset_resolver.dart';
import 'package:lost_in_egypt/l10n/app_localizations.dart';
import 'package:lost_in_egypt/feature/home/tabs/home/data/models/map_item_models.dart';
import 'package:lost_in_egypt/feature/home/tabs/map/data/datasources/map_focus_service.dart';
import 'package:lost_in_egypt/feature/home/tabs/map/data/map_repository.dart';
import 'package:lost_in_egypt/core/services/recommendation_service.dart';
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

  /// Cached map dataset for resolving synthetic stop names to real placeIds
  /// before recording signals. Empty until [_loadDataset] completes; signal
  /// recording falls back to a namespaced synthetic ID if resolution fails.
  List<MapItem> _dataset = const [];

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
          setState(() => _elapsed = DateTime.now().difference(_plan.startedAt!));
        }
      });
    }

    _loadWeather();
    _loadDataset();
    _showOnboardingIfNeeded();
  }

  /// Fires once per tour. Best-effort: if it fails we fall back to a
  /// namespaced synthetic placeId at signal time. MapRepository is cached, so
  /// subsequent screens that need the dataset don't pay this cost again.
  Future<void> _loadDataset() async {
    try {
      final items = await sl<MapRepository>().fetchAllMapItemsLimited();
      if (mounted) setState(() => _dataset = items);
    } catch (_) {}
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    _pulseCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadWeather() async {
    double? lat;
    double? lng;

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

  Future<void> _toggleStop(int dayIndex, int stopIndex, bool completed) async {
    setState(() => _completing = true);
    try {
      await SoloPlanService.instance.markStopCompleted(
        planId: _plan.id,
        dayIndex: dayIndex,
        stopIndex: stopIndex,
        completed: completed,
      );
      if (completed) {
        final stop = _plan.days[dayIndex].stops[stopIndex];
        // Try to resolve the AI-generated stop name to a real dataset entry so
        // the signal is recorded against the canonical placeId (matches the
        // Places API ID used by every other surface). Falls back to a clearly
        // namespaced synthetic ID when resolution fails — the taste vector
        // still updates either way.
        final resolved = stop.hasCoordinates && _dataset.isNotEmpty
            ? DatasetResolver.resolve(
                name: stop.name,
                lat: stop.lat!,
                lng: stop.lng!,
                dataset: _dataset,
              )
            : null;
        if (resolved != null) {
          RecommendationService.recordSignal(
            placeId: resolved.id,
            placeName: resolved.title,
            types: [resolved.category],
            tags: resolved.tags,
            signalType: 'visit',
            source: 'active_tour',
          );
        } else {
          RecommendationService.recordSignal(
            placeId:
                'tour_stop:${stop.name.toLowerCase().replaceAll(RegExp(r"\s+"), "_")}',
            placeName: stop.name,
            types: [stop.placeType],
            signalType: 'visit',
            source: 'active_tour',
          );
        }
      }
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
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.tourEndTitle),
        content: Text(l10n.tourEndBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.commonCancel)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.tourEndConfirm, style: const TextStyle(color: Colors.red))),
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
          content: Text(l10n.tourEnded),
          backgroundColor: AppColors.lightPrimaryButton,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r)),
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
        completedStops: _plan.days.expand((d) => d.stops).toList(),
        dataset: _dataset,
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textColor = isDark ? AppColors.darkText : AppColors.lightBox;
    final cardColor = isDark ? AppColors.darkPatternOverlay : const Color(0xFFFFFEF0);
    final gold = AppColors.lightPrimaryButton;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.chevron_left_rounded, color: textColor, size: 28.r),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _plan.title,
          style: TextStyle(
            fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo'],
            color: textColor,
            fontSize: 17.sp,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.map_outlined, color: gold),
            tooltip: AppLocalizations.of(context).soloViewFullRoute,
            onPressed: _viewFullRoute,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_weather != null)
            _WeatherBanner(weather: _weather!, gold: gold, textColor: textColor),

          // Progress header
          Container(
            margin: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: gold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(color: gold.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (_, _) => Container(
                        width: 10.r,
                        height: 10.r,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: gold.withValues(
                              alpha: 0.5 + _pulseCtrl.value * 0.5),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      AppLocalizations.of(context).tourInProgress,
                      style: TextStyle(
                        color: gold,
                        fontWeight: FontWeight.w700,
                        fontSize: 14.sp,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _elapsedLabel,
                      style: TextStyle(
                          color: textColor.withValues(alpha: 0.5),
                          fontSize: 13.sp),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                Row(
                  children: [
                    Expanded(
                      child: AnimatedBuilder(
                        animation: _progressCtrl,
                        builder: (_, _) => ClipRRect(
                          borderRadius: BorderRadius.circular(4.r),
                          child: LinearProgressIndicator(
                            value: _progressCtrl.value,
                            minHeight: 8.h,
                            backgroundColor: gold.withValues(alpha: 0.15),
                            valueColor: AlwaysStoppedAnimation<Color>(gold),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      '${_plan.completedStops}/${_plan.totalStops} stops',
                      style: TextStyle(
                        color: gold,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.sp,
                      ),
                    ),
                  ],
                ),
                if (_plan.nextIncompleteStop != null) ...[
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      Icon(Icons.arrow_forward_ios_rounded,
                          size: 12.r,
                          color: textColor.withValues(alpha: 0.5)),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          'Next: ${_plan.nextIncompleteStop!.name}',
                          style: TextStyle(
                            fontSize: 13.sp,
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
                            padding: EdgeInsets.symmetric(
                                horizontal: 10.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: gold,
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.navigation_rounded,
                                    size: 12.r, color: Colors.white),
                                SizedBox(width: 4.w),
                                Text(
                                  AppLocalizations.of(context).tourGo,
                                  style: TextStyle(
                                    fontSize: 12.sp,
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
          SizedBox(height: 12.h),

          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 100.h),
              children: _plan.days.asMap().entries.expand((dayEntry) {
                final dayIdx = dayEntry.key;
                final day = dayEntry.value;
                return [
                  if (day.transit != null)
                    _TransitBanner(
                      transit: day.transit!,
                      gold: gold,
                      textColor: textColor,
                      cardColor: cardColor,
                    ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 8.h, top: 4.h),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 14.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: gold.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Text(
                        day.label,
                        style: TextStyle(
                          fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo'],
                          fontWeight: FontWeight.w700,
                          color: gold,
                          fontSize: 14.sp,
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
            20.w, 12.h, 20.w, MediaQuery.of(context).padding.bottom + 12.h),
        color: bgColor,
        child: ElevatedButton.icon(
          onPressed: _ending ? null : _endTour,
          icon: _ending
              ? SizedBox(
                  width: 16.r,
                  height: 16.r,
                  child: const CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : Icon(Icons.stop_circle_outlined, size: 18.r, color: Colors.white),
          label: Text(
            AppLocalizations.of(context).tourEndConfirm,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            padding: EdgeInsets.symmetric(vertical: 14.h),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r)),
            elevation: 0,
          ),
        ),
      ),
    );
  }
}

// ── Weather banner ─────────────────────────────────────────────────────────────

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
      margin: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(weather.conditionIcon, color: color, size: 20.r),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${weather.tempDisplay}  •  ${weather.conditionLabel}',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                if (weather.isOutdoorAdvisory) ...[
                  SizedBox(height: 2.h),
                  Text(
                    weather.advisoryText,
                    style: TextStyle(
                      fontSize: 11.sp,
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
              fontSize: 11.sp,
              color: textColor.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stop tile ──────────────────────────────────────────────────────────────────

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
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: BoxDecoration(
        color: stop.completed
            ? gold.withValues(alpha: 0.08)
            : widget.cardColor,
        borderRadius: BorderRadius.circular(14.r),
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
          InkWell(
            onTap: hasDetails ? () => setState(() => _expanded = !_expanded) : null,
            borderRadius: BorderRadius.circular(14.r),
            child: Padding(
              padding: EdgeInsets.fromLTRB(14.w, 12.h, 10.w, 12.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: widget.onToggle == null
                        ? null
                        : () => widget.onToggle!(!stop.completed),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 28.r,
                      height: 28.r,
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
                          ? Icon(Icons.check_rounded,
                              size: 16.r, color: Colors.white)
                          : null,
                    ),
                  ),
                  SizedBox(width: 12.w),
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
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: stop.completed
                                      ? textColor.withValues(alpha: 0.45)
                                      : textColor,
                                  decoration: stop.completed
                                      ? TextDecoration.lineThrough
                                      : null,
                                  fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo'],
                                ),
                              ),
                            ),
                            if (widget.isNextUp && !stop.completed) ...[
                              SizedBox(width: 8.w),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8.w, vertical: 2.h),
                                decoration: BoxDecoration(
                                  color: gold,
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Text(
                                  AppLocalizations.of(context).tourUpNext,
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          stop.estimatedDuration,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: textColor.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.onNavigate != null)
                    IconButton(
                      icon: Icon(Icons.navigation_rounded, color: gold, size: 20.r),
                      tooltip: AppLocalizations.of(context).soloNavigateHere,
                      onPressed: widget.onNavigate,
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.all(6.r),
                    ),
                  if (hasDetails)
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: textColor.withValues(alpha: 0.4),
                      size: 20.r,
                    ),
                ],
              ),
            ),
          ),

          if (_expanded && hasDetails)
            Padding(
              padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(color: textColor.withValues(alpha: 0.1), height: 1),
                  SizedBox(height: 10.h),
                  Text(
                    stop.notes!,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: textColor.withValues(alpha: 0.7),
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  GestureDetector(
                    onTap: widget.onHearStory,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 12.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: gold.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                            color: gold.withValues(alpha: 0.3), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_stories_outlined,
                              size: 15.r, color: gold),
                          SizedBox(width: 6.w),
                          Text(
                            AppLocalizations.of(context).soloHearStory,
                            style: TextStyle(
                              fontSize: 13.sp,
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

// ── First-time tour onboarding sheet ──────────────────────────────────────────

class _TourOnboardingSheet extends StatelessWidget {
  const _TourOnboardingSheet();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkBox : Colors.white;
    final textColor = isDark ? AppColors.darkText : AppColors.lightBox;
    final gold = AppColors.lightPrimaryButton;

    final l10n = AppLocalizations.of(context);
    final features = [
      (Icons.map_outlined, l10n.tourFeatViewMap, l10n.tourFeatViewMapDesc),
      (Icons.check_circle_outline_rounded, l10n.tourFeatTrack, l10n.tourFeatTrackDesc),
      (Icons.auto_stories_outlined, l10n.tourFeatStories, l10n.tourFeatStoriesDesc),
    ];

    return Container(
      decoration: BoxDecoration(
        color: surface,
        // BottomSheet radius — not scaled per design convention
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
          24.w, 20.h, 24.w, MediaQuery.of(context).padding.bottom + 28.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: textColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            l10n.tourStartedTitle,
            style: TextStyle(
              fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo'],
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            l10n.tourOnboardTitle,
            style: TextStyle(
              fontSize: 14.sp,
              color: textColor.withValues(alpha: 0.5),
            ),
          ),
          SizedBox(height: 24.h),
          ...features.map((f) => Padding(
                padding: EdgeInsets.only(bottom: 18.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42.r,
                      height: 42.r,
                      decoration: BoxDecoration(
                        color: gold.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(f.$1, color: gold, size: 22.r),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            f.$2,
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                              fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo'],
                            ),
                          ),
                          SizedBox(height: 3.h),
                          Text(
                            f.$3,
                            style: TextStyle(
                              fontSize: 13.sp,
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
          SizedBox(height: 4.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: gold,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r)),
                elevation: 0,
              ),
              child: Text(
                l10n.tourLetsGo,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15.sp,
                  fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo'],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tour completion dialog ─────────────────────────────────────────────────────

class _TourCompleteDialog extends StatefulWidget {
  final String planTitle;
  final int stopsCompleted;
  final VoidCallback onDone;
  final List<SavedPlanStop> completedStops;
  final List<MapItem> dataset;

  const _TourCompleteDialog({
    required this.planTitle,
    required this.stopsCompleted,
    required this.onDone,
    this.completedStops = const [],
    this.dataset = const [],
  });

  @override
  State<_TourCompleteDialog> createState() => _TourCompleteDialogState();
}

class _TourCompleteDialogState extends State<_TourCompleteDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  List<String> _suggestionNames = [];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      if (widget.dataset.isEmpty) return;

      // Resolve completed AI stops to real dataset MapItems so we can both
      // (a) exclude them from the suggestion pool, and (b) use the last
      // resolved stop's coords as the proximity anchor.
      final completedIds = <String>{};
      MapItem? anchorStop;
      for (final stop in widget.completedStops) {
        if (!stop.hasCoordinates) continue;
        final match = DatasetResolver.resolve(
          name: stop.name,
          lat: stop.lat!,
          lng: stop.lng!,
          dataset: widget.dataset,
        );
        if (match != null) {
          completedIds.add(match.id);
          anchorStop = match;
        }
      }

      // Anchor for proximity sort: last resolved stop, then first stop with
      // coords, then Cairo centre as last resort.
      double anchorLat = 30.0444;
      double anchorLng = 31.2357;
      if (anchorStop != null) {
        anchorLat = anchorStop.coordinate.latitude;
        anchorLng = anchorStop.coordinate.longitude;
      } else {
        final firstWithCoords =
            widget.completedStops.where((s) => s.hasCoordinates).firstOrNull;
        if (firstWithCoords != null) {
          anchorLat = firstWithCoords.lat!;
          anchorLng = firstWithCoords.lng!;
        }
      }

      // Take the 50 nearest dataset entries that weren't just visited.
      // Pre-filter is needed because the Cloud Function caps candidates at
      // 200 — and we want the engine's similarity scoring to operate on a
      // tight relevant pool, not the whole 500-item dataset.
      final pool = widget.dataset
          .where((m) => !completedIds.contains(m.id))
          .toList();
      pool.sort((a, b) {
        final da = Geolocator.distanceBetween(anchorLat, anchorLng,
            a.coordinate.latitude, a.coordinate.longitude);
        final db = Geolocator.distanceBetween(anchorLat, anchorLng,
            b.coordinate.latitude, b.coordinate.longitude);
        return da.compareTo(db);
      });
      final candidates = pool.take(50).map((m) => {
            'placeId': m.id,
            'name': m.title,
            'types': [m.category],
            'tags': m.tags,
            'lat': m.coordinate.latitude,
            'lng': m.coordinate.longitude,
          }).toList();
      if (candidates.isEmpty) return;

      final fn = FirebaseFunctions.instance.httpsCallable('recommendPlaces');
      final result = await fn.call({
        'candidates': candidates,
        'context': 'similar',
        'limit': 3,
        // 50-item pool is "small" by the project's threshold — letting the
        // server filter against `soloPlanSeen` would drain it after a few
        // completed tours.
        'excludeSeen': false,
      });
      final ranked = (result.data['recommendations'] as List?) ?? [];
      final names = ranked
          .map((r) => r['name']?.toString() ?? '')
          .where((n) => n.isNotEmpty)
          .take(3)
          .toList();
      if (mounted) setState(() => _suggestionNames = names);
    } catch (_) {}
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
            padding: EdgeInsets.fromLTRB(28.w, 32.h, 28.w, 24.h),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(28.r),
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
                Container(
                  width: 80.r,
                  height: 80.r,
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
                  child: Icon(Icons.emoji_events_rounded, size: 40.r, color: gold),
                ),
                SizedBox(height: 20.h),
                Text(
                  AppLocalizations.of(context).tourComplete,
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo'],
                    color: textColor,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  widget.planTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15.sp,
                    color: gold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 16.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: gold.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: gold.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.place_rounded, size: 18.r, color: gold),
                      SizedBox(width: 8.w),
                      Text(
                        AppLocalizations.of(context).tourStopsExplored(widget.stopsCompleted),
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: gold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  AppLocalizations.of(context).tourCompleteSub,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: textColor.withValues(alpha: 0.6),
                    height: 1.5,
                  ),
                ),
                if (_suggestionNames.isNotEmpty) ...[
                  SizedBox(height: 20.h),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      AppLocalizations.of(context).tourYouMightLove,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: textColor.withValues(alpha: 0.7),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  ..._suggestionNames.map((name) => Padding(
                    padding: EdgeInsets.only(bottom: 6.h),
                    child: Row(
                      children: [
                        Icon(Icons.place_rounded, size: 14.r, color: gold),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(fontSize: 13.sp, color: textColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
                SizedBox(height: 24.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: widget.onDone,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: gold,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r)),
                      elevation: 0,
                    ),
                    child: Text(
                      AppLocalizations.of(context).tourDone,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo'],
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

// ── Inter-city transit banner ──────────────────────────────────────────────────

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
      margin: EdgeInsets.symmetric(vertical: 12.h),
      padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 14.h),
      decoration: BoxDecoration(
        color: gold.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: gold.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.alt_route_rounded, size: 16.r, color: gold),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  '${transit.from}  →  ${transit.to}',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: gold,
                    fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo'],
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            transit.mode,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          SizedBox(height: 6.h),
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
            SizedBox(height: 10.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline_rounded,
                    size: 14.r, color: textColor.withValues(alpha: 0.55)),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    transit.tip,
                    style: TextStyle(
                      fontSize: 12.sp,
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
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.r, color: gold),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: gold,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── AI Story bottom sheet ──────────────────────────────────────────────────────

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
      if (mounted) {
        setState(() { _isPlaying = true; _isPaused = false; _loadingAudio = false; });
      }
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
          // BottomSheet radius — not scaled per design convention
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(
              24.w, 20.h, 24.w, MediaQuery.of(context).padding.bottom + 28.h),
          children: [
            Center(
              child: Container(
                width: 36.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: textColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Icon(Icons.auto_stories_outlined, color: gold, size: 20.r),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    widget.stopName,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo'],
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            if (_loading)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 32.h),
                child: Center(
                  child: Column(
                    children: [
                      SizedBox(
                        width: 28.r,
                        height: 28.r,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: gold),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'Summoning the story…',
                        style: TextStyle(
                            fontSize: 13.sp,
                            color: textColor.withValues(alpha: 0.5)),
                      ),
                    ],
                  ),
                ),
              )
            else if (_error)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 24.h),
                child: Column(
                  children: [
                    Text(
                      AppLocalizations.of(context).soloStorySilent,
                      style: TextStyle(
                          fontSize: 14.sp,
                          color: textColor.withValues(alpha: 0.6)),
                    ),
                    SizedBox(height: 12.h),
                    TextButton(
                      onPressed: _fetchStory,
                      child: Text(AppLocalizations.of(context).commonTryAgain, style: TextStyle(color: gold)),
                    ),
                  ],
                ),
              )
            else ...[
              Text(
                _story ?? '',
                style: TextStyle(
                  fontSize: 15.sp,
                  color: textColor.withValues(alpha: 0.85),
                  height: 1.65,
                ),
              ),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _loadingAudio ? null : _handleAudioButton,
                      icon: _loadingAudio
                          ? SizedBox(
                              width: 18.r,
                              height: 18.r,
                              child: const CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Icon(
                              _isPlaying
                                  ? Icons.pause_rounded
                                  : _isPaused
                                      ? Icons.play_arrow_rounded
                                      : Icons.headphones_rounded,
                              color: Colors.white,
                              size: 20.r,
                            ),
                      label: Text(
                        _loadingAudio
                            ? AppLocalizations.of(context).soloStoryGenerating
                            : _isPlaying
                                ? AppLocalizations.of(context).soloStoryPause
                                : _isPaused
                                    ? AppLocalizations.of(context).soloStoryResume
                                    : AppLocalizations.of(context).soloStoryListen,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: gold,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  if (_audioFilePath != null) ...[
                    SizedBox(width: 10.w),
                    IconButton.filled(
                      onPressed: _loadingAudio ? null : _handleReplay,
                      icon: const Icon(Icons.replay_rounded),
                      tooltip: AppLocalizations.of(context).soloStoryReplay,
                      style: IconButton.styleFrom(
                        backgroundColor: gold.withValues(alpha: 0.15),
                        foregroundColor: gold,
                        padding: EdgeInsets.all(12.r),
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
