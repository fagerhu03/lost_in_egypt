import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../map/presentation/map_config.dart';
import '../../../map/domain/place_importance.dart';
import '../../../map/data/places_api_service.dart';

// ==========================================================
// 0. REVIEW MODEL
// ==========================================================
class PlaceReview {
  final String authorName;
  final double rating;
  final String text;
  final String relativeTime;

  const PlaceReview({
    required this.authorName,
    required this.rating,
    required this.text,
    required this.relativeTime,
  });

  factory PlaceReview.fromJson(Map<String, dynamic> json) {
    // authorAttribution can vary in structure
    String authorName = 'Traveler';
    final authorAttr = json['authorAttribution'];
    if (authorAttr is Map<String, dynamic>) {
      authorName = (authorAttr['displayName'] ?? 'Traveler').toString();
    }

    // originalText can also vary
    String reviewText = '';
    final origText = json['originalText'];
    if (origText is Map<String, dynamic>) {
      reviewText = (origText['text'] ?? '').toString();
    } else if (json['text'] is Map<String, dynamic>) {
      reviewText = ((json['text'] as Map<String, dynamic>)['text'] ?? '').toString();
    }

    return PlaceReview(
      authorName: authorName,
      rating: (json['rating'] ?? 0).toDouble(),
      text: reviewText,
      relativeTime: (json['relativePublishTimeDescription'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'authorAttribution': {'displayName': authorName},
    'rating': rating,
    'originalText': {'text': text},
    'relativePublishTimeDescription': relativeTime,
  };
}

// ==========================================================
// 1. SHARED INTERFACE (Domain Entity)
// ==========================================================
abstract class MapItem {
  String get id;
  String get title;
  GeoPoint get coordinate;
  String get category;
  String get imagePath;
  List<String> get imagePaths;
  String get locationAddress;
  double get rating;
  double get price;
  String get duration;
  String get weather;
  String get description;
  List<String> get tags;
  int get importance;
  bool get isCurrentlyOpen;
  String get openingHoursText;
  List<PlaceReview> get reviews;
}

// ==========================================================
// 2. CATEGORY MODEL
// ==========================================================
class CategoryModel {
  final String id;
  final String title;
  final String iconPath;

  const CategoryModel({
    required this.id,
    required this.title,
    required this.iconPath,
  });

  Map<String, dynamic> toMap() => {
        'title': title,
        'iconPath': iconPath,
      };

  factory CategoryModel.fromMap(Map<String, dynamic> map, String docId) {
    return CategoryModel(
      id: docId,
      title: map['title'] ?? '',
      iconPath: map['iconPath'] ?? '',
    );
  }
}

// ==========================================================
// 3. PLACE MODEL (Data Transfer Object)
// ==========================================================
class PlaceModel implements MapItem {
  @override
  final String id;
  @override
  final String title;
  @override
  final String category;
  @override
  final GeoPoint coordinate;
  @override
  final String imagePath;
  @override
  final List<String> imagePaths;
  @override
  final String locationAddress;
  @override
  final double rating;
  @override
  final double price;
  @override
  final String duration;
  @override
  final String weather;
  @override
  final String description;
  @override
  final List<String> tags;
  @override
  final int importance;
  @override
  final bool isCurrentlyOpen;
  @override
  final String openingHoursText;
  @override
  final List<PlaceReview> reviews;

  // Legacy alias
  bool get isOpenNow => isCurrentlyOpen;

  const PlaceModel({
    required this.id,
    required this.title,
    required this.category,
    required this.coordinate,
    required this.imagePath,
    this.imagePaths = const [],
    required this.locationAddress,
    required this.rating,
    required this.price,
    required this.duration,
    required this.weather,
    required this.description,
    this.isCurrentlyOpen = false,
    this.openingHoursText = '',
    this.reviews = const [],
    this.tags = const [],
    this.importance = 10,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'category': category,
      'coordinate': coordinate,
      'imagePath': imagePath,
      'imagePaths': imagePaths,
      'locationAddress': locationAddress,
      'rating': rating,
      'price': price,
      'duration': duration,
      'weather': weather,
      'description': description,
      'isOpenNow': isCurrentlyOpen,
      'openingHoursText': openingHoursText,
      'tags': tags,
      'importance': importance,
    };
  }

  factory PlaceModel.fromMap(Map<String, dynamic> map, String docId) {
    return PlaceModel(
      id: docId,
      title: map['title'] ?? '',
      category: map['category'] ?? '',
      coordinate: map['coordinate'] ?? const GeoPoint(30.0444, 31.2357),
      imagePath: map['imagePath'] ?? '',
      imagePaths: (map['imagePaths'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      locationAddress: map['locationAddress'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
      price: (map['price'] ?? 0).toDouble(),
      duration: map['duration'] ?? '',
      weather: map['weather'] ?? '',
      description: map['description'] ?? '',
      isCurrentlyOpen: map['isOpenNow'] ?? false,
      openingHoursText: map['openingHoursText'] ?? '',
      tags: (map['tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      importance: (map['importance'] ?? 10).toInt(),
    );
  }

  /// Factory constructor for Google Places API (New) response.
  factory PlaceModel.fromPlacesApi(Map<String, dynamic> json, String apiKey) {
    final placeId = json['id'] as String? ?? '';

    // displayName is { "text": "...", "languageCode": "en" }
    final displayName = json['displayName'] as Map<String, dynamic>? ?? {};
    final title = displayName['text'] as String? ?? 'Unknown Place';

    // location is { "latitude": ..., "longitude": ... }
    final location = json['location'] as Map<String, dynamic>? ?? {};
    final lat = (location['latitude'] ?? 30.0444).toDouble();
    final lng = (location['longitude'] ?? 31.2357).toDouble();

    // Map primaryType → app category
    final primaryType = json['primaryType'] as String? ?? '';
    final types = (json['types'] as List<dynamic>?)?.cast<String>() ?? [];
    final category = _resolveCategory(primaryType, types);

    // Rating & reviews
    final rating = (json['rating'] ?? 0).toDouble();
    final userRatingCount = (json['userRatingCount'] ?? 0).toInt();

    // Compute importance from rating + review count
    int importance = ImportanceConfig.computeFromApi(
      rating: rating,
      userRatingCount: userRatingCount,
    );

    // Geographic diversity boost: places far from Cairo get higher
    // importance so they show at wider zoom levels. This ensures
    // the map shows Egypt has attractions everywhere, not just Cairo.
    final distKm = _distanceFromCairo(lat, lng);
    if (distKm > 200) {
      importance = (importance + 3).clamp(1, 10);
    } else if (distKm > 100) {
      importance = (importance + 2).clamp(1, 10);
    } else if (distKm > 50) {
      importance = (importance + 1).clamp(1, 10);
    }

    // Address
    final address = json['formattedAddress'] as String? ?? '';

    // Photo URLs (Parse up to 5 for the carousel, using maxWidth=500 for speed)
    String imagePath = '';
    List<String> imagePaths = [];
    final photos = json['photos'] as List<dynamic>?;
    if (photos != null && photos.isNotEmpty) {
      for (int i = 0; i < photos.length && i < 5; i++) {
        final photoName = photos[i]['name'] as String? ?? '';
        if (photoName.isNotEmpty) {
          final url = PlacesApiService.buildPhotoUrl(photoName, apiKey, maxWidth: 500);
          imagePaths.add(url);
          if (i == 0) {
            imagePath = url; // Set the first photo as the primary imagePath
          }
        }
      }
    }

    // Editorial summary
    final editorialSummary = json['editorialSummary'] as Map<String, dynamic>?;
    final description = editorialSummary?['text'] as String? ?? '';

    // Price level → numeric price hint
    final priceLevelStr = json['priceLevel'] as String? ?? '';
    double price = 0;
    if (priceLevelStr == 'PRICE_LEVEL_INEXPENSIVE') price = 50;
    if (priceLevelStr == 'PRICE_LEVEL_MODERATE') price = 150;
    if (priceLevelStr == 'PRICE_LEVEL_EXPENSIVE') price = 300;
    if (priceLevelStr == 'PRICE_LEVEL_VERY_EXPENSIVE') price = 500;

    // Build tags from types list
    final tags = types.take(5).toList();

    // Opening hours
    final openingHours = json['currentOpeningHours'] as Map<String, dynamic>?;
    final isCurrentlyOpen = openingHours?['openNow'] as bool? ?? false;
    final weekdayDescs = (openingHours?['weekdayDescriptions'] as List<dynamic>?);
    String openingHoursText = '';
    if (weekdayDescs != null && weekdayDescs.isNotEmpty) {
      openingHoursText = weekdayDescs.map((d) => d.toString()).join('\n');
    }

    // Reviews
    final reviewsList = <PlaceReview>[];
    final rawReviews = json['reviews'] as List<dynamic>?;
    if (rawReviews != null) {
      for (int i = 0; i < rawReviews.length && i < 5; i++) {
        try {
          reviewsList.add(PlaceReview.fromJson(rawReviews[i] as Map<String, dynamic>));
        } catch (_) {}
      }
    }

    return PlaceModel(
      id: placeId,
      title: title,
      category: category,
      coordinate: GeoPoint(lat, lng),
      imagePath: imagePath,
      imagePaths: imagePaths,
      locationAddress: address,
      rating: rating,
      price: price,
      duration: '',
      weather: '',
      description: description,
      isCurrentlyOpen: isCurrentlyOpen,
      openingHoursText: openingHoursText,
      reviews: reviewsList,
      tags: tags,
      importance: importance,
    );
  }

  /// Resolve the app category from Places API primaryType + types list.
  static String _resolveCategory(String primaryType, List<String> types) {
    // Check primaryType first
    if (MapConfig.apiTypeToCategory.containsKey(primaryType)) {
      return MapConfig.apiTypeToCategory[primaryType]!;
    }
    // Fallback: check all types
    for (final type in types) {
      if (MapConfig.apiTypeToCategory.containsKey(type)) {
        return MapConfig.apiTypeToCategory[type]!;
      }
    }
    return 'tourism'; // default category
  }

  /// Approximate distance from Cairo center (30.04°N, 31.24°E) in km.
  static double _distanceFromCairo(double lat, double lng) {
    const cairoLat = 30.04;
    const cairoLng = 31.24;
    // Simple equirectangular approximation (good enough for importance boost)
    final dLat = (lat - cairoLat) * 111.0; // ~111 km per degree latitude
    final dLng = (lng - cairoLng) * 111.0 * math.cos(cairoLat * math.pi / 180);
    return math.sqrt(dLat * dLat + dLng * dLng);
  }
}

// ==========================================================
// 4. EVENT MODEL (Data Transfer Object)
// ==========================================================
class EventModel implements MapItem {
  @override
  final String id;
  @override
  final String title;
  @override
  final GeoPoint coordinate;
  @override
  final String imagePath;
  @override
  final List<String> imagePaths;
  @override
  final String locationAddress;
  @override
  final double rating;
  @override
  final double price;
  @override
  final String duration;
  @override
  final String weather;
  @override
  final String description;
  @override
  final List<String> tags;
  @override
  final int importance;

  @override
  bool get isCurrentlyOpen => false;
  @override
  String get openingHoursText => '';
  @override
  List<PlaceReview> get reviews => const [];

  @override
  String get category => 'event';

  final DateTime date;

  const EventModel({
    required this.id,
    required this.title,
    required this.coordinate,
    required this.imagePath,
    this.imagePaths = const [],
    required this.locationAddress,
    required this.rating,
    required this.price,
    required this.duration,
    required this.weather,
    required this.description,
    required this.date,
    this.tags = const [],
    this.importance = 5,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'coordinate': coordinate,
      'imagePath': imagePath,
      'imagePaths': imagePaths,
      'locationAddress': locationAddress,
      'rating': rating,
      'price': price,
      'duration': duration,
      'weather': weather,
      'description': description,
      'date': Timestamp.fromDate(date),
      'isEvent': true,
      'tags': tags,
      'importance': importance,
    };
  }

  factory EventModel.fromMap(Map<String, dynamic> map, String docId) {
    return EventModel(
      id: docId,
      title: map['title'] ?? '',
      coordinate: map['coordinate'] ?? const GeoPoint(30.0444, 31.2357),
      imagePath: map['imagePath'] ?? '',
      imagePaths: (map['imagePaths'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      locationAddress: map['locationAddress'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
      price: (map['price'] ?? 0).toDouble(),
      duration: map['duration'] ?? '',
      weather: map['weather'] ?? '',
      description: map['description'] ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      tags: (map['tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      importance: (map['importance'] ?? 5).toInt(),
    );
  }
}