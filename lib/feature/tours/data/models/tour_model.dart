import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/tour_entity.dart';

class TourModel extends TourEntity {
  const TourModel({
    required super.id,
    required super.guideId,
    required super.title,
    required super.description,
    required super.destinations,
    required super.price,
    required super.meetingLatitude,
    required super.meetingLongitude,
    required super.meetingTime,
    required super.frequency,
    required super.meetingLocationName,
    required super.images,
    required super.maxAttendees,
    required super.createdAt,
    super.rating,
    super.reviewCount,
    super.totalCapacity,
    super.recurrenceType,
    super.recurrenceDays,
    super.meetingTimeOfDay,
    super.nextOccurrence,
    super.isArchived,
  });

  factory TourModel.fromMap(Map<String, dynamic> data, String documentId) {
    final maxAttendees = (data['maxAttendees'] as num?)?.toInt() ?? 10;
    return TourModel(
      id: documentId,
      guideId: data['guideId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      destinations: List<String>.from(data['destinations'] ?? []),
      price: (data['price'] ?? 0.0).toDouble(),
      meetingLatitude: (data['meetingLatitude'] ?? 0.0).toDouble(),
      meetingLongitude: (data['meetingLongitude'] ?? 0.0).toDouble(),
      meetingTime: (data['meetingTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      frequency: data['frequency'] ?? 'One-Time',
      meetingLocationName: data['meetingLocationName'] ?? 'Unknown Location',
      images: List<String>.from(data['images'] ?? []),
      maxAttendees: maxAttendees,
      rating: _sanitizeRating((data['rating'] ?? 0.0).toDouble()),
      reviewCount: data['reviewCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      // Phase 1 fields with backward-compatible defaults
      totalCapacity: (data['totalCapacity'] as num?)?.toInt() ?? maxAttendees,
      recurrenceType: data['recurrenceType'] as String? ?? _inferRecurrenceType(data['frequency'] as String?),
      recurrenceDays: (data['recurrenceDays'] as List?)?.map((e) => e as int).toList() ??
          _inferRecurrenceDays(data['frequency'] as String?),
      meetingTimeOfDay: data['meetingTimeOfDay'] as String? ?? '',
      nextOccurrence: (data['nextOccurrence'] as Timestamp?)?.toDate(),
      isArchived: data['isArchived'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'guideId': guideId,
      'title': title,
      'description': description,
      'destinations': destinations,
      'price': price,
      'meetingLatitude': meetingLatitude,
      'meetingLongitude': meetingLongitude,
      'meetingTime': Timestamp.fromDate(meetingTime),
      'frequency': frequency,
      'meetingLocationName': meetingLocationName,
      'images': images,
      'maxAttendees': maxAttendees,
      'rating': _sanitizeRating(rating),
      'reviewCount': reviewCount,
      'createdAt': Timestamp.fromDate(createdAt),
      // Phase 1 fields
      'totalCapacity': totalCapacity,
      'recurrenceType': recurrenceType,
      'recurrenceDays': recurrenceDays,
      'meetingTimeOfDay': meetingTimeOfDay,
      if (nextOccurrence != null) 'nextOccurrence': Timestamp.fromDate(nextOccurrence!),
      'isArchived': isArchived,
    };
  }

  static double _sanitizeRating(double val) {
    if (val.isNaN || val.isInfinite) return 0.0;
    return val;
  }

  static String _inferRecurrenceType(String? frequency) {
    if (frequency == null || frequency.isEmpty || frequency == 'One-Time') return 'one_time';
    if (frequency.toLowerCase() == 'daily') return 'daily';
    final days = frequency.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    return days.length == 1 ? 'weekly' : 'custom';
  }

  static const _dayNameToIndex = {
    'Mon': 0, 'Tue': 1, 'Wed': 2, 'Thu': 3, 'Fri': 4, 'Sat': 5, 'Sun': 6,
    'Monday': 0, 'Tuesday': 1, 'Wednesday': 2, 'Thursday': 3,
    'Friday': 4, 'Saturday': 5, 'Sunday': 6,
  };

  static List<int> _inferRecurrenceDays(String? frequency) {
    if (frequency == null || frequency.isEmpty || frequency == 'One-Time' || frequency.toLowerCase() == 'daily') return [];
    return frequency
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .map((s) => _dayNameToIndex[s])
        .whereType<int>()
        .toList();
  }
}
