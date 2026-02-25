import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'data/places_api_service.dart';

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

  /// Traveler-focused search queries per category.
  /// Each returns a PlacesSearchQuery with a descriptive text + optional type filter.
  static List<PlacesSearchQuery> getQueriesForCategory(String categoryId) {
    switch (categoryId) {
      case 'tourism':
        return const [
          PlacesSearchQuery(query: 'famous tourist attractions Cairo Egypt', includedType: 'tourist_attraction'),
          PlacesSearchQuery(query: 'tourist attractions Luxor Egypt'),
          PlacesSearchQuery(query: 'tourist attractions Aswan Egypt'),
          PlacesSearchQuery(query: 'tourist attractions Alexandria Egypt'),
          PlacesSearchQuery(query: 'tourist places Sharm El Sheikh Egypt'),
          PlacesSearchQuery(query: 'tourist attractions Hurghada Egypt'),
        ];
      case 'historical':
        return const [
          PlacesSearchQuery(query: 'ancient pyramids and sphinx Giza Egypt'),
          PlacesSearchQuery(query: 'ancient temples Luxor Karnak Egypt'),
          PlacesSearchQuery(query: 'ancient temples Aswan Abu Simbel Egypt'),
          PlacesSearchQuery(query: 'historical sites Islamic Cairo Egypt'),
          PlacesSearchQuery(query: 'pharaonic tombs Valley of Kings Egypt'),
        ];
      case 'museum':
        return const [
          PlacesSearchQuery(query: 'museums in Cairo Egypt', includedType: 'museum'),
          PlacesSearchQuery(query: 'Grand Egyptian Museum National Museum Cairo', includedType: 'museum'),
          PlacesSearchQuery(query: 'museums Alexandria Egypt', includedType: 'museum'),
          PlacesSearchQuery(query: 'museums Luxor Egypt', includedType: 'museum'),
          PlacesSearchQuery(query: 'museums Aswan Nubia Egypt', includedType: 'museum'),
          PlacesSearchQuery(query: 'military museum war museum Egypt', includedType: 'museum'),
          PlacesSearchQuery(query: 'art galleries modern art museums Cairo Egypt'),
          PlacesSearchQuery(query: 'open air museum Karnak Giza Egypt'),
        ];
      case 'hotel':
        return const [
          PlacesSearchQuery(query: 'best hotels Cairo Egypt tourists', includedType: 'lodging'),
          PlacesSearchQuery(query: 'best resort hotels Sharm El Sheikh Hurghada Egypt', includedType: 'lodging'),
          PlacesSearchQuery(query: 'best hotels Luxor Aswan Egypt', includedType: 'lodging'),
        ];
      case 'religious':
        return const [
          // Mosques — by city
          PlacesSearchQuery(query: 'famous mosques Cairo Egypt', includedType: 'mosque'),
          PlacesSearchQuery(query: 'historic mosques Islamic Cairo Egypt', includedType: 'mosque'),
          PlacesSearchQuery(query: 'famous mosques Alexandria Egypt', includedType: 'mosque'),
          PlacesSearchQuery(query: 'mosques Luxor Aswan Upper Egypt', includedType: 'mosque'),
          PlacesSearchQuery(query: 'mosques Tanta Mansoura Delta Egypt', includedType: 'mosque'),
          PlacesSearchQuery(query: 'mosques Port Said Ismailia Suez Egypt', includedType: 'mosque'),
          // Churches & Cathedrals
          PlacesSearchQuery(query: 'coptic churches Old Cairo Egypt', includedType: 'church'),
          PlacesSearchQuery(query: 'coptic churches cathedrals Alexandria Egypt', includedType: 'church'),
          PlacesSearchQuery(query: 'churches cathedrals Luxor Aswan Minya Egypt', includedType: 'church'),
          // Monasteries
          PlacesSearchQuery(query: 'coptic monasteries Wadi Natrun Egypt'),
          PlacesSearchQuery(query: 'monasteries Red Sea Sinai Saint Catherine Egypt'),
          PlacesSearchQuery(query: 'coptic monasteries Sohag Asyut Upper Egypt'),
          // Other
          PlacesSearchQuery(query: 'Jewish synagogues Cairo Alexandria Egypt'),
          PlacesSearchQuery(query: 'Sufi shrines mausoleums Cairo Egypt'),
          PlacesSearchQuery(query: 'Al Azhar mosque university Islamic architecture Cairo'),
        ];
      case 'food':
        return const [
          PlacesSearchQuery(query: 'best restaurants in Cairo Egypt', includedType: 'restaurant'),
          PlacesSearchQuery(query: 'best restaurants Alexandria Hurghada Egypt', includedType: 'restaurant'),
        ];
      case 'nature':
        return const [
          // Beaches & diving
          PlacesSearchQuery(query: 'beaches Sharm El Sheikh Dahab Sinai Egypt'),
          PlacesSearchQuery(query: 'beaches Hurghada El Gouna Red Sea Egypt'),
          PlacesSearchQuery(query: 'beaches Marsa Alam Marsa Matrouh Egypt'),
          PlacesSearchQuery(query: 'diving snorkeling coral reef Ras Mohammed Egypt'),
          // Deserts & oases
          PlacesSearchQuery(query: 'White Desert Black Desert Bahariya Egypt'),
          PlacesSearchQuery(query: 'Siwa Oasis salt lakes sand dunes Egypt'),
          PlacesSearchQuery(query: 'Fayoum Wadi El Rayan waterfalls Egypt'),
          // Parks & gardens
          PlacesSearchQuery(query: 'national parks nature reserves Egypt', includedType: 'national_park'),
          PlacesSearchQuery(query: 'botanical gardens parks Cairo Alexandria Egypt', includedType: 'park'),
          PlacesSearchQuery(query: 'zoos aquariums animal parks Egypt', includedType: 'zoo'),
          // Mountains & wadis
          PlacesSearchQuery(query: 'Mount Sinai colored canyon Sinai Egypt'),
          PlacesSearchQuery(query: 'Wadi Degla Wadi El Gemal nature Egypt'),
        ];
      case 'entertainment':
        return const [
          // Theme parks & water parks
          PlacesSearchQuery(query: 'water parks aqua parks Cairo Egypt'),
          PlacesSearchQuery(query: 'water parks Sharm El Sheikh Hurghada Egypt'),
          PlacesSearchQuery(query: 'theme parks amusement parks Cairo Egypt', includedType: 'amusement_park'),
          // Shows & performances
          PlacesSearchQuery(query: 'sound and light show pyramids Karnak Egypt'),
          PlacesSearchQuery(query: 'Cairo Opera House cultural shows Egypt'),
          // Nightlife & entertainment
          PlacesSearchQuery(query: 'nightlife entertainment clubs Cairo Egypt'),
          PlacesSearchQuery(query: 'entertainment venues Sharm Hurghada Egypt'),
          // Sports & activities
          PlacesSearchQuery(query: 'go karting bowling entertainment Cairo Egypt'),
          PlacesSearchQuery(query: 'boat trips felucca Nile cruise Egypt'),
          PlacesSearchQuery(query: 'hot air balloon Luxor quad biking desert Egypt'),
        ];
      case 'shopping':
        return const [
          PlacesSearchQuery(query: 'Khan El Khalili bazaar shopping Cairo Egypt'),
          PlacesSearchQuery(query: 'shopping malls Cairo City Stars Mall of Egypt'),
          PlacesSearchQuery(query: 'shopping malls Alexandria Egypt', includedType: 'shopping_mall'),
          PlacesSearchQuery(query: 'traditional markets souks Cairo Egypt'),
          PlacesSearchQuery(query: 'Aswan souk Luxor market shopping Egypt'),
          PlacesSearchQuery(query: 'shopping Sharm El Sheikh old market Naama Bay'),
          PlacesSearchQuery(query: 'handicrafts souvenirs shopping Egypt'),
          PlacesSearchQuery(query: 'gold market spice bazaar Cairo Egypt'),
        ];
      default:
        return const [
          PlacesSearchQuery(query: 'top tourist attractions Egypt'),
        ];
    }
  }

  /// All traveler-focused queries — geographically spread across ALL of Egypt.
  static List<PlacesSearchQuery> getAllTravelerQueries() {
    return const [
      // ===== MAJOR CITIES =====
      PlacesSearchQuery(query: 'famous tourist attractions Cairo Egypt', includedType: 'tourist_attraction'),
      PlacesSearchQuery(query: 'tourist attractions Luxor Egypt'),
      PlacesSearchQuery(query: 'tourist attractions Aswan Egypt'),
      PlacesSearchQuery(query: 'tourist attractions Alexandria Egypt'),

      // ===== SINAI PENINSULA =====
      PlacesSearchQuery(query: 'tourist attractions Sharm El Sheikh Egypt'),
      PlacesSearchQuery(query: 'Dahab blue hole diving Sinai Egypt'),
      PlacesSearchQuery(query: 'Saint Catherine monastery Mount Sinai Egypt'),
      PlacesSearchQuery(query: 'Nuweiba Taba tourist places Sinai Egypt'),

      // ===== RED SEA COAST =====
      PlacesSearchQuery(query: 'Hurghada tourist attractions Egypt'),
      PlacesSearchQuery(query: 'El Gouna resort town Red Sea Egypt'),
      PlacesSearchQuery(query: 'Marsa Alam diving beaches Red Sea Egypt'),
      PlacesSearchQuery(query: 'Safaga Port Ghalib Red Sea Egypt'),

      // ===== SUEZ CANAL CITIES =====
      PlacesSearchQuery(query: 'tourist attractions Port Said Egypt'),
      PlacesSearchQuery(query: 'tourist places Ismailia Suez Canal Egypt'),

      // ===== NORTH COAST / WESTERN =====
      PlacesSearchQuery(query: 'El Alamein war memorial North Coast Egypt'),
      PlacesSearchQuery(query: 'Marsa Matrouh beaches Cleopatra Egypt'),

      // ===== WESTERN DESERT OASES =====
      PlacesSearchQuery(query: 'Siwa Oasis tourist attractions Egypt'),
      PlacesSearchQuery(query: 'Bahariya Oasis White Desert Farafra Egypt'),
      PlacesSearchQuery(query: 'Dakhla Kharga Oasis Western Desert Egypt'),

      // ===== UPPER EGYPT =====
      PlacesSearchQuery(query: 'tourist attractions Minya Beni Hassan Egypt'),
      PlacesSearchQuery(query: 'temples Abydos Dendera Sohag Qena Egypt'),

      // ===== FAYOUM =====
      PlacesSearchQuery(query: 'Fayoum Wadi El Rayan waterfalls whale valley Egypt'),

      // ===== HISTORICAL & MUSEUMS =====
      PlacesSearchQuery(query: 'ancient pyramids sphinx Giza Egypt'),
      PlacesSearchQuery(query: 'ancient temples Luxor Karnak Egypt'),
      PlacesSearchQuery(query: 'Abu Simbel temple Aswan Egypt'),
      PlacesSearchQuery(query: 'pharaonic tombs Valley of Kings Egypt'),
      PlacesSearchQuery(query: 'historical Islamic Cairo citadel Egypt'),
      PlacesSearchQuery(query: 'museums in Cairo Egypt', includedType: 'museum'),
      PlacesSearchQuery(query: 'Grand Egyptian Museum National Museum Cairo', includedType: 'museum'),
      PlacesSearchQuery(query: 'museums Luxor Alexandria Aswan Egypt', includedType: 'museum'),
      PlacesSearchQuery(query: 'art galleries open air museums Egypt'),

      // ===== RELIGIOUS — comprehensive coverage =====
      PlacesSearchQuery(query: 'famous historic mosques Cairo Egypt', includedType: 'mosque'),
      PlacesSearchQuery(query: 'mosques Alexandria Tanta Delta Egypt', includedType: 'mosque'),
      PlacesSearchQuery(query: 'mosques Luxor Aswan Upper Egypt', includedType: 'mosque'),
      PlacesSearchQuery(query: 'coptic churches Old Cairo Hanging Church Egypt', includedType: 'church'),
      PlacesSearchQuery(query: 'coptic churches Alexandria Minya Egypt', includedType: 'church'),
      PlacesSearchQuery(query: 'coptic monasteries Wadi Natrun Red Sea Egypt'),
      PlacesSearchQuery(query: 'Saint Catherine monastery Sinai Egypt'),
      PlacesSearchQuery(query: 'Sufi shrines synagogues Cairo Alexandria Egypt'),

      // ===== NATURE & PARKS =====
      PlacesSearchQuery(query: 'Ras Mohammed national park Sinai Egypt'),
      PlacesSearchQuery(query: 'zoos aquariums animal parks Egypt', includedType: 'zoo'),
      PlacesSearchQuery(query: 'botanical gardens parks Cairo Alexandria Egypt', includedType: 'park'),
      PlacesSearchQuery(query: 'White Desert Black Desert Bahariya Egypt'),
      PlacesSearchQuery(query: 'Wadi Degla Wadi El Gemal nature reserve Egypt'),

      // ===== COMMERCIAL (shown at higher zoom) =====
      PlacesSearchQuery(query: 'top hotels resorts Sharm Hurghada Egypt', includedType: 'lodging'),
      PlacesSearchQuery(query: 'best hotels Cairo Luxor Aswan Egypt', includedType: 'lodging'),
      PlacesSearchQuery(query: 'best restaurants Cairo Egypt', includedType: 'restaurant'),
      PlacesSearchQuery(query: 'popular cafes Cairo Alexandria Egypt', includedType: 'cafe'),
      PlacesSearchQuery(query: 'Khan El Khalili bazaar markets Cairo Egypt'),
      PlacesSearchQuery(query: 'shopping malls Cairo Alexandria Egypt', includedType: 'shopping_mall'),
      PlacesSearchQuery(query: 'traditional souks markets Aswan Luxor Egypt'),

      // ===== ENTERTAINMENT =====
      PlacesSearchQuery(query: 'sound and light show pyramids Karnak Egypt'),
      PlacesSearchQuery(query: 'water parks theme parks Cairo Egypt'),
      PlacesSearchQuery(query: 'hot air balloon Luxor Nile cruise Egypt'),
    ];
  }

  /// Maps Places API primaryType → app category for pin assignment
  static const Map<String, String> apiTypeToCategory = {
    'tourist_attraction': 'tourism',
    'museum':             'museum',
    'lodging':            'hotel',
    'hotel':              'hotel',
    'mosque':             'religious',
    'church':             'religious',
    'hindu_temple':       'religious',
    'synagogue':          'religious',
    'restaurant':         'food',
    'cafe':               'food',
    'bakery':             'food',
    'park':               'nature',
    'national_park':      'nature',
    'campground':         'nature',
    'zoo':                'nature',
    'aquarium':           'nature',
    'amusement_park':     'entertainment',
    'night_club':         'entertainment',
    'movie_theater':      'entertainment',
    'stadium':            'entertainment',
    'university':         'education',
    'library':            'education',
    'shopping_mall':      'shopping',
    'market':             'shopping',
    'transit_station':    'transport',
    'bus_station':        'transport',
    'train_station':      'transport',
    'airport':            'transport',
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
    UiCategory('shopping', 'Shopping', '🛍️'),
  ];
}

