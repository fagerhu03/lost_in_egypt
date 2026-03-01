/// Maps numeric importance values (1-10) to zoom levels
/// YOUR SCALE: 10 = Most Important, 1 = Least Important
/// Adjusted so zoom 10 (initial view) shows only important places
class ImportanceConfig {
  
  /// Returns minimum zoom level required to see a place with given importance
  static double getMinZoomForImportance(int importance) {
    switch (importance) {
      case 10:
        return 0;    // 🏛️ World landmark - Always visible
      case 9:
        return 7;    // ⭐ National landmark - Country view
      case 8:
        return 9;    // 🌟 Very famous - Region level
      case 7:
        return 11;   // 📍 Famous
      case 6:
        return 12;   // 🔷 Well-known
      case 5:
        return 13;   // 📌 Notable
      case 4:
        return 14;   // 🔹 Average
      case 3:
        return 15;   // 🔸 Below Average
      case 2:
        return 16;   // ◽ Minor
      case 1:
      default:
        return 17;   // ◾ Minimal
    }
  }

  /// Returns label for importance level
  static String getLabelForImportance(int importance) {
    switch (importance) {
      case 10:
        return 'Landmark';
      case 9:
        return 'Very Major';
      case 8:
        return 'Major';
      case 7:
        return 'Very Notable';
      case 6:
        return 'Notable';
      case 5:
        return 'Above Average';
      case 4:
        return 'Average';
      case 3:
        return 'Below Average';
      case 2:
        return 'Minor';
      case 1:
      default:
        return 'Minimal';
    }
  }

  /// Check if item should be visible at current zoom
  static bool isVisibleAtZoom(int importance, double currentZoom) {
    return currentZoom >= getMinZoomForImportance(importance);
  }

  /// Compute importance from Google Places API data.
  /// Strict thresholds to spread places across levels for effective zoom filtering.
  /// Only world-famous landmarks get top importance.
  static int computeFromApi({
    required double rating,
    required int userRatingCount,
  }) {
    if (rating >= 4.7 && userRatingCount >= 10000) return 10; // World-famous landmark
    if (rating >= 4.5 && userRatingCount >= 5000)  return 9;  // National landmark
    if (rating >= 4.5 && userRatingCount >= 2000)  return 8;  // Very famous
    if (rating >= 4.5 && userRatingCount >= 500)   return 7;  // Famous
    if (rating >= 4.0 && userRatingCount >= 200)   return 6;  // Well-known
    if (rating >= 4.0 && userRatingCount >= 50)    return 5;  // Notable
    if (rating >= 3.5 && userRatingCount >= 20)    return 4;  // Average
    if (rating >= 3.0 && userRatingCount >= 5)     return 3;  // Below Average
    if (userRatingCount >= 1)                      return 2;  // Minor
    return 1;                                                 // Minimal
  }
}

/// Extension for easy access on int (importance value)
extension ImportanceExtension on int {
  double get minZoomLevel => ImportanceConfig.getMinZoomForImportance(this);
  String get importanceLabel => ImportanceConfig.getLabelForImportance(this);
  bool isVisibleAt(double zoom) => ImportanceConfig.isVisibleAtZoom(this, zoom);
}