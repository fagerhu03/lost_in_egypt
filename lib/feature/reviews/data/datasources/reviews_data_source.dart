import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/review_model.dart';
import 'package:flutter/foundation.dart';

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
        // 1. Get current tour
        final tourDoc = await transaction.get(tourRef);
        double currentTourRating = 0.0;
        int tourReviewCount = 0;

        if (tourDoc.exists) {
          currentTourRating = (tourDoc.data()?['rating'] ?? 0.0).toDouble();
          tourReviewCount = tourDoc.data()?['reviewCount'] ?? 0;
        }

        // 2. Get current guide profile
        final guideDoc = await transaction.get(guideRef);
        double currentGuideRating = 0.0;
        int guideReviewCount = 0;

        if (guideDoc.exists) {
           currentGuideRating = (guideDoc.data()?['rating'] ?? 0.0).toDouble();
           guideReviewCount = guideDoc.data()?['reviewCount'] ?? 0;
        }

        // 3. Calculate new Tour Averages
        int newTourReviewCount = tourReviewCount + 1;
        double newTourRating = ((currentTourRating * tourReviewCount) + review.rating) / newTourReviewCount;

        // 4. Calculate new Guide Averages
        int newGuideReviewCount = guideReviewCount + 1;
        double newGuideRating = ((currentGuideRating * guideReviewCount) + review.rating) / newGuideReviewCount;

        // 5. Atomic writes
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
    } catch (e) {
      debugPrint("Error submitting review transaction: $e");
      throw Exception("Failed to submit review");
    }
  }

  @override
  Stream<List<ReviewModel>> getGuideReviews(String guideId) {
    return _firestore
        .collection('reviews')
        .where('guideId', isEqualTo: guideId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ReviewModel.fromMap(doc.data(), doc.id)).toList());
  }

  @override
  Stream<List<ReviewModel>> getTourReviews(String tourId) {
    return _firestore
        .collection('reviews')
        .where('tourId', isEqualTo: tourId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ReviewModel.fromMap(doc.data(), doc.id)).toList());
  }
}
