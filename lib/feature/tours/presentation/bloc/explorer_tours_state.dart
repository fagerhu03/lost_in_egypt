import 'package:equatable/equatable.dart';
import '../../domain/entities/tour_entity.dart';

abstract class ExplorerToursState extends Equatable {
  const ExplorerToursState();

  @override
  List<Object> get props => [];
}

class ExplorerToursInitial extends ExplorerToursState {}

class ExplorerToursLoading extends ExplorerToursState {}

class ExplorerToursLoaded extends ExplorerToursState {
  final List<TourEntity> tours;

  const ExplorerToursLoaded(this.tours);

  @override
  List<Object> get props => [tours];
}

class ExplorerToursError extends ExplorerToursState {
  final String message;

  const ExplorerToursError(this.message);

  @override
  List<Object> get props => [message];
}
