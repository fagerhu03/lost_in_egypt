import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image/image.dart' as img; // Make sure 'image' package is in pubspec.yaml

class LandmarkService {
  
  static Future<String?> identifyLandmark(File imageFile) async {
    // 1. Read key from .env
    // Ensure you have a file named .env in your root with: GOOGLE_CLOUD_VISION_API_KEY=your_key
    final String apiKey = dotenv.env['GOOGLE_CLOUD_VISION_API_KEY'] ?? '';
    
    if (apiKey.isEmpty) {
      throw Exception("API Key not found in .env file. Please check your configuration.");
    }

    try {
      // 2. OPTIMIZATION: Resize the image before uploading
      // Google Vision doesn't need 12MP photos. 800px is plenty and 10x faster.
      List<int> imageBytes = await imageFile.readAsBytes();
      
      // Decode the image to manipulate it
      img.Image? originalImage = img.decodeImage(Uint8List.fromList(imageBytes));
      
      if (originalImage != null) {
        // Resize to a max width of 800px, maintaining aspect ratio
        img.Image resized = img.copyResize(originalImage, width: 800);
        // Encode back to JPG with 85% quality
        imageBytes = img.encodeJpg(resized, quality: 85);
      }

      // 3. Convert to Base64
      String base64Image = base64Encode(imageBytes);

      // 4. Prepare the Request Body
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

      // 5. Send Request to Google Cloud Vision API
      var response = await http.post(
        Uri.parse('https://vision.googleapis.com/v1/images:annotate?key=$apiKey'),
        headers: {
          "Content-Type": "application/json",
          // Optional: Add Android package restriction headers here if you set them up in Google Console
          // "X-Android-Package": "com.example.yourapp",
          // "X-Android-Cert": "YOUR_SHA1_FINGERPRINT", 
        },
        body: jsonEncode(requestBody),
      );

      // 6. Handle Response
      if (response.statusCode == 200) {
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        
        // The API returns a list of 'responses' (one per image sent)
        var responses = jsonResponse['responses'] as List?;

        if (responses != null && responses.isNotEmpty) {
          var firstResponse = responses[0] as Map<String, dynamic>;
          
          // Check if any landmarks were actually found
          if (firstResponse.containsKey('landmarkAnnotations')) {
            var landmarks = firstResponse['landmarkAnnotations'] as List?;
            
            if (landmarks != null && landmarks.isNotEmpty) {
              // Success! Return the name of the first landmark found
              String landmarkName = landmarks[0]['description'];
              return landmarkName;
            }
          }
        }
        return null;
      } else {
        throw Exception("API Error: ${response.statusCode} - ${response.body}");
      }

    } catch (e) {
      rethrow;
    }
  }
}
