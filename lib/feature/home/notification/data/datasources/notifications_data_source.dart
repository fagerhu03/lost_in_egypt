import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/notification_model.dart';
import '../../domain/services/local_notification_service.dart';

abstract class NotificationsDataSource {
  Stream<List<NotificationModel>> getNotifications(String userId);
  Stream<int> getUnreadCount(String userId);
  Future<void> sendNotification(NotificationModel notification);
  Future<void> markAsRead(String userId, String notificationId);
  Future<void> markAllAsRead(String userId);
  Future<void> deleteNotification(String userId, String notificationId);
  void startListeningForNewNotifications(String userId);
  void stopListening();
}

class NotificationsDataSourceImpl implements NotificationsDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<QuerySnapshot>? _notifSubscription;
  final Set<String> _seenNotificationIds = {};
  bool _isFirstSnapshot = true;

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

  @override
  void startListeningForNewNotifications(String userId) {
    _notifSubscription?.cancel();
    _seenNotificationIds.clear();
    _isFirstSnapshot = true;

    _notifSubscription = _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .snapshots()
        .listen((snapshot) {
      if (_isFirstSnapshot) {
        // Populate known IDs so we don't re-notify about existing ones
        _seenNotificationIds.addAll(snapshot.docs.map((d) => d.id));
        _isFirstSnapshot = false;
        return;
      }

      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added &&
            !_seenNotificationIds.contains(change.doc.id)) {
          _seenNotificationIds.add(change.doc.id);
          final data = change.doc.data()!;
          final senderName = (data['senderName'] ?? '') as String;
          final title = (data['title'] as String? ?? '');
          final message = (data['message'] ?? data['body'] ?? '') as String;
          // Include sender name in the notification body so the popup reads
          // e.g. "New Like / John Doe liked your post." instead of just "liked your post."
          final body = senderName.isNotEmpty ? '$senderName $message' : message;
          if (title.isNotEmpty || body.isNotEmpty) {
            LocalNotificationService().showLocalNotification(
              id: change.doc.id.hashCode.abs() % 100000,
              title: title,
              body: body,
            );
          }
        }
      }
    }, onError: (e) {
      debugPrint('NotificationListener error: $e');
    });
  }

  @override
  void stopListening() {
    _notifSubscription?.cancel();
    _notifSubscription = null;
    _seenNotificationIds.clear();
    _isFirstSnapshot = true;
  }
}
