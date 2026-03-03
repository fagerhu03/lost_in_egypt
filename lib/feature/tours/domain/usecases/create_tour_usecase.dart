import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/tour_entity.dart';
import '../repositories/tours_repository.dart';

class CreateTourParams {
  final TourEntity tour;
  final List<File> imageFiles;

  CreateTourParams({required this.tour, required this.imageFiles});
}

class CreateTourUseCase {
  final ToursRepository repository;

  CreateTourUseCase({required this.repository});

  Future<Either<Failure, void>> call(CreateTourParams params) async {
    return await repository.createTour(params.tour, params.imageFiles);
  }
}
