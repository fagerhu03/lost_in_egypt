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
    super.visitedLandmarks,
    required super.createdAt,
    super.applicationStatus,
    super.motaLicenseNumber,
    super.syndicateNumber,
    super.certifiedLanguages,
    super.guideDocuments,
    super.isVerifiedGuide,
    super.rejectionReason,
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
      visitedLandmarks: List<String>.from(data['visitedLandmarks'] ?? []),
      instagramHandle: data['instagramHandle'] ?? '',
      twitterHandle: data['twitterHandle'] ?? '',

      // Verification & Settings
      phoneVerified: data['phoneVerified'] ?? false,
      emailVerified: data['emailVerified'] ?? false,
      isNotificationsEnabled: data['preferences']?['notifications'] ?? true,
      isDarkMode: data['preferences']?['darkMode'] ?? false,
      language: data['preferences']?['language'] ?? 'English',

      // Guide Fields
      applicationStatus: data['applicationStatus'] ?? 'none',
      motaLicenseNumber: data['motaLicenseNumber'] ?? '',
      syndicateNumber: data['syndicateNumber'] ?? '',
      certifiedLanguages: List<String>.from(data['certifiedLanguages'] ?? []),
      guideDocuments: Map<String, String>.from(data['guideDocuments'] ?? {}),
      isVerifiedGuide: data['isVerifiedGuide'] ?? false,
      rejectionReason: data['rejectionReason'],

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
      'visitedLandmarks': visitedLandmarks,
      'instagramHandle': instagramHandle,
      'twitterHandle': twitterHandle,
      'phoneVerified': phoneVerified,
      'emailVerified': emailVerified,
      'preferences': {
        'notifications': isNotificationsEnabled,
        'darkMode': isDarkMode,
        'language': language,
      },
      'applicationStatus': applicationStatus,
      'motaLicenseNumber': motaLicenseNumber,
      'syndicateNumber': syndicateNumber,
      'certifiedLanguages': certifiedLanguages,
      'guideDocuments': guideDocuments,
      'isVerifiedGuide': isVerifiedGuide,
      'rejectionReason': rejectionReason,
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
    List<String>? visitedLandmarks,
    String? instagramHandle,
    String? twitterHandle,
    bool? isNotificationsEnabled,
    bool? isDarkMode,
    String? language,
    bool? phoneVerified,
    bool? emailVerified,
    DateTime? createdAt,
    String? applicationStatus,
    String? motaLicenseNumber,
    String? syndicateNumber,
    List<String>? certifiedLanguages,
    Map<String, String>? guideDocuments,
    bool? isVerifiedGuide,
    String? rejectionReason,
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
      visitedLandmarks: visitedLandmarks ?? this.visitedLandmarks,
      instagramHandle: instagramHandle ?? this.instagramHandle,
      twitterHandle: twitterHandle ?? this.twitterHandle,
      isNotificationsEnabled:
          isNotificationsEnabled ?? this.isNotificationsEnabled,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      language: language ?? this.language,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      emailVerified: emailVerified ?? this.emailVerified,
      createdAt: createdAt ?? this.createdAt,
      applicationStatus: applicationStatus ?? this.applicationStatus,
      motaLicenseNumber: motaLicenseNumber ?? this.motaLicenseNumber,
      syndicateNumber: syndicateNumber ?? this.syndicateNumber,
      certifiedLanguages: certifiedLanguages ?? this.certifiedLanguages,
      guideDocuments: guideDocuments ?? this.guideDocuments,
      isVerifiedGuide: isVerifiedGuide ?? this.isVerifiedGuide,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}
