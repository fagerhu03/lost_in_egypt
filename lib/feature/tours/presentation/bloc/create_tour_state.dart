import 'package:equatable/equatable.dart';

abstract class CreateTourState extends Equatable {
  const CreateTourState();

  @override
  List<Object?> get props => [];
}

class CreateTourInitial extends CreateTourState {}

class CreateTourLoading extends CreateTourState {}

class CreateTourSuccess extends CreateTourState {}

class CreateTourError extends CreateTourState {
  final String message;

  const CreateTourError(this.message);

  @override
  List<Object?> get props => [message];
}
