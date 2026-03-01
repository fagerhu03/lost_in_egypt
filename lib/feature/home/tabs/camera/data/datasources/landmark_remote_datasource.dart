import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:image/image.dart' as img;

/// Custom exception for landmark detection errors
class LandmarkDetectionException implements Exception {
  final String message;
  final bool isApiKeyError;

  LandmarkDetectionException(this.message, {this.isApiKeyError = false});

  @override
  String toString() => message;
}

/// Data source for calling Google Cloud Vision API
class LandmarkRemoteDataSource {
  /// Identifies a landmark from the given image file
  /// Throws [LandmarkDetectionException] on errors
  Future<String?> identifyLandmark(File imageFile) async {
    try {
      // 1. Read and resize the image for better performance
      List<int> imageBytes = await imageFile.readAsBytes();
      
      img.Image? originalImage = img.decodeImage(Uint8List.fromList(imageBytes));
      
      if (originalImage != null) {
        // Resize to max 800px width for faster API response
        img.Image resized = img.copyResize(originalImage, width: 800);
        imageBytes = img.encodeJpg(resized, quality: 85);
      }

      // 2. Convert to Base64
      String base64Image = base64Encode(imageBytes);

      // 3. Call Cloud Function securely
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('identifyLandmark');
      
      final result = await callable.call(<String, dynamic>{
        'base64Image': base64Image,
      });

      // 4. Handle Response
      if (result.data != null && result.data['landmarkName'] != null) {
        return result.data['landmarkName'] as String;
      }
      
      return null;
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'unauthenticated') {
         throw LandmarkDetectionException('You must be logged in to identify landmarks.', isApiKeyError: false);
      } else if (e.code == 'resource-exhausted') {
         throw LandmarkDetectionException('API Usage Limit Reached. Please try again later.');
      }
      throw LandmarkDetectionException('Cloud Function Error: ${e.code} - ${e.message}');
    } catch (e) {
      throw LandmarkDetectionException('Failed to identify landmark: $e');
    }
  }
}

