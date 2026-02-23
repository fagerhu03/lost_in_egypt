import 'package:equatable/equatable.dart';

sealed class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object> get props => [];
}

class LoginSubmitted extends LoginEvent {
  final String email;
  final String password;

  const LoginSubmitted({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

class LoginWithGoogleSubmitted extends LoginEvent {}
class LoginWithAppleSubmitted extends LoginEvent {}
class LoginWithFacebookSubmitted extends LoginEvent {}
