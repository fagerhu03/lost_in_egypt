import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../feature/auth/domain/entities/user_entity.dart';
import '../repositories/admin_repository.dart';

class GetPendingGuidesUseCase {
  final AdminRepository repository;
  GetPendingGuidesUseCase(this.repository);

  Future<Either<Failure, List<UserEntity>>> call() async {
    return await repository.getPendingGuides();
  }
}

class ApproveGuideUseCase {
  final AdminRepository repository;
  ApproveGuideUseCase(this.repository);

  Future<Either<Failure, void>> call(String userId) async {
    return await repository.approveGuide(userId);
  }
}

class RejectGuideUseCase {
  final AdminRepository repository;
  RejectGuideUseCase(this.repository);

  Future<Either<Failure, void>> call(String userId, String rejectionReason) async {
    return await repository.rejectGuide(userId, rejectionReason);
  }
}
