import 'package:equatable/equatable.dart';

class BookingEntity extends Equatable {
  final String id;
  final String tourId;
  final String userId;
  final String guideId;
  final String status; // 'pending', 'confirmed', 'completed', 'cancelled'
  final String paymentReference;
  final String paymentStatus;
  final DateTime date;
  final DateTime createdAt;

  const BookingEntity({
    required this.id,
    required this.tourId,
    required this.userId,
    required this.guideId,
    required this.status,
    required this.paymentReference,
    required this.paymentStatus,
    required this.date,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        tourId,
        userId,
        guideId,
        status,
        paymentReference,
        paymentStatus,
        date,
        createdAt,
      ];
}
