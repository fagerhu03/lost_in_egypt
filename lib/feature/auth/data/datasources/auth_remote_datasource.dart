import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import '../models/user.dart'; // Verify this path matches your project

abstract class AuthRemoteDataSource {
  Future<UserModel> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String birthMonth,
    required String birthDay,   
    required String birthYear,  
    String? phoneNumber,
  });

  Future<UserModel> login({required String email, required String password});
  
  Future<void> forgetPassword({required String email});

  Future<UserModel?> signInWithGoogle();
  
  Future<UserModel?> signInWithFacebook();

  Future<UserModel?> signInWithApple();

  Future<void> completeSocialProfile({
    required String birthMonth,
    required String birthDay,
    required String birthYear,
  });
  Future<bool> checkEmailExists(String email);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;
  final GoogleSignIn googleSignIn = GoogleSignIn();

  AuthRemoteDataSourceImpl({
    required this.firebaseAuth,
    required this.firestore,
  });

  @override
  Future<UserModel> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String birthMonth,
    required String birthDay,
    required String birthYear,
    String? phoneNumber,
  }) async {
    final UserCredential result = await firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final User user = result.user!;

    int monthIndex = _getMonthIndex(birthMonth);
    int day = int.parse(birthDay);
    int year = int.parse(birthYear);
    DateTime parsedBirthDate = DateTime(year, monthIndex, day);

    final newUser = UserModel(
      id: user.uid,
      email: email,
      firstName: firstName,
      lastName: lastName,
      birthDate: parsedBirthDate,
      role: "tourist",
      profileImageUrl: "",
      phoneNumber: phoneNumber ?? "",
      language: "en",
      preferences: {},
    );

    await firestore.collection('users').doc(user.uid).set(newUser.toDocument());
    return newUser;
  }

  @override
  Future<UserModel> login({required String email, required String password}) async {
    final UserCredential result = await firebaseAuth.signInWithEmailAndPassword(
      email: email, 
      password: password
    );
    
    final DocumentSnapshot doc = await firestore
        .collection('users')
        .doc(result.user!.uid)
        .get();

    if (!doc.exists) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'User authenticated but profile data is missing.',
      );
    }
    return UserModel.fromSnapshot(doc);
  }

  @override
  Future<void> forgetPassword({required String email}) async {
    await firebaseAuth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<UserModel?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser == null) return null; 

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final UserCredential userCredential = await firebaseAuth.signInWithCredential(credential);
    
    // FIX: Pass the Google Photo URL to the check function
    return _checkUserInFirestore(
      userCredential.user!.uid, 
      newPhotoUrl: userCredential.user?.photoURL
    );
  }

  @override
  Future<UserModel?> signInWithFacebook() async {
    final LoginResult result = await FacebookAuth.instance.login();

    if (result.status == LoginStatus.success) {
      final AccessToken accessToken = result.accessToken!;
      final OAuthCredential credential = FacebookAuthProvider.credential(accessToken.tokenString);
      final UserCredential userCredential = await firebaseAuth.signInWithCredential(credential);
      
      // FIX: Pass Facebook Photo URL (if available)
      return _checkUserInFirestore(
        userCredential.user!.uid,
        newPhotoUrl: userCredential.user?.photoURL
      );
    } else if (result.status == LoginStatus.cancelled) {
      return null;
    } else {
      throw FirebaseAuthException(
        code: 'facebook-login-failed',
        message: result.message ?? "Facebook login failed",
      );
    }
  }

  // --- MOCK APPLE IMPLEMENTATION ---
  @override
  Future<UserModel?> signInWithApple() async {
    const mockEmail = "apple.demo@lostinegypt.com";
    const mockPassword = "AppleDemoPassword123!";
    
    UserCredential userCredential;
    try {
      userCredential = await firebaseAuth.signInWithEmailAndPassword(
        email: mockEmail, 
        password: mockPassword
      );
    } on FirebaseAuthException catch (_) {
      userCredential = await firebaseAuth.createUserWithEmailAndPassword(
        email: mockEmail, 
        password: mockPassword
      );
    }

    return _checkUserInFirestore(userCredential.user!.uid);
  }

  // Helper
  Future<UserModel?> _checkUserInFirestore(String uid, {String? newPhotoUrl}) async {
    final DocumentReference docRef = firestore.collection('users').doc(uid);
    final DocumentSnapshot doc = await docRef.get();

    if (doc.exists) {
      // 1. If we have a new photo (e.g. from Google) and it's different, UPDATE IT.
      if (newPhotoUrl != null && newPhotoUrl.isNotEmpty) {
        final currentData = doc.data() as Map<String, dynamic>;
        final currentPhoto = currentData['profileImageUrl'] as String?;

        // If current photo is empty OR different from new one -> Update DB
        if (currentPhoto == null || currentPhoto.isEmpty || currentPhoto != newPhotoUrl) {
          await docRef.update({'profileImageUrl': newPhotoUrl});
          
          // Fetch fresh data after update
          final updatedDoc = await docRef.get();
          return UserModel.fromSnapshot(updatedDoc);
        }
      }
      return UserModel.fromSnapshot(doc);
    } else {
      return null; 
    }
  }

  @override
  Future<void> completeSocialProfile({
    required String birthMonth,
    required String birthDay,
    required String birthYear,
  }) async {
    final user = firebaseAuth.currentUser;
    if (user == null) throw Exception("No authenticated user found");

    int monthIndex = _getMonthIndex(birthMonth);
    int day = int.parse(birthDay);
    int year = int.parse(birthYear);
    DateTime parsedBirthDate = DateTime(year, monthIndex, day);

    String firstName = "Apple"; 
    String lastName = "User";

    if (user.displayName != null && user.displayName!.isNotEmpty) {
      final names = user.displayName!.split(" ");
      firstName = names.first;
      if (names.length > 1) lastName = names.sublist(1).join(" ");
    } else if (user.email == "apple.demo@lostinegypt.com") {
        firstName = "Apple";
        lastName = "Demo";
    }

    final newUser = UserModel(
      id: user.uid,
      email: user.email ?? "",
      firstName: firstName,
      lastName: lastName,
      birthDate: parsedBirthDate,
      role: "tourist",
      profileImageUrl: user.photoURL ?? "",
      phoneNumber: "",
      language: "en",
      preferences: {},
    );

    await firestore.collection('users').doc(user.uid).set(newUser.toDocument());
  }

  int _getMonthIndex(String monthName) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    int index = months.indexOf(monthName);
    return index == -1 ? 1 : index + 1;
  }
  @override
  Future<bool> checkEmailExists(String email) async {
    try {
      // NEW STRATEGY: Query Firestore 'users' collection
      final QuerySnapshot result = await firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      // If we found any documents, the email exists
      return result.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}