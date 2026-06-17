import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lost_in_egypt/core/services/recommendation_service.dart';
import 'package:lost_in_egypt/core/services/weather_controller.dart';
import 'package:lost_in_egypt/core/widgets/shimmer_image.dart';
import 'package:lost_in_egypt/feature/home/tabs/home/data/models/map_item_models.dart';

class NearMeSheet extends StatefulWidget {
  final List<MapItem> allItems;

  const NearMeSheet({super.key, required this.allItems});

  @override
  State<NearMeSheet> createState() => _NearMeSheetState();
}

class _NearMeSheetState extends State<NearMeSheet> {
  bool _isLoading = true;
  List<_NearbyPlace> _nearbyPlaces = [];
  bool _isPersonalized = false;

  @override
  void initState() {
    super.initState();
    _loadNearbyPlaces();
  }

  Future<void> _loadNearbyPlaces() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      ).timeout(const Duration(seconds: 10));

      final withDistance = <_NearbyPlace>[];
      for (final item in widget.allItems) {
        try {
          final dist = Geolocator.distanceBetween(
            pos.latitude, pos.longitude,
            item.coordinate.latitude, item.coordinate.longitude,
          );
          withDistance.add(_NearbyPlace(item: item, distanceMeters: dist));
        } catch (_) {}
      }
      withDistance.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
      final pool = withDistance.take(50).toList();

      final candidates = pool.map((np) => <String, dynamic>{
        'placeId': np.item.id,
        'name': np.item.title,
        'types': [np.item.category],
        'tags': np.item.tags,
        'rating': np.item.rating,
        'userRatingCount': 0,
        'lat': np.item.coordinate.latitude,
        'lng': np.item.coordinate.longitude,
      }).toList();

      final result = await RecommendationService.recommendPlaces(
        candidates: candidates,
        context: 'nearby',
        userLat: pos.latitude,
        userLng: pos.longitude,
        limit: 20,
        weather: WeatherController.weather.value,
      );

      if (!mounted) return;

      if (result != null && result.recommendations.isNotEmpty) {
        final idToNp = {for (final np in pool) np.item.id: np};
        final ranked = result.recommendations
            .map((r) {
              final np = idToNp[r.placeId];
              if (np == null) return null;
              return _NearbyPlace(
                item: np.item,
                distanceMeters: np.distanceMeters,
                reasons: r.reasons.take(2).toList(),
              );
            })
            .whereType<_NearbyPlace>()
            .toList();

        setState(() {
          _nearbyPlaces = ranked;
          _isPersonalized = true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _nearbyPlaces = pool.take(20).toList();
          _isPersonalized = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Near Me error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()} m';
    final km = meters / 1000;
    if (km < 10) return '${km.toStringAsFixed(1)} km';
    return '${km.round()} km';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;
    final surface = theme.colorScheme.surface;
    final isDark = theme.brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: surface,
            // BottomSheet radius — not scaled per design convention
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: onSurface.withValues(alpha: 0.06)),
          ),
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.only(top: 12.h, bottom: 8.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: onSurface.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                child: Row(
                  children: [
                    Icon(Icons.near_me, color: primary, size: 22.r),
                    SizedBox(width: 10.w),
                    Text(
                      "Nearest Places",
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: onSurface,
                      ),
                    ),
                    if (_isPersonalized) ...[
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome, size: 11.r, color: primary),
                            SizedBox(width: 3.w),
                            Text(
                              'For You',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                                color: primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Divider(height: 1, color: onSurface.withValues(alpha: 0.10)),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _nearbyPlaces.isEmpty
                        ? Center(
                            child: Text(
                              'Could not determine your location.',
                              style: TextStyle(color: onSurface.withValues(alpha: 0.5)),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: _nearbyPlaces.length,
                            itemBuilder: (context, index) {
                              final np = _nearbyPlaces[index];
                              final topReason = np.reasons.isNotEmpty ? np.reasons.first : null;
                              return ListTile(
                                leading: ShimmerImage(
                                  url: np.item.imagePaths.isNotEmpty
                                      ? np.item.imagePaths.first
                                      : null,
                                  width: 48.r,
                                  height: 48.r,
                                  borderRadius: BorderRadius.circular(10.r),
                                  fit: BoxFit.cover,
                                  fallbackIcon: Icons.place,
                                  fallbackBackgroundColor: onSurface.withValues(alpha: 0.05),
                                  fallbackIconColor: primary.withValues(alpha: 0.5),
                                ),
                                title: Text(
                                  np.item.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: onSurface,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      np.item.category.toUpperCase(),
                                      style: TextStyle(
                                          fontSize: 11.sp, color: primary),
                                    ),
                                    if (topReason != null) ...[
                                      SizedBox(height: 4.h),
                                      // Small AI-reason chip — visually distinct so
                                      // users see this list is personalised, not just sorted by distance.
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 6.w, vertical: 2.h),
                                        decoration: BoxDecoration(
                                          color: primary.withValues(
                                              alpha: isDark ? 0.18 : 0.10),
                                          borderRadius: BorderRadius.circular(8.r),
                                          border: Border.all(
                                              color: primary.withValues(alpha: 0.25)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.auto_awesome,
                                                size: 10.r, color: primary),
                                            SizedBox(width: 4.w),
                                            Flexible(
                                              child: Text(
                                                topReason,
                                                style: TextStyle(
                                                  fontSize: 10.sp,
                                                  color: primary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                trailing: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                  decoration: BoxDecoration(
                                    color: primary.withValues(alpha: isDark ? 0.15 : 0.10),
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: Text(
                                    _formatDistance(np.distanceMeters),
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.bold,
                                      color: primary,
                                    ),
                                  ),
                                ),
                                onTap: () => Navigator.pop(context, np.item),
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NearbyPlace {
  final MapItem item;
  final double distanceMeters;
  final List<String> reasons;

  const _NearbyPlace({
    required this.item,
    required this.distanceMeters,
    this.reasons = const [],
  });
}
