import 'dart:io';
import '../../domain/entities/landmark_entity.dart';
import '../../domain/repositories/landmark_repository.dart';
import '../datasources/landmark_remote_datasource.dart';

/// Implementation of [LandmarkRepository] using Google Cloud Vision API
class LandmarkRepositoryImpl implements LandmarkRepository {
  final LandmarkRemoteDataSource _remoteDataSource;

  LandmarkRepositoryImpl({LandmarkRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? LandmarkRemoteDataSource();

  @override
  Future<LandmarkEntity?> identifyLandmark(File imageFile) async {
    try {
      final String? landmarkName = await _remoteDataSource.identifyLandmark(imageFile);
      
      if (landmarkName == null) {
        return null;
      }

      return LandmarkEntity(
        name: landmarkName,
        confidence: null, // Google Vision doesn't always return confidence for landmarks
      );
    } on LandmarkDetectionException {
      rethrow;
    } catch (e) {
      throw LandmarkDetectionException('Something went wrong. Please try again.');
    }
  }
}
