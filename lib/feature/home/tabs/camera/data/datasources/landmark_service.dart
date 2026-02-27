import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:image/image.dart' as img;

class LandmarkService {
  
  static Future<String?> identifyLandmark(File imageFile) async {
    try {
      // 1. OPTIMIZATION: Resize the image before uploading
      List<int> imageBytes = await imageFile.readAsBytes();
      
      img.Image? originalImage = img.decodeImage(Uint8List.fromList(imageBytes));
      
      if (originalImage != null) {
        // Resize to a max width of 800px, maintaining aspect ratio
        img.Image resized = img.copyResize(originalImage, width: 800);
        // Encode back to JPG with 85% quality
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
      throw Exception("Cloud Function Error: \${e.code} - \${e.message}");
    } catch (e) {
      rethrow;
    }
  }
}

