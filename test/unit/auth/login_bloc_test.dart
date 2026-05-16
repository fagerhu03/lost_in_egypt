import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:lost_in_egypt/core/error/failures.dart';
import 'package:lost_in_egypt/feature/auth/domain/entities/user_entity.dart';
import 'package:lost_in_egypt/feature/auth/domain/repositories/auth_repository.dart';
import 'package:lost_in_egypt/feature/auth/presentation/login/bloc/login_bloc.dart';
import 'package:lost_in_egypt/feature/auth/presentation/login/bloc/login_event.dart';
import 'package:lost_in_egypt/feature/auth/presentation/login/bloc/login_state.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class FakeUserEntity extends Fake implements UserEntity {
  @override
  String get role => 'tourist';
  @override
  String get applicationStatus => 'none';
}

FirebaseAuthException _fbEx(String code) =>
    FirebaseAuthException(code: code);

void main() {
  late MockAuthRepository mockRepo;
  late FakeUserEntity fakeUser;

  setUp(() {
    mockRepo = MockAuthRepository();
    fakeUser = FakeUserEntity();
  });

  LoginBloc build() => LoginBloc(authRepository: mockRepo);

  // ─── Email validation ──────────────────────────────────────────────────────

  group('LoginSubmitted — email validation', () {
    blocTest<LoginBloc, LoginState>(
      'emits [Loading, Failure] for empty email',
      build: build,
      act: (b) => b.add(const LoginSubmitted(email: '', password: 'pass1234')),
      expect: () => [isA<LoginLoading>(), isA<LoginFailure>()],
    );

    blocTest<LoginBloc, LoginState>(
      'emits [Loading, Failure] for malformed email',
      build: build,
      act: (b) =>
          b.add(const LoginSubmitted(email: 'not-an-email', password: 'pass1234')),
      expect: () => [isA<LoginLoading>(), isA<LoginFailure>()],
    );

    blocTest<LoginBloc, LoginState>(
      'failure message is the exact validation string, not a raw exception',
      build: build,
      act: (b) =>
          b.add(const LoginSubmitted(email: 'bad@@email', password: 'pass')),
      expect: () => [
        isA<LoginLoading>(),
        isA<LoginFailure>().having(
          (s) => s.error,
          'error',
          'Please enter a valid email address',
        ),
      ],
    );

    blocTest<LoginBloc, LoginState>(
      'emits [Loading, Failure] for email with spaces (not trimmed)',
      build: build,
      act: (b) =>
          b.add(const LoginSubmitted(email: ' user@test.com ', password: 'pass1234')),
      expect: () => [isA<LoginLoading>(), isA<LoginFailure>()],
    );

    blocTest<LoginBloc, LoginState>(
      'accepts valid subdomain email',
      build: build,
      setUp: () {
        when(() => mockRepo.login(
              email: 'user@mail.company.co.uk',
              password: 'pass1234',
            )).thenAnswer((_) async => Right(fakeUser));
      },
      act: (b) => b.add(const LoginSubmitted(
          email: 'user@mail.company.co.uk', password: 'pass1234')),
      expect: () => [isA<LoginLoading>(), isA<LoginSuccess>()],
    );
  });

  // ─── Repository responses ──────────────────────────────────────────────────

  group('LoginSubmitted — repository responses', () {
    const validEmail = 'user@example.com';
    const validPassword = 'password123';

    blocTest<LoginBloc, LoginState>(
      'emits [Loading, Success] on successful login',
      build: build,
      setUp: () {
        when(() => mockRepo.login(email: validEmail, password: validPassword))
            .thenAnswer((_) async => Right(fakeUser));
      },
      act: (b) =>
          b.add(const LoginSubmitted(email: validEmail, password: validPassword)),
      expect: () => [
        isA<LoginLoading>(),
        isA<LoginSuccess>().having((s) => s.user, 'user', isNotNull),
      ],
    );

    blocTest<LoginBloc, LoginState>(
      'emits [Loading, Failure] on repository Left(ServerFailure)',
      build: build,
      setUp: () {
        when(() => mockRepo.login(email: validEmail, password: validPassword))
            .thenAnswer((_) async => Left(ServerFailure('Invalid credentials')));
      },
      act: (b) =>
          b.add(const LoginSubmitted(email: validEmail, password: validPassword)),
      expect: () => [
        isA<LoginLoading>(),
        isA<LoginFailure>()
            .having((s) => s.error, 'error', contains('Invalid credentials')),
      ],
    );

    blocTest<LoginBloc, LoginState>(
      'emits [Loading, Failure] on thrown exception — message is human-readable',
      build: build,
      setUp: () {
        when(() => mockRepo.login(email: validEmail, password: validPassword))
            .thenThrow(Exception('network down'));
      },
      act: (b) =>
          b.add(const LoginSubmitted(email: validEmail, password: validPassword)),
      expect: () => [
        isA<LoginLoading>(),
        isA<LoginFailure>().having(
          (s) => s.error,
          'error',
          allOf(
            isNot(contains('Exception:')),
            isNot(contains('network down')),
            isNot(isEmpty),
          ),
        ),
      ],
    );
  });

  // ─── FirebaseAuthException handling ───────────────────────────────────────

  group('LoginSubmitted — FirebaseAuthException mapping', () {
    const validEmail = 'user@example.com';
    const validPassword = 'password123';

    blocTest<LoginBloc, LoginState>(
      'wrong-password → human-readable message',
      build: build,
      setUp: () {
        when(() => mockRepo.login(email: validEmail, password: validPassword))
            .thenThrow(_fbEx('wrong-password'));
      },
      act: (b) =>
          b.add(const LoginSubmitted(email: validEmail, password: validPassword)),
      expect: () => [
        isA<LoginLoading>(),
        isA<LoginFailure>().having(
          (s) => s.error,
          'error',
          allOf(
            isNot(contains('wrong-password')),
            isNot(contains('Exception')),
            isNotEmpty,
          ),
        ),
      ],
    );

    blocTest<LoginBloc, LoginState>(
      'user-not-found → human-readable message',
      build: build,
      setUp: () {
        when(() => mockRepo.login(email: validEmail, password: validPassword))
            .thenThrow(_fbEx('user-not-found'));
      },
      act: (b) =>
          b.add(const LoginSubmitted(email: validEmail, password: validPassword)),
      expect: () => [
        isA<LoginLoading>(),
        isA<LoginFailure>().having(
          (s) => s.error,
          'error',
          allOf(isNot(contains('user-not-found')), isNotEmpty),
        ),
      ],
    );

    blocTest<LoginBloc, LoginState>(
      'user-disabled → message mentions disabled or support',
      build: build,
      setUp: () {
        when(() => mockRepo.login(email: validEmail, password: validPassword))
            .thenThrow(_fbEx('user-disabled'));
      },
      act: (b) =>
          b.add(const LoginSubmitted(email: validEmail, password: validPassword)),
      expect: () => [
        isA<LoginLoading>(),
        isA<LoginFailure>().having(
          (s) => s.error,
          'error',
          anyOf(contains('disabled'), contains('support')),
        ),
      ],
    );
  });

  // ─── Google sign-in ────────────────────────────────────────────────────────

  group('LoginWithGoogleSubmitted', () {
    blocTest<LoginBloc, LoginState>(
      'existing user → [Loading, Success] with isNewSocialUser false',
      build: build,
      setUp: () {
        when(() => mockRepo.signInWithGoogle())
            .thenAnswer((_) async => Right(fakeUser));
      },
      act: (b) => b.add(LoginWithGoogleSubmitted()),
      expect: () => [
        isA<LoginLoading>(),
        isA<LoginSuccess>()
            .having((s) => s.isNewSocialUser, 'isNewSocialUser', isFalse),
      ],
    );

    blocTest<LoginBloc, LoginState>(
      'new user (null from repo) → [Loading, Success] with isNewSocialUser true',
      build: build,
      setUp: () {
        when(() => mockRepo.signInWithGoogle())
            .thenAnswer((_) async => const Right(null));
      },
      act: (b) => b.add(LoginWithGoogleSubmitted()),
      expect: () => [
        isA<LoginLoading>(),
        isA<LoginSuccess>()
            .having((s) => s.isNewSocialUser, 'isNewSocialUser', isTrue),
      ],
    );

    blocTest<LoginBloc, LoginState>(
      'user cancels → [Loading, Failure]',
      build: build,
      setUp: () {
        when(() => mockRepo.signInWithGoogle())
            .thenAnswer((_) async =>
                Left(ServerFailure('Sign-in was cancelled')));
      },
      act: (b) => b.add(LoginWithGoogleSubmitted()),
      expect: () => [
        isA<LoginLoading>(),
        isA<LoginFailure>().having(
            (s) => s.error, 'error', contains('cancelled')),
      ],
    );

    blocTest<LoginBloc, LoginState>(
      'unexpected exception → [Loading, Failure]',
      build: build,
      setUp: () {
        when(() => mockRepo.signInWithGoogle())
            .thenThrow(Exception('sign_in_cancelled'));
      },
      act: (b) => b.add(LoginWithGoogleSubmitted()),
      expect: () => [isA<LoginLoading>(), isA<LoginFailure>()],
    );
  });

  // ─── Facebook sign-in ──────────────────────────────────────────────────────

  group('LoginWithFacebookSubmitted', () {
    blocTest<LoginBloc, LoginState>(
      'existing user → [Loading, Success] with isNewSocialUser false',
      build: build,
      setUp: () {
        when(() => mockRepo.signInWithFacebook())
            .thenAnswer((_) async => Right(fakeUser));
      },
      act: (b) => b.add(LoginWithFacebookSubmitted()),
      expect: () => [
        isA<LoginLoading>(),
        isA<LoginSuccess>()
            .having((s) => s.isNewSocialUser, 'isNewSocialUser', isFalse),
      ],
    );

    blocTest<LoginBloc, LoginState>(
      'new user (null from repo) → [Loading, Success] with isNewSocialUser true',
      build: build,
      setUp: () {
        when(() => mockRepo.signInWithFacebook())
            .thenAnswer((_) async => const Right(null));
      },
      act: (b) => b.add(LoginWithFacebookSubmitted()),
      expect: () => [
        isA<LoginLoading>(),
        isA<LoginSuccess>()
            .having((s) => s.isNewSocialUser, 'isNewSocialUser', isTrue),
      ],
    );

    blocTest<LoginBloc, LoginState>(
      'failure → [Loading, Failure]',
      build: build,
      setUp: () {
        when(() => mockRepo.signInWithFacebook()).thenAnswer(
            (_) async => Left(ServerFailure('Facebook login failed')));
      },
      act: (b) => b.add(LoginWithFacebookSubmitted()),
      expect: () => [isA<LoginLoading>(), isA<LoginFailure>()],
    );
  });

  // ─── Apple sign-in ─────────────────────────────────────────────────────────

  group('LoginWithAppleSubmitted', () {
    blocTest<LoginBloc, LoginState>(
      'returns Failure with user-friendly message (not yet available)',
      build: build,
      setUp: () {
        when(() => mockRepo.signInWithApple()).thenAnswer((_) async =>
            Left(ServerFailure('Apple Sign-In is not yet available.')));
      },
      act: (b) => b.add(LoginWithAppleSubmitted()),
      expect: () => [
        isA<LoginLoading>(),
        isA<LoginFailure>().having(
          (s) => s.error,
          'error',
          allOf(
            isNot(contains('operation-not-supported')),
            isNot(contains('Exception')),
            isNotEmpty,
          ),
        ),
      ],
    );
  });
}
