import 'dart:io';
import '../entities/landmark_entity.dart';

/// Abstract repository for landmark detection operations
abstract class LandmarkRepository {
  /// Identifies a landmark from the given image file
  /// Returns the landmark name if found, null otherwise
  Future<LandmarkEntity?> identifyLandmark(File imageFile);
}
