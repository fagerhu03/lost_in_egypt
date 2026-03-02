import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../auth/data/models/user.dart';

class SettingsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<UserModel?> fetchCurrentUser() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
    } catch (e) {
      // Handle error or log it
    }
    return null;
  }

  Future<void> updateSetting(UserModel user, String key, dynamic value) async {
    final updatedUser = UserModel(
      id: user.id,
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName,
      birthDate: user.birthDate,
      role: user.role,
      profileImageUrl: user.profileImageUrl,
      phoneNumber: user.phoneNumber,
      nationality: user.nationality,
      isNotificationsEnabled: key == 'notif' ? value : user.isNotificationsEnabled,
      isDarkMode: key == 'theme' ? value : user.isDarkMode,
      language: key == 'lang' ? value : user.language,
      createdAt: user.createdAt,
      phoneVerified: user.phoneVerified,
      emailVerified: user.emailVerified,
      instagramHandle: user.instagramHandle,
      twitterHandle: user.twitterHandle,
      bio: user.bio,
      interests: user.interests,
      visitedLandmarks: key == 'visitedLandmarks' ? value : user.visitedLandmarks,
    );

    await _firestore
        .collection('users')
        .doc(user.id)
        .set(updatedUser.toMap(), SetOptions(merge: true));
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
