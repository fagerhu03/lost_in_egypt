import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final DateTime birthDate;
  final String role;
  final String profileImageUrl;

  // Profile Fields
  final String phoneNumber;
  final String nationality;
  final String bio;
  final List<String> interests;

  // Social Links
  final String instagramHandle;
  final String twitterHandle;

  // Verification & Settings
  final bool isNotificationsEnabled;
  final bool isDarkMode;
  final String language;
  final bool phoneVerified;
  final bool emailVerified;

  // Timestamps
  final DateTime createdAt;

  const UserEntity({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    required this.role,
    required this.profileImageUrl,
    this.phoneNumber = '',
    this.nationality = '',
    this.bio = '',
    this.interests = const [],
    this.instagramHandle = '',
    this.twitterHandle = '',
    this.isNotificationsEnabled = true,
    this.isDarkMode = false,
    this.language = 'English',
    this.phoneVerified = false,
    this.emailVerified = false,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    email,
    firstName,
    lastName,
    birthDate,
    role,
    profileImageUrl,
    phoneNumber,
    nationality,
    bio,
    interests,
    instagramHandle,
    twitterHandle,
    isNotificationsEnabled,
    isDarkMode,
    language,
    phoneVerified,
    emailVerified,
    createdAt,
  ];
}
