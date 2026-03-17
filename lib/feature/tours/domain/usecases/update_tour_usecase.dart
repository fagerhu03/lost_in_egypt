import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/tour_entity.dart';
import '../repositories/tours_repository.dart';

class UpdateTourUseCase {
  final ToursRepository repository;

  UpdateTourUseCase({required this.repository});

  Future<Either<Failure, void>> call(UpdateTourParams params) async {
    return await repository.updateTour(params.tour, params.newImageFiles);
  }
}

class UpdateTourParams {
  final TourEntity tour;
  final List<File> newImageFiles;

  UpdateTourParams({required this.tour, required this.newImageFiles});
}
