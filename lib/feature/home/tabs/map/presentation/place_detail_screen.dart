import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_it/get_it.dart';

import 'package:lost_in_egypt/core/models/weather_context.dart';
import 'package:lost_in_egypt/core/services/recommendation_service.dart';
import 'package:lost_in_egypt/core/services/weather_controller.dart';
import 'package:lost_in_egypt/core/widgets/shimmer_loading_widget.dart';
import 'package:lost_in_egypt/core/widgets/weather_banner.dart';
import 'package:lost_in_egypt/core/widgets/weather_forecast_sheet.dart';
import 'package:lost_in_egypt/core/utils/error_handler.dart';
import 'package:lost_in_egypt/feature/home/tabs/home/data/models/map_item_models.dart';
import 'package:lost_in_egypt/feature/home/tabs/map/data/datasources/map_focus_service.dart';
import 'package:lost_in_egypt/feature/home/tabs/map/data/places_api_service.dart';
import 'package:lost_in_egypt/feature/home/tabs/map/widgets/full_screen_gallery.dart';

// Mirrors OUTDOOR_TYPES + SEMI_OUTDOOR_TYPES in functions/recommendation.js.
// Used to gate the weather advisory banner — indoor places never show it.
const _outdoorOrSemiOutdoor = {
  'park', 'beach', 'archaeological_site', 'monument', 'historical_landmark',
  'zoo', 'stadium', 'amusement_park', 'tourist_attraction', 'national_park',
  'market', 'street_market', 'bazaar',
};

class PlaceDetailSheet extends StatefulWidget {
  final MapItem place;
  final VoidCallback onClose;
  final VoidCallback onShowOnMap;
  final VoidCallback onDirections;
  final ValueChanged<double>? onScrollExtentChanged;
  final VoidCallback? onSavedToggled;
  final List<MapItem> allItems;

  const PlaceDetailSheet({
    super.key,
    required this.place,
    required this.onClose,
    required this.onShowOnMap,
    required this.onDirections,
    this.onScrollExtentChanged,
    this.onSavedToggled,
    this.allItems = const [],
  });

  @override
  State<PlaceDetailSheet> createState() => _PlaceDetailSheetState();
}

class _PlaceDetailSheetState extends State<PlaceDetailSheet> {
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  int _currentImageIndex = 0;
  bool _isSaved = false;
  String? _userId;
  double? _distanceKm;
  int? _crowdCount;
  int _communityPostCount = 0;
  List<_SimilarPlace> _similarPlaces = [];
  bool _loadingSimilar = false;

  // Lazy-loaded display fields. Initialised from widget.place; backfilled from
  // getPlaceDetails when missing. The bulk Places API fetch in MapRepository
  // omits `reviews` and `editorialSummary` (drops SKU from Atmosphere $0.040
  // to Enterprise $0.035), so we restore the rich data on demand here. Places
  // sourced from cat_*.json already arrive with descriptions populated, so the
  // empty-check below short-circuits and no API call fires for those.
  late String _description = widget.place.description;
  late List<PlaceReview> _reviews = widget.place.reviews;

  @override
  void initState() {
    super.initState();
    _checkIfSaved();
    _calculateDistance();
    _loadCrowdLevel();
    _loadCommunityPostCount();
    _backfillDetailsIfMissing();
    if (widget.allItems.length > 1) {
      _loadingSimilar = true;
      _loadSimilarPlaces();
    }
  }

