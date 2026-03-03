import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';

abstract class GuideApplicationRepository {
  Future<Either<Failure, void>> submitApplication({
    required String motaLicenseNumber,
    required String syndicateNumber,
    required List<String> certifiedLanguages,
    required File motaLicenseImage,
    required File syndicateCardImage,
    required File nationalIdFrontImage,
    required File nationalIdBackImage,
    required File selfieWithIdImage,
    required File profileImage,
  });
}
