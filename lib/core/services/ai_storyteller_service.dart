import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

class AIStorytellerService {
  static Future<String> getLandmarkStory(String landmarkName) async {
    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('analyzeImageOrStory');
      final result = await callable.call(<String, dynamic>{
        'landmarkName': landmarkName,
      });

      return result.data['story'] ?? "I'm sorry, I couldn't find a story for this place yet.";
    } on FirebaseFunctionsException catch (e) {
      debugPrint("AI Storyteller Cloud Function error: \${e.code} - \${e.message}");
      return "The spirits of history are silent right now. Please try again later.";
    } catch (e) {
      debugPrint("AI Storyteller error: \$e");
      return "The spirits of history are silent right now. Error: \$e";
    }
  }
}

