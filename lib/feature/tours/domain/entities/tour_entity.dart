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
  final String frequency; // Human-readable display string
  final String meetingLocationName;
  final List<String> images;
  final int maxAttendees; // Remaining spots
  final double rating;
  final int reviewCount;
  final DateTime createdAt;

  // Phase 1: Tour Scheduling Overhaul fields
  final int totalCapacity; // Original max, immutable
  final String recurrenceType; // 'one_time' | 'weekly' | 'daily' | 'custom'
  final List<int> recurrenceDays; // [0=Mon...6=Sun], used for 'weekly' and 'custom'
  final String meetingTimeOfDay; // "HH:mm" string (e.g. "09:00")
  final DateTime? nextOccurrence; // Pre-computed next date
  final bool isArchived; // Default false

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
    required this.meetingLocationName,
    required this.images,
    required this.maxAttendees,
    required this.createdAt,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.totalCapacity = 0,
    this.recurrenceType = 'one_time',
    this.recurrenceDays = const [],
    this.meetingTimeOfDay = '',
    this.nextOccurrence,
    this.isArchived = false,
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
        meetingLocationName,
        images,
        maxAttendees,
        rating,
        reviewCount,
        createdAt,
        totalCapacity,
        recurrenceType,
        recurrenceDays,
        meetingTimeOfDay,
        nextOccurrence,
        isArchived,
      ];
}
