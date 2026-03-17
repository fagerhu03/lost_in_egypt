import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/guide_application_repository.dart';

class ApplyGuideUseCase {
  final GuideApplicationRepository repository;

  ApplyGuideUseCase(this.repository);

  Future<Either<Failure, void>> call(ApplyGuideParams params) async {
    return await repository.submitApplication(
      motaLicenseNumber: params.motaLicenseNumber,
      syndicateNumber: params.syndicateNumber,
      certifiedLanguages: params.certifiedLanguages,
      motaLicenseImage: params.motaLicenseImage,
      syndicateCardImage: params.syndicateCardImage,
      nationalIdFrontImage: params.nationalIdFrontImage,
      nationalIdBackImage: params.nationalIdBackImage,
      selfieWithIdImage: params.selfieWithIdImage,
      profileImage: params.profileImage,
    );
  }
}

class ApplyGuideParams {
  final String motaLicenseNumber;
  final String syndicateNumber;
  final List<String> certifiedLanguages;
  final File motaLicenseImage;
  final File syndicateCardImage;
  final File nationalIdFrontImage;
  final File nationalIdBackImage;
  final File selfieWithIdImage;
  final File profileImage;

  ApplyGuideParams({
    required this.motaLicenseNumber,
    required this.syndicateNumber,
    required this.certifiedLanguages,
    required this.motaLicenseImage,
    required this.syndicateCardImage,
    required this.nationalIdFrontImage,
    required this.nationalIdBackImage,
    required this.selfieWithIdImage,
    required this.profileImage,
  });
}
