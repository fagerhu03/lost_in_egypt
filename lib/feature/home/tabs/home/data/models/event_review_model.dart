import 'package:cloud_firestore/cloud_firestore.dart';

class EventReviewModel {
  final String id;
  final String eventId;
  final String userId;
  final double rating;
  final String comment;
  final String userName;
  final String userImage;
  final DateTime createdAt;

  const EventReviewModel({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.userName = '',
    this.userImage = '',
  });

  factory EventReviewModel.fromMap(Map<String, dynamic> map, String id) {
    return EventReviewModel(
      id: id,
      eventId: map['eventId'] ?? '',
      userId: map['userId'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      comment: map['comment'] ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      userName: map['userName'] ?? '',
      userImage: map['userImage'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'userId': userId,
      'rating': rating,
      'comment': comment,
      'userName': userName,
      'userImage': userImage,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
