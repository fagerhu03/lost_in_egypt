import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/utils/error_handler.dart';
import '../../domain/repositories/auth_repository.dart';
import 'login_event.dart';
import 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthRepository _authRepository;

  LoginBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(LoginInitial()) {
    on<LoginSubmitted>(_onLoginSubmitted);
    on<LoginWithGoogleSubmitted>(_onLoginWithGoogleSubmitted);
    on<LoginWithFacebookSubmitted>(_onLoginWithFacebookSubmitted);
    on<LoginWithAppleSubmitted>(_onLoginWithAppleSubmitted);
  }

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    emit(LoginLoading());

    // Validate email
    final emailError = ErrorHandler.validateEmail(event.email);
    if (emailError != null) {
      emit(LoginFailure(emailError));
      return;
    }

    try {
      final result = await _authRepository.login(
        email: event.email,
        password: event.password,
      );

      result.fold(
        (failure) => emit(LoginFailure(failure.message)),
        (user) => emit(LoginSuccess(user: user)),
      );
    } on FirebaseAuthException catch (e) {
      emit(LoginFailure(ErrorHandler.handleAuthError(e)));
    } catch (e) {
      emit(LoginFailure(ErrorHandler.handleGenericError(e)));
    }
  }

  Future<void> _onLoginWithGoogleSubmitted(
    LoginWithGoogleSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    emit(LoginLoading());
    try {
      final result = await _authRepository.signInWithGoogle();
      result.fold(
        (failure) => emit(LoginFailure(failure.message)),
        (user) => emit(LoginSuccess(user: user, isNewSocialUser: user == null)),
      );
    } catch (e) {
      emit(LoginFailure(ErrorHandler.handleGenericError(e)));
    }
  }

  Future<void> _onLoginWithFacebookSubmitted(
    LoginWithFacebookSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    emit(LoginLoading());
    try {
      final result = await _authRepository.signInWithFacebook();
      result.fold(
        (failure) => emit(LoginFailure(failure.message)),
        (user) => emit(LoginSuccess(user: user, isNewSocialUser: user == null)),
      );
    } catch (e) {
      emit(LoginFailure(ErrorHandler.handleGenericError(e)));
    }
  }

  Future<void> _onLoginWithAppleSubmitted(
    LoginWithAppleSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    emit(LoginLoading());
    try {
      final result = await _authRepository.signInWithApple();
      result.fold(
        (failure) => emit(LoginFailure(failure.message)),
        (user) => emit(LoginSuccess(user: user, isNewSocialUser: user == null)),
      );
    } catch (e) {
      emit(LoginFailure(ErrorHandler.handleGenericError(e)));
    }
  }
}
