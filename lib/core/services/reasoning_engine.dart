import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../../models/scheme_model.dart';
import 'scheme_knowledge_base.dart';

enum Intent { discovery, schemeInfo, eligibility, documents, process, unknown }

class ReasoningEngine {
  final String languageCode; // 'en' or 'hi'
  late final String _apiKey;
  static const String _apiUrl = 'https://api.groq.com/openai/v1/chat/completions';
  
  ReasoningEngine({this.languageCode = 'en'}) {
    _apiKey = (dotenv.env['GROQ_API_KEY'] ?? '').trim();
    if (_apiKey.isEmpty) {
      debugPrint("WARNING: GROQ_API_KEY is missing in .env file");
    }
  }

  String _buildSystemInstruction() {
    final schemesSummary = SchemeKnowledgeBase.schemes.map((s) {
      return """
      Scheme: ${s.names['en']} (${s.names['hi']})
      ID: ${s.id}
      Description: ${s.description}
      Eligibility: ${s.eligibilityRules.map((r) => r.explanation['en']).join(', ')}
      Documents: ${s.requiredDocuments.map((d) => d.name['en']).join(', ')}
      Steps: ${s.steps.map((st) => st.title['en']).join(', ')}
      Alternatives: ${s.alternativeSchemeIds?.join(', ') ?? 'None'}
      """;
    }).join("\n---\n");

    return """
    You are 'Civic Voice Assistant' (CVI), an advanced AI specialized in Indian Government Schemes.
    
    KNOWLEDGE BASE:
    $schemesSummary

    Your goal is to guide checking eligibility, explaining benefits, and navigating application processes.

    Intelligence Guidelines:
    1. **"What-If" & Disqualification (Feature 1)**:
       - If a user fails an eligibility rule (e.g., age < 60), DO NOT just say "You are not eligible."
       - IMMEDIATELY suggest the 'Alternatives' listed for that scheme.
       - Use the format: "Unfortunately, you don't qualify for [Scheme A] because [Reason]. However, you might qualify for: [Scheme B]..."
       - Offer a "What-If" path: "If you can obtain [missing document], you can apply."

    2. **Comparison Engine (Feature 8)**:
       - If user asks "Which is better?", compare schemes side-by-side.
       - Compare on: Benefits, Eligibility, and Time.
       - Use bullet points for clarity.

    3. **Fraud Detection (Feature 14)**:
       - If the user mentions "paying money", "agent", "bribe", or "password", TRIGGER A FRAUD WARNING.
       - Say: "⚠️ WARNING: Government schemes never ask for money or passwords. This sounds like a SCAM. Do not pay anyone."

    4. **Status & Process**:
       - Simplify steps. Don't read long lists unless asked.
    
    5. **Voice Notes & Reminders (Feature 9)**:
       - If user says "Remind me to [Task] at [Time]" or "Take a note", output a STRUCTURAL ACTION.
       - Format: `[ACTION:REMINDER] {"title": "Reminder", "body": "[Task]", "time": "[Time]" } | I've set a reminder for [Task].`
       - Example: User: "Remind me to call Mom at 5 PM." -> `[ACTION:REMINDER] {"title": "Call Mom", "body": "Don't forget to call Mom", "time": "5:00 PM"} | I've scheduled a reminder to call Mom at 5 PM.`

    Response Format:
    - Keep it under 3 sentences for voice output.
    - Use bullet points (•) for lists (UI renders these well).
    """;
  }

