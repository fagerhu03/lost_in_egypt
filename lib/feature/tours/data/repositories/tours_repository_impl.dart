import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/tour_entity.dart';
import '../../domain/repositories/tours_repository.dart';
import '../datasources/tours_data_source.dart';
import '../models/tour_model.dart';

class ToursRepositoryImpl implements ToursRepository {
  final ToursDataSource remoteDataSource;

  ToursRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, void>> createTour(TourEntity tour, List<File> imageFiles) async {
    try {
      final tourModel = TourModel(
        id: tour.id,
        guideId: tour.guideId,
        title: tour.title,
        description: tour.description,
        destinations: tour.destinations,
        price: tour.price,
        meetingLatitude: tour.meetingLatitude,
        meetingLongitude: tour.meetingLongitude,
        meetingTime: tour.meetingTime,
        frequency: tour.frequency,
        images: tour.images,
        maxAttendees: tour.maxAttendees,
        rating: tour.rating,
        reviewCount: tour.reviewCount,
        createdAt: tour.createdAt,
      );

      await remoteDataSource.createTour(tourModel, imageFiles);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TourEntity>>> getToursForGuide(String guideId) async {
    try {
      final tours = await remoteDataSource.getToursForGuide(guideId);
      return Right(tours);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TourEntity>>> getAllTours() async {
    try {
      final tours = await remoteDataSource.getAllTours();
      return Right(tours);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
