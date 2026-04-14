import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/review_model.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../../home/notification/data/models/notification_model.dart';
import '../../../home/notification/data/datasources/notifications_data_source.dart';

abstract class ReviewsDataSource {
  Future<void> submitReview(ReviewModel review);
  Stream<List<ReviewModel>> getTourReviews(String tourId);
  Stream<List<ReviewModel>> getGuideReviews(String guideId);
}

class ReviewsDataSourceImpl implements ReviewsDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<void> submitReview(ReviewModel review) async {
    final reviewRef = _firestore.collection('reviews').doc(review.id);
    final tourRef = _firestore.collection('tours').doc(review.tourId);
    final guideRef = _firestore.collection('users').doc(review.guideId);

    try {
      await _firestore.runTransaction((transaction) async {
        final tourDoc = await transaction.get(tourRef);
        double currentTourRating = 0.0;
        int tourReviewCount = 0;

        if (tourDoc.exists) {
          currentTourRating = (tourDoc.data()?['rating'] ?? 0.0).toDouble();
          tourReviewCount = tourDoc.data()?['reviewCount'] ?? 0;
        }

        final guideDoc = await transaction.get(guideRef);
        double currentGuideRating = 0.0;
        int guideReviewCount = 0;

        if (guideDoc.exists) {
          currentGuideRating = (guideDoc.data()?['rating'] ?? 0.0).toDouble();
          guideReviewCount = guideDoc.data()?['reviewCount'] ?? 0;
        }

        final newTourReviewCount = tourReviewCount + 1;
        final newTourRating =
            ((currentTourRating * tourReviewCount) + review.rating) /
                newTourReviewCount;

        final newGuideReviewCount = guideReviewCount + 1;
        final newGuideRating =
            ((currentGuideRating * guideReviewCount) + review.rating) /
                newGuideReviewCount;

        transaction.set(reviewRef, review.toMap());

        transaction.update(tourRef, {
          'rating': newTourRating,
          'reviewCount': newTourReviewCount,
        });

        transaction.update(guideRef, {
          'rating': newGuideRating,
          'reviewCount': newGuideReviewCount,
        });
      });

      // Notify the guide after a successful review
      if (review.guideId.isNotEmpty && review.guideId != review.touristId) {
        try {
          final tourDoc =
              await _firestore.collection('tours').doc(review.tourId).get();
          final tourTitle =
              tourDoc.exists ? (tourDoc.data()?['title'] ?? 'your tour') : 'your tour';
          final stars = review.rating.toStringAsFixed(1);
          final displayName =
              review.userName.isNotEmpty ? review.userName : 'Someone';

          final notif = NotificationModel(
            id: const Uuid().v4(),
            recipientId: review.guideId,
            senderId: review.touristId,
            senderName: displayName,
            senderAvatar: review.userImage,
            title: 'New Review ⭐$stars',
            message: 'reviewed "$tourTitle"',
            type: 'review',
            deepLinkTargetId: review.tourId,
            isRead: false,
            timestamp: DateTime.now(),
          );

          await NotificationsDataSourceImpl().sendNotification(notif);
        } catch (e) {
          debugPrint('Failed to send review notification: $e');
        }
      }
    } catch (e) {
      debugPrint('Error submitting review transaction: $e');
      throw Exception('Failed to submit review');
    }
  }

  @override
  Stream<List<ReviewModel>> getGuideReviews(String guideId) {
    return _firestore
        .collection('reviews')
        .where('guideId', isEqualTo: guideId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReviewModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  @override
  Stream<List<ReviewModel>> getTourReviews(String tourId) {
    return _firestore
        .collection('reviews')
        .where('tourId', isEqualTo: tourId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReviewModel.fromMap(doc.data(), doc.id))
            .toList());
  }
}
