import 'package:equatable/equatable.dart';
import 'package:lost_in_egypt/feature/auth/domain/entities/user_entity.dart';
import 'package:lost_in_egypt/feature/tours/domain/entities/tour_entity.dart';
import 'package:lost_in_egypt/feature/home/tabs/home/data/models/map_item_models.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {
  const HomeInitial();
}

class HomeLoading extends HomeState {
  const HomeLoading();
}

class HomeLoaded extends HomeState {
  final UserEntity? user;
  final List<PlaceModel> popularPlaces;
  final Future<List<EventModel>> eventsFuture;
  final Stream<List<TourEntity>> popularToursStream;

  const HomeLoaded({
    required this.user,
    required this.popularPlaces,
    required this.eventsFuture,
    required this.popularToursStream,
  });

  @override
  List<Object?> get props => [
        user,
        popularPlaces,
        eventsFuture,
        popularToursStream,
      ];
}

class HomeError extends HomeState {
  final String message;

  const HomeError(this.message);

  @override
  List<Object?> get props => [message];
}
