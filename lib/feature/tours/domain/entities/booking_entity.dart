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
  final int quantity;
  final double totalAmountEGP;

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
    this.quantity = 1,
    this.totalAmountEGP = 0,
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
        quantity,
        totalAmountEGP,
      ];
}
