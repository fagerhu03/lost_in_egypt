import 'package:equatable/equatable.dart';
import '../../domain/entities/tour_entity.dart';

abstract class GuideToursState extends Equatable {
  const GuideToursState();

  @override
  List<Object?> get props => [];
}

class GuideToursInitial extends GuideToursState {}

class GuideToursLoading extends GuideToursState {}

class GuideToursLoaded extends GuideToursState {
  final List<TourEntity> tours;

  const GuideToursLoaded(this.tours);

  @override
  List<Object?> get props => [tours];
}

class GuideToursError extends GuideToursState {
  final String message;

  const GuideToursError(this.message);

  @override
  List<Object?> get props => [message];
}
