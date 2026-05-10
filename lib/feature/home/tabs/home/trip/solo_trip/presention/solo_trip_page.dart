import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
      // Fetch taste vector and user location in parallel
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

      final scored = CuratedTrips.all.map((trip) {
        final taste = trip.scoreAgainst(tasteVector);
        final location = _locationBonus(trip, position);
        return (trip: trip, score: taste + location);
      }).toList()
        ..sort((a, b) => b.score.compareTo(a.score));

      if (!mounted) return;
      setState(() {
        _trips = scored.map((e) => e.trip).toList();
        _bestMatchId =
            scored.first.score > 0 ? scored.first.trip.id : null;
        _loadingPersonalization = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingPersonalization = false);
    }
  }

  /// Returns GPS position, requesting permission if not yet granted.
  /// Returns null silently if denied or unavailable.
  Future<Position?> _getUserPosition() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return null;
      }
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 5),
      );
    } catch (_) {
      return null;
    }
  }

  /// Haversine distance in km between two lat/lng points.
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

  /// Returns a score bonus/penalty based on user proximity to the trip's area.
  ///
  /// < 50 km   → +2.0 strong boost (user is right there)
  /// 50–150 km → +1.0 moderate boost (within day-trip range)
  /// 150–300 km→ +0.2 slight boost
  /// > 300 km  → −0.5 mild penalty (far away)
  double _locationBonus(CuratedTrip trip, Position? pos) {
    if (pos == null) return 0;
    final km = _haversineKm(
        pos.latitude, pos.longitude, trip.centerLat, trip.centerLng);
    if (km < 50) return 2.0;
    if (km < 150) return 1.0;
    if (km < 300) return 0.2;
    return -0.5;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final sectionColor =
        isDark ? AppColors.darkPatternOverlay : const Color(0xFFFFFEF0);
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.chevron_left_rounded,
                          color: titleColor,
                          size: 30,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Solo Trip',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                            color: titleColor,
                            fontFamily: 'Marcellus',
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // My Plans button with live count badge
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
                                    color: gold, size: 24),
                              ),
                              if (count > 0)
                                Positioned(
                                  right: 6,
                                  top: 6,
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: gold,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        count > 9 ? '9+' : '$count',
                                        style: const TextStyle(
                                          fontSize: 9,
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
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      children: [
                        const SizedBox(height: 6),
                        const CustomizePlanCard(),
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding:
                              const EdgeInsets.fromLTRB(14, 18, 14, 18),
                          decoration: BoxDecoration(
                            color: sectionColor,
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Recommended Plans',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w500,
                                      color: titleColor,
                                      fontFamily: 'Marcellus',
                                    ),
                                  ),
                                  if (_loadingPersonalization)
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 1.5, color: gold),
                                    ),
                                ],
                              ),
                              if (_bestMatchId != null) ...[
                                const SizedBox(height: 6),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Personalised based on your travel history',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color:
                                          titleColor.withValues(alpha: 0.55),
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 18),
                              StreamBuilder<List<SavedPlan>>(
                                stream:
                                    SoloPlanService.instance.streamPlans(),
                                builder: (context, snap) {
                                  final savedTripIds = (snap.data ?? [])
                                      .where((p) =>
                                          p.curatedTripId != null &&
                                          p.status !=
                                              SoloPlanStatus.completed)
                                      .map((p) => p.curatedTripId!)
                                      .toSet();
                                  return Column(
                                    children: _trips
                                        .asMap()
                                        .entries
                                        .map((entry) {
                                      final trip = entry.value;
                                      final isLast =
                                          entry.key == _trips.length - 1;
                                      final heroTag = 'trip-${trip.id}';
                                      return Padding(
                                        padding: EdgeInsets.only(
                                            bottom: isLast ? 0 : 16),
                                        child: PlanCard(
                                          title: trip.title,
                                          location: trip.primaryArea,
                                          rating: trip.rating.round(),
                                          image: trip.imagePath,
                                          isBestMatch:
                                              trip.id == _bestMatchId,
                                          isSaved: savedTripIds
                                              .contains(trip.id),
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
                                      );
                                    }).toList(),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
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
