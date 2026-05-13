import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lost_in_egypt/core/constants/curated_trips.dart';
import 'package:lost_in_egypt/core/models/curated_trip.dart';
import 'package:lost_in_egypt/feature/home/tabs/home/trip/solo_trip/presention/curated_trip_detail_screen.dart';
import 'package:lost_in_egypt/core/models/solo_plan.dart';
import 'package:lost_in_egypt/core/services/solo_plan_service.dart';
import 'package:lost_in_egypt/feature/home/tabs/home/trip/solo_trip/presention/my_plans_screen.dart';
import 'package:lost_in_egypt/feature/home/tabs/home/trip/solo_trip/presention/widgets/customize_plan_card.dart';
import 'package:lost_in_egypt/feature/home/tabs/home/trip/solo_trip/presention/widgets/plan_card.dart';
import '../../../../../../../../theme/theme.dart';
import '../../../../navigator/widget/account_menu_button.dart';
import 'package:lost_in_egypt/core/services/recommendation_service.dart';

class SoloTripPage extends StatefulWidget {
  final String? profileImageUrl;
  final VoidCallback onSignOut;

  const SoloTripPage({
    super.key,
    required this.profileImageUrl,
    required this.onSignOut,
  });

  @override
  State<SoloTripPage> createState() => _SoloTripPageState();
}

class _SoloTripPageState extends State<SoloTripPage> {
  List<CuratedTrip> _trips = CuratedTrips.all;
  String? _bestMatchId;
  bool _loadingPersonalization = true;

  @override
  void initState() {
    super.initState();
    _loadPersonalization();
  }

