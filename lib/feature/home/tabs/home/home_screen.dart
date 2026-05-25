import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lost_in_egypt/core/widgets/shimmer_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lost_in_egypt/core/models/weather_context.dart';
import 'package:lost_in_egypt/core/services/recommendation_service.dart';
import 'package:lost_in_egypt/core/services/weather_controller.dart';
import 'package:lost_in_egypt/core/widgets/weather_banner.dart';
import 'package:lost_in_egypt/core/widgets/weather_forecast_sheet.dart';
import 'package:lost_in_egypt/feature/home/tabs/home/trip/guide/guides_body.dart';
import 'package:lost_in_egypt/feature/home/tabs/home/trip/solo_trip/presention/solo_trip_page.dart';
import 'package:lost_in_egypt/feature/tours/domain/entities/tour_entity.dart';
import 'package:lost_in_egypt/feature/tours/presentation/pages/tour_detail_screen.dart';
import 'package:lost_in_egypt/core/services/currency_controller.dart';
import 'package:lost_in_egypt/core/services/currency_service.dart';
import 'package:lost_in_egypt/core/constants/event_categories.dart';
import '../../../../theme/theme.dart';
import '../navigator/widget/account_menu_button.dart';
import './data/datasources/local_mock_data.dart';
import './data/datasources/local_places_service.dart';
import './data/models/map_item_models.dart';
import './presentation/category_places_screen.dart';
import './presentation/all_events_screen.dart';
import './presentation/event_details_screen.dart';
import 'package:lost_in_egypt/feature/home/tabs/map/data/datasources/map_focus_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin<HomeScreen> {
  @override
  bool get wantKeepAlive => true;
  String? _profileImageUrl;
  String? _firstName;
  List<EventModel> _curatedEvents = [];
  String _selectedEventCategory = 'all';
  List<PlaceModel> _popularPlaces = [];
  List<PlaceModel> _forYouPlaces = [];
  bool _loadingForYou = true;
  bool _loadingEvents = true;

  // Session-level caches — avoids re-fetching on hot rebuilds / tab switches / back-nav
  static List<PlaceModel>? _cachedAllPlaces;
  static List<PlaceModel>? _cachedPopular;
  static List<PlaceModel>? _cachedForYou;
  static List<EventModel>? _cachedEvents;
  static DateTime? _forYouCacheTime;

  @override
  void initState() {
    super.initState();

    // Sync-init from static cache so the first build never shows shimmer/blank sections
    // when navigating back from a sub-screen (e.g. SoloTripPage).
    if (_cachedPopular != null) _popularPlaces = _cachedPopular!;
    if (_cachedForYou != null) {
      _forYouPlaces = _cachedForYou!;
      _loadingForYou = false;
    }
    if (_cachedEvents != null) {
      _curatedEvents = _cachedEvents!;
      _loadingEvents = false;
    }

    _fetchUserProfile();
    _loadPopularPlaces();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    if (_cachedEvents != null) return;
    try {
      // Load live events from Firestore
      List<EventModel> firestoreEvents = [];
      try {
        final snap = await FirebaseFirestore.instance
            .collection('events')
            .limit(30)
            .get();
        firestoreEvents = snap.docs
            .map((d) => EventModel.fromMap(d.data(), d.id))
            .toList();
      } catch (e) {
        print("Firestore events error: $e");
      }
      
      final merged = firestoreEvents;

      // Filter out past non-recurring events
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final active = merged.where((e) {
        if (e.isRecurring) return true; // recurring events never expire
        return !e.date.isBefore(today);  // keep if date is today or future
      }).toList();

      // Prioritize Passboard and Eventbrite events at the top
      active.sort((a, b) {
        final aLive = a.source == 'passboard' || a.source == 'eventbrite';
        final bLive = b.source == 'passboard' || b.source == 'eventbrite';
        if (aLive && !bLive) return -1;
        if (!aLive && bLive) return 1;
        return (b.importance ?? 5).compareTo(a.importance ?? 5);
      });

      if (!mounted) return;
      _cachedEvents = active;
      setState(() {
        _curatedEvents = active;
        _loadingEvents = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingEvents = false);
    }
  }

  Future<void> _loadPopularPlaces() async {
    if (_cachedAllPlaces != null) {
      // Already loaded — just refresh For You if needed (cache check is inside _loadForYou)
      unawaited(_loadForYou(_cachedAllPlaces!));
      return;
    }

    // Load every place across all categories for the recommendation pool
    final allPlaces = await LocalPlacesService.getTopRatedPlaces(limit: 99999);
    if (!mounted) return;

    _cachedAllPlaces = allPlaces;

    // Popular section: top-20 shuffled to 10 cards
    final shuffled = List<PlaceModel>.from(allPlaces.take(20))..shuffle();
    _cachedPopular = shuffled.take(10).toList();

    setState(() => _popularPlaces = _cachedPopular!);
    unawaited(_loadForYou(allPlaces));
  }

  Future<Position?> _getUserPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return null;
      }

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return null;
      }

      // Last-known is instant and usually available — only treat it as stale
      // after 10 min (a user can't switch Egyptian cities in that window).
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        final age = DateTime.now().difference(lastKnown.timestamp);
        if (age < const Duration(minutes: 10)) {
          return lastKnown;
        }
      }

      try {
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 10),
        );
      } catch (_) {
        return lastKnown;
      }
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadForYou(List<PlaceModel> pool) async {
    if (pool.isEmpty) {
      if (mounted) setState(() => _loadingForYou = false);
      return;
    }

    final now = DateTime.now();
    if (_cachedForYou != null &&
        _forYouCacheTime != null &&
        now.difference(_forYouCacheTime!).inMinutes < 5) {
      if (mounted) setState(() { _forYouPlaces = _cachedForYou!; _loadingForYou = false; });
      return;
    }

    final position = await _getUserPosition();
    // Fall back to Cairo centre so distant places still get a proximity penalty.
    final lat = position?.latitude ?? 30.0444;
    final lng = position?.longitude ?? 31.2357;

    // Mixed candidate pool: nearest 100 by distance + top-rated 50 from the rest.
    // This ensures local places always appear while still letting 1-2 high-taste-match
    // distant places (e.g. Dahab beach for a beach lover in Cairo) surface in For You.
    final List<PlaceModel> sorted;
    if (pool.length > 100) {
      final byDistance = List<PlaceModel>.from(pool)
        ..sort((a, b) {
          final dA = Geolocator.distanceBetween(
              lat, lng, a.coordinate.latitude, a.coordinate.longitude);
          final dB = Geolocator.distanceBetween(
              lat, lng, b.coordinate.latitude, b.coordinate.longitude);
          return dA.compareTo(dB);
        });
      final nearest100 = byDistance.take(100).toSet();
      final topRated50 = (byDistance.skip(100).toList()
            ..sort((a, b) => b.rating.compareTo(a.rating)))
          .take(50)
          .toList();
      sorted = [...nearest100, ...topRated50];
    } else {
      sorted = pool;
    }

    final candidates = sorted.map((p) => <String, dynamic>{
      'placeId': p.id,
      'name': p.title,
      'types': [p.category],
      'tags': p.tags,
      'rating': p.rating,
      'userRatingCount': p.userRatingCount,
      'lat': p.coordinate.latitude,
      'lng': p.coordinate.longitude,
    }).toList();

    final result = await RecommendationService.recommendPlaces(
      candidates: candidates,
      context: 'home',
      limit: 8,
      weather: WeatherController.weather.value,
      userLat: lat,
      userLng: lng,
    );

    if (!mounted) return;

    if (result != null && result.recommendations.isNotEmpty) {
      final idToPlace = {for (final p in sorted) p.id: p};
      final forYou = result.recommendations
          .map((r) => idToPlace[r.placeId])
          .whereType<PlaceModel>()
          .toList();
      if (forYou.isNotEmpty) {
        _cachedForYou = forYou;
        _forYouCacheTime = DateTime.now();
        setState(() { _forYouPlaces = forYou; _loadingForYou = false; });
        return;
      }
    }

    setState(() => _loadingForYou = false);
  }

  Future<void> _fetchUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists && mounted) {
          setState(() {
            _profileImageUrl = doc.data()?['profileImageUrl'];
            _firstName = doc.data()?['firstName'];
          });
        }
      } catch (e) {
        debugPrint("Error fetching profile: $e");
      }
    }
  }

  Future<void> _handleSignOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg = theme.scaffoldBackgroundColor;
    final surface = theme.colorScheme.surface;
    final primary = isDark ? AppColors.darkNavBar : theme.colorScheme.primary;

    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final secondaryTextColor = textColor.withValues(alpha: 0.65);

    final cardShadow = BoxShadow(
      color: isDark
          ? Colors.white.withValues(alpha: 0.02)
          : Colors.black.withValues(alpha: 0.10),
      blurRadius: 14,
      spreadRadius: 1,
      offset: const Offset(0, 8),
    );

    return Scaffold(
      backgroundColor: bg,
      body: SingleChildScrollView(
        key: const PageStorageKey<String>('home_scroll'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeroBanner(
              profileImageUrl: _profileImageUrl,
              onSignOut: _handleSignOut,
            ),
            SizedBox(height: 12.h),
            // ── Weather advisory banner ──
            ValueListenableBuilder<WeatherContext?>(
              valueListenable: WeatherController.weather,
              builder: (_, weather, _) {
                if (weather == null || !WeatherBanner.shouldShow(weather)) {
                  return const SizedBox.shrink();
                }
                return WeatherBanner(
                  weather: weather,
                  onTap: () => WeatherForecastSheet.show(context),
                );
              },
            ),
            SizedBox(height: 4.h),
            // ── Greeting ──
            if (_firstName != null && _firstName!.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Text(
                  "${_greetingForTimeOfDay()}, $_firstName 👋",
                  style: TextStyle(
                    color: primary,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: "Marcellus",
                  ),
                ),
              ),
            SizedBox(height: 8.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Text(
                "Where do you want to go?",
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.9),
                  fontSize: 22.sp,
                  fontFamily: "Marcellus",
                ),
              ),
            ),
            SizedBox(height: 12.h),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.15,
                crossAxisSpacing: 12.w,
                mainAxisSpacing: 12.h,
              ),
              itemCount: LocalMockData.categories.length.clamp(0, 6),
              itemBuilder: (context, index) {
                final category = LocalMockData.categories[index];
                return _categoryCard(
                  icon: category.iconPath,
                  title: category.title,
                  surface: surface,
                  textColor: textColor,
                  shadow: cardShadow,
                  isDark: isDark,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CategoryPlacesScreen(
                          categoryId: category.id,
                          categoryTitle: category.title,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            SizedBox(height: 25.h),
            // ── Popular Places ──
            if (_popularPlaces.isNotEmpty) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Row(
                  children: [
                    Container(
                      width: 4.w,
                      height: 22.h,
                      decoration: BoxDecoration(
                        color: primary,
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      "Popular Places",
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.9),
                        fontSize: 22.sp,
                        fontFamily: "Marcellus",
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
              SizedBox(
                height: 200.h,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.only(left: 16.w),
                  itemCount: _popularPlaces.length,
                  itemBuilder: (context, index) {
                    final place = _popularPlaces[index];
                    return _popularPlaceCard(
                      place: place,
                      primary: primary,
                      textColor: textColor,
                      shadow: cardShadow,
                      isDark: isDark,
                    );
                  },
                ),
              ),
              SizedBox(height: 25.h),
            ],
            // ── For You ──
            if (_loadingForYou || _forYouPlaces.isNotEmpty) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Row(
                  children: [
                    Container(
                      width: 4.w,
                      height: 22.h,
                      decoration: BoxDecoration(
                        color: primary,
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      "For You",
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.9),
                        fontSize: 22.sp,
                        fontFamily: "Marcellus",
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Icon(Icons.auto_awesome, size: 16.r, color: primary),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
              if (_loadingForYou)
                SizedBox(
                  height: 200.h,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.only(left: 16.w),
                    itemCount: 3,
                    itemBuilder: (_, _) => const _ForYouSkeletonCard(),
                  ),
                )
              else
                SizedBox(
                  height: 200.h,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.only(left: 16.w),
                    itemCount: _forYouPlaces.length,
                    itemBuilder: (context, index) {
                      return _popularPlaceCard(
                        place: _forYouPlaces[index],
                        primary: primary,
                        textColor: textColor,
                        shadow: cardShadow,
                        isDark: isDark,
                      );
                    },
                  ),
                ),
              SizedBox(height: 25.h),
            ],
            // ── Events ──
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4.w,
                        height: 22.h,
                        decoration: BoxDecoration(
                          color: primary,
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        "Experiences",
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.9),
                          fontSize: 22.sp,
                          fontFamily: "Marcellus",
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AllEventsScreen(events: _curatedEvents)),
                      );
                    },
                    child: Text(
                      "see all >",
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.bold,
                        fontFamily: "Marcellus",
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8.h),
            // Category filter chips
            SizedBox(
              height: 36.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.only(left: 16.w),
                itemCount: EventCategories.values.length,
                itemBuilder: (context, index) {
                  final cat = EventCategories.values[index];
                  final isSelected = _selectedEventCategory == cat.id;
                  return Padding(
                    padding: EdgeInsets.only(right: 8.w),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedEventCategory = cat.id);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: isSelected ? primary : surface,
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: isSelected ? primary : textColor.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Text(
                          cat.label,
                          style: TextStyle(
                            color: isSelected ? Colors.white : textColor.withValues(alpha: 0.7),
                            fontSize: 12.sp,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            fontFamily: "Marcellus",
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 10.h),
            // Events carousel
            SizedBox(
              height: 200.h,
              child: _loadingEvents
                  ? Center(
                      child: CircularProgressIndicator(
                        color: theme.colorScheme.primary,
                      ),
                    )
                  : Builder(
                      builder: (context) {
                        final filtered = _selectedEventCategory == 'all'
                            ? _curatedEvents
                            : _curatedEvents
                                .where((e) => e.eventCategory == _selectedEventCategory)
                                .toList();
                        if (filtered.isEmpty) {
                          return Center(
                            child: Text(
                              "No events in this category",
                              style: TextStyle(color: secondaryTextColor),
                            ),
                          );
                        }
                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.only(left: 16.w),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            return _eventCard(
                              event: filtered[index],
                              surface: surface,
                              textColor: textColor,
                              shadow: cardShadow,
                              primary: primary,
                            );
                          },
                        );
                      },
                    ),
            ),
            SizedBox(height: 25.h),
            // ── Popular Tours ──
            _popularToursSection(
              primary: primary,
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              surface: surface,
              cardShadow: cardShadow,
              isDark: isDark,
            ),
            // ── Plan your trip ──
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                children: [
                  Container(
                    width: 4.w,
                    height: 22.h,
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    "Plan your trip",
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.9),
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      fontFamily: "Marcellus",
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                children: [
                  Expanded(
                    child: _tripCard(
                      title: "Guides",
                      surface: surface,
                      textColor: textColor,
                      shadow: cardShadow,
                      isDark: isDark,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const GuideBodyScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _tripCard(
                      title: "Solo trip",
                      surface: surface,
                      textColor: textColor,
                      shadow: cardShadow,
                      isDark: isDark,
                      onTap: () {
                        // Fade-through transition feels smoother than the
                        // default slide — and the slide was what made the
                        // pop-back to home look like a jarring "refresh".
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            transitionDuration:
                                const Duration(milliseconds: 280),
                            reverseTransitionDuration:
                                const Duration(milliseconds: 220),
                            pageBuilder: (_, _, _) => SoloTripPage(
                              profileImageUrl: _profileImageUrl,
                              onSignOut: _handleSignOut,
                            ),
                            transitionsBuilder: (_, animation, _, child) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 120.h),
          ],
        ),
      ),
    );
  }

  Widget _categoryCard({
    required String icon,
    required String title,
    required Color surface,
    required Color textColor,
    required BoxShadow shadow,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [shadow],
        border: Border.all(
          color: (Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black)
              .withValues(alpha: 0.06),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14.r),
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14.r),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                icon,
                width: 40.r,
                color: isDark
                    ? AppColors.darkNavBar
                    : Theme.of(context).colorScheme.primary,
                colorBlendMode: BlendMode.srcIn,
              ),
              SizedBox(height: 8.h),
              Text(
                title,
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                  fontFamily: "Marcellus",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _eventCard({
    required EventModel event,
    required Color surface,
    required Color textColor,
    required BoxShadow shadow,
    required Color primary,
  }) {
    final imagePath = event.imagePath;
    final categoryInfo = EventCategories.fromId(event.eventCategory);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EventDetailsScreen(event: event),
          ),
        );
      },
      child: Container(
        width: 170.w,
        margin: EdgeInsets.only(right: 12.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [shadow],
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Full-bleed image
            imagePath.startsWith('http')
                ? ShimmerImage(
                    url: imagePath,
                    fit: BoxFit.cover,
                    fallbackIcon: Icons.image_not_supported_outlined,
                    fallbackBackgroundColor: primary.withValues(alpha: 0.06),
                    fallbackIconColor: primary.withValues(alpha: 0.3),
                    fallbackIconSize: 32.r,
                  )
                : Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: primary.withValues(alpha: 0.06),
                      child: Icon(Icons.image_not_supported_outlined,
                          color: primary.withValues(alpha: 0.3), size: 32.r),
                    ),
                  ),
            // Gradient overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.65),
                    ],
                    stops: const [0.4, 1.0],
                  ),
                ),
              ),
            ),
            // Category pill — top-left
            Positioned(
              top: 8.h,
              left: 8.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  categoryInfo.emoji,
                  style: TextStyle(fontSize: 11.sp),
                ),
              ),
            ),
            // Rating pill — top-right (matches places)
            if (event.rating > 0)
              Positioned(
                top: 8.h,
                right: 8.w,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade700,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, size: 12.r, color: Colors.white),
                      SizedBox(width: 2.w),
                      Text(
                        event.rating.toStringAsFixed(1) + (event.reviewCount > 0 ? " (${event.reviewCount})" : ""),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Title + City — bottom (matches places)
            Positioned(
              bottom: 10.h,
              left: 10.w,
              right: 10.w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      fontFamily: "Marcellus",
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (event.city.isNotEmpty || event.venueName.isNotEmpty) ...[
                    SizedBox(height: 3.h),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded,
                            size: 11.r, color: Colors.white.withValues(alpha: 0.8)),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: Text(
                            event.venueName.isNotEmpty ? event.venueName : event.city,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 11.sp,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tripCard({
    required String title,
    required Color surface,
    required Color textColor,
    required BoxShadow shadow,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 145.h,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [shadow],
        border: Border.all(
          color: (Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black)
              .withValues(alpha: 0.06),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.r),
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.r),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                title == "Guides"
                    ? "assets/icons/guide.png"
                    : "assets/icons/solo_trip.png",
                width: 80.r,
                color: isDark
                    ? AppColors.darkNavBar.withValues(alpha: 0.9)
                    : Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                colorBlendMode: BlendMode.srcIn,
              ),
              SizedBox(height: 6.h),
              Text(
                title,
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.9),
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: "Marcellus",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _greetingForTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good morning";
    if (hour < 17) return "Good afternoon";
    return "Good evening";
  }

  Widget _popularPlaceCard({
    required PlaceModel place,
    required Color primary,
    required Color textColor,
    required BoxShadow shadow,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: () => MapFocusService.instance.triggerFocus(place),
      child: Container(
        width: 170.w,
        margin: EdgeInsets.only(right: 12.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [shadow],
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          fit: StackFit.expand,
          children: [
            place.imagePath.startsWith('http')
                ? ShimmerImage(
                    url: place.imagePath,
                    fit: BoxFit.cover,
                    fallbackIcon: Icons.image_not_supported_outlined,
                    fallbackBackgroundColor: primary.withValues(alpha: 0.06),
                    fallbackIconColor: primary.withValues(alpha: 0.3),
                    fallbackIconSize: 32.r,
                  )
                : Image.asset(place.imagePath, fit: BoxFit.cover),
            // Gradient overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.65),
                    ],
                    stops: const [0.4, 1.0],
                  ),
                ),
              ),
            ),
            // Rating pill
            Positioned(
              top: 8.h,
              right: 8.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: Colors.amber.shade700,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, size: 12.r, color: Colors.white),
                    SizedBox(width: 2.w),
                    Text(
                      place.rating.toStringAsFixed(1),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Title + City
            Positioned(
              bottom: 10.h,
              left: 10.w,
              right: 10.w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      fontFamily: "Marcellus",
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (place.locationAddress.isNotEmpty) ...[
                    SizedBox(height: 3.h),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded,
                            size: 11.r, color: Colors.white.withValues(alpha: 0.8)),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: Text(
                            place.locationAddress,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 11.sp,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _popularToursSection({
    required Color primary,
    required Color textColor,
    required Color secondaryTextColor,
    required Color surface,
    required BoxShadow cardShadow,
    required bool isDark,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tours')
          .where('isArchived', isEqualTo: false)
          .orderBy('rating', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final docs = snapshot.data!.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                children: [
                  Container(
                    width: 4.w,
                    height: 22.h,
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    "Popular Tours",
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.9),
                      fontSize: 22.sp,
                      fontFamily: "Marcellus",
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            SizedBox(
              height: 200.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.only(left: 16.w),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final tour = TourEntity(
                    id: docs[index].id,
                    guideId: data['guideId'] ?? '',
                    title: data['title'] ?? '',
                    description: data['description'] ?? '',
                    destinations: (data['destinations'] as List<dynamic>?)
                            ?.map((e) => e.toString())
                            .toList() ??
                        [],
                    price: (data['price'] ?? 0).toDouble(),
                    meetingLatitude: (data['meetingLatitude'] ?? 30.0444).toDouble(),
                    meetingLongitude: (data['meetingLongitude'] ?? 31.2357).toDouble(),
                    meetingTime: (data['meetingTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
                    frequency: data['frequency'] ?? '',
                    meetingLocationName: data['meetingLocationName'] ?? '',
                    images: (data['images'] as List<dynamic>?)
                            ?.map((e) => e.toString())
                            .toList() ??
                        [],
                    maxAttendees: (data['maxAttendees'] ?? 10).toInt(),
                    rating: (data['rating'] ?? 0).toDouble(),
                    reviewCount: (data['reviewCount'] ?? 0).toInt(),
                    createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                  );

                  final hasImage = tour.images.isNotEmpty;

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => TourDetailScreen(tour: tour)),
                      );
                    },
                    child: Container(
                      width: 220.w,
                      margin: EdgeInsets.only(right: 12.w),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [cardShadow],
                        border: Border.all(
                          color: (isDark ? Colors.white : Colors.black)
                              .withValues(alpha: 0.06),
                        ),
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShimmerImage(
                            url: hasImage ? tour.images.first : null,
                            height: 120.h,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            fallbackIcon: Icons.tour,
                            fallbackBackgroundColor: primary.withValues(alpha: 0.06),
                            fallbackIconColor: primary.withValues(alpha: 0.3),
                            fallbackIconSize: 40.r,
                          ),
                          Padding(
                            padding: EdgeInsets.fromLTRB(10.w, 8.h, 10.w, 8.h),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tour.title,
                                  style: TextStyle(
                                    color: textColor.withValues(alpha: 0.9),
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: "Marcellus",
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4.h),
                                Row(
                                  children: [
                                    if (tour.rating > 0) ...[
                                      Icon(Icons.star_rounded,
                                          size: 14.r, color: Colors.amber.shade700),
                                      SizedBox(width: 2.w),
                                      Text(
                                        tour.rating.toStringAsFixed(1),
                                        style: TextStyle(
                                          color: secondaryTextColor,
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(width: 8.w),
                                    ],
                                    ValueListenableBuilder<String>(
                                      valueListenable: CurrencyController.currency,
                                      builder: (context, currency, _) {
                                        return FutureBuilder<double>(
                                          future: CurrencyService.instance
                                              .convertFromEGP(tour.price, currency),
                                          builder: (_, snap) {
                                            final label = snap.hasData
                                                ? CurrencyService.format(snap.data!, currency)
                                                : 'EGP ${tour.price.toStringAsFixed(0)}';
                                            return Text(
                                              label,
                                              style: TextStyle(
                                                color: primary,
                                                fontSize: 12.sp,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 25.h),
          ],
        );
      },
    );
  }
}

// ── Skeleton card mirroring _popularPlaceCard's silhouette so the "For You"
// loading state reads as content-in-progress rather than four grey slabs.
class _ForYouSkeletonCard extends StatelessWidget {
  const _ForYouSkeletonCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlight = isDark ? Colors.grey[700]! : Colors.grey[200]!;
    final accent = isDark ? Colors.grey[600]! : Colors.grey[100]!;

    return Container(
      width: 170.w,
      margin: EdgeInsets.only(right: 12.w),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Shimmer.fromColors(
        baseColor: base,
        highlightColor: highlight,
        child: Stack(
          children: [
            Container(color: base),
            // Rating pill placeholder — top-right, matches real card's pill
            Positioned(
              top: 10.h,
              right: 10.w,
              child: Container(
                width: 34.w,
                height: 16.h,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
            // Title + subtitle bars at the bottom — matches real card layout
            Positioned(
              left: 10.w,
              right: 10.w,
              bottom: 12.h,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 110.w,
                    height: 12.h,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Container(
                    width: 70.w,
                    height: 10.h,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hero banner extracted so its 3-second timer setState only rebuilds
// this subtree instead of the full 1000-line HomeScreen build method. ──────
class _HeroBanner extends StatefulWidget {
  final String? profileImageUrl;
  final VoidCallback onSignOut;

  const _HeroBanner({required this.profileImageUrl, required this.onSignOut});

  @override
  State<_HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<_HeroBanner> {
  static const _images = [
    'assets/images/event1.jpg',
    'assets/images/event3.jpg',
    'assets/images/home_bridge.png',
  ];

  final PageController _pageController = PageController();
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_pageController.hasClients) return;
      final next = (_index + 1) % _images.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = theme.scaffoldBackgroundColor;
    final primary = isDark ? AppColors.darkNavBar : theme.colorScheme.primary;

    return Column(
      children: [
        Stack(
          children: [
            SizedBox(
              height: 300.h,
              width: double.infinity,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _images.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) => Image.asset(_images[i], fit: BoxFit.cover),
              ),
            ),
            Container(
              height: 260.h,
              width: double.infinity,
              color: Colors.black.withValues(alpha: 0.08),
            ),
            Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16.w,
                right: 16.w,
              ),
              child: Row(
                children: [
                  const Spacer(),
                  AccountMenuButton(
                    profileImageUrl: widget.profileImageUrl,
                    onSignOut: widget.onSignOut,
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 20.h,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24.r),
                    topRight: Radius.circular(24.r),
                  ),
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: EdgeInsetsDirectional.only(start: 50.w, end: 50.w),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(_images.length, (i) {
                final active = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: EdgeInsets.symmetric(horizontal: 4.w),
                  height: 8.h,
                  width: active ? 22.w : 8.w,
                  decoration: BoxDecoration(
                    color: active ? primary : primary.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}
