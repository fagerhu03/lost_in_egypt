/// Maps quiz answer labels and Google Places API types to the canonical keys
/// used by the recommendation engine's taste vector.
///
/// The engine (functions/recommendation.js) operates on a fixed set of 37
/// canonical keys — 20 place types + 17 content tags. Every signal and
/// scoring call must use these exact strings. This file is the single source
/// of truth for that mapping on the Flutter side.
library;

// ── Interest → types + tags ──────────────────────────────────────────────────
// Each quiz interest label maps to the canonical engine keys that best
// represent it. Used to build the answers[] payload for applyQuizAnswers().

const Map<String, Map<String, List<String>>> _interestMappings = {
  'Shopping': {
    'types': ['shopping_mall', 'market'],
    'tags': ['shopping'],
  },
  'Nightlife': {
    'types': ['night_club', 'restaurant'],
    'tags': ['entertainment'],
  },
  'Monuments': {
    'types': ['monument', 'historical_landmark'],
    'tags': ['historical', 'ancient'],
  },
  'Museums': {
    'types': ['museum'],
    'tags': ['cultural', 'historical'],
  },
  'Nature & Parks': {
    'types': ['park'],
    'tags': ['natural', 'relaxation'],
  },
  'Beaches': {
    'types': ['beach'],
    'tags': ['natural', 'relaxation'],
  },
  'Culture & Traditions': {
    'types': ['museum', 'mosque', 'church', 'market'],
    'tags': ['cultural', 'religious'],
  },
  'Entertainment': {
    'types': ['amusement_park', 'stadium', 'zoo'],
    'tags': ['entertainment', 'family'],
  },
  'Adventure Activities': {
    'types': ['park', 'tourist_attraction'],
    'tags': ['adventure', 'natural'],
  },
  'Local Experiences': {
    'types': ['market', 'restaurant', 'cafe'],
    'tags': ['cultural', 'food'],
  },
};

// ── Area → geographic centre + Places API search radius ─────────────────────
// Used when calling the Places API to fetch candidates for a selected area.
// Radius is in metres and sized to cover the key attractions in each region.

const Map<String, Map<String, dynamic>> _areaBounds = {
  'Cairo': {'lat': 30.0444, 'lng': 31.2357, 'radius': 30000},
  'Luxor': {'lat': 25.6872, 'lng': 32.6396, 'radius': 20000},
  'Aswan': {'lat': 24.0889, 'lng': 32.8998, 'radius': 20000},
  'Alexandria': {'lat': 31.2001, 'lng': 29.9187, 'radius': 25000},
  'Hurghada': {'lat': 27.2579, 'lng': 33.8116, 'radius': 20000},
  'Sharm El-Sheikh': {'lat': 27.9158, 'lng': 34.3300, 'radius': 20000},
  'Dahab': {'lat': 28.4886, 'lng': 34.5132, 'radius': 15000},
  'Siwa': {'lat': 29.2033, 'lng': 25.5195, 'radius': 15000},
  'Fayoum': {'lat': 29.3084, 'lng': 30.8428, 'radius': 20000},
  'North Coast': {'lat': 31.0409, 'lng': 28.0384, 'radius': 30000},
};

// ── Areas that imply taste signals ──────────────────────────────────────────
// When a user selects certain areas, we can infer additional taste signals
// beyond the interests they explicitly picked. Luxor/Aswan selection implies
// historical interest; beach areas imply relaxation, etc.

const _historicalAreas = {'Luxor', 'Aswan', 'Cairo'};
const _beachAreas = {'Hurghada', 'Sharm El-Sheikh', 'Dahab', 'North Coast', 'Alexandria'};
const _naturalAreas = {'Dahab', 'Siwa', 'Fayoum'};

// ── Google Places API type → canonical engine type ───────────────────────────
// The Places API (New) returns its own set of type strings. We normalise them
// to the engine's canonical set before passing to recordTasteSignal or
// recommendPlaces. Types not in this map are silently dropped (the engine
// ignores unknown keys anyway, but filtering here keeps payloads clean).

