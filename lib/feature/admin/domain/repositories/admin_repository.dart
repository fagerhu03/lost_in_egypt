import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../feature/auth/domain/entities/user_entity.dart';

abstract class AdminRepository {
  Future<Either<Failure, List<UserEntity>>> getPendingGuides();
  Future<Either<Failure, void>> approveGuide(String userId);
  Future<Either<Failure, void>> rejectGuide(String userId, String rejectionReason);
}