  /// Fetches description + reviews from the Places Details API when the bulk
  /// fetch didn't include them. Idempotent: skips if both are already
  /// populated, skips for synthetic / non-Google IDs, and the underlying
  /// getPlaceDetails call is Firestore-cached for 30 days.
  Future<void> _backfillDetailsIfMissing() async {
    if (_description.isNotEmpty && _reviews.isNotEmpty) return;

    final placeId = widget.place.id;
    if (placeId.isEmpty) return;
    // Synthetic IDs from SOS results / AI-generated trip stops / local JSON
    // entries that don't have a real Google place ID. The Places API would
    // reject these — short-circuit silently. Local JSON entries already arrive
    // with descriptions populated, so the empty-check above usually handles
    // them, but the explicit prefix list is the durable guarantee.
    //   cat_*    → cat_*.json (LocalPlacesService curated places)
    //   place_*  → final_places_clean_v2.json (offline fallback dataset)
    //   sos_*    → SOSScreen synthetic markers
    //   local_*, synthetic_* → reserved prefixes for future synthetic sources
    if (placeId.startsWith('cat_') ||
        placeId.startsWith('place_') ||
        placeId.startsWith('sos_') ||
        placeId.startsWith('local_') ||
        placeId.startsWith('synthetic_')) {
      return;
    }

    final details =
        await GetIt.instance<PlacesApiService>().getPlaceDetails(placeId);
    if (!mounted || details == null) return;

    String? freshDescription;
    final editorial = details['editorialSummary'];
    if (editorial is Map<String, dynamic>) {
      final t = editorial['text'];
      if (t is String && t.isNotEmpty) freshDescription = t;
    }

    final freshReviews = <PlaceReview>[];
    final rawReviews = details['reviews'];
    if (rawReviews is List) {
      for (final r in rawReviews) {
        if (r is Map<String, dynamic>) {
          try {
            freshReviews.add(PlaceReview.fromJson(r));
          } catch (_) {}
        }
      }
    }

    if (!mounted) return;
    if ((freshDescription == null || _description.isNotEmpty) &&
        (freshReviews.isEmpty || _reviews.isNotEmpty)) {
      return;
    }
    setState(() {
      if (_description.isEmpty && freshDescription != null) {
        _description = freshDescription;
      }
      if (_reviews.isEmpty && freshReviews.isNotEmpty) {
        _reviews = freshReviews;
      }
    });
  }

  Future<void> _loadSimilarPlaces() async {
    final pool = widget.allItems.where((i) => i.id != widget.place.id).toList();
    if (pool.isEmpty) return;

    final lat = widget.place.coordinate.latitude;
    final lng = widget.place.coordinate.longitude;
    pool.sort((a, b) {
      final da = Geolocator.distanceBetween(
          lat, lng, a.coordinate.latitude, a.coordinate.longitude);
      final db = Geolocator.distanceBetween(
          lat, lng, b.coordinate.latitude, b.coordinate.longitude);
      return da.compareTo(db);
    });
    final nearby = pool.take(50).toList();

    final candidates = nearby.map((item) => <String, dynamic>{
      'placeId': item.id,
      'name': item.title,
      'types': [item.category],
      'tags': item.tags,
      'rating': item.rating,
      'userRatingCount': 0,
      'lat': item.coordinate.latitude,
      'lng': item.coordinate.longitude,
    }).toList();

    final result = await RecommendationService.recommendPlaces(
      candidates: candidates,
      context: 'similar',
      userLat: lat,
      userLng: lng,
      limit: 5,
      excludeSeen: false,
      weather: WeatherController.weather.value,
    );

    if (!mounted) return;

    if (result == null || result.recommendations.isEmpty) {
      setState(() => _loadingSimilar = false);
      return;
    }

    final idToItem = {for (final item in pool) item.id: item};
    final similar = result.recommendations
        .map((r) {
          final item = idToItem[r.placeId];
          if (item == null) return null;
          return _SimilarPlace(item: item, reasons: r.reasons.take(1).toList());
        })
        .whereType<_SimilarPlace>()
        .toList();

    if (mounted) {
      setState(() {
        if (similar.isNotEmpty) _similarPlaces = similar;
        _loadingSimilar = false;
      });
    }
  }

