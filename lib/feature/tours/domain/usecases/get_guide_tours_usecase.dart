import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/tour_entity.dart';
import '../repositories/tours_repository.dart';

class GetGuideToursUseCase {
  final ToursRepository repository;

  GetGuideToursUseCase({required this.repository});

  Future<Either<Failure, List<TourEntity>>> call(String guideId) async {
    return await repository.getToursForGuide(guideId);
  }
}
