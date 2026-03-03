import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import '../models/user.dart'; // ✅ Make sure this imports the NEW UserModel

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

  // ✅ NEW METHODS (Must return UserModel, NOT Either)
  Future<UserModel> getUserProfile(String uid);
  Future<void> updateUserProfile(UserModel user);
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
    final UserCredential result = await firebaseAuth
        .createUserWithEmailAndPassword(email: email, password: password);
    final User user = result.user!;

    // ✅ Send email verification
    if (!user.emailVerified) {
      await user.sendEmailVerification();
    }

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
      role: "tourist", // or UserRole.tourist.name if using Enum
      profileImageUrl: "",
      phoneNumber: phoneNumber ?? "",
      nationality: "",
      language: "English",
      isNotificationsEnabled: true,
      isDarkMode: false,
      createdAt: DateTime.now(),
    );

    // ✅ FIX: Use toMap(), not toDocument()
    await firestore.collection('users').doc(user.uid).set(newUser.toMap());
    return newUser;
  }

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final UserCredential result = await firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
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
    // ✅ FIX: Use fromMap()
    return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  @override
  Future<void> forgetPassword({required String email}) async {
    await firebaseAuth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<UserModel?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser == null) return null;

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final UserCredential userCredential = await firebaseAuth
        .signInWithCredential(credential);

    return _checkUserInFirestore(
      userCredential.user!.uid,
      newPhotoUrl: userCredential.user?.photoURL,
    );
  }

  @override
  Future<UserModel?> signInWithFacebook() async {
    final LoginResult result = await FacebookAuth.instance.login();

    if (result.status == LoginStatus.success) {
      final AccessToken accessToken = result.accessToken!;
      final OAuthCredential credential = FacebookAuthProvider.credential(
        accessToken.tokenString,
      );
      final UserCredential userCredential = await firebaseAuth
          .signInWithCredential(credential);

      return _checkUserInFirestore(
        userCredential.user!.uid,
        newPhotoUrl: userCredential.user?.photoURL,
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

  @override
  Future<UserModel?> signInWithApple() async {
    const mockEmail = "apple.demo@lostinegypt.com";
    const mockPassword = "AppleDemoPassword123!";

    UserCredential userCredential;
    try {
      userCredential = await firebaseAuth.signInWithEmailAndPassword(
        email: mockEmail,
        password: mockPassword,
      );
    } on FirebaseAuthException catch (_) {
      userCredential = await firebaseAuth.createUserWithEmailAndPassword(
        email: mockEmail,
        password: mockPassword,
      );
    }

    return _checkUserInFirestore(userCredential.user!.uid);
  }

  Future<UserModel?> _checkUserInFirestore(
    String uid, {
    String? newPhotoUrl,
  }) async {
    final DocumentReference docRef = firestore.collection('users').doc(uid);
    final DocumentSnapshot doc = await docRef.get();

    if (doc.exists) {
      Map<String, dynamic> updateData = {'emailVerified': true};

      if (newPhotoUrl != null && newPhotoUrl.isNotEmpty) {
        final currentData = doc.data() as Map<String, dynamic>;
        final currentPhoto = currentData['profileImageUrl'] as String?;

        if (currentPhoto == null ||
            currentPhoto.isEmpty ||
            currentPhoto != newPhotoUrl) {
          updateData['profileImageUrl'] = newPhotoUrl;
        }
      }

      // ✅ Always verify email for social logins (Google, Facebook, Apple)
      await docRef.update(updateData);
      final updatedDoc = await docRef.get();
      // ✅ FIX: fromMap
      return UserModel.fromMap(
        updatedDoc.data() as Map<String, dynamic>,
        updatedDoc.id,
      );
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
      nationality: "",
      language: "English",
      isNotificationsEnabled: true,
      isDarkMode: false,
      createdAt: DateTime.now(),
    );

    // ✅ FIX: toMap
    await firestore.collection('users').doc(user.uid).set(newUser.toMap());
  }

  // ✅ NEW: Correct Get Profile Implementation
  @override
  Future<UserModel> getUserProfile(String uid) async {
    final doc = await firestore.collection('users').doc(uid).get();

    if (doc.exists) {
      return UserModel.fromMap(doc.data()!, doc.id);
    } else {
      // Create default shell if missing
      final currentUser = firebaseAuth.currentUser;
      return UserModel(
        id: uid,
        email: currentUser?.email ?? '',
        firstName: currentUser?.displayName?.split(' ').first ?? 'User',
        lastName: '',
        birthDate: DateTime.now(),
        role: 'tourist',
        profileImageUrl: currentUser?.photoURL ?? '',
        phoneNumber: '',
        nationality: '',
        isNotificationsEnabled: true,
        isDarkMode: false,
        language: 'English',
        createdAt: DateTime.now(),
      );
    }
  }

  // ✅ NEW: Correct Update Profile Implementation
  @override
  Future<void> updateUserProfile(UserModel user) async {
    // ✅ FIX: toMap with merge
    await firestore
        .collection('users')
        .doc(user.id)
        .set(user.toMap(), SetOptions(merge: true));
  }

  int _getMonthIndex(String monthName) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    int index = months.indexOf(monthName);
    return index == -1 ? 1 : index + 1;
  }

  @override
  Future<bool> checkEmailExists(String email) async {
    try {
      // Firebase removed fetchSignInMethodsForEmail() for security/enumeration prevention.
      // The modern, secure workaround is attempting a dummy login with a bad password.
      await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: "TempInvalidPassword123!\$",
      );
      // If it surprisingly succeeds (impossible due to password), the email exists.
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        // Try the DB check, but gracefully fail if Firestore rules block unauthenticated reads
        try {
          final QuerySnapshot result = await firestore
              .collection('users')
              .where('email', isEqualTo: email)
              .get();
          return result.docs.isNotEmpty;
        } on FirebaseException catch (_) {
          // Permission Denied because user isn't logged in. 
          // If Auth says not found, and DB blocks us, we assume it's an unregistered email.
          return false;
        } catch (_) {
          return false;
        }
      } else if (e.code == 'wrong-password') {
        // The email definitely exists!
        return true;
      }
      return false; // Other errors
    } catch (e) {
      return false;
    }
  }
}
