import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/review_entity.dart';

class ReviewModel extends ReviewEntity {
  const ReviewModel({
    required super.id,
    required super.tourId,
    required super.guideId,
    required super.touristId,
    required super.rating,
    required super.comment,
    required super.createdAt,
    super.userName,
    super.userImage,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> map, String id) {
    return ReviewModel(
      id: id,
      tourId: map['tourId'] ?? '',
      guideId: map['guideId'] ?? '',
      touristId: map['touristId'] ?? map['userId'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      comment: map['comment'] ?? map['text'] ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      userName: map['userName'] ?? '',
      userImage: map['userImage'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tourId': tourId,
      'guideId': guideId,
      'touristId': touristId,
      'userId': touristId,    // alias — tour_detail_screen reads 'userId'
      'rating': rating,
      'comment': comment,
      'text': comment,        // alias — tour_detail_screen reads 'text'
      'userName': userName,
      'userImage': userImage,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
