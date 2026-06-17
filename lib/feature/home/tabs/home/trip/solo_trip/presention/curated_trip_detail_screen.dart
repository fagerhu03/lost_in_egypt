import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lost_in_egypt/core/services/ai_storyteller_service.dart';
import 'package:lost_in_egypt/core/models/curated_trip.dart';
import 'package:path_provider/path_provider.dart';
import 'package:lost_in_egypt/core/models/solo_plan.dart';
import 'package:lost_in_egypt/core/services/place_photos_service.dart';
import 'package:lost_in_egypt/core/services/solo_plan_service.dart';
import 'package:lost_in_egypt/core/services/story_cache_service.dart';
import 'package:lost_in_egypt/core/services/locale_controller.dart';
import 'package:lost_in_egypt/feature/home/tabs/home/data/models/map_item_models.dart';
import 'package:lost_in_egypt/feature/home/tabs/map/data/datasources/map_focus_service.dart';
import 'package:lost_in_egypt/l10n/app_localizations.dart';
import '../../../../../../../theme/theme.dart';
import 'active_tour_screen.dart';
import 'widgets/trip_theme.dart';

class CuratedTripDetailScreen extends StatefulWidget {
  final CuratedTrip trip;
  final String? heroTag;

  const CuratedTripDetailScreen({
    super.key,
    required this.trip,
    this.heroTag,
  });

  @override
  State<CuratedTripDetailScreen> createState() =>
      _CuratedTripDetailScreenState();
}

