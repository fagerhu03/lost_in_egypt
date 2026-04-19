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
  final List<String> visitedLandmarks;
  final List<String> savedPlaces;

  // Username handle (unique, e.g. @explorer_ahmed)
  final String username;

  // Social Links
  final String instagramHandle;
  final String twitterHandle;

  // Verification & Settings
  final bool isNotificationsEnabled;
  final bool isDarkMode;
  final String language;
  final String preferredCurrency;
  final bool phoneVerified;
  final bool emailVerified;

  // Granular notification preferences
  final bool notifBookings;
  final bool notifCommunity;
  final bool notifReviews;
  final bool notifGuideUpdates;

  // Timestamps
  final DateTime createdAt;

  // Guide Fields
  final String applicationStatus; // 'none', 'pending', 'rejected', 'approved'
  final String motaLicenseNumber;
  final String syndicateNumber;
  final List<String> certifiedLanguages;
  final Map<String, String> guideDocuments;
  final bool isVerifiedGuide;
  final String? rejectionReason;

  final double rating;
  final int reviewCount;

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
    this.visitedLandmarks = const [],
    this.savedPlaces = const [],
    this.username = '',
    this.instagramHandle = '',
    this.twitterHandle = '',
    this.isNotificationsEnabled = true,
    this.isDarkMode = false,
    this.language = 'English',
    this.preferredCurrency = 'EGP',
    this.phoneVerified = false,
    this.emailVerified = false,
    this.notifBookings = true,
    this.notifCommunity = true,
    this.notifReviews = true,
    this.notifGuideUpdates = true,
    required this.createdAt,
    this.applicationStatus = 'none',
    this.motaLicenseNumber = '',
    this.syndicateNumber = '',
    this.certifiedLanguages = const [],
    this.guideDocuments = const {},
    this.isVerifiedGuide = false,
    this.rejectionReason,
    this.rating = 0.0,
    this.reviewCount = 0,
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
    visitedLandmarks,
    savedPlaces,
    username,
    instagramHandle,
    twitterHandle,
    isNotificationsEnabled,
    isDarkMode,
    language,
    preferredCurrency,
    phoneVerified,
    emailVerified,
    notifBookings,
    notifCommunity,
    notifReviews,
    notifGuideUpdates,
    createdAt,
    applicationStatus,
    motaLicenseNumber,
    syndicateNumber,
    certifiedLanguages,
    guideDocuments,
    isVerifiedGuide,
    rejectionReason,
    rating,
    reviewCount,
  ];
}
