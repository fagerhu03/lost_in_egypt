import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
    final String apiKey = dotenv.env['GOOGLE_CLOUD_VISION_API_KEY'] ?? '';

    if (apiKey.isEmpty) {
      throw LandmarkDetectionException(
        'Google Cloud Vision API key not found. Please add GOOGLE_CLOUD_VISION_API_KEY to your .env file.',
        isApiKeyError: true,
      );
    }

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

      // 3. Prepare request
      Map<String, dynamic> requestBody = {
        "requests": [
          {
            "image": {"content": base64Image},
            "features": [
              {"type": "LANDMARK_DETECTION", "maxResults": 1}
            ]
          }
        ]
      };

      // 4. Send request to Google Cloud Vision API
      var response = await http.post(
        Uri.parse('https://vision.googleapis.com/v1/images:annotate?key=$apiKey'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      // 5. Handle response
      if (response.statusCode == 200) {
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        var responses = jsonResponse['responses'] as List?;

        if (responses != null && responses.isNotEmpty) {
          var firstResponse = responses[0] as Map<String, dynamic>;
          
          if (firstResponse.containsKey('landmarkAnnotations')) {
            var landmarks = firstResponse['landmarkAnnotations'] as List?;
            
            if (landmarks != null && landmarks.isNotEmpty) {
              return landmarks[0]['description'];
            }
          }
        }
        return null; // No landmark found
      } else if (response.statusCode == 403) {
        throw LandmarkDetectionException(
          'API key is invalid or has insufficient permissions.',
          isApiKeyError: true,
        );
      } else {
        throw LandmarkDetectionException(
          'API error: ${response.statusCode} - ${response.body}',
        );
      }

    } on LandmarkDetectionException {
      rethrow;
    } catch (e) {
      throw LandmarkDetectionException('Failed to identify landmark: $e');
    }
  }
}
