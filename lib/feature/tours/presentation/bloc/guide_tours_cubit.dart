import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_guide_tours_usecase.dart';
import 'guide_tours_state.dart';

class GuideToursCubit extends Cubit<GuideToursState> {
  final GetGuideToursUseCase getGuideToursUseCase;

  GuideToursCubit({required this.getGuideToursUseCase}) : super(GuideToursInitial());

  Future<void> fetchTours(String guideId) async {
    emit(GuideToursLoading());
    final result = await getGuideToursUseCase(guideId);
    result.fold(
      (failure) => emit(GuideToursError(failure.message)),
      (tours) => emit(GuideToursLoaded(tours)),
    );
  }

  void removeTour(String tourId) {
    final current = state;
    if (current is GuideToursLoaded) {
      emit(GuideToursLoaded(current.tours.where((t) => t.id != tourId).toList()));
    }
  }
}
