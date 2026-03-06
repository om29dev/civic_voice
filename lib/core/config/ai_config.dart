import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIConfig {
  // Google Gemini — for document image reading
  // Get free key at: aistudio.google.com
  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  
  // Use gemini-2.5-flash as it is listed in the project models
  static String get geminiUrl => 
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  // Groq — for Voice AI and Chat (Supports text only)
  static String get groqApiKey => dotenv.env['GROQ_API_KEY'] ?? '';
}
