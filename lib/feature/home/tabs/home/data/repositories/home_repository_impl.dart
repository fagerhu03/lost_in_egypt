import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lost_in_egypt/core/error/failures.dart';
import 'package:lost_in_egypt/core/utils/error_handler.dart';
import 'package:lost_in_egypt/feature/auth/domain/entities/user_entity.dart';
import 'package:lost_in_egypt/feature/tours/data/models/tour_model.dart';
import 'package:lost_in_egypt/feature/tours/domain/entities/tour_entity.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_remote_datasource.dart';
import '../datasources/local_places_service.dart';
import '../models/map_item_models.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource remoteDataSource;
  final FirebaseAuth firebaseAuth;

  HomeRepositoryImpl({
    required this.remoteDataSource,
    required this.firebaseAuth,
  });

  @override
  Future<Either<Failure, UserEntity>> getUserProfile() async {
    try {
      final currentUser = firebaseAuth.currentUser;
      if (currentUser == null) {
        return Left(ServerFailure('User is not logged in'));
      }
      
      final userData = await remoteDataSource.getUserProfile(currentUser.uid);
      
      // Parse UserEntity
      final userEntity = UserEntity(
        id: currentUser.uid,
        email: userData['email'] ?? '',
        firstName: userData['firstName'] ?? '',
        lastName: userData['lastName'] ?? '',
        role: userData['role'] ?? 'tourist',
        profileImageUrl: userData['profileImageUrl'] ?? '',
        username: userData['username'] ?? '',
        phoneNumber: userData['phoneNumber'] ?? '',
        nationality: userData['nationality'] ?? '',
        birthDate: userData['birthDate']?.toDate() ?? DateTime.now(),
        emailVerified: userData['emailVerified'] ?? false,
        phoneVerified: userData['phoneVerified'] ?? false,
        createdAt: userData['createdAt']?.toDate() ?? DateTime.now(),
      );
      
      return Right(userEntity);
    } catch (e) {
      return Left(ServerFailure(ErrorHandler.handleGenericError(e)));
    }
  }

  @override
  Stream<List<EventModel>> getEventsStream(int limit) {
    return remoteDataSource.getEventsStream(limit).map((snapshot) {
      return snapshot.docs.map((doc) {
        return EventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  @override
  Stream<List<TourEntity>> getPopularToursStream(int limit) {
    return remoteDataSource.getPopularToursStream(limit).map((snapshot) {
      return snapshot.docs.map((doc) {
        return TourModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  @override
  Future<Either<Failure, List<PlaceModel>>> getPopularPlaces(int limit) async {
    try {
      // Calls local JSON implementation
      final places = await LocalPlacesService.getTopRatedPlaces(limit: 20);
      places.shuffle();
      return Right(places.take(limit).toList());
    } catch (e) {
      return Left(ServerFailure(ErrorHandler.handleGenericError(e)));
    }
  }

  @override
  Future<void> syncLiveEvents() async {
    await remoteDataSource.syncLiveEvents();
  }
}
