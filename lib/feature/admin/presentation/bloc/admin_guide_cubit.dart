import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/admin_usecases.dart';
import 'admin_guide_state.dart';

class AdminGuideCubit extends Cubit<AdminGuideState> {
  final GetPendingGuidesUseCase getPendingGuidesUseCase;
  final ApproveGuideUseCase approveGuideUseCase;
  final RejectGuideUseCase rejectGuideUseCase;

  AdminGuideCubit({
    required this.getPendingGuidesUseCase,
    required this.approveGuideUseCase,
    required this.rejectGuideUseCase,
  }) : super(AdminGuideInitial());

  Future<void> fetchPendingGuides() async {
    emit(AdminGuideLoading());
    final result = await getPendingGuidesUseCase();
    result.fold(
      (failure) => emit(AdminGuideError(failure.message)),
      (guides) => emit(AdminGuideLoaded(guides)),
    );
  }

  Future<void> approveGuide(String userId) async {
    final currentState = state;
    if (currentState is AdminGuideLoaded) {
      emit(AdminGuideLoading());
      final result = await approveGuideUseCase(userId);
      result.fold(
        (failure) => emit(AdminGuideError(failure.message)),
        (_) {
          final updatedList = currentState.pendingGuides.where((g) => g.id != userId).toList();
          emit(AdminGuideActionSuccess(updatedList, 'Guide approved successfully'));
          emit(AdminGuideLoaded(updatedList));
        },
      );
    }
  }

  Future<void> rejectGuide(String userId, String rejectionReason) async {
    final currentState = state;
    if (currentState is AdminGuideLoaded) {
      emit(AdminGuideLoading());
      final result = await rejectGuideUseCase(userId, rejectionReason);
      result.fold(
        (failure) => emit(AdminGuideError(failure.message)),
        (_) {
          final updatedList = currentState.pendingGuides.where((g) => g.id != userId).toList();
          emit(AdminGuideActionSuccess(updatedList, 'Guide rejected successfully'));
          emit(AdminGuideLoaded(updatedList));
        },
      );
    }
  }
}
