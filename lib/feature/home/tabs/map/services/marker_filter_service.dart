import '../../home/data/models/map_item_models.dart';
import '../domain/place_importance.dart';

class MarkerFilterService {
  
  static List<MapItem> filterByZoom(List<MapItem> items, double currentZoom) {
    return items.where((item) {
      return ImportanceConfig.isVisibleAtZoom(item.importance, currentZoom);
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