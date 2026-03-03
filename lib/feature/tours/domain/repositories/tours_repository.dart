import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/tour_entity.dart';

abstract class ToursRepository {
  Future<Either<Failure, void>> createTour(TourEntity tour, List<File> imageFiles);
  Future<Either<Failure, List<TourEntity>>> getToursForGuide(String guideId);
  Future<Either<Failure, List<TourEntity>>> getAllTours();
}
