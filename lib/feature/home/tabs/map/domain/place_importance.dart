/// Maps numeric importance values (1-10) to zoom levels
/// YOUR SCALE: 10 = Most Important, 1 = Least Important
/// Adjusted so zoom 10 (initial view) shows only important places
class ImportanceConfig {
  
  /// Returns minimum zoom level required to see a place with given importance
  static double getMinZoomForImportance(int importance) {
    switch (importance) {
      case 10:
        return 0;    // 🏛️ Landmark - Always visible
      case 9:
        return 8;    // ⭐ Very Major - Visible at country level
      case 8:
        return 10;   // 🌟 Major - Visible when map opens
      case 7:
        return 11;   // 📍 Very Notable
      case 6:
        return 12;   // 🔷 Notable
      case 5:
        return 13;   // 📌 Above Average
      case 4:
        return 14;   // 🔹 Average
      case 3:
        return 15;   // 🔸 Below Average
      case 2:
        return 16;   // ◽ Minor
      case 1:
      default:
        return 17;   // ◾ Minimal - Very close zoom only
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
}

/// Extension for easy access on int (importance value)
extension ImportanceExtension on int {
  double get minZoomLevel => ImportanceConfig.getMinZoomForImportance(this);
  String get importanceLabel => ImportanceConfig.getLabelForImportance(this);
  bool isVisibleAt(double zoom) => ImportanceConfig.isVisibleAtZoom(this, zoom);
}