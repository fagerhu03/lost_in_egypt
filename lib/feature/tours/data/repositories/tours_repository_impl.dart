import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/error_handler.dart';
import '../../domain/repositories/tours_repository.dart';
import '../datasources/tours_data_source.dart';
import '../models/tour_model.dart';
import '../models/booking_model.dart';
import '../../domain/entities/booking_entity.dart';
import '../../domain/entities/tour_entity.dart';

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
        meetingLocationName: tour.meetingLocationName,
        meetingLatitude: tour.meetingLatitude,
        meetingLongitude: tour.meetingLongitude,
        meetingTime: tour.meetingTime,
        frequency: tour.frequency,
        images: tour.images,
        maxAttendees: tour.maxAttendees,
        rating: tour.rating,
        reviewCount: tour.reviewCount,
        createdAt: tour.createdAt,
        totalCapacity: tour.totalCapacity,
        recurrenceType: tour.recurrenceType,
        recurrenceDays: tour.recurrenceDays,
        meetingTimeOfDay: tour.meetingTimeOfDay,
        nextOccurrence: tour.nextOccurrence,
        isArchived: tour.isArchived,
      );

      await remoteDataSource.createTour(tourModel, imageFiles);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(ErrorHandler.handleGenericError(e)));
    }
  }

  @override
  Future<Either<Failure, void>> updateTour(TourEntity tour, List<File> newImageFiles) async {
    try {
      final tourModel = TourModel(
        id: tour.id,
        guideId: tour.guideId,
        title: tour.title,
        description: tour.description,
        destinations: tour.destinations,
        price: tour.price,
        meetingLocationName: tour.meetingLocationName,
        meetingLatitude: tour.meetingLatitude,
        meetingLongitude: tour.meetingLongitude,
        meetingTime: tour.meetingTime,
        frequency: tour.frequency,
        images: tour.images,
        maxAttendees: tour.maxAttendees,
        rating: tour.rating,
        reviewCount: tour.reviewCount,
        createdAt: tour.createdAt,
        totalCapacity: tour.totalCapacity,
        recurrenceType: tour.recurrenceType,
        recurrenceDays: tour.recurrenceDays,
        meetingTimeOfDay: tour.meetingTimeOfDay,
        nextOccurrence: tour.nextOccurrence,
        isArchived: tour.isArchived,
      );

      await remoteDataSource.updateTour(tourModel, newImageFiles);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(ErrorHandler.handleGenericError(e)));
    }
  }

  @override
  Future<Either<Failure, List<TourEntity>>> getToursForGuide(String guideId) async {
    try {
      final tours = await remoteDataSource.getToursForGuide(guideId);
      return Right(tours);
    } catch (e) {
      return Left(ServerFailure(ErrorHandler.handleGenericError(e)));
    }
  }

  @override
  Future<Either<Failure, List<TourEntity>>> getAllTours() async {
    try {
      final tours = await remoteDataSource.getAllTours();
      return Right(tours);
    } catch (e) {
      return Left(ServerFailure(ErrorHandler.handleGenericError(e)));
    }
  }

  @override
  Stream<List<TourEntity>> getToursStream() {
    return remoteDataSource.getToursStream();
  }

  @override
  Future<Either<Failure, void>> bookTour(BookingEntity booking) async {
    try {
      final bookingModel = BookingModel(
        id: booking.id,
        tourId: booking.tourId,
        userId: booking.userId,
        guideId: booking.guideId,
        status: booking.status,
        paymentReference: booking.paymentReference,
        paymentStatus: booking.paymentStatus,
        date: booking.date,
        createdAt: booking.createdAt,
      );

      await remoteDataSource.bookTour(bookingModel);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(ErrorHandler.handleGenericError(e)));
    }
  }
}
