import 'package:lost_in_egypt/feature/home/tabs/home/data/models/map_item_models.dart';
import 'package:lost_in_egypt/feature/home/tabs/map/domain/importance_calculator.dart';

/// Service to filter map markers based on zoom level and importance
class MarkerFilterService {
  
  /// Filter items based on current zoom level
  static List<MapItem> filterByZoom(List<MapItem> items, double currentZoom) {
    return items.where((item) => item.isVisibleAtZoom(currentZoom)).toList();
  }

  /// Filter with additional category filter
  static List<MapItem> filterByZoomAndCategory(
    List<MapItem> items,
    double currentZoom, {
    String? categoryFilter,
  }) {
    return items.where((item) {
      final zoomVisible = item.isVisibleAtZoom(currentZoom);
      final categoryMatch = categoryFilter == null || 
                            item.category.toLowerCase() == categoryFilter.toLowerCase();
      return zoomVisible && categoryMatch;
    }).toList();
  }

  /// Get count of items at each importance level (for debugging/UI)
  static Map<String, int> getImportanceBreakdown(List<MapItem> items) {
    final breakdown = <String, int>{
      'landmark': 0,
      'major': 0,
      'moderate': 0,
      'minor': 0,
    };

    for (final item in items) {
      final key = item.importance.name;
      breakdown[key] = (breakdown[key] ?? 0) + 1;
    }

    return breakdown;
  }
}