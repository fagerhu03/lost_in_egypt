import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../feature/auth/domain/entities/user_entity.dart';
import '../../domain/repositories/admin_repository.dart';
import '../datasources/admin_data_source.dart';

class AdminRepositoryImpl implements AdminRepository {
  final AdminDataSource remoteDataSource;

  AdminRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<UserEntity>>> getPendingGuides() async {
    try {
      final guides = await remoteDataSource.getPendingGuides();
      return Right(guides);
    } catch (e) {
      return Left(ServerFailure(ErrorHandler.handleGenericError(e)));
    }
  }

  @override
  Future<Either<Failure, void>> approveGuide(String userId) async {
    try {
      await remoteDataSource.approveGuide(userId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(ErrorHandler.handleGenericError(e)));
    }
  }

  @override
  Future<Either<Failure, void>> rejectGuide(String userId, String rejectionReason) async {
    try {
      await remoteDataSource.rejectGuide(userId, rejectionReason);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(ErrorHandler.handleGenericError(e)));
    }
  }
}