  Future<void> _loadPersonalization() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _loadingPersonalization = false);
      return;
    }

    try {
      final futures = await Future.wait([
        FirebaseFirestore.instance.collection('users').doc(uid).get(),
        _getUserPosition(),
      ]);

      final doc = futures[0] as DocumentSnapshot;
      final position = futures[1] as Position?;

      final raw = doc.data() != null
          ? (doc.data() as Map<String, dynamic>)['tasteVector']
          : null;
      final tasteVector = (raw is Map)
          ? Map<String, dynamic>.from(raw)
          : <String, dynamic>{};

      // Tiered ranking: location dominates, taste vector tie-breaks within tier.
      // This guarantees local trips ALWAYS rank above distant trips regardless
      // of how heavily the user's taste vector favours pharaonic / Alex sites.
      //
      // CRITICAL: when GPS is unavailable, we KEEP the curator's static order
      // and do NOT fall back to taste-only sorting. A pharaonic-heavy taste
      // vector would otherwise wrongly elevate Greco-Roman Alexandria above
      // Islamic Cairo for a Cairo-based user — exactly the bug we just fixed.
      if (position == null) {
        if (!mounted) return;
        setState(() {
          _trips = CuratedTrips.all;
          _bestMatchId = null;
          _loadingPersonalization = false;
        });
        return;
      }

      final scored = CuratedTrips.all.map((trip) {
        final taste = trip.scoreAgainst(tasteVector);
        final tier = _locationTier(trip, position);
        return (trip: trip, taste: taste, tier: tier);
      }).toList()
        ..sort((a, b) {
          if (a.tier != b.tier) return a.tier.compareTo(b.tier);
          return b.taste.compareTo(a.taste);
        });

      if (!mounted) return;
      setState(() {
        _trips = scored.map((e) => e.trip).toList();
        // Best match: top-tier-0 trip, or top-tier-1 with strong taste signal.
        _bestMatchId =
            scored.first.tier == 0 || scored.first.taste > 5.0
                ? scored.first.trip.id
                : null;
        _loadingPersonalization = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingPersonalization = false);
    }
  }

  Future<Position?> _getUserPosition() async {
    try {
      // 1. Location services must be enabled at the OS level.
      if (!await Geolocator.isLocationServiceEnabled()) {
        return null;
      }

      // 2. App-level permission.
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return null;
      }

      // 3. Try last-known first — it's instant and usually available even on
      // cold start. A user can't realistically travel between Egyptian cities
      // in 10 minutes, so this is safe for tier-based trip ranking.
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        final age = DateTime.now().difference(lastKnown.timestamp);
        if (age < const Duration(minutes: 10)) {
          return lastKnown;
        }
      }

      // 4. Get a fresh fix. Medium accuracy is the reliability sweet-spot —
      // low (cell/wifi only) frequently times out in weaker signal areas,
      // high (GPS-only) is slow to acquire indoors. 10s timeout accounts for
      // first-acquire cold-start latency.
      try {
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 10),
        );
      } catch (_) {
        // Fresh fix failed — fall back to whatever last-known we have,
        // even if it's >10 min old. Better than nothing.
        return lastKnown;
      }
    } catch (_) {
      return null;
    }
  }

  double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLng = (lng2 - lng1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  /// Proximity tier for sorting (lower = closer = higher priority).
  /// Trips are bucketed by distance, then taste vector tie-breaks within a tier.
  /// This guarantees a Cairo user sees Cairo trips before Alexandria trips
  /// regardless of taste-vector skew.
  ///   tier 0: <50 km   (local — same city)
  ///   tier 1: <250 km  (regional — same governorate cluster)
  ///   tier 2: <600 km  (national — domestic flight territory)
  ///   tier 3: ≥600 km  (far — multi-day trip)
  /// When position is unknown, all trips collapse to tier 1 so taste vector
  /// alone decides the order.
  int _locationTier(CuratedTrip trip, Position? pos) {
    if (pos == null) return 1;
    final km = _haversineKm(
        pos.latitude, pos.longitude, trip.centerLat, trip.centerLng);
    if (km < 50) return 0;
    if (km < 250) return 1;
    if (km < 600) return 2;
    return 3;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final sectionColor = isDark ? AppColors.darkPatternOverlay : const Color(0xFFFFFEF0);
    final titleColor = isDark ? AppColors.darkText : AppColors.lightBox;
    final patternOpacity = isDark ? 0.1 : 0.4;
    final gold = AppColors.lightPrimaryButton;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          Positioned.fill(child: Container(color: bgColor)),
          Positioned.fill(
            child: Opacity(
              opacity: patternOpacity,
              child: Image.asset(
                'assets/pattern_comp.png',
                fit: BoxFit.cover,
                repeat: ImageRepeat.repeat,
                errorBuilder: (_, _, _) => Container(),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.chevron_left_rounded,
                          color: titleColor,
                          size: 30.r,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Solo Trip',
                          style: TextStyle(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w500,
                            color: titleColor,
                            fontFamily: 'Marcellus',
                          ),
                        ),
                      ),
                      SizedBox(width: 4.w),
                      StreamBuilder<List<SavedPlan>>(
                        stream: SoloPlanService.instance.streamPlans(),
                        builder: (context, snap) {
                          final count = (snap.data ?? [])
                              .where((p) =>
                                  p.status == SoloPlanStatus.saved ||
                                  p.status == SoloPlanStatus.active)
                              .length;
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              IconButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const MyPlansScreen()),
                                ),
                                tooltip: 'My Plans',
                                icon: Icon(Icons.bookmark_outlined,
                                    color: gold, size: 24.r),
                              ),
                              if (count > 0)
                                Positioned(
                                  right: 6,
                                  top: 6,
                                  child: Container(
                                    width: 16.r,
                                    height: 16.r,
                                    decoration: BoxDecoration(
                                      color: gold,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        count > 9 ? '9+' : '$count',
                                        style: TextStyle(
                                          fontSize: 9.sp,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      AccountMenuButton(
                        profileImageUrl: widget.profileImageUrl,
                        onSignOut: widget.onSignOut,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    child: Column(
                      children: [
                        SizedBox(height: 6.h),
                        const CustomizePlanCard(),
                        SizedBox(height: 20.h),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.fromLTRB(14.w, 18.h, 14.w, 18.h),
                          decoration: BoxDecoration(
                            color: sectionColor,
                            borderRadius: BorderRadius.circular(28.r),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Recommended Plans',
                                    style: TextStyle(
                                      fontSize: 24.sp,
                                      fontWeight: FontWeight.w500,
                                      color: titleColor,
                                      fontFamily: 'Marcellus',
                                    ),
                                  ),
                                  if (_loadingPersonalization)
                                    SizedBox(
                                      width: 16.r,
                                      height: 16.r,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 1.5, color: gold),
                                    ),
                                ],
                              ),
                              if (_bestMatchId != null) ...[
                                SizedBox(height: 6.h),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Personalised based on your travel history',
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      color: titleColor.withValues(alpha: 0.55),
                                    ),
                                  ),
                                ),
                              ],
                              SizedBox(height: 18.h),
                              StreamBuilder<List<SavedPlan>>(
                                stream: SoloPlanService.instance.streamPlans(),
                                builder: (context, snap) {
                                  final savedTripIds = (snap.data ?? [])
                                      .where((p) =>
                                          p.curatedTripId != null &&
                                          p.status != SoloPlanStatus.completed)
                                      .map((p) => p.curatedTripId!)
                                      .toSet();
                                  return Column(
                                    children: _trips.asMap().entries.map((entry) {
                                      final trip = entry.value;
                                      final isLast = entry.key == _trips.length - 1;
                                      final heroTag = 'trip-${trip.id}';
                                      return Dismissible(
                                        key: ValueKey(trip.id),
                                        direction: DismissDirection.endToStart,
                                        background: Container(
                                          alignment: Alignment.centerRight,
                                          padding: EdgeInsets.only(right: 20.w),
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade400,
                                            borderRadius: BorderRadius.circular(20.r),
                                          ),
                                          child: Icon(Icons.close_rounded,
                                              color: Colors.white, size: 28.r),
                                        ),
                                        onDismissed: (_) {
                                          for (final key in trip.scoringKeys) {
                                            RecommendationService.recordSignal(
                                              placeId: trip.id,
                                              placeName: trip.title,
                                              types: [key],
                                              signalType: 'dismiss',
                                              source: 'solo_trip',
                                            );
                                          }
                                        },
                                        child: Padding(
                                          padding: EdgeInsets.only(
                                              bottom: isLast ? 0 : 16.h),
                                          child: PlanCard(
                                            title: trip.title,
                                            location: trip.primaryArea,
                                            rating: trip.rating.round(),
                                            image: trip.imagePath,
                                            isBestMatch: trip.id == _bestMatchId,
                                            isSaved: savedTripIds.contains(trip.id),
                                            tagline: trip.tagline,
                                            durationLabel: trip.durationLabel,
                                            heroTag: heroTag,
                                            tripId: trip.id,
                                            onTap: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    CuratedTripDetailScreen(
                                                  trip: trip,
                                                  heroTag: heroTag,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20.h),
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
