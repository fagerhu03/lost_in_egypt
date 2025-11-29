import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required String id,
    required String email,
    required String firstName,
    required String lastName,
    required DateTime birthDate,
    required String role,
    required String profileImageUrl,
    required String phoneNumber,
    required String language,
    required Map<String, dynamic> preferences,
  }) : super(
          id: id,
          email: email,
          firstName: firstName,
          lastName: lastName,
          birthDate: birthDate,
          role: role,
          profileImageUrl: profileImageUrl,
        );

  // 1. Send to Firestore
  Map<String, dynamic> toDocument() {
    return {
      "email": email,
      "firstName": firstName,
      "lastName": lastName,
      "birthDate": Timestamp.fromDate(birthDate),
      "role": role,
      "profileImageUrl": profileImageUrl,
      "createdAt": FieldValue.serverTimestamp(),
    };
  }

  // 2. Read from Firestore
  factory UserModel.fromSnapshot(DocumentSnapshot snap) {
    var data = snap.data() as Map<String, dynamic>;
    return UserModel(
      id: snap.id,
      email: data['email'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      // Forces a crash if date is missing (Good for strict debugging)
      birthDate: (data['birthDate'] as Timestamp).toDate(),
      role: data['role'] ?? 'tourist',
      profileImageUrl: data['profileImageUrl'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      language: data['language'] ?? 'en',
      preferences: data['preferences'] is Map ? data['preferences'] : {},
    );
  }
}