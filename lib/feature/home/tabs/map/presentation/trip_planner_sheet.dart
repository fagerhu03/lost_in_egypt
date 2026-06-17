import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lost_in_egypt/l10n/app_localizations.dart';
import 'package:lost_in_egypt/core/services/recommendation_service.dart';
import 'package:lost_in_egypt/core/services/weather_controller.dart';
import 'package:lost_in_egypt/core/widgets/shimmer_image.dart';
import 'package:lost_in_egypt/feature/home/tabs/home/data/models/map_item_models.dart';

class TripPlannerSheet extends StatefulWidget {
  final List<MapItem> allItems;

  const TripPlannerSheet({super.key, required this.allItems});

  @override
  State<TripPlannerSheet> createState() => _TripPlannerSheetState();
}

class _TripPlannerSheetState extends State<TripPlannerSheet> {
  final List<MapItem> _itinerary = [];
  final TextEditingController _searchController = TextEditingController();
  List<MapItem> _searchResults = [];
  bool _isSorting = false;

  List<MapItem> _suggestions = [];
  bool _loadingSuggestions = true;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Returns the user's current GPS or null on permission/timeout failures.
  /// Silent failure — proximity scoring just contributes 0 if this returns null.
  Future<Position?> _getUserPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      ).timeout(const Duration(seconds: 8));
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadSuggestions() async {
    final sorted = List<MapItem>.from(widget.allItems)
      ..sort((a, b) => b.rating.compareTo(a.rating));
    final pool = sorted.take(50).toList();

    final candidates = pool.map((item) => <String, dynamic>{
      'placeId': item.id,
      'name': item.title,
      'types': [item.category],
      'tags': item.tags,
      'rating': item.rating,
      'userRatingCount': 0,
      'lat': item.coordinate.latitude,
      'lng': item.coordinate.longitude,
    }).toList();

    final pos = await _getUserPosition();

    final result = await RecommendationService.recommendPlaces(
      candidates: candidates,
      context: 'solo',
      limit: 8,
      excludeSeen: false,
      userLat: pos?.latitude,
      userLng: pos?.longitude,
      weather: WeatherController.weather.value,
    );

    if (!mounted) return;

    if (result != null && result.recommendations.isNotEmpty) {
      final idToItem = {for (final item in pool) item.id: item};
      final suggested = result.recommendations
          .map((r) => idToItem[r.placeId])
          .whereType<MapItem>()
          .toList();
      setState(() {
        _suggestions = suggested;
        _loadingSuggestions = false;
      });
    } else {
      setState(() {
        _suggestions = pool.take(8).toList();
        _loadingSuggestions = false;
      });
    }
  }

  Future<void> _refreshSuggestions() async {
    if (_itinerary.isEmpty) return;
    setState(() => _loadingSuggestions = true);

    final seedIds = _itinerary.map((i) => i.id).toSet();
    final pool = widget.allItems
        .where((item) => !seedIds.contains(item.id))
        .take(60)
        .toList();

    final candidates = pool.map((item) => <String, dynamic>{
      'placeId': item.id,
      'name': item.title,
      'types': [item.category],
      'tags': item.tags,
      'rating': item.rating,
      'userRatingCount': 0,
      'lat': item.coordinate.latitude,
      'lng': item.coordinate.longitude,
    }).toList();

    final pos = await _getUserPosition();

    final result = await RecommendationService.recommendPlaces(
      candidates: candidates,
      context: 'similar',
      limit: 6,
      excludeSeen: false,
      userLat: pos?.latitude,
      userLng: pos?.longitude,
      weather: WeatherController.weather.value,
    );

    if (!mounted) return;

    if (result != null && result.recommendations.isNotEmpty) {
      final idToItem = {for (final item in pool) item.id: item};
      final suggested = result.recommendations
          .map((r) => idToItem[r.placeId])
          .whereType<MapItem>()
          .toList();
      setState(() {
        _suggestions = suggested;
        _loadingSuggestions = false;
      });
    } else {
      setState(() => _loadingSuggestions = false);
    }
  }

  void _searchPlaces(String query) {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    final q = query.toLowerCase();
    setState(() {
      _searchResults = widget.allItems
          .where((item) =>
              item.title.toLowerCase().contains(q) ||
              item.category.toLowerCase().contains(q))
          .where((item) => !_itinerary.any((i) => i.id == item.id))
          .take(8)
          .toList();
    });
  }

  void _addToItinerary(MapItem item) {
    setState(() {
      _itinerary.add(item);
      _searchResults = [];
      _searchController.clear();
      _suggestions.removeWhere((s) => s.id == item.id);
    });
    _refreshSuggestions();
  }

  Future<List<MapItem>> _sortByNearestNeighbor(List<MapItem> stops) async {
    if (stops.length <= 1) return stops;

    Position? userPos;
    try {
      userPos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      ).timeout(const Duration(seconds: 8));
    } catch (_) {}

    final remaining = List<MapItem>.from(stops);
    final sorted = <MapItem>[];

    double curLat = userPos?.latitude ?? remaining.first.coordinate.latitude;
    double curLng = userPos?.longitude ?? remaining.first.coordinate.longitude;

    while (remaining.isNotEmpty) {
      double minDist = double.infinity;
      int nearestIdx = 0;
      for (int i = 0; i < remaining.length; i++) {
        final d = Geolocator.distanceBetween(
          curLat, curLng,
          remaining[i].coordinate.latitude,
          remaining[i].coordinate.longitude,
        );
        if (d < minDist) {
          minDist = d;
          nearestIdx = i;
        }
      }
      final nearest = remaining.removeAt(nearestIdx);
      sorted.add(nearest);
      curLat = nearest.coordinate.latitude;
      curLng = nearest.coordinate.longitude;
    }
    return sorted;
  }

  Future<void> _startTrip() async {
    if (_itinerary.isEmpty) return;
    setState(() => _isSorting = true);
    final sorted = await _sortByNearestNeighbor(_itinerary);
    if (mounted) Navigator.pop(context, sorted);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    final showSuggestions = _searchResults.isEmpty;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
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
              // ── Handle + header ──────────────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 12.h, 16.w, 0),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 40.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: onSurface.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Icon(Icons.route_rounded, color: primary, size: 22.r),
                        SizedBox(width: 10.w),
                        Text(
                          l10n.tripPlannerTitle,
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo'],
                            color: onSurface,
                          ),
                        ),
                        const Spacer(),
                        if (_itinerary.isNotEmpty)
                          FilledButton.icon(
                            onPressed: _isSorting ? null : _startTrip,
                            icon: _isSorting
                                ? SizedBox(
                                    width: 14.r,
                                    height: 14.r,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: theme.colorScheme.onPrimary,
                                    ),
                                  )
                                : Icon(Icons.play_arrow_rounded, size: 18.r),
                            label: Text(_isSorting ? l10n.tripPlannerOptimising : l10n.tripPlannerStart),
                            style: FilledButton.styleFrom(
                              backgroundColor: primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 14.w, vertical: 8.h),
                              textStyle: TextStyle(
                                  fontSize: 13.sp, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                  ],
                ),
              ),
              Divider(height: 1, color: onSurface.withValues(alpha: 0.10)),

              // ── Search bar ───────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
                child: TextField(
                  controller: _searchController,
                  onChanged: _searchPlaces,
                  decoration: InputDecoration(
                    hintText: l10n.tripPlannerSearchHint,
                    prefixIcon:
                        Icon(Icons.search, color: onSurface.withValues(alpha: 0.4)),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear,
                                color: onSurface.withValues(alpha: 0.4), size: 18.r),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchResults = []);
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: onSurface.withValues(alpha: isDark ? 0.08 : 0.04),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.r),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                ),
              ),

              // ── Search results dropdown ───────────────────────────────────
              if (_searchResults.isNotEmpty)
                Container(
                  constraints: BoxConstraints(maxHeight: 220.h),
                  margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: onSurface.withValues(alpha: 0.08)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final item = _searchResults[index];
                      return ListTile(
                        dense: true,
                        leading: Icon(Icons.add_location_alt_outlined,
                            color: primary, size: 20.r),
                        title: Text(item.title,
                            style: TextStyle(fontSize: 14.sp, color: onSurface)),
                        subtitle: Text(item.category.toUpperCase(),
                            style: TextStyle(fontSize: 10.sp, color: primary)),
                        onTap: () => _addToItinerary(item),
                      );
                    },
                  ),
                ),

              // ── Itinerary info chip ──────────────────────────────────────
              if (_itinerary.isNotEmpty)
                Container(
                  margin: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: isDark ? 0.12 : 0.08),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 15.r, color: primary),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          l10n.tripPlannerStopsInfo(_itinerary.length),
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Main scrollable area ─────────────────────────────────────
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 32.h),
                  children: [
                    if (_itinerary.isEmpty && showSuggestions) ...[
                      Center(
                        child: Column(
                          children: [
                            SizedBox(height: 8.h),
                            Icon(Icons.route,
                                size: 52.r,
                                color: onSurface.withValues(alpha: 0.15)),
                            SizedBox(height: 12.h),
                            Text(
                              l10n.tripPlannerEmptyTitle,
                              style: TextStyle(
                                fontSize: 16.sp,
                                color: onSurface.withValues(alpha: 0.45),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              l10n.tripPlannerEmptySub,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: onSurface.withValues(alpha: 0.28),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      for (int i = 0; i < _itinerary.length; i++)
                        _ItineraryTile(
                          item: _itinerary[i],
                          index: i,
                          onSurface: onSurface,
                          primary: primary,
                          isDark: isDark,
                          surface: surface,
                          onRemove: () =>
                              setState(() => _itinerary.removeAt(i)),
                        ),
                    ],

                    // AI suggestions section
                    if (showSuggestions && _suggestions.isNotEmpty) ...[
                      SizedBox(height: 16.h),
                      Row(
                        children: [
                          Container(
                            width: 3.w,
                            height: 14.h,
                            decoration: BoxDecoration(
                              color: primary,
                              borderRadius: BorderRadius.circular(2.r),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Icon(Icons.auto_awesome, size: 14.r, color: primary),
                          SizedBox(width: 5.w),
                          Text(
                            _itinerary.isEmpty
                                ? l10n.tripPlannerSuggested
                                : l10n.tourDetailYouMightEnjoy,
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10.h),
                      for (final item in _suggestions)
                        if (!_itinerary.any((i) => i.id == item.id))
                          _SuggestionTile(
                            item: item,
                            onSurface: onSurface,
                            primary: primary,
                            isDark: isDark,
                            onAdd: () => _addToItinerary(item),
                          ),
                    ] else if (showSuggestions && _loadingSuggestions) ...[
                      SizedBox(height: 24.h),
                      Center(
                        child: SizedBox(
                          width: 20.r,
                          height: 20.r,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: primary),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Itinerary stop tile ────────────────────────────────────────────────────────

class _ItineraryTile extends StatelessWidget {
  final MapItem item;
  final int index;
  final Color onSurface;
  final Color primary;
  final bool isDark;
  final Color surface;
  final VoidCallback onRemove;

  const _ItineraryTile({
    required this.item,
    required this.index,
    required this.onSurface,
    required this.primary,
    required this.isDark,
    required this.surface,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsetsDirectional.only(end: 20.w),
        margin: EdgeInsets.only(bottom: 8.h),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Icon(Icons.delete_outline,
            color: Colors.red.withValues(alpha: 0.8)),
      ),
      onDismissed: (_) => onRemove(),
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        decoration: BoxDecoration(
          color: isDark ? onSurface.withValues(alpha: 0.05) : surface,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: onSurface.withValues(alpha: 0.07)),
        ),
        child: ListTile(
          leading: Container(
            width: 34.r,
            height: 34.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primary.withValues(alpha: 0.12),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.sp,
                ),
              ),
            ),
          ),
          title: Text(
            item.title,
            style: TextStyle(fontWeight: FontWeight.w600, color: onSurface),
          ),
          subtitle: Text(
            item.category.toUpperCase(),
            style: TextStyle(fontSize: 11.sp, color: primary),
          ),
          trailing: Icon(Icons.drag_handle_rounded,
              color: onSurface.withValues(alpha: 0.3)),
        ),
      ),
    );
  }
}

// ── AI suggestion tile ────────────────────────────────────────────────────────

class _SuggestionTile extends StatelessWidget {
  final MapItem item;
  final Color onSurface;
  final Color primary;
  final bool isDark;
  final VoidCallback onAdd;

  const _SuggestionTile({
    required this.item,
    required this.onSurface,
    required this.primary,
    required this.isDark,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: isDark ? 0.06 : 0.03),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: primary.withValues(alpha: 0.12)),
      ),
      child: ListTile(
        dense: true,
        leading: ShimmerImage(
          url: item.imagePaths.isNotEmpty ? item.imagePaths.first : null,
          width: 36.r,
          height: 36.r,
          borderRadius: BorderRadius.circular(8.r),
          fit: BoxFit.cover,
          fallbackIcon: Icons.place_outlined,
          fallbackBackgroundColor: onSurface.withValues(alpha: 0.06),
          fallbackIconColor: primary.withValues(alpha: 0.5),
          fallbackIconSize: 18.r,
        ),
        title: Text(
          item.title,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: onSurface,
          ),
        ),
        subtitle: Text(
          item.category.toUpperCase(),
          style: TextStyle(fontSize: 10.sp, color: primary),
        ),
        trailing: GestureDetector(
          onTap: onAdd,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 14.r, color: primary),
                SizedBox(width: 3.w),
                Text(
                  AppLocalizations.of(context).tripPlannerAdd,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: primary,
                    fontWeight: FontWeight.w600,
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
