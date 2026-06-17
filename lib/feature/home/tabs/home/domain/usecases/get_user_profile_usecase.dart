import 'package:dartz/dartz.dart';
import 'package:lost_in_egypt/core/error/failures.dart';
import 'package:lost_in_egypt/feature/auth/domain/entities/user_entity.dart';
import '../repositories/home_repository.dart';

class GetUserProfileUseCase {
  final HomeRepository repository;

  GetUserProfileUseCase(this.repository);

  Future<Either<Failure, UserEntity>> call() async {
    return await repository.getUserProfile();
  }
}