  Future<void> _loadCrowdLevel() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('place_affinity')
          .doc(widget.place.id)
          .get();
      if (!mounted || !doc.exists) return;
      final data = doc.data()!;
      final buckets = (data['crowdBuckets'] as Map<String, dynamic>?) ?? {};
      final h = DateTime.now().hour;
      final current = (buckets['h$h'] as num? ?? 0).toInt();
      final prev = (buckets['h${(h - 1 + 24) % 24}'] as num? ?? 0).toInt();
      if (mounted) setState(() => _crowdCount = current + prev);
    } catch (_) {}
  }

  Future<void> _loadCommunityPostCount() async {
    try {
      final q = await FirebaseFirestore.instance
          .collection('community_posts')
          .where('locationId', isEqualTo: widget.place.id)
          .count()
          .get();
      if (mounted) setState(() => _communityPostCount = q.count ?? 0);
    } catch (_) {}
  }

  @override
  void didUpdateWidget(PlaceDetailSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.place.id != widget.place.id) {
      setState(() {
        _isSaved = false;
        _currentImageIndex = 0;
        _distanceKm = null;
        _similarPlaces = [];
        _loadingSimilar = widget.allItems.length > 1;
      });
      _checkIfSaved();
      _calculateDistance();
      if (widget.allItems.length > 1) _loadSimilarPlaces();
    }
  }

  Future<void> _checkIfSaved() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userId = user.uid;
      final doc = await FirebaseFirestore.instance.collection('users').doc(_userId).get();
      if (doc.exists && mounted) {
        final savedPlaces = List<String>.from(doc.data()?['savedPlaces'] ?? []);
        setState(() {
          _isSaved = savedPlaces.contains(widget.place.id);
        });
      }
    }
  }

  Future<void> _calculateDistance() async {
    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
      final distMeters = Geolocator.distanceBetween(
        pos.latitude, pos.longitude,
        widget.place.coordinate.latitude, widget.place.coordinate.longitude,
      );
      if (mounted) {
        setState(() {
          _distanceKm = distMeters / 1000;
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleSave() async {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to save places.')),
      );
      return;
    }

    setState(() {
      _isSaved = !_isSaved;
    });

    try {
      if (_isSaved) {
        await FirebaseFirestore.instance.collection('users').doc(_userId).update({
          'savedPlaces': FieldValue.arrayUnion([widget.place.id])
        });
        RecommendationService.recordSignal(
          placeId: widget.place.id,
          placeName: widget.place.title,
          types: [widget.place.category],
          tags: widget.place.tags,
          signalType: 'save',
          source: 'map',
        );
      } else {
        await FirebaseFirestore.instance.collection('users').doc(_userId).update({
          'savedPlaces': FieldValue.arrayRemove([widget.place.id])
        });
      }
      widget.onSavedToggled?.call();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaved = !_isSaved;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHandler.handleGenericError(e))),
        );
      }
    }
  }

  String _formatDistance(double km) {
    if (km < 1) return '${(km * 1000).round()} m away';
    if (km < 10) return '${km.toStringAsFixed(1)} km away';
    return '${km.round()} km away';
  }

  String _estimateFare(double km) {
    final fare = (10 + km * 5).round();
    final fareHigh = (fare * 1.5).round();
    return '~$fare–$fareHigh EGP by taxi';
  }

  String _getOpeningStatus() {
    if (widget.place.openingHoursText.isNotEmpty) {
      return widget.place.isCurrentlyOpen ? 'Open Now' : 'Closed';
    }
    return '';
  }

  String _getTodayHours() {
    if (widget.place.openingHoursText.isEmpty) return '';
    final lines = widget.place.openingHoursText.split('\n');
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final today = weekdays[DateTime.now().weekday - 1];
    for (final line in lines) {
      if (line.contains(today)) {
        return line.replaceFirst('$today: ', '').trim();
      }
    }
    return lines.first;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    final sheetShadow = isDark
        ? BoxShadow(
            color: Colors.white.withValues(alpha: 0.18),
            blurRadius: 26,
            spreadRadius: 2,
            offset: const Offset(0, -10),
          )
        : BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 26,
            spreadRadius: 2,
            offset: const Offset(0, -10),
          );

    final borderColor = (isDark ? Colors.white : Colors.black)
        .withValues(alpha: isDark ? 0.10 : 0.06);

    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (notification) {
        widget.onScrollExtentChanged?.call(notification.extent);
        return false;
      },
      child: DraggableScrollableSheet(
        controller: _sheetController,
        initialChildSize: 0.55,
        minChildSize: 0.2,
        maxChildSize: 0.95,
        snap: true,
        snapSizes: const [0.2, 0.55, 0.95],
        builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: surface,
            // BottomSheet radius — not scaled per design convention
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: borderColor),
            boxShadow: [sheetShadow],
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.zero,
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: EdgeInsets.only(top: 12.h, bottom: 8.h),
                  width: 40.w,
                  height: 5.h,
                  decoration: BoxDecoration(
                    color: onSurface.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2.5.r),
                  ),
                ),
              ),

              // Image Carousel
              Stack(
                children: [
                  SizedBox(
                    height: 220.h,
                    width: double.infinity,
                    child: widget.place.imagePaths.isNotEmpty
                        ? PageView.builder(
                            itemCount: widget.place.imagePaths.length,
                            onPageChanged: (index) => setState(() => _currentImageIndex = index),
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => FullScreenGallery(
                                        imageUrls: widget.place.imagePaths,
                                        initialIndex: index,
                                        title: widget.place.title,
                                      ),
                                    ),
                                  );
                                },
                                child: CachedNetworkImage(
                                  imageUrl: widget.place.imagePaths[index],
                                  fit: BoxFit.cover,
                                  placeholder: (_, _) => ShimmerLoadingWidget.rectangular(height: 220.h),
                                  errorWidget: (_, _, _) => Container(
                                    color: Colors.grey.withValues(alpha: 0.15),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.image_not_supported_outlined,
                                              color: Colors.grey.withValues(alpha: 0.5), size: 50.r),
                                          SizedBox(height: 8.h),
                                          Text('Photo not available',
                                              style: TextStyle(
                                                  color: Colors.grey.withValues(alpha: 0.6),
                                                  fontSize: 12.sp)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                        : widget.place.imagePath.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: widget.place.imagePath,
                                fit: BoxFit.cover,
                                placeholder: (_, _) => ShimmerLoadingWidget.rectangular(height: 220.h),
                                errorWidget: (_, _, _) => Container(
                                  color: Colors.grey.withValues(alpha: 0.15),
                                  child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                                ),
                              )
                            : Container(
                                color: primary.withValues(alpha: isDark ? 0.15 : 0.08),
                                child: Center(
                                  child: Icon(Icons.place,
                                      color: primary.withValues(alpha: 0.4), size: 64.r),
                                ),
                              ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.center,
                            colors: [
                              Colors.black.withValues(alpha: 0.25),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10.h,
                    right: 10.w,
                    child: GestureDetector(
                      onTap: widget.onClose,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.keyboard_arrow_down_rounded,
                                size: 18.r, color: Colors.white),
                            SizedBox(width: 2.w),
                            Text('Close',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (widget.place.imagePaths.length > 1)
                    Positioned(
                      bottom: 12.h,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          widget.place.imagePaths.length,
                          (index) => Container(
                            margin: EdgeInsets.symmetric(horizontal: 3.w),
                            width: _currentImageIndex == index ? 8.r : 6.r,
                            height: _currentImageIndex == index ? 8.r : 6.r,
                            decoration: BoxDecoration(
                              color: _currentImageIndex == index
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // Content
              Padding(
                padding: EdgeInsets.all(20.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      widget.place.title,
                      style: TextStyle(
                        fontFamily: "Marcellus",
                        fontSize: 26.sp,
                        fontWeight: FontWeight.bold,
                        color: onSurface,
                      ),
                    ),
                    SizedBox(height: 6.h),

                    // Category + rating
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: isDark ? 0.18 : 0.12),
                            borderRadius: BorderRadius.circular(6.r),
                            border: Border.all(
                              color: primary.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Text(
                            widget.place.category.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              color: primary,
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Icon(Icons.star, size: 16.r, color: Colors.amber),
                        Text(
                          " ${widget.place.rating}",
                          style: TextStyle(
                            color: onSurface.withValues(alpha: 0.65),
                            fontSize: 13.sp,
                          ),
                        ),
                      ],
                    ),

                    // Weather advisory — only for outdoor / semi-outdoor places
                    if (_outdoorOrSemiOutdoor
                        .contains(widget.place.category.toLowerCase()))
                      ValueListenableBuilder<WeatherContext?>(
                        valueListenable: WeatherController.weather,
                        builder: (_, weather, _) {
                          if (weather == null ||
                              !WeatherBanner.shouldShow(weather)) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: EdgeInsets.only(top: 14.h),
                            child: WeatherBanner(
                              weather: weather,
                              onTap: () =>
                                  WeatherForecastSheet.show(context),
                            ),
                          );
                        },
                      ),
                    SizedBox(height: 24.h),

                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildActionButton(
                          icon: Icons.map_outlined,
                          label: "Show on Map",
                          isPrimary: true,
                          primary: primary,
                          onSurface: onSurface,
                          isDark: isDark,
                          onTap: () {
                            _sheetController.animateTo(
                              0.2,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            );
                            widget.onShowOnMap();
                          },
                        ),
                        _buildActionButton(
                          icon: Icons.directions,
                          label: "Directions",
                          isPrimary: false,
                          primary: primary,
                          onSurface: onSurface,
                          isDark: isDark,
                          onTap: widget.onDirections,
                        ),
                        _buildActionButton(
                          icon: Icons.share,
                          label: "Share",
                          isPrimary: false,
                          primary: primary,
                          onSurface: onSurface,
                          isDark: isDark,
                          onTap: () {},
                        ),
                        _buildActionButton(
                          icon: _isSaved ? Icons.favorite : Icons.favorite_border,
                          label: _isSaved ? "Saved" : "Save",
                          isPrimary: false,
                          primary: primary,
                          onSurface: onSurface,
                          isDark: isDark,
                          onTap: _toggleSave,
                          iconColor: _isSaved ? Colors.red : primary,
                        ),
                      ],
                    ),

                    Divider(
                      height: 40.h,
                      thickness: 1,
                      color: onSurface.withValues(alpha: 0.10),
                    ),

                    // About
                    Text(
                      "About",
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: onSurface,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      _description.isNotEmpty
                          ? _description
                          : "Explore the ancient wonders and hidden gems of Egypt. "
                              "This location offers a unique glimpse into the rich "
                              "history and culture of the region.",
                      style: TextStyle(
                        height: 1.6,
                        color: onSurface.withValues(alpha: 0.85),
                        fontSize: 15.sp,
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // Info tiles
                    if (widget.place.locationAddress.isNotEmpty)
                      _buildInfoTile(
                        icon: Icons.location_on_outlined,
                        text: widget.place.locationAddress,
                        iconColor: primary,
                        onSurface: onSurface,
                      ),

                    if (_distanceKm != null)
                      _buildInfoTile(
                        icon: Icons.near_me_outlined,
                        text: _formatDistance(_distanceKm!),
                        iconColor: Colors.blue,
                        onSurface: onSurface,
                      ),

                    if (_getOpeningStatus().isNotEmpty)
                      _buildInfoTile(
                        icon: Icons.access_time,
                        text: '${_getOpeningStatus()} • ${_getTodayHours()}',
                        iconColor: widget.place.isCurrentlyOpen ? Colors.green : Colors.red,
                        onSurface: onSurface,
                      ),

                    if (widget.place.price > 0)
                      _buildInfoTile(
                        icon: Icons.confirmation_number_outlined,
                        text: "${widget.place.price.toStringAsFixed(0)} EGP Entry Fee",
                        iconColor: Colors.green,
                        onSurface: onSurface,
                      ),

                    if (_distanceKm != null && _distanceKm! > 1)
                      _buildInfoTile(
                        icon: Icons.local_taxi_outlined,
                        text: _estimateFare(_distanceKm!),
                        iconColor: Colors.amber.shade700,
                        onSurface: onSurface,
                      ),

                    // ── Crowd level ─────────────────────────────────────────
                    if (_crowdCount != null) ...[
                      SizedBox(height: 20.h),
                      _buildCrowdBadge(_crowdCount!, primary, onSurface, isDark),
                    ],

                    if (_reviews.isNotEmpty) ...[
                      SizedBox(height: 16.h),
                      Divider(thickness: 1, color: onSurface.withValues(alpha: 0.10)),
                      SizedBox(height: 16.h),
                      Text(
                        "What Travelers Say",
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: onSurface,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      ..._reviews.take(3).map((review) =>
                        _buildReviewCard(review, onSurface, primary, isDark),
                      ),
                    ],

                    // ── Community posts from this place ──────────────────────
                    if (_communityPostCount > 0) ...[
                      SizedBox(height: 16.h),
                      Divider(thickness: 1, color: onSurface.withValues(alpha: 0.10)),
                      SizedBox(height: 16.h),
                      Row(
                        children: [
                          Icon(Icons.people_outline_rounded, color: primary, size: 20.r),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              '$_communityPostCount traveler${_communityPostCount == 1 ? '' : 's'} posted from here',
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                                color: onSurface,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => _openCommunityPosts(context),
                            child: Text(
                              'See Posts',
                              style: TextStyle(color: primary, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ],

                    // ── Similar Places ────────────────────────────────────
                    if (_loadingSimilar || _similarPlaces.isNotEmpty) ...[
                      SizedBox(height: 16.h),
                      Divider(thickness: 1, color: onSurface.withValues(alpha: 0.10)),
                      SizedBox(height: 16.h),
                      Row(
                        children: [
                          Icon(Icons.auto_awesome, size: 16.r, color: primary),
                          SizedBox(width: 8.w),
                          Text(
                            "Similar Places",
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: onSurface,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      if (_loadingSimilar)
                        SizedBox(
                          height: 148.h,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: 3,
                            itemBuilder: (_, _) => Container(
                              width: 150.w,
                              margin: EdgeInsets.only(right: 10.w),
                              child: ShimmerLoadingWidget.rectangular(height: 148.h),
                            ),
                          ),
                        )
                      else
                      SizedBox(
                        height: 148.h,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _similarPlaces.length,
                          itemBuilder: (context, index) {
                            final sp = _similarPlaces[index];
                            return GestureDetector(
                              onTap: () {
                                // Tapping a Similar Places thumbnail expresses
                                // interest, not a real visit — use 'like' (+0.4)
                                // not 'visit' (+1.0). Otherwise five thumbnail
                                // taps cross the 5-signal cold-start threshold.
                                RecommendationService.recordSignal(
                                  placeId: sp.item.id,
                                  placeName: sp.item.title,
                                  types: [sp.item.category],
                                  tags: sp.item.tags,
                                  signalType: 'like',
                                  source: 'similar_places',
                                );
                                widget.onClose();
                                MapFocusService.instance.triggerFocus(sp.item);
                              },
                              child: Container(
                                width: 150.w,
                                margin: EdgeInsets.only(
                                  right: index < _similarPlaces.length - 1 ? 10.w : 0,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14.r),
                                  color: onSurface.withValues(alpha: 0.05),
                                  border: Border.all(
                                    color: onSurface.withValues(alpha: 0.08),
                                  ),
                                ),
                                clipBehavior: Clip.hardEdge,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      height: 80.h,
                                      width: double.infinity,
                                      child: sp.item.imagePaths.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: sp.item.imagePaths.first,
                                              fit: BoxFit.cover,
                                              placeholder: (ctx, url) => Container(
                                                color: primary.withValues(alpha: 0.08),
                                              ),
                                              errorWidget: (ctx, url, err) => Container(
                                                color: primary.withValues(alpha: 0.06),
                                                child: Icon(Icons.place,
                                                    color: primary.withValues(alpha: 0.3)),
                                              ),
                                            )
                                          : Container(
                                              color: primary.withValues(alpha: 0.06),
                                              child: Icon(Icons.place,
                                                  color: primary.withValues(alpha: 0.3), size: 32.r),
                                            ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.fromLTRB(8.w, 6.h, 8.w, 4.h),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            sp.item.title,
                                            style: TextStyle(
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.w600,
                                              color: onSurface,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (sp.reasons.isNotEmpty)
                                            Text(
                                              sp.reasons.first,
                                              style: TextStyle(
                                                fontSize: 10.sp,
                                                color: primary.withValues(alpha: 0.8),
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
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
                      SizedBox(height: 16.h),
                    ],

                    SizedBox(height: 100.h),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ));
  }

  Widget _buildReviewCard(PlaceReview review, Color onSurface, Color primary, bool isDark) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: onSurface.withValues(alpha: isDark ? 0.06 : 0.03),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: onSurface.withValues(alpha: isDark ? 0.10 : 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14.r,
                backgroundColor: primary.withValues(alpha: 0.15),
                child: Text(
                  review.authorName.isNotEmpty ? review.authorName[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.sp,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.authorName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.sp,
                        color: onSurface,
                      ),
                    ),
                    Row(
                      children: [
                        ...List.generate(5, (i) => Icon(
                          i < review.rating.round() ? Icons.star : Icons.star_border,
                          size: 12.r,
                          color: Colors.amber,
                        )),
                        SizedBox(width: 6.w),
                        Text(
                          review.relativeTime,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (review.text.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Text(
              review.text.length > 200 ? '${review.text.substring(0, 200)}...' : review.text,
              style: TextStyle(
                fontSize: 13.sp,
                height: 1.5,
                color: onSurface.withValues(alpha: 0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCrowdBadge(int count, Color primary, Color onSurface, bool isDark) {
    final Color dotColor;
    final String label;
    if (count <= 2) {
      dotColor = Colors.green.shade500;
      label = 'Quiet right now';
    } else if (count <= 8) {
      dotColor = Colors.amber.shade600;
      label = 'Moderately busy';
    } else {
      dotColor = Colors.red.shade500;
      label = 'Very busy';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: dotColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: dotColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8.r,
            height: 8.r,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          SizedBox(width: 8.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: dotColor,
            ),
          ),
        ],
      ),
    );
  }

  void _openCommunityPosts(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CommunityPostsSheet(
        placeId: widget.place.id,
        placeName: widget.place.title,
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String text,
    required Color iconColor,
    required Color onSurface,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22.r),
          SizedBox(width: 16.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15.sp,
                color: onSurface.withValues(alpha: 0.85),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool isPrimary,
    required VoidCallback onTap,
    required Color primary,
    required Color onSurface,
    required bool isDark,
    Color? iconColor,
  }) {
    final bg = isPrimary ? primary : Colors.transparent;

    final border = Border.all(
      color: isPrimary
          ? Colors.transparent
          : onSurface.withValues(alpha: isDark ? 0.18 : 0.20),
    );

    final buttonShadow = isPrimary
        ? [
            BoxShadow(
              color: (isDark ? Colors.white : Colors.black)
                  .withValues(alpha: 0.14),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 6),
            )
          ]
        : <BoxShadow>[];

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50.r,
            height: 50.r,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              border: isPrimary ? null : border,
              boxShadow: buttonShadow,
            ),
            child: Icon(
              icon,
              color: iconColor ?? (isPrimary ? Colors.white : primary),
              size: 24.r,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: TextStyle(
              color: isPrimary ? primary : onSurface.withValues(alpha: 0.70),
              fontWeight: FontWeight.w600,
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Similar place data holder ─────────────────────────────────────────────────

class _SimilarPlace {
  final MapItem item;
  final List<String> reasons;
  const _SimilarPlace({required this.item, this.reasons = const []});
}

// ── Community posts bottom sheet ──────────────────────────────────────────────

class _CommunityPostsSheet extends StatelessWidget {
  final String placeId;
  final String placeName;

  const _CommunityPostsSheet({required this.placeId, required this.placeName});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF1A2E3A) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final primary = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: surface,
          // BottomSheet radius — not scaled per design convention
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            SizedBox(height: 12.h),
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 4.h),
              child: Row(
                children: [
                  Icon(Icons.people_outline_rounded, color: primary, size: 20.r),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Posts from $placeName',
                      style: TextStyle(
                        fontFamily: 'Marcellus',
                        fontSize: 18.sp,
                        color: textColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('community_posts')
                    .where('locationId', isEqualTo: placeId)
                    .orderBy('timestamp', descending: true)
                    .limit(20)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return Center(
                      child: Text(
                        'No posts yet from this place.\nBe the first to share!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: onSurface.withValues(alpha: 0.5)),
                      ),
                    );
                  }
                  return ListView.separated(
                    controller: controller,
                    padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
                    itemCount: docs.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final data = docs[i].data() as Map<String, dynamic>;
                      final content = data['content'] as String? ?? '';
                      final userName = data['userName'] as String? ?? 'Traveler';
                      final avatar = data['userAvatar'] as String? ?? '';
                      return ListTile(
                        contentPadding: EdgeInsets.symmetric(vertical: 8.h),
                        leading: CircleAvatar(
                          radius: 18.r,
                          backgroundColor: primary.withValues(alpha: 0.15),
                          child: avatar.isNotEmpty
                              ? ClipOval(child: CachedNetworkImage(
                                  imageUrl: avatar, width: 36.r, height: 36.r,
                                  fit: BoxFit.cover,
                                  errorWidget: (ctx, url, err) => Icon(Icons.person, size: 16.r, color: primary),
                                ))
                              : Icon(Icons.person, size: 16.r, color: primary),
                        ),
                        title: Text(userName,
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.sp, color: textColor)),
                        subtitle: Text(
                          content.length > 120 ? '${content.substring(0, 117)}…' : content,
                          style: TextStyle(fontSize: 13.sp, color: onSurface.withValues(alpha: 0.75), height: 1.4),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
