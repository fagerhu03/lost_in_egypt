import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/error_handler.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, void>> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String birthMonth,
    required String birthDay,
    required String birthYear,
  }) async {
    try {
      await remoteDataSource.signUp(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        birthMonth: birthMonth,
        birthDay: birthDay,
        birthYear: birthYear,
      );
      return const Right(null);
    } on FirebaseAuthException catch (e) {
      return Left(ServerFailure(ErrorHandler.handleAuthError(e)));
    } catch (e) {
      return Left(ServerFailure(ErrorHandler.handleGenericError(e)));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  }) async {
    try {
      final userModel = await remoteDataSource.login(
        email: email,
        password: password,
      );
      return Right(userModel);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return Left(ServerFailure('No user found for that email.'));
      } else if (e.code == 'wrong-password') {
        return Left(ServerFailure('Wrong password provided.'));
      }
      return Left(ServerFailure(ErrorHandler.handleAuthError(e)));
    } catch (e) {
      return Left(ServerFailure(ErrorHandler.handleGenericError(e)));
    }
  }

  @override
  Future<Either<Failure, void>> forgetPassword({required String email}) async {
    try {
      await remoteDataSource.forgetPassword(email: email);
      return const Right(null);
    } on FirebaseAuthException catch (e) {
      return Left(ServerFailure(ErrorHandler.handleAuthError(e)));
    } catch (e) {
      return Left(ServerFailure(ErrorHandler.handleGenericError(e)));
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> signInWithGoogle() async {
    try {
      final userModel = await remoteDataSource.signInWithGoogle();
      return Right(userModel);
    } on FirebaseAuthException catch (e) {
      return Left(ServerFailure(ErrorHandler.handleAuthError(e)));
    } catch (e) {
      return Left(ServerFailure(ErrorHandler.handleGenericError(e)));
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> signInWithFacebook() async {
    try {
      final userModel = await remoteDataSource.signInWithFacebook();
      return Right(userModel);
    } on FirebaseAuthException catch (e) {
      return Left(ServerFailure(ErrorHandler.handleAuthError(e)));
    } catch (e) {
      return Left(ServerFailure(ErrorHandler.handleGenericError(e)));
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> signInWithApple() async {
    try {
      final userModel = await remoteDataSource.signInWithApple();
      return Right(userModel);
    } on FirebaseAuthException catch (e) {
      return Left(ServerFailure(ErrorHandler.handleAuthError(e)));
    } catch (e) {
      return Left(ServerFailure(ErrorHandler.handleGenericError(e)));
    }
  }

  @override
  Future<Either<Failure, void>> completeSocialProfile({
    required String birthMonth,
    required String birthDay,
    required String birthYear,
  }) async {
    try {
      await remoteDataSource.completeSocialProfile(
        birthMonth: birthMonth,
        birthDay: birthDay,
        birthYear: birthYear,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(ErrorHandler.handleGenericError(e)));
    }
  }

  @override
  Future<Either<Failure, bool>> checkEmailExists(String email) async {
    try {
      final exists = await remoteDataSource.checkEmailExists(email);
      return Right(exists);
    } catch (e) {
      // Even if it fails, we return Left to handle it gracefully
      return Left(ServerFailure(ErrorHandler.handleGenericError(e)));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getUserProfile(String uid) async {
    try {
      final userModel = await remoteDataSource.getUserProfile(uid);
      return Right(userModel); // UserModel extends UserEntity, so this is valid
    } catch (e) {
      return Left(ServerFailure(ErrorHandler.handleGenericError(e)));
    }
  }

  // ✅ NEW: UPDATE PROFILE IMPLEMENTATION
  @override
  Future<Either<Failure, void>> updateUserProfile(UserEntity user) async {
    try {
      // ⚠️ Critical Step: Convert Domain Entity -> Data Model
      // The DataSource requires a UserModel because it has the .toMap() method.
      final userModel = UserModel(
        id: user.id,
        email: user.email,
        firstName: user.firstName,
        lastName: user.lastName,
        birthDate: user.birthDate,
        role: user.role,
        profileImageUrl: user.profileImageUrl,
        // New fields
        phoneNumber: user.phoneNumber,
        nationality: user.nationality,
        isNotificationsEnabled: user.isNotificationsEnabled,
        isDarkMode: user.isDarkMode,
        language: user.language,
        createdAt: user.createdAt,
      );

      await remoteDataSource.updateUserProfile(userModel);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(ErrorHandler.handleGenericError(e)));
    }
  }
}
