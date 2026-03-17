import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/notification_model.dart';

abstract class NotificationsDataSource {
  Stream<List<NotificationModel>> getNotifications(String userId);
  Stream<int> getUnreadCount(String userId);
  Future<void> sendNotification(NotificationModel notification);
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead(String userId);
  Future<void> deleteNotification(String notificationId);
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
    // 1. Fetch User Preferences to determine if this notification type is allowed
    // Note: User preferences are stored within the user document per Phase 3 specifications.
    final userDoc = await _firestore.collection('users').doc(notification.recipientId).get();
    
    if (userDoc.exists) {
      final data = userDoc.data()!;
      
      // Defaulting to true if the preference map isn't explicit
      bool shouldSend = true;
      final prefs = data['notificationPreferences'] as Map<String, dynamic>?;

      if (prefs != null) {
        if (notification.type == 'like' && prefs['likes'] == false) shouldSend = false;
        if (notification.type == 'comment' && prefs['comments'] == false) shouldSend = false;
        if (notification.type == 'booking' && prefs['bookings'] == false) shouldSend = false;
        // admin and reminders cannot be opted out of for safety reasons
      }

      if (shouldSend) {
        // 2. Write Notification to the subcollection
        await _firestore
            .collection('users')
            .doc(notification.recipientId)
            .collection('notifications')
            .doc(notification.id)
            .set(notification.toMap(), SetOptions(merge: true));
            
        // 3. Trigger Local Push Notification
        // Since Flutter Local Notifications handles the foreground/background delivery, 
        // a Cloud Function or FCM trigger (Node.js) usually handles this, but since we are running 
        // completely serverless and requested local push, the client app that initiated the action 
        // could theoretially trigger it, but standard practice triggers an HTTP / FCM boundary.
        // For the scope of 'local push notifications' requested by the user, we will map a listener in the UI.
      }
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    // To mark as read securely, run a collectionGroup query or require the recipientId.
    // For simplicity, we query the subcollection group.
    final query = await _firestore
        .collectionGroup('notifications')
        .where(FieldPath.documentId, isEqualTo: notificationId)
        .get();

    for (var doc in query.docs) {
      await doc.reference.update({'isRead': true});
    }
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
  Future<void> deleteNotification(String notificationId) async {
    final query = await _firestore
        .collectionGroup('notifications')
        .where(FieldPath.documentId, isEqualTo: notificationId)
        .get();

    for (var doc in query.docs) {
      await doc.reference.delete();
    }
  }
}
