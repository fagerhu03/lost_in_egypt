import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

abstract class GuideApplicationDataSource {
  Future<void> submitApplication({
    required String motaLicenseNumber,
    required String syndicateNumber,
    required List<String> certifiedLanguages,
    required File motaLicenseImage,
    required File syndicateCardImage,
    required File nationalIdFrontImage,
    required File nationalIdBackImage,
    required File selfieWithIdImage,
    required File profileImage,
  });
}

class GuideApplicationDataSourceImpl implements GuideApplicationDataSource {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  Future<void> submitApplication({
    required String motaLicenseNumber,
    required String syndicateNumber,
    required List<String> certifiedLanguages,
    required File motaLicenseImage,
    required File syndicateCardImage,
    required File nationalIdFrontImage,
    required File nationalIdBackImage,
    required File selfieWithIdImage,
    required File profileImage,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    // 1. Upload all 5 images to Firebase Storage
    final motaUrl = await _uploadImage(motaLicenseImage, user.uid, 'mota_license');
    final syndicateUrl = await _uploadImage(syndicateCardImage, user.uid, 'syndicate_card');
    final idFrontUrl = await _uploadImage(nationalIdFrontImage, user.uid, 'national_id_front');
    final idBackUrl = await _uploadImage(nationalIdBackImage, user.uid, 'national_id_back');
    final selfieUrl = await _uploadImage(selfieWithIdImage, user.uid, 'selfie_with_id');
    final profileUrl = await _uploadImage(profileImage, user.uid, 'guide_profile');

    // 2. Prepare guide documents map
    final guideDocuments = {
      'motaLicense': motaUrl,
      'syndicateCard': syndicateUrl,
      'nationalIdFront': idFrontUrl,
      'nationalIdBack': idBackUrl,
      'selfieWithId': selfieUrl,
    };

    // 3. Update Firestore User Document
    await _firestore.collection('users').doc(user.uid).update({
      'applicationStatus': 'pending',
      'motaLicenseNumber': motaLicenseNumber,
      'syndicateNumber': syndicateNumber,
      'certifiedLanguages': certifiedLanguages,
      'guideDocuments': guideDocuments,
      // update profile image as well if user submitted a professional one
      'profileImageUrl': profileUrl,
    });
  }

  Future<String> _uploadImage(File image, String uid, String suffix) async {
    final ext = path.extension(image.path);
    final ref = _storage.ref().child('guide_applications/$uid/${suffix}_${DateTime.now().millisecondsSinceEpoch}$ext');
    final uploadTask = await ref.putFile(image);
    return await uploadTask.ref.getDownloadURL();
  }
}
