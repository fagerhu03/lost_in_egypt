import 'package:dartz/dartz.dart';
import 'package:lost_in_egypt/core/error/failures.dart';
import 'package:lost_in_egypt/feature/auth/domain/entities/user_entity.dart';
import 'package:lost_in_egypt/feature/tours/domain/entities/tour_entity.dart';
import 'package:lost_in_egypt/feature/home/tabs/home/data/models/map_item_models.dart';

abstract class HomeRepository {
  Future<Either<Failure, UserEntity>> getUserProfile();
  Stream<List<EventModel>> getEventsStream(int limit);
  Stream<List<TourEntity>> getPopularToursStream(int limit);
  Future<Either<Failure, List<PlaceModel>>> getPopularPlaces(int limit);
  Future<void> syncLiveEvents();
}
