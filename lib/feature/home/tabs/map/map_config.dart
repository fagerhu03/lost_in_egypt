import 'package:google_maps_flutter/google_maps_flutter.dart';

class UiCategory {
  final String id;
  final String label;
  final String icon;
  const UiCategory(this.id, this.label, this.icon);
}

class MapConfig {
  static const CameraPosition initialPosition = CameraPosition(
    target: LatLng(30.0444, 31.2357),
    zoom: 10,
  );

  static const int markerSize = 120;

  static const Set<String> excludedCategories = {
    'sports',
    'health',
    'government',
  };

  static const Map<String, String> categoryToPinMap = {
    'tourism': 'tourism',
    'historical': 'historical',
    'museum': 'museum',
    'hotel': 'hotels',
    'food': 'resturants',
    'nature': 'nature',
    'entertainment': 'entertainment',
    'shopping': 'shopping',
    'transport': 'transport',
    'religious': 'religious',
    'education': 'default',
  };

  static const List<UiCategory> categories = [
    UiCategory('all', 'All', '🗺️'),
    UiCategory('tourism', 'Tourism', '🏛️'),
    UiCategory('historical', 'Historical', '🏺'),
    UiCategory('museum', 'Museums', '🖼️'),
    UiCategory('hotel', 'Hotels', '🏨'),
    UiCategory('religious', 'Religious', '🕌'),
    UiCategory('food', 'Food & Dining', '🍽️'),
    UiCategory('nature', 'Nature', '🌿'),
    UiCategory('entertainment', 'Entertainment', '🎭'),
    UiCategory('education', 'Education', '🎓'),
    UiCategory('shopping', 'Shopping', '🛍️'),
    UiCategory('transport', 'Transport', '🚌'),
  ];
}
