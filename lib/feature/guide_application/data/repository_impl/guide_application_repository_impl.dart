import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/guide_application_repository.dart';
import '../datasources/guide_application_data_source.dart';

class GuideApplicationRepositoryImpl implements GuideApplicationRepository {
  final GuideApplicationDataSource remoteDataSource;

  GuideApplicationRepositoryImpl({required this.remoteDataSource});

  @override
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
  }) async {
    try {
      await remoteDataSource.submitApplication(
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
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
