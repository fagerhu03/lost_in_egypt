import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/booking_entity.dart';

class BookingModel extends BookingEntity {
  const BookingModel({
    required super.id,
    required super.tourId,
    required super.userId,
    required super.guideId,
    required super.status,
    required super.paymentReference,
    required super.paymentStatus,
    required super.date,
    required super.createdAt,
    super.quantity = 1,
    super.totalAmountEGP = 0,
    super.sessionDate,
  });

  factory BookingModel.fromMap(Map<String, dynamic> data, String documentId) {
    return BookingModel(
      id: documentId,
      tourId: data['tourId'] ?? '',
      userId: data['userId'] ?? '',
      guideId: data['guideId'] ?? '',
      status: data['status'] ?? 'pending',
      paymentReference: data['paymentReference'] ?? '',
      paymentStatus: data['paymentStatus'] ?? 'none',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      quantity: (data['quantity'] as num?)?.toInt() ?? 1,
      totalAmountEGP: (data['totalAmountEGP'] as num?)?.toDouble() ?? 0,
      sessionDate: (data['sessionDate'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tourId': tourId,
      'userId': userId,
      'guideId': guideId,
      'status': status,
      'paymentReference': paymentReference,
      'paymentStatus': paymentStatus,
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(createdAt),
      'quantity': quantity,
      'totalAmountEGP': totalAmountEGP,
      if (sessionDate != null) 'sessionDate': Timestamp.fromDate(sessionDate!),
    };
  }
}
