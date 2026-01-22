import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../map/domain/place_importance.dart';

// ==========================================================
// 1. SHARED INTERFACE (Domain Entity)
// ==========================================================
abstract class MapItem {
  String get id;
  String get title;
  GeoPoint get coordinate;
  String get category;
  String get imagePath;
  String get locationAddress;
  double get rating;
  double get price;
  String get duration;
  String get weather;
  String get description;
  List<String> get tags;
  
  // Added for Map Logic
  PlaceImportance get importance;
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
  final PlaceImportance importance;

  final bool isOpenNow;

  const PlaceModel({
    required this.id,
    required this.title,
    required this.category,
    required this.coordinate,
    required this.imagePath,
    required this.locationAddress,
    required this.rating,
    required this.price,
    required this.duration,
    required this.weather,
    required this.description,
    required this.isOpenNow,
    this.tags = const [],
    this.importance = PlaceImportance.minor,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'category': category,
      'coordinate': coordinate,
      'imagePath': imagePath,
      'locationAddress': locationAddress,
      'rating': rating,
      'price': price,
      'duration': duration,
      'weather': weather,
      'description': description,
      'isOpenNow': isOpenNow,
      'tags': tags,
    };
  }

  factory PlaceModel.fromMap(Map<String, dynamic> map, String docId, {PlaceImportance? importance}) {
    return PlaceModel(
      id: docId,
      title: map['title'] ?? '',
      category: map['category'] ?? '',
      coordinate: map['coordinate'] is GeoPoint 
          ? map['coordinate'] 
          : const GeoPoint(30.0444, 31.2357),
      imagePath: map['imagePath'] ?? '',
      locationAddress: map['locationAddress'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
      price: (map['price'] ?? 0).toDouble(),
      duration: map['duration'] ?? '',
      weather: map['weather'] ?? '',
      description: map['description'] ?? '',
      isOpenNow: map['isOpenNow'] ?? false,
      tags: (map['tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      importance: importance ?? PlaceImportance.minor,
    );
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
  final PlaceImportance importance;

  @override
  String get category => 'event';

  final DateTime date;

  const EventModel({
    required this.id,
    required this.title,
    required this.coordinate,
    required this.imagePath,
    required this.locationAddress,
    required this.rating,
    required this.price,
    required this.duration,
    required this.weather,
    required this.description,
    required this.date,
    this.tags = const [],
    this.importance = PlaceImportance.major, // Events usually important
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'coordinate': coordinate,
      'imagePath': imagePath,
      'locationAddress': locationAddress,
      'rating': rating,
      'price': price,
      'duration': duration,
      'weather': weather,
      'description': description,
      'date': Timestamp.fromDate(date),
      'isEvent': true,
      'tags': tags,
    };
  }

  factory EventModel.fromMap(Map<String, dynamic> map, String docId) {
    return EventModel(
      id: docId,
      title: map['title'] ?? '',
      coordinate: map['coordinate'] is GeoPoint 
          ? map['coordinate'] 
          : const GeoPoint(30.0444, 31.2357),
      imagePath: map['imagePath'] ?? '',
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
      importance: PlaceImportance.major,
    );
  }
}