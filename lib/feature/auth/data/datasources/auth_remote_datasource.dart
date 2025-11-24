import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;

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
    // 1. Create User in Firebase Authentication
    final UserCredential result = await firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final User user = result.user!;

    // 2. Logic to convert Dropdown Strings to DateTime
    // This assumes the inputs are valid strings (validated by UI regex)
    int monthIndex = _getMonthIndex(birthMonth);
    int day = int.parse(birthDay);
    int year = int.parse(birthYear);
    DateTime parsedBirthDate = DateTime(year, monthIndex, day);

    // 3. Create Model with default values for new users
    final newUser = UserModel(
      id: user.uid,
      email: email,
      firstName: firstName,
      lastName: lastName,
      birthDate: parsedBirthDate,
      role: "tourist", // Default role
      profileImageUrl: "",
      phoneNumber: phoneNumber ?? "", // Handle empty phone
      language: "en", // Default language
      preferences: {}, // Empty map
    );

    // 4. Save to Firestore 'users' collection
    await firestore.collection('users').doc(user.uid).set(newUser.toDocument());

    return newUser;
  }

  // Helper to convert "January" -> 1
  int _getMonthIndex(String monthName) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    // Returns index + 1 (Jan = 1), defaults to 1 if not found
    int index = months.indexOf(monthName);
    return index == -1 ? 1 : index + 1;
  }
}