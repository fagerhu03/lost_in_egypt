/// Defines importance levels for map items and their visibility rules

enum PlaceImportance {
  landmark,   // Always visible (zoom >= 0)
  major,      // Visible at zoom >= 10
  moderate,   // Visible at zoom >= 13
  minor;      // Visible at zoom >= 15
}

extension PlaceImportanceExtension on PlaceImportance {
  double get minZoomLevel {
    switch (this) {
      case PlaceImportance.landmark:
        return 0;
      case PlaceImportance.major:
        return 10;
      case PlaceImportance.moderate:
        return 13;
      case PlaceImportance.minor:
        return 15;
    }
  }
  
  String get label {
    switch (this) {
      case PlaceImportance.landmark:
        return 'Landmark';
      case PlaceImportance.major:
        return 'Major';
      case PlaceImportance.moderate:
        return 'Moderate';
      case PlaceImportance.minor:
        return 'Minor';
    }
  }
}