class _CuratedTripDetailScreenState extends State<CuratedTripDetailScreen>
    with TickerProviderStateMixin {
  late final AnimationController _staggerCtrl;
  bool _saving = false;
  bool _isSaved = false;
  bool _isActive = false;
  bool _starting = false;
  bool _navigatingToStop = false;
  SavedPlan? _existingPlan;

  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _loadPhoto();
    _loadSavedState();
  }

  void _loadPhoto() async {
    final theme = TripTheme.forId(widget.trip.id);
    final url = await PlacePhotosService.instance
        .getPhotoUrl(widget.trip.id, theme.photoQuery);
    if (mounted && url != null) setState(() => _photoUrl = url);
  }

  /// Reflects existing save state so the "Save Plan" button shows as already
  /// saved when the user opens a trip they've previously saved or started.
  void _loadSavedState() async {
    try {
      final existing =
          await SoloPlanService.instance.getCuratedPlanByTripId(widget.trip.id);
      if (mounted && existing != null) {
        setState(() {
          _isSaved = true;
          _isActive = existing.status == SoloPlanStatus.active;
          _existingPlan = existing;
        });
      }
    } catch (_) {/* best-effort — UI will fall back to the in-session state */}
  }

  @override
  void dispose() {
    _staggerCtrl.dispose();
    super.dispose();
  }

  // ── Staggered animation helper ────────────────────────────────────────────

  Animation<double> _slideAnim(int index) => Tween<double>(begin: 40, end: 0).animate(
        CurvedAnimation(
          parent: _staggerCtrl,
          curve: Interval(
            (index * 0.08).clamp(0.0, 0.8),
            ((index * 0.08) + 0.4).clamp(0.0, 1.0),
            curve: Curves.easeOutCubic,
          ),
        ),
      );

  Animation<double> _fadeAnim(int index) => Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _staggerCtrl,
          curve: Interval(
            (index * 0.08).clamp(0.0, 0.8),
            ((index * 0.08) + 0.4).clamp(0.0, 1.0),
            curve: Curves.easeOut,
          ),
        ),
      );

  void _showStorySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TripStorySheet(
        tripTitle: widget.trip.title,
        gold: AppColors.lightPrimaryButton,
      ),
    );
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  Future<void> _navigateToStop(CuratedTripStop stop) async {
    if (!stop.hasCoordinates) return;
    if (_navigatingToStop) return; // debounce double-taps while we save+start
    setState(() => _navigatingToStop = true);

    final model = _stopToPlaceModel(stop);

    // Save & start the tour so the map gets a real `SavedPlan` to attach the
    // gold pin and "Back to Tour" button to. Without this the user lands on
    // the map with no pin and no way back to the trip.
    SavedPlan? activePlan;
    try {
      final saved =
          await SoloPlanService.instance.saveCuratedPlan(widget.trip);
      if (saved.status != SoloPlanStatus.active) {
        await SoloPlanService.instance.startTour(saved.id);
      }
      activePlan = saved.copyWith(
        status: SoloPlanStatus.active,
        startedAt: saved.startedAt ?? DateTime.now(),
      );
      if (mounted) setState(() => _isSaved = true);
    } catch (_) {/* fall through to camera-only */}

    if (!mounted) return;
    setState(() => _navigatingToStop = false);

    MapFocusService.instance.clearTourStop();
    if (activePlan != null) {
      MapFocusService.instance.triggerTourStop(model, activePlan);
    } else {
      MapFocusService.instance.triggerCameraFocus(model);
    }
    if (!mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  void _viewFullRoute() {
    final stops = widget.trip.allStops
        .where((s) => s.hasCoordinates)
        .map(_stopToPlaceModel)
        .toList();
    if (stops.isEmpty) return;
    MapFocusService.instance.triggerViewRoute(stops);
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  PlaceModel _stopToPlaceModel(CuratedTripStop stop) => PlaceModel(
        id: '${widget.trip.id}_${stop.name.toLowerCase().replaceAll(' ', '_')}',
        title: stop.name,
        category: stop.type,
        coordinate: GeoPoint(stop.lat!, stop.lng!),
        imagePath: widget.trip.imagePath,
        locationAddress: stop.name,
        rating: widget.trip.rating,
        price: 0,
        duration: stop.estimatedDuration,
        weather: '',
        description: stop.description,
      );

  // ── Save / Start ──────────────────────────────────────────────────────────

  Future<void> _savePlan() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _saving = true);
    try {
      await SoloPlanService.instance.saveCuratedPlan(widget.trip);
      if (!mounted) return;
      setState(() => _isSaved = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.soloPlanSaved),
          backgroundColor: AppColors.lightPrimaryButton,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.soloCouldNotSave),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _startTour() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _starting = true);
    try {
      final plan = _existingPlan ?? await SoloPlanService.instance.saveCuratedPlan(widget.trip);
      if (plan.status != SoloPlanStatus.active) {
        await SoloPlanService.instance.startTour(plan.id);
      }
      final started = plan.copyWith(
        status: SoloPlanStatus.active,
        startedAt: plan.startedAt ?? DateTime.now(),
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ActiveTourScreen(plan: started)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.soloCouldNotStart),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        ),
      );
    } finally {
      if (mounted) setState(() => _starting = false);
    }
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
    final trip = widget.trip;
    final theme = TripTheme.forId(trip.id);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ── Hero ─────────────────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 300.h,
                pinned: true,
                backgroundColor: bgColor,
                leading: Padding(
                  padding: EdgeInsets.all(8.r),
                  child: CircleAvatar(
                    backgroundColor: Colors.black.withValues(alpha: 0.45),
                    child: IconButton(
                      icon: Icon(Icons.chevron_left_rounded,
                          color: Colors.white, size: 26.r),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                actions: [
                  Padding(
                    padding: EdgeInsets.all(8.r),
                    child: CircleAvatar(
                      backgroundColor: Colors.black.withValues(alpha: 0.45),
                      child: IconButton(
                        icon: Icon(Icons.map_outlined,
                            color: Colors.white, size: 20.r),
                        tooltip: AppLocalizations.of(context).soloViewFullRouteMap,
                        onPressed: _viewFullRoute,
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Gradient — always visible as background / fallback
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: theme.gradient,
                          ),
                        ),
                      ),
                      // Real photo fades in once loaded
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 700),
                        child: _photoUrl != null
                            ? CachedNetworkImage(
                                key: ValueKey(_photoUrl),
                                imageUrl: _photoUrl!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                errorWidget: (_, _, _) => const SizedBox.shrink(),
                              )
                            : const SizedBox.shrink(key: ValueKey('none')),
                      ),
                      // Depth circles — only shown when no photo yet
                      if (_photoUrl == null) ...[
                        PositionedDirectional(
                          top: -40.h,
                          end: -40.w,
                          child: Container(
                            width: 200.r,
                            height: 200.r,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.06),
                            ),
                          ),
                        ),
                        PositionedDirectional(
                          bottom: 60.h,
                          start: -30.w,
                          child: Container(
                            width: 140.r,
                            height: 140.r,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.05),
                            ),
                          ),
                        ),
                      ],
                      // Hero-animated icon — shown on gradient, badge on photo
                      Center(
                        child: widget.heroTag != null
                            ? Hero(
                                tag: widget.heroTag!,
                                child: _photoUrl == null
                                    ? _HeroIcon(theme: theme)
                                    : const SizedBox.shrink(),
                              )
                            : (_photoUrl == null
                                ? _HeroIcon(theme: theme)
                                : const SizedBox.shrink()),
                      ),
                      // Bottom gradient so title text is always readable
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.70),
                            ],
                            stops: const [0.35, 1.0],
                          ),
                        ),
                      ),
                      // Title & bestFor overlaid on the image
                      Positioned(
                        left: 20.w,
                        right: 20.w,
                        bottom: 20.h,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (trip.bestFor.isNotEmpty)
                              Container(
                                margin: EdgeInsets.only(bottom: 8.h),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 10.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  color: gold.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(20.r),
                                  border: Border.all(
                                      color: gold.withValues(alpha: 0.5)),
                                ),
                                child: Text(
                                  '🧭 Best for: ${trip.bestFor}',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            Text(
                              trip.title,
                              style: TextStyle(
                                fontSize: 26.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo'],
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              trip.tagline,
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: Colors.white.withValues(alpha: 0.85),
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Body ─────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 100.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info pills
                      _AnimatedSection(
                        slideAnim: _slideAnim(0),
                        fadeAnim: _fadeAnim(0),
                        child: Wrap(
                          spacing: 8.w,
                          runSpacing: 8.h,
                          children: [
                            _Pill(
                                icon: Icons.schedule_outlined,
                                label: trip.durationLabel,
                                gold: gold),
                            _Pill(
                                icon: Icons.location_on_outlined,
                                label: trip.primaryArea,
                                gold: gold),
                            _Pill(
                                icon: Icons.wallet_outlined,
                                label: trip.budgetRange,
                                gold: gold),
                            _Pill(
                                icon: Icons.star_rounded,
                                label: '${trip.rating} rating',
                                gold: gold),
                          ],
                        ),
                      ),
                      SizedBox(height: 16.h),

                      // Hear the Story button
                      _AnimatedSection(
                        slideAnim: _slideAnim(1),
                        fadeAnim: _fadeAnim(1),
                        child: GestureDetector(
                          onTap: () => _showStorySheet(context),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16.w, vertical: 11.h),
                            decoration: BoxDecoration(
                              color: gold.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(14.r),
                              border: Border.all(
                                  color: gold.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.auto_stories_outlined,
                                    size: 17.r, color: gold),
                                SizedBox(width: 8.w),
                                Text(
                                  AppLocalizations.of(context).soloHearStory,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: gold,
                                    fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo'],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 24.h),

                      // Highlights
                      _AnimatedSection(
                        slideAnim: _slideAnim(2),
                        fadeAnim: _fadeAnim(2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context).soloHighlights,
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                                fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo'],
                              ),
                            ),
                            SizedBox(height: 10.h),
                            ...trip.highlights.map(
                              (h) => Padding(
                                padding: EdgeInsets.only(bottom: 8.h),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.check_circle_outline_rounded,
                                        size: 18.r, color: gold),
                                    SizedBox(width: 10.w),
                                    Expanded(
                                      child: Text(
                                        h,
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          color: textColor.withValues(alpha: 0.8),
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24.h),

                      // Itinerary header + full route button
                      _AnimatedSection(
                        slideAnim: _slideAnim(3),
                        fadeAnim: _fadeAnim(3),
                        child: Row(
                          children: [
                            Text(
                              AppLocalizations.of(context).soloItinerary,
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                                fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo'],
                              ),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: _viewFullRoute,
                              icon: Icon(Icons.map_outlined,
                                  size: 16.r, color: gold),
                              label: Text(
                                AppLocalizations.of(context).soloFullRoute,
                                style: TextStyle(
                                    color: gold,
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600),
                              ),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12.w, vertical: 6.h),
                                backgroundColor: gold.withValues(alpha: 0.1),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20.r)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 14.h),

                      // Days
                      ...trip.days.asMap().entries.map((entry) {
                        final dayIdx = entry.key;
                        final day = entry.value;
                        return _AnimatedSection(
                          slideAnim: _slideAnim(4 + dayIdx),
                          fadeAnim: _fadeAnim(4 + dayIdx),
                          child: _DaySection(
                            day: day,
                            cardColor: cardColor,
                            textColor: textColor,
                            gold: gold,
                            onNavigate: _navigateToStop,
                            stopAnimOffset: 4 + dayIdx + 1,
                            slideAnim: _slideAnim,
                            fadeAnim: _fadeAnim,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── Fixed bottom bar ─────────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  20.w, 12.h, 20.w, MediaQuery.of(context).padding.bottom + 12.h),
              decoration: BoxDecoration(
                color: bgColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Save Plan
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: (_saving || _isSaved) ? null : _savePlan,
                      icon: _saving
                          ? SizedBox(
                              width: 16.w,
                              height: 16.h,
                              child: const CircularProgressIndicator(strokeWidth: 2))
                          : Icon(
                              _isSaved
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_outline_rounded,
                              size: 18.r,
                              color: gold,
                            ),
                      label: Text(
                        _isSaved ? AppLocalizations.of(context).soloStatusSaved : AppLocalizations.of(context).soloSavePlan,
                        style: TextStyle(
                            color: gold, fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: gold, width: 1.5),
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r)),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  // Start Tour
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _starting ? null : _startTour,
                      icon: _starting
                          ? SizedBox(
                              width: 16.w,
                              height: 16.h,
                              child: const CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Icon(
                              _isActive
                                  ? Icons.directions_walk_rounded
                                  : Icons.play_arrow_rounded,
                              size: 20.r,
                              color: Colors.white),
                      label: Text(
                        _isActive ? AppLocalizations.of(context).soloContinueTour : AppLocalizations.of(context).soloStartTour,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: gold,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Animated wrapper ───────────────────────────────────────────────────────────

class _AnimatedSection extends StatelessWidget {
  final Animation<double> slideAnim;
  final Animation<double> fadeAnim;
  final Widget child;

  const _AnimatedSection({
    required this.slideAnim,
    required this.fadeAnim,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: slideAnim,
      builder: (_, _) => Opacity(
        opacity: fadeAnim.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, slideAnim.value),
          child: child,
        ),
      ),
    );
  }
}

// ── Pill chip ─────────────────────────────────────────────────────────────────

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color gold;

  const _Pill({required this.icon, required this.label, required this.gold});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: gold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: gold.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.r, color: gold),
          SizedBox(width: 5.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 13.sp,
              color: gold,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Day section ───────────────────────────────────────────────────────────────

class _DaySection extends StatelessWidget {
  final CuratedTripDay day;
  final Color cardColor;
  final Color textColor;
  final Color gold;
  final void Function(CuratedTripStop) onNavigate;
  final int stopAnimOffset;
  final Animation<double> Function(int) slideAnim;
  final Animation<double> Function(int) fadeAnim;

  const _DaySection({
    required this.day,
    required this.cardColor,
    required this.textColor,
    required this.gold,
    required this.onNavigate,
    required this.stopAnimOffset,
    required this.slideAnim,
    required this.fadeAnim,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding:
              EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
          decoration: BoxDecoration(
            color: gold.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Text(
            day.label,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: gold,
              fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo'],
            ),
          ),
        ),
        ...day.stops.asMap().entries.map((entry) {
          final i = entry.key;
          final stop = entry.value;
          final isLast = i == day.stops.length - 1;
          return _AnimatedSection(
            slideAnim: slideAnim(stopAnimOffset + i),
            fadeAnim: fadeAnim(stopAnimOffset + i),
            child: _StopRow(
              stop: stop,
              isLast: isLast,
              cardColor: cardColor,
              textColor: textColor,
              gold: gold,
              onNavigate: () => onNavigate(stop),
            ),
          );
        }),
        SizedBox(height: 16.h),
      ],
    );
  }
}

// ── Stop row ──────────────────────────────────────────────────────────────────

class _StopRow extends StatelessWidget {
  final CuratedTripStop stop;
  final bool isLast;
  final Color cardColor;
  final Color textColor;
  final Color gold;
  final VoidCallback onNavigate;

  const _StopRow({
    required this.stop,
    required this.isLast,
    required this.cardColor,
    required this.textColor,
    required this.gold,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline column
          SizedBox(
            width: 36.w,
            child: Column(
              children: [
                Container(
                  width: 32.r,
                  height: 32.r,
                  decoration: BoxDecoration(
                    color: gold.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: gold, width: 1.5),
                  ),
                  child: Icon(
                    _iconForType(stop.type),
                    size: 16.r,
                    color: gold,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      margin: EdgeInsets.symmetric(vertical: 4.h),
                      color: gold.withValues(alpha: 0.25),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          // Stop card
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16.h),
              child: Container(
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            stop.name,
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                              fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo'],
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: gold.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.schedule_outlined,
                                  size: 12.r, color: gold),
                              SizedBox(width: 3.w),
                              Text(
                                stop.estimatedDuration,
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: gold,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      stop.description,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: textColor.withValues(alpha: 0.7),
                        height: 1.45,
                      ),
                    ),
                    if (stop.hasCoordinates) ...[
                      SizedBox(height: 10.h),
                      GestureDetector(
                        onTap: onNavigate,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 12.w, vertical: 7.h),
                          decoration: BoxDecoration(
                            color: gold.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20.r),
                            border:
                                Border.all(color: gold.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.navigation_rounded,
                                  size: 14.r, color: gold),
                              SizedBox(width: 6.w),
                              Text(
                                AppLocalizations.of(context).soloNavigateHere,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: gold,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForType(String type) {
    return switch (type) {
      'mosque' => Icons.mosque_outlined,
      'church' => Icons.church_outlined,
      'museum' => Icons.museum_outlined,
      'market' => Icons.store_mall_directory_outlined,
      'beach' => Icons.beach_access_outlined,
      'park' => Icons.park_outlined,
      'restaurant' || 'cafe' => Icons.restaurant_outlined,
      'archaeological_site' => Icons.explore_outlined,
      'monument' => Icons.account_balance_outlined,
      'historical_landmark' => Icons.location_city_outlined,
      'cultural' => Icons.people_outline_rounded,
      _ => Icons.place_outlined,
    };
  }
}

// ── Hero icon widget (animates via Hero transition from PlanCard) ──────────────

// ── Trip story bottom sheet ───────────────────────────────────────────────────

class _TripStorySheet extends StatefulWidget {
  final String tripTitle;
  final Color gold;

  const _TripStorySheet({required this.tripTitle, required this.gold});

  @override
  State<_TripStorySheet> createState() => _TripStorySheetState();
}

class _TripStorySheetState extends State<_TripStorySheet> {
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
      final story = await StoryCacheService.instance
          .getStory(widget.tripTitle, locale: LocaleController.localeCode);
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
      final bytes = await AIStorytellerService.getStoryAudio(_story!,
          locale: LocaleController.localeCode);
      if (bytes == null || !mounted) {
        if (mounted) setState(() => _loadingAudio = false);
        return;
      }
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/curated_trip_story.mp3');
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
                    widget.tripTitle,
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
                        width: 28.w,
                        height: 28.h,
                        child: CircularProgressIndicator(strokeWidth: 2, color: gold),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'Summoning the story…',
                        style: TextStyle(fontSize: 13.sp, color: textColor.withValues(alpha: 0.5)),
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
                      style: TextStyle(fontSize: 14.sp, color: textColor.withValues(alpha: 0.6)),
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
                              width: 18.w,
                              height: 18.h,
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
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: gold,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
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

class _HeroIcon extends StatelessWidget {
  final TripTheme theme;

  const _HeroIcon({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100.r,
      height: 100.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(theme.icon, color: Colors.white, size: 46.r),
    );
  }
}
