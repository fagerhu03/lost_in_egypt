import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/map_item_models.dart';

class LocalPlacesService {
  // Per-category cache
  static final Map<String, List<PlaceModel>> _cache = {};

  /// Maps category IDs to their JSON asset files.
  static const Map<String, String> _categoryAssets = {
    'cat_museum':     'assets/cat_museum.json',
    'cat_restaurant': 'assets/cat_restaurant.json',
    'cat_beach':      'assets/cat_beach.json',
    'cat_mosque':     'assets/cat_mosque.json',
    'cat_hotel':      'assets/cat_hotel.json',
    'cat_adventure':  'assets/cat_adventure.json',
  };

  /// Maps the asset-bucket categoryId (`cat_museum`) to the canonical engine
  /// type (`museum`). Used so the `category` field on every loaded PlaceModel
  /// matches what places loaded from Places API / dataset return — otherwise
  /// `category.toUpperCase()` renders inconsistently across the app
  /// ("MUSEUM" vs "CAT_MUSEUM") and the recommendation engine fails to score
  /// these places against the user's tasteVector (which uses canonical keys).
  static const Map<String, String> _canonicalCategory = {
    'cat_museum':     'museum',
    'cat_restaurant': 'restaurant',
    'cat_beach':      'beach',
    'cat_mosque':     'mosque',
    'cat_hotel':      'tourist_attraction',
    'cat_adventure':  'tourist_attraction',
  };

  /// Load all places for a given category directly from its JSON file.
  static Future<List<PlaceModel>> getPlacesByCategory(String categoryId) async {
    if (_cache.containsKey(categoryId)) return _cache[categoryId]!;

    final assetPath = _categoryAssets[categoryId];
    if (assetPath == null) return [];

    try {
      final jsonString = await rootBundle.loadString(assetPath);
      final List<dynamic> jsonList = jsonDecode(jsonString);

      final canonicalCat = _canonicalCategory[categoryId] ?? 'tourist_attraction';
      final places = jsonList.map((item) {
        return PlaceModel(
          id: item['id'] ?? '',
          title: item['title'] ?? '',
          category: canonicalCat,
          coordinate: GeoPoint(
            (item['latitude'] as num?)?.toDouble() ?? 30.0444,
            (item['longitude'] as num?)?.toDouble() ?? 31.2357,
          ),
          imagePath: (item['imagePath'] != null && item['imagePath'].toString().isNotEmpty)
              ? item['imagePath']
              : _getImageForPlace(categoryId, item['title']),
          locationAddress: item['city'] ?? '',
          rating: (item['rating'] as num?)?.toDouble() ?? 4.0,
          userRatingCount: (item['userRatingCount'] as num?)?.toInt() ?? 0,
          price: 0.0,
          duration: '',
          weather: '',
          description: item['highlight'] ?? item['cuisine_type'] ?? item['activity_type'] ?? item['sea'] ?? item['era'] ?? '',
        );
      }).toList();

      _cache[categoryId] = places;
      return places;
    } catch (e) {
      print("Error loading places for $categoryId: $e");
      return [];
    }
  }

  static final List<String> _placeholderImages = [
    'assets/images/event1.jpg',
    'assets/images/event2.jpg',
    'assets/images/event3.jpg',
    'assets/images/event4.jpg',
    'assets/images/event5.png',
    'assets/images/event6.png',
    'assets/images/event7.png',
    'assets/images/home_bridge.png',
    'assets/images/coastal_tour.png',
    'assets/images/greek_tour.png',
    'assets/images/islamic_tour.png',
  ];

  static String _getImageForPlace(String? category, String? title) {
    final hashCode = (title ?? '').hashCode.abs();
    return _placeholderImages[hashCode % _placeholderImages.length];
  }

  /// Load top-rated places across ALL categories.
  /// Sorted by rating (desc) → userRatingCount (desc). Returns up to [limit].
  static Future<List<PlaceModel>> getTopRatedPlaces({int limit = 10}) async {
    final List<PlaceModel> all = [];
    for (final categoryId in _categoryAssets.keys) {
      final places = await getPlacesByCategory(categoryId);
      all.addAll(places);
    }

    // Sort by rating descending, then by user rating count descending
    all.sort((a, b) {
      final ratingCmp = b.rating.compareTo(a.rating);
      if (ratingCmp != 0) return ratingCmp;
      return b.userRatingCount.compareTo(a.userRatingCount);
    });

    return all.take(limit).toList();
  }
}
