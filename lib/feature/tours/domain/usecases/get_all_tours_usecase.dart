import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/tour_entity.dart';
import '../repositories/tours_repository.dart';

class GetAllToursUseCase {
  final ToursRepository repository;

  GetAllToursUseCase({required this.repository});

  Future<Either<Failure, List<TourEntity>>> call() async {
    return await repository.getAllTours();
  }
}
