import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lost_in_egypt/feature/home/tabs/map/presentation/map_config.dart';
import 'package:lost_in_egypt/feature/home/tabs/home/data/models/map_item_models.dart';

class MapMarkerService {
  final Map<String, BitmapDescriptor> _markerIcons = {};
  bool _iconsLoaded = false;

  bool get iconsLoaded => _iconsLoaded;

  Future<void> loadCustomMarkerIcons() async {
    try {
      final pinNames = [
        'default',
        'entertainment',
        'historical',
        'hotels',
        'museum',
        'nature',
        'religious',
        'resturants',
        'shopping',
        'tourism',
        'transport',
      ];

      int failedCount = 0;

      // Load all icons in parallel for faster startup
      final futures = pinNames.map((pinName) async {
        try {
          // Natively scale markers based on device pixel ratio
          final icon = await BitmapDescriptor.asset(
            const ImageConfiguration(),
            'assets/pins/$pinName.png',
            width: MapConfig.markerSize.toDouble(),
          );
          _markerIcons[pinName] = icon;
        } catch (e) {
          debugPrint('⚠️ Failed to load marker $pinName: $e');
          _markerIcons[pinName] = BitmapDescriptor.defaultMarker;
          failedCount++;
        }
      });
      await Future.wait(futures);

      _iconsLoaded = true;

      if (failedCount > 0) {
        debugPrint(
          '⚠️ Marker Loading Summary: ${pinNames.length - failedCount}/${pinNames.length} loaded successfully',
        );
      } else {
        debugPrint(
          '🎨 All custom markers loaded! Total: ${_markerIcons.length}',
        );
      }
    } catch (e) {
      debugPrint('❌ Error loading custom markers: $e');
      _iconsLoaded = true;

      // Fallback
      for (final name in [
        'default',
        'entertainment',
        'historical',
        'hotels',
        'museum',
        'nature',
        'religious',
        'resturants',
        'shopping',
        'tourism',
        'transport',
      ]) {
        _markerIcons[name] = BitmapDescriptor.defaultMarker;
      }
    }
  }

  BitmapDescriptor getMarkerIconByCategory(MapItem item, bool isSelected) {
    if (!_iconsLoaded || _markerIcons.isEmpty) {
      return BitmapDescriptor.defaultMarker;
    }

    final category = item.category.toLowerCase();
    final pinName = MapConfig.categoryToPinMap[category] ?? 'default';

    if (_markerIcons.containsKey(pinName)) {
      return _markerIcons[pinName]!;
    }

    return _markerIcons['default'] ?? BitmapDescriptor.defaultMarker;
  }
}
