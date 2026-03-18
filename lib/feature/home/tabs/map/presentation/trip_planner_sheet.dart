import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
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
  double? _totalDistanceKm;

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
          .take(10)
          .toList();
    });
  }

  /// Sort itinerary using nearest-neighbor from user's GPS then calculate total distance.
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
    double totalDist = 0;

    // Start from user location or first item
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
      totalDist += minDist;
      curLat = nearest.coordinate.latitude;
      curLng = nearest.coordinate.longitude;
    }

    _totalDistanceKm = totalDist / 1000;
    return sorted;
  }

  Future<void> _startTrip() async {
    if (_itinerary.isEmpty) return;

    setState(() => _isSorting = true);

    final sorted = await _sortByNearestNeighbor(_itinerary);

    if (mounted) {
      Navigator.pop(context, sorted);
    }
  }

  String _formatDist(double km) {
    if (km < 1) return '${(km * 1000).round()} m';
    if (km < 10) return '${km.toStringAsFixed(1)} km';
    return '${km.round()} km';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Trip Planner', style: TextStyle(fontFamily: 'Marcellus')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (_itinerary.isNotEmpty)
            TextButton(
              onPressed: _isSorting ? null : _startTrip,
              child: _isSorting
                  ? SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: primary),
                    )
                  : Text(
                      'Start Trip',
                      style: TextStyle(color: primary, fontWeight: FontWeight.bold),
                    ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              onChanged: _searchPlaces,
              decoration: InputDecoration(
                hintText: 'Search places to add...',
                prefixIcon: Icon(Icons.search, color: onSurface.withOpacity(0.4)),
                filled: true,
                fillColor: onSurface.withOpacity(isDark ? 0.08 : 0.04),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // Search results
          if (_searchResults.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: onSurface.withOpacity(0.08)),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final item = _searchResults[index];
                  return ListTile(
                    dense: true,
                    leading: Icon(Icons.add_circle_outline, color: primary, size: 20),
                    title: Text(item.title, style: TextStyle(fontSize: 14, color: onSurface)),
                    subtitle: Text(item.category.toUpperCase(),
                        style: TextStyle(fontSize: 10, color: primary)),
                    onTap: () {
                      setState(() {
                        _itinerary.add(item);
                        _searchResults = [];
                        _searchController.clear();
                      });
                    },
                  );
                },
              ),
            ),

          // Info bar when items added
          if (_itinerary.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: primary.withOpacity(isDark ? 0.12 : 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_itinerary.length} stop${_itinerary.length > 1 ? "s" : ""} — route will be optimized by distance',
                      style: TextStyle(fontSize: 12, color: primary, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),

          // Itinerary list
          Expanded(
            child: _itinerary.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.route, size: 64, color: onSurface.withOpacity(0.2)),
                        const SizedBox(height: 16),
                        Text(
                          'Plan your day in Egypt',
                          style: TextStyle(
                            fontSize: 18,
                            color: onSurface.withOpacity(0.5),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Search and add places to your trip.\nStops will be auto-sorted by shortest route.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: onSurface.withOpacity(0.35),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _itinerary.length,
                    itemBuilder: (context, index) {
                      final item = _itinerary[index];
                      return Dismissible(
                        key: ValueKey(item.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(Icons.delete, color: Colors.red.withOpacity(0.7)),
                        ),
                        onDismissed: (_) => setState(() => _itinerary.removeAt(index)),
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          color: surface,
                          elevation: isDark ? 0 : 1,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: primary.withOpacity(0.15),
                              child: Icon(Icons.place, color: primary, size: 20),
                            ),
                            title: Text(
                              item.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: onSurface,
                              ),
                            ),
                            subtitle: Text(
                              item.category.toUpperCase(),
                              style: TextStyle(fontSize: 11, color: primary),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
