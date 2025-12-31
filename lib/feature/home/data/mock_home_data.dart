// 1. CATEGORY MODEL
class CategoryModel {
  final String id;
  final String title;
  final String iconPath;

  const CategoryModel({
    required this.id,
    required this.title,
    required this.iconPath,
  });
  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'iconPath': iconPath,
      'order': DateTime.now().millisecondsSinceEpoch, 
    };
  }

  // Convert from Firestore to App
  factory CategoryModel.fromMap(Map<String, dynamic> map, String docId) {
    return CategoryModel(
      id: docId,
      title: map['title'] ?? '',
      iconPath: map['iconPath'] ?? '',
    );
  }
}


// 2. UPDATED EVENT MODEL
class EventModel {
  final String id;
  final String title;
  final String location;
  final String imagePath;
  final double price;
  final double rating;
  final String distance;
  final String duration;
  final String weather; // e.g., "28° C"
  final String dressCode; // e.g., "Smart Casual"
  final String description;
  final bool isFavorite;

  const EventModel({
    required this.id,
    required this.title,
    required this.location,
    required this.imagePath,
    required this.price,
    required this.rating,
    required this.distance,
    required this.duration,
    required this.weather,
    required this.dressCode,
    required this.description,
    this.isFavorite = false,
  });
  // Converts Object -> Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'location': location,
      'imagePath': imagePath,
      'price': price,
      'rating': rating,
      'distance': distance,
      'duration': duration,
      'weather': weather,
      'dressCode': dressCode,
      'description': description,
      'isFavorite': isFavorite,
    };
  }

  // Converts Firestore Map -> Object (For when we fetch it back)
  factory EventModel.fromMap(Map<String, dynamic> map, String docId) {
    return EventModel(
      id: docId, // Use the Document ID from Firestore
      title: map['title'] ?? '',
      location: map['location'] ?? '',
      imagePath: map['imagePath'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      rating: (map['rating'] ?? 0).toDouble(),
      distance: map['distance'] ?? '',
      duration: map['duration'] ?? '',
      weather: map['weather'] ?? '',
      dressCode: map['dressCode'] ?? '',
      description: map['description'] ?? '',
      isFavorite: map['isFavorite'] ?? false,
    );
  }
}

// 3. MOCK REPOSITORY (The Fake Database)
class MockHomeRepository {
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
      id: "1",
      title: "Arabian Night",
      location: "Faiyum Desert Rd, Tamiya, Faiyum Governorate 2975",
      imagePath: "assets/images/event1.jpg",
      price: 89.0,
      rating: 4.1,
      distance: "466KM",
      duration: "3 Days",
      weather: "28° C",
      dressCode: "None",
      description:
          "This resort presents itself as a tranquil yet upscale getaway, set within the scenic landscape of the Faiyum region. The architecture and landscaping suggest a design that blends leisure luxury with the surrounding natural environment.",
      isFavorite: true,
    ),
    EventModel(
      id: "2",
      title: "Crimson Bar & Grill",
      location: "Zamalek, Cairo Governorate",
      imagePath: "assets/images/event2.jpg",
      price: 45.0,
      rating: 4.8,
      distance: "12KM",
      duration: "4 Hours",
      weather: "22° C",
      dressCode: "Smart Casual",
      description:
          "Experience fine dining with a breathtaking view of the Nile. Crimson offers a curated menu of grilled specialties and signature cocktails in a sophisticated rooftop setting.",
      isFavorite: false,
    ),
    EventModel(
      id: "3",
      title: "Temple Tour",
      location: "Luxor, Egypt",
      imagePath: "assets/images/event3.jpg",
      price: 120.0,
      rating: 4.9,
      distance: "650KM",
      duration: "1 Day",
      weather: "35° C",
      dressCode: "Casual",
      description:
          "Step back in time and explore the majestic temples of Luxor. This guided tour covers Karnak and Luxor temples, offering deep insights into ancient Egyptian history.",
      isFavorite: false,
    ),
    EventModel(
      id: "4",
      title: "Nile Cruise",
      location: "Aswan to Luxor",
      imagePath: "assets/images/event4.jpg",
      price: 300.0,
      rating: 4.7,
      distance: "200KM",
      duration: "4 Days",
      weather: "30° C",
      dressCode: "Casual",
      description:
          "A relaxing cruise down the Nile river, stopping at major historical sites. Includes full board and guided tours.",
      isFavorite: false,
    ),
  ];
}
