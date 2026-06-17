import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, void>> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String birthMonth,
    required String birthDay,
    required String birthYear,
    required String phoneNumber,
    required String nationalityCode,
  });

  Future<Either<Failure, UserEntity>> login({
    required String email, 
    required String password
  });

  Future<Either<Failure, void>> forgetPassword({required String email});

  Future<Either<Failure, UserEntity?>> signInWithGoogle();
  
  Future<Either<Failure, UserEntity?>> signInWithFacebook();
  
  Future<Either<Failure, UserEntity?>> signInWithApple();

  Future<Either<Failure, void>> completeSocialProfile({
    required String birthMonth,
    required String birthDay,
    required String birthYear,
  });

  Future<Either<Failure, bool>> checkEmailExists(String email);

  // ✅ NEW METHODS for Edit Profile & Settings
  Future<Either<Failure, UserEntity>> getUserProfile(String uid);
  Future<Either<Failure, void>> updateUserProfile(UserEntity user);
}