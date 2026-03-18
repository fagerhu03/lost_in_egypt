import 'package:equatable/equatable.dart';
import '../../../../feature/auth/domain/entities/user_entity.dart';

abstract class AdminGuideState extends Equatable {
  const AdminGuideState();
  @override
  List<Object> get props => [];
}

class AdminGuideInitial extends AdminGuideState {}

class AdminGuideLoading extends AdminGuideState {}

class AdminGuideLoaded extends AdminGuideState {
  final List<UserEntity> pendingGuides;
  const AdminGuideLoaded(this.pendingGuides);
  @override
  List<Object> get props => [pendingGuides];
}

class AdminGuideError extends AdminGuideState {
  final String message;
  const AdminGuideError(this.message);
  @override
  List<Object> get props => [message];
}

class AdminGuideActionSuccess extends AdminGuideLoaded {
  final String actionMessage;
  const AdminGuideActionSuccess(super.pendingGuides, this.actionMessage);
  @override
  List<Object> get props => [pendingGuides, actionMessage];
}
