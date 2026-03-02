import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
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

      // 3. Call Cloud Function securely using HTTP to bypass Android SDK ExecutionException
      final user = FirebaseAuth.instance.currentUser;
      final idToken = await user?.getIdToken();

      if (idToken == null) {
        throw LandmarkDetectionException(
            'You must be logged in to identify landmarks.',
            isApiKeyError: false);
      }

      final url = Uri.parse(
          'https://us-central1-lost-in-egypt-elasly.cloudfunctions.net/identifyLandmark');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'data': {
            'base64Image': base64Image,
          }
        }),
      );

      // 4. Handle Response
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData.containsKey('result') && responseData['result'] != null) {
          final resultData = responseData['result'];
          if (resultData['landmarkName'] != null) {
            return resultData['landmarkName'] as String;
          }
        }
        return null;
      } else {
        // Attempt to parse Firebase function error message
        String errorMsg = 'Unknown error';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData.containsKey('error') &&
              errorData['error']['message'] != null) {
            errorMsg = errorData['error']['message'];
          }
        } catch (_) {}

        if (response.statusCode == 401 || response.statusCode == 403) {
          throw LandmarkDetectionException(
              'You must be logged in to identify landmarks.',
              isApiKeyError: false);
        } else if (response.statusCode == 429) {
          throw LandmarkDetectionException(
              'API Usage Limit Reached. Please try again later.');
        }
        throw LandmarkDetectionException(
            'Cloud Function HTTP Error: ${response.statusCode} - $errorMsg');
      }
    } catch (e) {
      if (e is LandmarkDetectionException) rethrow;
      throw LandmarkDetectionException('Failed to identify landmark: $e');
    }
  }
}

