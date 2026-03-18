import 'package:equatable/equatable.dart';

class ReviewEntity extends Equatable {
  final String id;
  final String tourId;
  final String guideId;
  final String touristId;
  final double rating;
  final String comment;
  final DateTime createdAt;

  const ReviewEntity({
    required this.id,
    required this.tourId,
    required this.guideId,
    required this.touristId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        tourId,
        guideId,
        touristId,
        rating,
        comment,
        createdAt,
      ];
}
