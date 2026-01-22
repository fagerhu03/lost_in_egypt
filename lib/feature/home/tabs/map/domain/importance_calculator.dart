import 'place_importance.dart';
// Go up: domain -> map -> tabs -> home -> then down to data/models
import '../../home/data/models/map_item_models.dart';

/// Calculates importance dynamically based on available MapItem properties
class ImportanceCalculator {
  
  // ============================================================
  // LANDMARK KEYWORDS (Score: +5)
  // Places with these in title/description = Always visible
  // ============================================================
  static const List<String> landmarkKeywords = [
    // Ancient Egyptian
    'pyramid', 'pyramids', 'sphinx', 'pharaoh', 'pharaonic',
    'tutankhamun', 'ramses', 'ramesses', 'cleopatra', 'ptolemy',
    'ancient egypt', 'tomb', 'necropolis', 'theban',
    
    // UNESCO / World Heritage
    'unesco', 'world heritage', 'seven wonders', 'wonder of the world',
    
    // Major landmarks
    'lighthouse of alexandria', 'library of alexandria',
    'karnak', 'luxor temple', 'abu simbel', 'valley of the kings',
    'hatshepsut', 'philae', 'edfu', 'kom ombo',
    
    // Major structures
    'citadel', 'qaitbay', 'saladin',
  ];

  // ============================================================
  // MAJOR KEYWORDS (Score: +3)
  // Important places, visible at medium zoom
  // ============================================================
  static const List<String> majorKeywords = [
    // Historical
    'historic', 'historical', 'ancient', 'medieval', 'ottoman',
    'coptic', 'islamic', 'mamluk', 'fatimid',
    
    // Important buildings
    'palace', 'fortress', 'castle', 'cathedral', 'basilica',
    'grand mosque', 'great mosque', 'al-azhar',
    
    // Major museums
    'egyptian museum', 'national museum', 'grand egyptian museum',
    'antiquities', 'mummy', 'mummies',
    
    // Nature
    'national park', 'nature reserve', 'protected area',
    'nile', 'red sea', 'sinai',
  ];

  // ============================================================
  // MODERATE KEYWORDS (Score: +2)
  // Moderately important places
  // ============================================================
  static const List<String> moderateKeywords = [
    // Cultural
    'museum', 'gallery', 'cultural center', 'culture wheel',
    'theatre', 'theater', 'opera',
    
    // Religious
    'mosque', 'church', 'synagogue', 'temple',
    'monastery', 'convent',
    
    // Other attractions
    'zoo', 'aquarium', 'park', 'garden', 'botanical',
    'market', 'bazaar', 'souq', 'khan el-khalili',
  ];

  // ============================================================
  // LANDMARK CATEGORIES (Direct category match)
  // ============================================================
  static const List<String> landmarkCategories = [
    'pyramid',
    'ancient_site',
    'world_heritage',
  ];

  static const List<String> majorCategories = [
    'monument',
    'palace',
    'fortress',
    'national_park',
  ];

  static const List<String> moderateCategories = [
    'museum',
    'landmark',
    'religious',
    'nature',
  ];

  /// Calculate importance for any MapItem
  static PlaceImportance calculate(MapItem item) {
    int score = 0;

    // Combine title and description for keyword search
    final searchText = '${item.title} ${item.description}'.toLowerCase();
    final category = item.category.toLowerCase();

    // ========== Factor 1: Landmark Keywords (0-5 points) ==========
    if (_containsAny(searchText, landmarkKeywords)) {
      score += 5;
    }

    // ========== Factor 2: Major Keywords (0-3 points) ==========
    if (_containsAny(searchText, majorKeywords)) {
      score += 3;
    }

    // ========== Factor 3: Moderate Keywords (0-2 points) ==========
    if (_containsAny(searchText, moderateKeywords)) {
      score += 2;
    }

    // ========== Factor 4: Category Boost (0-4 points) ==========
    if (landmarkCategories.contains(category)) {
      score += 4;
    } else if (majorCategories.contains(category)) {
      score += 3;
    } else if (moderateCategories.contains(category)) {
      score += 2;
    }

    // ========== Factor 5: Rating (0-2 points) ==========
    if (item.rating >= 4.5) {
      score += 2;
    } else if (item.rating >= 4.0) {
      score += 1;
    }

    // ========== Factor 6: Description Quality (0-2 points) ==========
    // Longer, more detailed descriptions often indicate more important places
    if (item.description.length > 300) {
      score += 2;
    } else if (item.description.length > 150) {
      score += 1;
    }

    // ========== Factor 7: Tags (if available) ==========
    if (item.tags.isNotEmpty) {
      final tagsText = item.tags.join(' ').toLowerCase();
      if (_containsAny(tagsText, landmarkKeywords)) score += 3;
      if (_containsAny(tagsText, majorKeywords)) score += 2;
    }

    // ========== Determine Importance Level ==========
    if (score >= 8) return PlaceImportance.landmark;
    if (score >= 5) return PlaceImportance.major;
    if (score >= 3) return PlaceImportance.moderate;
    return PlaceImportance.minor;
  }

  /// Check if text contains any of the keywords
  static bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }

  /// Special calculation for events (considers date proximity)
  static PlaceImportance calculateForEvent(EventModel event) {
    int score = 0;

    // Base score from common factors
    final baseImportance = calculate(event);
    // Convert base importance to a starting score
    // landmark=0, major=1, moderate=2, minor=3 in enum definition
    // We invert it for points: landmark=3, major=2, moderate=1, minor=0
    int baseScore = 0;
    switch (baseImportance) {
      case PlaceImportance.landmark: baseScore = 6; break;
      case PlaceImportance.major: baseScore = 4; break;
      case PlaceImportance.moderate: baseScore = 2; break;
      case PlaceImportance.minor: baseScore = 0; break;
    }
    score += baseScore;

    // ========== Event-specific: Date Proximity ==========
    final daysUntilEvent = event.date.difference(DateTime.now()).inDays;
    
    if (daysUntilEvent >= 0 && daysUntilEvent <= 3) {
      score += 4; // Happening very soon!
    } else if (daysUntilEvent >= 0 && daysUntilEvent <= 7) {
      score += 3; // This week
    } else if (daysUntilEvent >= 0 && daysUntilEvent <= 14) {
      score += 2; // Within 2 weeks
    }

    if (score >= 8) return PlaceImportance.landmark;
    if (score >= 5) return PlaceImportance.major;
    if (score >= 3) return PlaceImportance.moderate;
    return PlaceImportance.minor;
  }
}

/// Extension to easily get importance from any MapItem
extension MapItemImportance on MapItem {
  PlaceImportance get importance {
    if (this is EventModel) {
      return ImportanceCalculator.calculateForEvent(this as EventModel);
    }
    return ImportanceCalculator.calculate(this);
  }

  bool isVisibleAtZoom(double zoom) {
    return zoom >= importance.minZoomLevel;
  }
}