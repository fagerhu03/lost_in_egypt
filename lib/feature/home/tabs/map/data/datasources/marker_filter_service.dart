import 'package:lost_in_egypt/feature/home/tabs/home/data/models/map_item_models.dart';
import 'package:lost_in_egypt/feature/home/tabs/map/domain/place_importance.dart';

class MarkerFilterService {
  
  /// Categories that represent Egypt's identity — shown at wider zoom levels
  static const Set<String> _highlightCategories = {
    'tourism', 'historical', 'museum', 'nature', 'entertainment', 'religious',
  };

  /// Minimum zoom to show commercial/detail categories (hotels, food, shopping)
  static const double _commercialMinZoom = 14.0;

  static List<MapItem> filterByZoom(List<MapItem> items, double currentZoom) {
    return items.where((item) {
      final category = item.category.toLowerCase();
      
      if (_highlightCategories.contains(category)) {
        // Highlight categories: use normal importance-based zoom
        return ImportanceConfig.isVisibleAtZoom(item.importance, currentZoom);
      } else {
        // Commercial categories: require higher zoom + importance check
        if (currentZoom < _commercialMinZoom) return false;
        return ImportanceConfig.isVisibleAtZoom(item.importance, currentZoom);
      }
    }).toList();
  }

  static List<MapItem> filterByZoomAndCategory(
    List<MapItem> items,
    double currentZoom, {
    String? categoryFilter,
  }) {
    return items.where((item) {
      final zoomVisible = ImportanceConfig.isVisibleAtZoom(item.importance, currentZoom);
      final categoryMatch = categoryFilter == null || 
                            categoryFilter == 'all' ||
                            item.category.toLowerCase() == categoryFilter.toLowerCase();
      return zoomVisible && categoryMatch;
    }).toList();
  }

  static Map<int, int> getImportanceBreakdown(List<MapItem> items) {
    final breakdown = <int, int>{};
    for (final item in items) {
      breakdown[item.importance] = (breakdown[item.importance] ?? 0) + 1;
    }
    return breakdown;
  }
}