import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart';
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
          final icon = await _loadPngMarkerIcon(
            'assets/pins/$pinName.png',
            MapConfig.markerSize,
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

  Future<BitmapDescriptor> _loadPngMarkerIcon(
    String assetPath,
    int width,
  ) async {
    final ByteData data = await rootBundle.load(assetPath);

    final ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );

    final ui.FrameInfo frameInfo = await codec.getNextFrame();

    final ByteData? byteData = await frameInfo.image.toByteData(
      format: ui.ImageByteFormat.png,
    );

    frameInfo.image.dispose();

    if (byteData == null) {
      throw Exception('Failed to convert image to bytes');
    }

    return BitmapDescriptor.fromBytes(byteData.buffer.asUint8List());
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
