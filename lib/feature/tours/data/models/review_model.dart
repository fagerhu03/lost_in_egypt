import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String userId;
  final String userName;
  final String userImage;
  final double rating;
  final String text;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userImage,
    required this.rating,
    required this.text,
    required this.createdAt,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> data, String id) {
    return ReviewModel(
      id: id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Anonymous',
      userImage: data['userImage'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      text: data['text'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userImage': userImage,
      'rating': rating,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
