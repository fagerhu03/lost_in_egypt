import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

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
      return Left(ServerFailure(e.message ?? 'Signup Failed'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> login({required String email, required String password}) async {
    try {
      final userModel = await remoteDataSource.login(email: email, password: password);
      return Right(userModel);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return Left(ServerFailure('No user found for that email.'));
      } else if (e.code == 'wrong-password') {
        return Left(ServerFailure('Wrong password provided.'));
      }
      return Left(ServerFailure(e.message ?? 'Login Failed'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> forgetPassword({required String email}) async {
    try {
      await remoteDataSource.forgetPassword(email: email);
      return const Right(null);
    } on FirebaseAuthException catch (e) {
      return Left(ServerFailure(e.message ?? 'Reset Failed'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> signInWithGoogle() async {
    try {
      final userModel = await remoteDataSource.signInWithGoogle();
      return Right(userModel);
    } on FirebaseAuthException catch (e) {
      return Left(ServerFailure(e.message ?? 'Google Sign In Failed'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> signInWithFacebook() async {
    try {
      final userModel = await remoteDataSource.signInWithFacebook();
      return Right(userModel);
    } on FirebaseAuthException catch (e) {
      return Left(ServerFailure(e.message ?? 'Facebook Sign In Failed'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> signInWithApple() async {
    try {
      final userModel = await remoteDataSource.signInWithApple();
      return Right(userModel);
    } on FirebaseAuthException catch (e) {
      return Left(ServerFailure(e.message ?? 'Apple Sign In Failed'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> completeSocialProfile({
    required String birthMonth, 
    required String birthDay, 
    required String birthYear
  }) async {
    try {
      await remoteDataSource.completeSocialProfile(
        birthMonth: birthMonth, 
        birthDay: birthDay, 
        birthYear: birthYear
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}