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
    await _firestore.collection('users').doc(userId).update({
      'applicationStatus': 'approved',
      'role': 'guide',
      'isVerifiedGuide': true,
    });
  }

  @override
  Future<void> rejectGuide(String userId, String rejectionReason) async {
    await _firestore.collection('users').doc(userId).update({
      'applicationStatus': 'rejected',
      'rejectionReason': rejectionReason,
    });
  }
}
