import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/apply_guide_usecase.dart';
import 'apply_guide_state.dart';

class ApplyGuideCubit extends Cubit<ApplyGuideState> {
  final ApplyGuideUseCase applyGuideUseCase;

  ApplyGuideCubit({required this.applyGuideUseCase}) : super(ApplyGuideInitial());

  Future<void> submitApplication({
    required String motaLicenseNumber,
    required String syndicateNumber,
    required List<String> certifiedLanguages,
    required File motaLicenseImage,
    required File syndicateCardImage,
    required File nationalIdFrontImage,
    required File nationalIdBackImage,
    required File selfieWithIdImage,
    required File profileImage,
  }) async {
    emit(ApplyGuideLoading());

    final params = ApplyGuideParams(
      motaLicenseNumber: motaLicenseNumber,
      syndicateNumber: syndicateNumber,
      certifiedLanguages: certifiedLanguages,
      motaLicenseImage: motaLicenseImage,
      syndicateCardImage: syndicateCardImage,
      nationalIdFrontImage: nationalIdFrontImage,
      nationalIdBackImage: nationalIdBackImage,
      selfieWithIdImage: selfieWithIdImage,
      profileImage: profileImage,
    );

    final result = await applyGuideUseCase(params);

    result.fold(
      (failure) => emit(ApplyGuideError(failure.message)),
      (_) => emit(ApplyGuideSuccess()),
    );
  }
}