const Map<String, String> _placesApiTypeMap = {
  // Direct 1-to-1 matches
  'museum': 'museum',
  'historical_landmark': 'historical_landmark',
  'tourist_attraction': 'tourist_attraction',
  'mosque': 'mosque',
  'church': 'church',
  'park': 'park',
  'restaurant': 'restaurant',
  'cafe': 'cafe',
  'shopping_mall': 'shopping_mall',
  'market': 'market',
  'beach': 'beach',
  'zoo': 'zoo',
  'art_gallery': 'art_gallery',
  'amusement_park': 'amusement_park',
  'aquarium': 'aquarium',
  'monument': 'monument',
  'archaeological_site': 'archaeological_site',
  'night_club': 'night_club',
  'spa': 'spa',
  'stadium': 'stadium',
  // Common Places API subtypes mapped to nearest canonical equivalent
  'point_of_interest': 'tourist_attraction',
  'natural_feature': 'park',
  'place_of_worship': 'mosque',
  'food': 'restaurant',
  'store': 'shopping_mall',
  'hindu_temple': 'historical_landmark',
  'synagogue': 'church',
  'library': 'museum',
  'university': 'historical_landmark',
  'city_hall': 'historical_landmark',
  'embassy': 'historical_landmark',
};

// ── Outdoor place classification ─────────────────────────────────────────────
// Used by the weather integration to decide whether to show a warning badge
// on a place card, and by the recommendation engine to apply weather penalties.

const _outdoorTypes = {
  'park', 'beach', 'archaeological_site', 'monument',
  'historical_landmark', 'zoo', 'stadium', 'amusement_park',
  'tourist_attraction',
};

// Markets like Khan el-Khalili are partially covered — a softer penalty applies.
const _semiOutdoorTypes = {'market'};

// ── Public API ────────────────────────────────────────────────────────────────

class RecommendationMappings {
  RecommendationMappings._();

  /// Returns the canonical types + tags for a quiz [interest] label.
  /// Falls back to generic tourist_attraction / cultural if label is unknown.
  static Map<String, List<String>> forInterest(String interest) {
    return _interestMappings[interest] ??
        {'types': ['tourist_attraction'], 'tags': ['cultural']};
  }

  /// Builds the `answers[]` list expected by the `applyQuizAnswers` Cloud
  /// Function from the selections the user made in the quiz.
  ///
  /// Both [selectedInterests] and [selectedAreas] generate answer entries —
  /// areas carry implicit taste signals (Luxor → historical, Dahab → natural).
  static List<Map<String, dynamic>> answersFromSelections({
    required List<String> selectedInterests,
    List<String> selectedAreas = const [],
  }) {
    final answers = <Map<String, dynamic>>[];

    for (final interest in selectedInterests) {
      final m = forInterest(interest);
      answers.add({
        'optionId': interest,
        'types': m['types']!,
        'tags': m['tags']!,
      });
    }

    for (final area in selectedAreas) {
      if (_historicalAreas.contains(area)) {
        answers.add({
          'optionId': 'area_$area',
          'types': ['historical_landmark', 'monument'],
          'tags': ['historical', 'ancient'],
        });
      } else if (_beachAreas.contains(area)) {
        answers.add({
          'optionId': 'area_$area',
          'types': ['beach'],
          'tags': ['natural', 'relaxation'],
        });
      } else if (_naturalAreas.contains(area)) {
        answers.add({
          'optionId': 'area_$area',
          'types': ['park'],
          'tags': ['natural', 'adventure'],
        });
      }
    }

    return answers;
  }

  /// Returns centre coordinates and radius (metres) for a quiz area label,
  /// suitable for a Places API nearby search. Returns null for unknown areas.
  static Map<String, dynamic>? boundsForArea(String area) => _areaBounds[area];

  /// Returns bounds for every area in [selectedAreas], de-duplicated.
  static List<Map<String, dynamic>> boundsForAreas(List<String> selectedAreas) {
    return selectedAreas
        .map(boundsForArea)
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  /// Normalises a list of raw Google Places API type strings to the canonical
  /// engine keys. Unknown types are dropped. Returns a de-duplicated list.
  static List<String> normalizeApiTypes(List<String> apiTypes) {
    final canonical = <String>{};
    for (final t in apiTypes) {
      final mapped = _placesApiTypeMap[t];
      if (mapped != null) canonical.add(mapped);
    }
    return canonical.toList();
  }

  /// Returns true when a place with the given canonical [types] is considered
  /// fully outdoor and should receive weather scoring penalties.
  static bool isOutdoor(List<String> types) =>
      types.any(_outdoorTypes.contains);

  /// Returns true for partially covered outdoor places (e.g. markets).
  /// These receive a softer weather penalty than fully outdoor places.
  static bool isSemiOutdoor(List<String> types) =>
      types.any(_semiOutdoorTypes.contains) && !isOutdoor(types);
}
