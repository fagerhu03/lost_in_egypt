import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.firstName,
    required super.lastName,
    required super.birthDate,
    required super.role,
    required super.profileImageUrl,
    super.phoneNumber,
    super.nationality,
    super.isNotificationsEnabled,
    super.isDarkMode,
    super.language,
    super.bio,
    super.interests,
    super.instagramHandle,
    super.twitterHandle,
    super.phoneVerified,
    super.emailVerified,
    required super.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    return UserModel(
      id: documentId,
      email: data['email'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      birthDate: (data['birthDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      role: data['role'] ?? 'tourist',
      profileImageUrl: data['profileImageUrl'] ?? '',

      // Phone & Nationality
      phoneNumber: data['phoneNumber'] ?? '',
      nationality: data['nationality'] ?? '',

      // New Profile Fields
      bio: data['bio'] ?? '',
      interests: List<String>.from(data['interests'] ?? []),
      instagramHandle: data['instagramHandle'] ?? '',
      twitterHandle: data['twitterHandle'] ?? '',

      // Verification & Settings
      phoneVerified: data['phoneVerified'] ?? false,
      emailVerified: data['emailVerified'] ?? false,
      isNotificationsEnabled: data['preferences']?['notifications'] ?? true,
      isDarkMode: data['preferences']?['darkMode'] ?? false,
      language: data['preferences']?['language'] ?? 'English',

      // Timestamps
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'birthDate': Timestamp.fromDate(birthDate),
      'role': role,
      'profileImageUrl': profileImageUrl,
      'phoneNumber': phoneNumber,
      'nationality': nationality,
      'bio': bio,
      'interests': interests,
      'instagramHandle': instagramHandle,
      'twitterHandle': twitterHandle,
      'phoneVerified': phoneVerified,
      'emailVerified': emailVerified,
      'preferences': {
        'notifications': isNotificationsEnabled,
        'darkMode': isDarkMode,
        'language': language,
      },
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    DateTime? birthDate,
    String? role,
    String? profileImageUrl,
    String? phoneNumber,
    String? nationality,
    String? bio,
    List<String>? interests,
    String? instagramHandle,
    String? twitterHandle,
    bool? isNotificationsEnabled,
    bool? isDarkMode,
    String? language,
    bool? phoneVerified,
    bool? emailVerified,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      birthDate: birthDate ?? this.birthDate,
      role: role ?? this.role,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      nationality: nationality ?? this.nationality,
      bio: bio ?? this.bio,
      interests: interests ?? this.interests,
      instagramHandle: instagramHandle ?? this.instagramHandle,
      twitterHandle: twitterHandle ?? this.twitterHandle,
      isNotificationsEnabled:
          isNotificationsEnabled ?? this.isNotificationsEnabled,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      language: language ?? this.language,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      emailVerified: emailVerified ?? this.emailVerified,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
