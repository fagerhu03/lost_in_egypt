import 'package:equatable/equatable.dart';

class TourEntity extends Equatable {
  final String id;
  final String guideId;
  final String title;
  final String description;
  final List<String> destinations; // Landmark names or IDs
  final double price;
  final double meetingLatitude;
  final double meetingLongitude;
  final DateTime meetingTime;
  final String frequency; // 'Daily', 'Weekly', 'Weekends', 'One-Time'
  final List<String> images;
  final int maxAttendees;
  final double rating;
  final int reviewCount;
  final DateTime createdAt;

  const TourEntity({
    required this.id,
    required this.guideId,
    required this.title,
    required this.description,
    required this.destinations,
    required this.price,
    required this.meetingLatitude,
    required this.meetingLongitude,
    required this.meetingTime,
    required this.frequency,
    required this.images,
    required this.maxAttendees,
    required this.createdAt,
    this.rating = 0.0,
    this.reviewCount = 0,
  });

  @override
  List<Object?> get props => [
        id,
        guideId,
        title,
        description,
        destinations,
        price,
        meetingLatitude,
        meetingLongitude,
        meetingTime,
        frequency,
        images,
        maxAttendees,
        rating,
        reviewCount,
        createdAt,
      ];
}
