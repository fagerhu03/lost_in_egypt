import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/notification_model.dart';

abstract class NotificationsDataSource {
  Stream<List<NotificationModel>> getNotifications(String userId);
  Stream<int> getUnreadCount(String userId);
  Future<void> sendNotification(NotificationModel notification);
  Future<void> markAsRead(String userId, String notificationId);
  Future<void> markAllAsRead(String userId);
  Future<void> deleteNotification(String userId, String notificationId);
}

class NotificationsDataSourceImpl implements NotificationsDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<List<NotificationModel>> getNotifications(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  @override
  Stream<int> getUnreadCount(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  @override
  Future<void> sendNotification(NotificationModel notification) async {
    final userDoc = await _firestore.collection('users').doc(notification.recipientId).get();

    if (!userDoc.exists) {
      debugPrint('sendNotification: recipient ${notification.recipientId} not found, dropping notification.');
      return;
    }

    final data = userDoc.data()!;
    bool shouldSend = true;
    final prefs = data['notificationPreferences'] as Map<String, dynamic>?;

    if (prefs != null) {
      if (notification.type == 'like' && prefs['likes'] == false) shouldSend = false;
      if (notification.type == 'comment' && prefs['comments'] == false) shouldSend = false;
      if (notification.type == 'booking' && prefs['bookings'] == false) shouldSend = false;
      // 'admin' and 'system' types cannot be opted out of
    }

    if (shouldSend) {
      await _firestore
          .collection('users')
          .doc(notification.recipientId)
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toMap(), SetOptions(merge: true));
    }
  }

  @override
  Future<void> markAsRead(String userId, String notificationId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  @override
  Future<void> deleteNotification(String userId, String notificationId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .delete();
  }
}
