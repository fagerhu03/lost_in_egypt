import 'package:equatable/equatable.dart';

sealed class LoginState extends Equatable {
  const LoginState();
  
  @override
  List<Object?> get props => [];
}

class LoginInitial extends LoginState {}

class LoginLoading extends LoginState {}

class LoginSuccess extends LoginState {
  final dynamic user;
  final bool isNewSocialUser;
  
  const LoginSuccess({this.user, this.isNewSocialUser = false});
  
  @override
  List<Object?> get props => [user, isNewSocialUser];
}

class LoginFailure extends LoginState {
  final String error;
  
  const LoginFailure(this.error);
  
  @override
  List<Object> get props => [error];
}
