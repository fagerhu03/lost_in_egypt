import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
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

  @override
  void initState() {
    super.initState();
    _loadNearbyPlaces();
  }

  Future<void> _loadNearbyPlaces() async {
    try {
      // Check location permission first
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      ).timeout(const Duration(seconds: 10));

      final sorted = <_NearbyPlace>[];
      for (final item in widget.allItems) {
        try {
          final dist = Geolocator.distanceBetween(
            pos.latitude, pos.longitude,
            item.coordinate.latitude, item.coordinate.longitude,
          );
          sorted.add(_NearbyPlace(item: item, distanceMeters: dist));
        } catch (_) {
          // Skip items with invalid coordinates
        }
      }

      sorted.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));

      if (mounted) {
        setState(() {
          _nearbyPlaces = sorted.take(20).toList();
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
    final isDark = theme.brightness == Brightness.dark;
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: onSurface.withOpacity(0.06)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: onSurface.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.near_me, color: primary, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      "Nearest Places",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: onSurface.withOpacity(0.10)),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _nearbyPlaces.isEmpty
                        ? Center(
                            child: Text(
                              'Could not determine your location.',
                              style: TextStyle(color: onSurface.withOpacity(0.5)),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: _nearbyPlaces.length,
                            itemBuilder: (context, index) {
                              final np = _nearbyPlaces[index];
                              return ListTile(
                                leading: Container(
                                  width: 48, height: 48,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: onSurface.withOpacity(0.05),
                                    image: np.item.imagePaths.isNotEmpty
                                        ? DecorationImage(
                                            image: NetworkImage(np.item.imagePaths.first),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: np.item.imagePaths.isEmpty
                                      ? Icon(Icons.place, color: primary.withOpacity(0.5))
                                      : null,
                                ),
                                title: Text(
                                  np.item.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: onSurface,
                                  ),
                                ),
                                subtitle: Text(
                                  np.item.category.toUpperCase(),
                                  style: TextStyle(fontSize: 11, color: primary),
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: primary.withOpacity(isDark ? 0.15 : 0.10),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _formatDistance(np.distanceMeters),
                                    style: TextStyle(
                                      fontSize: 12,
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
  const _NearbyPlace({required this.item, required this.distanceMeters});
}
