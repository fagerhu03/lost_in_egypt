import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_all_tours_usecase.dart';
import 'explorer_tours_state.dart';

class ExplorerToursCubit extends Cubit<ExplorerToursState> {
  final GetAllToursUseCase getAllToursUseCase;

  ExplorerToursCubit({required this.getAllToursUseCase}) : super(ExplorerToursInitial());

  Future<void> loadTours() async {
    emit(ExplorerToursLoading());
    final result = await getAllToursUseCase();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    result.fold(
      (failure) => emit(ExplorerToursError(failure.message)),
      (tours) {
        final filtered = currentUserId != null
            ? tours.where((t) => t.guideId != currentUserId).toList()
            : tours;
        emit(ExplorerToursLoaded(filtered));
      },
    );
  }
}
