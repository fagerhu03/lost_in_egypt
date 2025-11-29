import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final DateTime birthDate;
  final String role;
  final String profileImageUrl;

  const UserEntity({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    required this.role,
    required this.profileImageUrl,
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
  ];
}
