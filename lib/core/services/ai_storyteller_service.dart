import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

class AIStorytellerService {
  static Future<String> getLandmarkStory(String landmarkName, {String locale = 'en'}) async {
    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('analyzeImageOrStory');
      final result = await callable.call(<String, dynamic>{
        'landmarkName': landmarkName,
        'locale': locale,
      });

      return result.data['story'] ?? "I'm sorry, I couldn't find a story for this place yet.";
    } on FirebaseFunctionsException catch (e) {
      debugPrint("AI Storyteller Cloud Function error: ${e.code} - ${e.message}");
      return "The spirits of history are silent right now. Please try again later.";
    } catch (e) {
      debugPrint("AI Storyteller error: $e");
      return "The spirits of history are silent right now. Please try again later.";
    }
  }

  /// Calls Google Cloud TTS via our Cloud Function and returns raw MP3 bytes.
  static Future<Uint8List?> getStoryAudio(String storyText, {String locale = 'en'}) async {
    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable(
        'generateStoryAudio',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
      );
      final result = await callable.call(<String, dynamic>{
        'text': storyText,
        'locale': locale,
      });

      final base64Audio = result.data['audio'] as String?;
      if (base64Audio == null || base64Audio.isEmpty) return null;

      return base64Decode(base64Audio);
    } on FirebaseFunctionsException catch (e) {
      debugPrint("AI Audio Cloud Function error: ${e.code} - ${e.message}");
      return null;
    } catch (e) {
      debugPrint("AI Audio error: $e");
      return null;
    }
  }
}