  Future<String> generateAIResponse(String userInput, List<Map<String, String>> history) async {
    try {
      // Build messages array with system instruction and history
      final messages = [
        {'role': 'system', 'content': _buildSystemInstruction()},
        ...history,
        {'role': 'user', 'content': userInput},
      ];

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 300,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        return content ?? "I'm sorry, I couldn't process that.";
      } else if (response.statusCode == 429) {
        debugPrint("Groq Rate Limit: ${response.body}");
        return "I'm thinking too fast! Please wait a moment and try again.";
      } else {
        debugPrint("Groq API Error (${response.statusCode}): ${response.body}");
        return "I'm having trouble connecting. Please check your internet and try again.";
      }
    } catch (e) {
      debugPrint("Groq Error: $e");
      return "I'm having connectivity issues. Please check your internet connection and try again.";
    }
  }

  String? _activeVisionModel;

  Future<String> _getBestVisionModel() async {
    if (_activeVisionModel != null) return _activeVisionModel!;

    try {
      final response = await http.get(
        Uri.parse('https://api.groq.com/openai/v1/models'),
        headers: {'Authorization': 'Bearer $_apiKey'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> models = data['data'];
        final modelIds = models.map((m) => m['id'].toString()).toList();
        
        // Priority list of models to look for
        final candidates = [
          'llama-3.2-90b-vision-preview',
          'llama-3.2-11b-vision-preview',
          'llama-3.2-90b-vision',
          'llama-3.2-11b-vision',
          'llama-3.2-90b-vision-instruct',
          'llama-3.2-11b-vision-instruct',
        ];

        for (final candidate in candidates) {
          if (modelIds.contains(candidate)) {
            debugPrint("Selected Active Vision Model: $candidate");
            _activeVisionModel = candidate;
            return candidate;
          }
        }
        
        // If none of our specific favorites are found, look for ANY llama vision model
        final fallback = modelIds.firstWhere(
          (id) => id.contains('llama') && id.contains('vision'),
          orElse: () => 'llama-3.2-11b-vision-preview', // Desperate fallback
        );
        _activeVisionModel = fallback;
        return fallback;
      }
    } catch (e) {
      debugPrint("Failed to fetch models list: $e");
    }

    // Default if API fails
    return 'llama-3.2-11b-vision-preview'; 
  }

  Future<Map<String, dynamic>> verifyDocumentImage(String base64Image) async {
    final String modelId = await _getBestVisionModel();
    debugPrint("Verifying with model: $modelId");

    const String verificationPrompt = """
    You are an expert Document Verifier for Indian Government IDs.
    Analyze the attached image and determine:
    1. Is this a valid document (Aadhaar, PAN, Voter ID, Ration Card, etc.)?
    2. Is it expired? (Compare found dates with today's date: 2026-01-26).
    3. Extract any key text found on the document.
    4. Provide a concise verification message.

    Return ONLY a JSON object with these keys:
    - "isValid": boolean
    - "message": string (concise explanation)
    - "documentType": string or null
    - "expiryDate": string (ISO 8601) or null
    - "extractedText": string
    """;

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': modelId, 
          'messages': [
            {
              'role': 'user',
              'content': [
                {'type': 'text', 'text': verificationPrompt},
                {
                  'type': 'image_url',
                  'image_url': {'url': 'data:image/jpeg;base64,$base64Image'}
                },
              ],
            },
          ],
          'temperature': 0.1,
          'response_format': {'type': 'json_object'},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return jsonDecode(data['choices'][0]['message']['content']);
      } else {
        debugPrint("Groq Vision API Error (${response.statusCode}): ${response.body}");
        // Explicitly clear cached model on 404 or 400 to force retry next time
        if (response.statusCode == 404 || response.statusCode == 400) {
             _activeVisionModel = null;
        }
        return {
          "isValid": false,
          "message": "AI Error (${response.statusCode}): ${response.body}",
          "documentType": null,
          "expiryDate": null,
          "extractedText": ""
        };
      }
    } catch (e) {
      debugPrint("Groq Vision Error: $e");
      return {
        "isValid": false,
        "message": "Connection Error: $e",
        "documentType": null,
        "expiryDate": null,
        "extractedText": ""
      };
    }
    
    // Fallback (unreachable ideally)
    return {
      "isValid": false,
      "message": "Unknown AI Error",
      "documentType": null,
      "expiryDate": null,
      "extractedText": ""
    };
  }

  Future<String> translateText(String text, String sourceLanguage) async {
    if (sourceLanguage.toLowerCase() == 'en' || sourceLanguage.toLowerCase() == 'english') return text;
    
    final String prompt = """
    Translate the following text from $sourceLanguage to English. 
    Return ONLY the translated English text, no explanations or quotes.
    """;

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'messages': [
            {'role': 'system', 'content': prompt},
            {'role': 'user', 'content': text},
          ],
          'temperature': 0.1,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].toString().trim();
      }
    } catch (e) {
      debugPrint("Groq Translation Error: $e");
    }
    return text; // Fallback to original text
  }

  // Legacy methods kept for compatibility
  Intent parseIntent(String text) => Intent.unknown;
  String detectSchemeId(String text) => 'unknown';
  String generateResponse(Intent intent, GovernmentScheme scheme, Map<String, dynamic> context) => "";
}
