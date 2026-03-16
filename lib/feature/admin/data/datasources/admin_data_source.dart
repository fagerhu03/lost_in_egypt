import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../feature/auth/data/models/user.dart';

abstract class AdminDataSource {
  Future<List<UserModel>> getPendingGuides();
  Future<void> approveGuide(String userId);
  Future<void> rejectGuide(String userId, String rejectionReason);
}

class AdminDataSourceImpl implements AdminDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<UserModel>> getPendingGuides() async {
    final snapshot = await _firestore
        .collection('users')
        .where('applicationStatus', isEqualTo: 'pending')
        .get();

    return snapshot.docs.map((doc) => UserModel.fromMap(doc.data(), doc.id)).toList();
  }

  @override
  Future<void> approveGuide(String userId) async {
    // 1. Update user role
    await _firestore.collection('users').doc(userId).update({
      'applicationStatus': 'approved',
      'role': 'guide',
      'isVerifiedGuide': true,
    });

    // 2. Send notification to the guide
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .add({
      'recipientId': userId,
      'senderId': 'system_admin',
      'senderName': 'Lost in Egypt Team',
      'senderAvatar': '', 
      'title': 'Application Approved! 🎉',
      'message': 'Congratulations! Your application to become a guide has been approved. You can now access the guide dashboard and create tours.',
      'type': 'system',
      'isRead': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> rejectGuide(String userId, String rejectionReason) async {
    // 1. Update user application status
    await _firestore.collection('users').doc(userId).update({
      'applicationStatus': 'rejected',
      'rejectionReason': rejectionReason,
    });

    // 2. Send notification to the user
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .add({
      'recipientId': userId,
      'senderId': 'system_admin',
      'senderName': 'Lost in Egypt Team',
      'senderAvatar': '', 
      'title': 'Application Update',
      'message': 'Your guide application was reviewed but could not be approved at this time.\nReason: $rejectionReason\n\nYou may update your details and apply again.',
      'type': 'system',
      'isRead': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
