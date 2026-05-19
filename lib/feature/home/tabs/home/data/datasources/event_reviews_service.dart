import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/event_review_model.dart';

class EventReviewsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Stream<List<EventReviewModel>> getEventReviews(String eventId) {
    return _firestore
        .collection('event_reviews')
        .where('eventId', isEqualTo: eventId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EventReviewModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  static Future<void> submitReview(EventReviewModel review, Map<String, dynamic>? initialEventData) async {
    final reviewRef = _firestore.collection('event_reviews').doc(review.id);
    final eventRef = _firestore.collection('events').doc(review.eventId);

    try {
      await _firestore.runTransaction((transaction) async {
        final eventDoc = await transaction.get(eventRef);
        double currentEventRating = 0.0;
        int eventReviewCount = 0;

        if (eventDoc.exists) {
          currentEventRating = (eventDoc.data()?['rating'] ?? 0.0).toDouble();
          eventReviewCount = eventDoc.data()?['reviewCount'] ?? 0;
        } else if (initialEventData != null) {
          // If the event doesn't exist (e.g. curated event), we initialize it
          // with the provided local data so that it's visible in Firestore.
          transaction.set(eventRef, initialEventData, SetOptions(merge: true));
        }

        final newEventReviewCount = eventReviewCount + 1;
        final newEventRating =
            ((currentEventRating * eventReviewCount) + review.rating) /
                newEventReviewCount;

        transaction.set(reviewRef, review.toMap());

        transaction.set(eventRef, {
          'rating': newEventRating,
          'reviewCount': newEventReviewCount,
        }, SetOptions(merge: true));
      });
    } catch (e) {
      debugPrint('Error submitting event review transaction: $e');
      throw Exception('Failed to submit event review');
    }
  }
}
