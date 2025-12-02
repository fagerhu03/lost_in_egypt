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
  });

  Future<Either<Failure, UserEntity>> login({
    required String email, 
    required String password
  });

  Future<Either<Failure, void>> forgetPassword({
    required String email
  });

  Future<Either<Failure, UserEntity?>> signInWithGoogle();
  
  
  Future<Either<Failure, UserEntity?>> signInWithFacebook();
  
  Future<Either<Failure, void>> completeSocialProfile({
    required String birthMonth,
    required String birthDay,
    required String birthYear,
  });
  Future<Either<Failure, bool>> checkEmailExists(String email);
}