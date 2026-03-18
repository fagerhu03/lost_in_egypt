import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_all_tours_usecase.dart';
import 'explorer_tours_state.dart';

class ExplorerToursCubit extends Cubit<ExplorerToursState> {
  final GetAllToursUseCase getAllToursUseCase;

  ExplorerToursCubit({required this.getAllToursUseCase}) : super(ExplorerToursInitial());

  Future<void> loadTours() async {
    emit(ExplorerToursLoading());
    final result = await getAllToursUseCase();

    result.fold(
      (failure) => emit(ExplorerToursError(failure.message)),
      (tours) => emit(ExplorerToursLoaded(tours)),
    );
  }
}
