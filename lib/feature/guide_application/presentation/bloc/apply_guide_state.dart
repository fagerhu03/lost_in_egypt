import 'package:equatable/equatable.dart';

abstract class ApplyGuideState extends Equatable {
  const ApplyGuideState();

  @override
  List<Object> get props => [];
}

class ApplyGuideInitial extends ApplyGuideState {}

class ApplyGuideLoading extends ApplyGuideState {}

class ApplyGuideSuccess extends ApplyGuideState {}

class ApplyGuideError extends ApplyGuideState {
  final String message;

  const ApplyGuideError(this.message);

  @override
  List<Object> get props => [message];
}
