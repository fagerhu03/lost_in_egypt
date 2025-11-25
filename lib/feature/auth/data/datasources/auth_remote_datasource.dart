import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import '../models/user.dart'; 

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

  Future<void> completeSocialProfile({
    required String birthMonth,
    required String birthDay,
    required String birthYear,
  });
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
    return _checkUserInFirestore(userCredential.user!.uid);
  }

  // --- FACEBOOK IMPLEMENTATION ---
  @override
  Future<UserModel?> signInWithFacebook() async {
    // 1. Trigger Facebook Login
    final LoginResult result = await FacebookAuth.instance.login();

    if (result.status == LoginStatus.success) {
      final AccessToken accessToken = result.accessToken!;

      // 2. Create Credential
      final OAuthCredential credential = FacebookAuthProvider.credential(accessToken.tokenString);

      // 3. Sign in to Firebase
      final UserCredential userCredential = await firebaseAuth.signInWithCredential(credential);

      // 4. Check Firestore (Reuse logic)
      return _checkUserInFirestore(userCredential.user!.uid);
    } else if (result.status == LoginStatus.cancelled) {
      return null;
    } else {
      throw FirebaseAuthException(
        code: 'facebook-login-failed',
        message: result.message ?? "Facebook login failed",
      );
    }
  }

  // Helper method to avoid duplicating code between Google and Facebook
  Future<UserModel?> _checkUserInFirestore(String uid) async {
    final DocumentSnapshot doc = await firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromSnapshot(doc);
    } else {
      return null; // Needs profile completion
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

    String firstName = "";
    String lastName = "";
    if (user.displayName != null) {
      final names = user.displayName!.split(" ");
      firstName = names.first;
      if (names.length > 1) lastName = names.sublist(1).join(" ");
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
}