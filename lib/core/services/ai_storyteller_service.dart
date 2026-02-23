import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class AIStorytellerService {
  static Future<String> getLandmarkStory(String landmarkName) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    
    if (apiKey.isEmpty) {
      return "Gemini API key not found. Please add GEMINI_API_KEY to your .env file.";
    }

    try {
      final model = GenerativeModel(model: 'gemini-flash-latest', apiKey: apiKey);
      
      final prompt = """
        You are a fascinating historical guide for Egypt. 
        I have identified this landmark: $landmarkName. 
        Tell me a short, captivating story or provide 3 amazing facts about it in 150 words or less. 
        Make it sound like an adventure!
        Don't use any symbols since this will be read aloud. Just pure storytelling.
      """;

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      
      return response.text ?? "I'm sorry, I couldn't find a story for this place yet.";
    } catch (e) {
      debugPrint("AI Storyteller error: $e");
      return "The spirits of history are silent right now. Please try again later.";
    }
  }
}
