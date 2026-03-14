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
  });

  factory TourModel.fromMap(Map<String, dynamic> data, String documentId) {
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
      maxAttendees: data['maxAttendees'] ?? 10,
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
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
      'rating': rating,
      'reviewCount': reviewCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
