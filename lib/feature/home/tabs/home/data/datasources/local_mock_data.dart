import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/map_item_models.dart';

class LocalMockData {
  static final List<CategoryModel> categories = [
    CategoryModel(id: "cat_hotel", title: "Hotels", iconPath: "assets/icons/hotel.png"),
    CategoryModel(id: "cat_museum", title: "Museums", iconPath: "assets/icons/museum.png"),
    CategoryModel(id: "cat_restaurant", title: "Restaurants", iconPath: "assets/icons/restaurant.png"),
    CategoryModel(id: "cat_mosque", title: "Mosques", iconPath: "assets/icons/mosque.png"),
    CategoryModel(id: "cat_beach", title: "Beaches", iconPath: "assets/icons/beach.png"),
    CategoryModel(id: "cat_adventure", title: "Adventure", iconPath: "assets/icons/adventure.png"),
  ];

  static final List<EventModel> events = [
    EventModel(
      id: "event_arabian_night",
      title: "Arabian Night",
      coordinate: const GeoPoint(29.5696, 30.9320),
      imagePath: "assets/images/event1.jpg",
      locationAddress: "Faiyum Desert Rd, Tamiya, 2975",
      rating: 4.1,
      price: 89.0,
      duration: "3 Days",
      weather: "28° C",
      description: "This resort presents itself as a tranquil yet upscale getaway...",
      date: DateTime(2025, 10, 20),
      tags: const ["event", "desert", "resort", "adventure", "weekend_trip"],
    ),
    EventModel(
      id: "event_crimson",
      title: "Crimson Bar & Grill",
      coordinate: const GeoPoint(30.0561, 31.2241),
      imagePath: "assets/images/event2.jpg",
      locationAddress: "Zamalek, Cairo",
      rating: 4.8,
      price: 45.0,
      duration: "4 Hours",
      weather: "22° C",
      description: "Experience fine dining with a breathtaking view of the Nile...",
      date: DateTime(2025, 10, 21),
      tags: const ["event", "food", "nightlife", "nile_view", "cairo"],
    ),
    EventModel(
      id: "event_temple_tour",
      title: "Temple Tour",
      coordinate: const GeoPoint(25.7188, 32.6573),
      imagePath: "assets/images/event3.jpg",
      locationAddress: "Luxor, Egypt",
      rating: 4.9,
      price: 120.0,
      duration: "1 Day",
      weather: "35° C",
      description: "Step back in time and explore the majestic temples...",
      date: DateTime(2025, 10, 22),
      tags: const ["event", "luxor", "historic", "temple", "day_trip"],
    ),
    EventModel(
      id: "event_jazz_night",
      title: "Cairo Jazz Festival",
      coordinate: const GeoPoint(30.0444, 31.2357),
      imagePath: "assets/images/jazz_festival.jpg",
      locationAddress: "Cairo Jazz Club",
      rating: 4.5,
      price: 500.0,
      duration: "1 Night",
      weather: "19° C",
      description: "Live Jazz music all night...",
      date: DateTime(2025, 11, 20),
      tags: const ["event", "music", "nightlife", "cairo"],
    ),
    EventModel(
      id: "event_opera_aida",
      title: "Opera Aida",
      coordinate: const GeoPoint(30.0425, 31.2238),
      imagePath: "assets/images/opera_aida.jpg",
      locationAddress: "Cairo Opera House",
      rating: 4.8,
      price: 1200.0,
      duration: "1 Night",
      weather: "18° C",
      description: "The classic opera performed at the historic Cairo Opera House.",
      date: DateTime(2025, 12, 15),
      tags: const ["event", "opera", "culture", "nightlife", "cairo"],
    ),
  ];

  static final List<PlaceModel> places = [
    // =========================
    // Core places (existing)
    // =========================
    PlaceModel(
      id: "place_pyramids",
      title: "Great Pyramids",
      category: "historic",
      tags: const [
        "pyramid",
        "historic",
        "giza",
        "unesco",
        "photo_spot",
        "family_friendly",
        "outdoor",
      ],
      coordinate: const GeoPoint(29.9792, 31.1342),
      imagePath: "assets/images/event1.jpg",
      locationAddress: "Al Haram, Giza",
      rating: 4.9,
      price: 540.0,
      duration: "3 Hours",
      weather: "32° C",
      description: "The oldest of the Seven Wonders...",
      isOpenNow: true,
    ),

  
  ];
}