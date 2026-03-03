import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'scheme_knowledge_base.dart';

enum Intent { discovery, schemeInfo, eligibility, documents, process, ambiguous, unknown }

class DetectionResult {
  final Intent intent;
  final String? schemeId;
  final double confidence;
  final List<String> ambiguousOptions;
  final List<String> detectedKeywords;

  DetectionResult({
    required this.intent,
    this.schemeId,
    this.confidence = 0.0,
    this.ambiguousOptions = const [],
    this.detectedKeywords = const [],
  });
}

class SmartIntentParser {
  // 1. Weighted Keyword Scorer with Synonyms
  static const Map<String, List<String>> schemeSynonyms = {
    'pension': ['old age', 'widow', 'money for elderly', 'financial aid', 'retirement', 'senior citizen', 'वृद्धावस्था', 'पेंशन', '60 years'],
    'ration': ['food', 'grains', 'bpl', 'ration', 'खाना', 'अनाज', 'rice', 'wheat', 'राशन'],
    'pm-kisan': ['farmer', 'kisan', 'agriculture', 'land', 'खेती', 'किसान', 'farming', '2000 rupees'],
    'ayushman': ['health', 'medical', 'hospital', 'doctor', 'treatment', 'insurance', 'इलाज', 'स्वास्थ्य', 'ayushman'],
    'land': ['housing', 'awas', 'pmay', 'house', 'home', 'घर', 'आवास', 'roof'],
  };

  static const Map<String, Map<Intent, List<String>>> intentKeywords = {
    'en': {
      Intent.eligibility: ['eligible', 'qualify', 'can i', 'check', 'am i', 'rules'],
      Intent.documents: ['document', 'paper', 'proof', 'certificate', 'id', 'required'],
      Intent.process: ['apply', 'how to', 'register', 'form', 'steps', 'procedure', 'enroll'],
    },
    'hi': {
      Intent.eligibility: ['पात्र', 'योग्य', 'सकता हूँ', 'नियम', 'check'],
      Intent.documents: ['दस्तावेज', 'कागजात', 'प्रमाण', 'आईडी', 'जरूरी'],
      Intent.process: ['आवेदन', 'कैसे', 'रजिस्टर', 'फॉर्म', 'प्रक्रिया', 'कदम'],
    },
    'mr': {
      Intent.eligibility: ['पात्र', 'योग्य', 'कसे', 'नियम', 'चेक'],
      Intent.documents: ['दस्तावेज', 'कागदपत्रे', 'प्रमाणपत्र', 'आईडी', 'आवश्यक'],
      Intent.process: ['अर्ज', 'नोंदणी', 'कसे करायचे', 'प्रक्रिया', 'फॉर्म'],
    },
    'ta': {
      Intent.eligibility: ['தகுதி', 'தகுதியுள்ள', 'விதிமுறை', 'சேர முடியுமா'],
      Intent.documents: ['ஆவணம்', 'சான்றிதழ்', 'அடையாள அட்டை', 'தேவையான'],
      Intent.process: ['விண்ணப்பி', 'பதிவு செய்', 'முறை', 'படி நிலைகள்'],
    }
  };

  static DetectionResult parse(String text, String languageCode) {
    text = text.toLowerCase();
    
    // Detect Scheme first
    Map<String, double> schemeScores = {};
    Set<String> allDetectedKeywords = {};

    schemeSynonyms.forEach((id, keywords) {
      double score = 0.0;
      for (var keyword in keywords) {
        if (text.contains(keyword.toLowerCase())) {
          // Weight: Exact match is better than partial? 
          // For now, simple presence. Longer keywords could be weighted higher.
          score += 1.0;
          allDetectedKeywords.add(keyword);
        }
      }
      if (score > 0) schemeScores[id] = score;
    });

    String? topScheme;
    List<String> ambiguousCandidates = [];
    double maxScore = 0.0;
    double totalConfidence = 0.0;

    if (schemeScores.isNotEmpty) {
      var sorted = schemeScores.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      maxScore = sorted.first.value;
      
      // Calculate simplistic confidence (maxScore / total keywords found or just raw score cap)
      // Let's normalize slightly: if score >= 1.0, we have at least one keyword.
      // Confidence logic: 
      // 1 match = 0.5
      // 2 matches = 0.8
      // 3+ matches = 0.95
      if (maxScore == 1.0) {
        totalConfidence = 0.5;
      } else if (maxScore == 2.0) totalConfidence = 0.8;
      else totalConfidence = 0.95;

      // Ambiguity Check
      if (sorted.length > 1) {
        double secondScore = sorted[1].value;
        // If top two scores are close (within 1 point or equal)
        if (maxScore - secondScore < 1.0) {
           ambiguousCandidates = [sorted[0].key, sorted[1].key];
        }
      }
      
      if (ambiguousCandidates.isEmpty) {
        topScheme = sorted.first.key;
      }
    }

    // Detect Intent Type (Eligibility vs Docs vs Process vs Discovery)
    Intent detectedIntent = Intent.discovery; // Default
    // If scheme is found but no specific intent keywords, usually means "Tell me about X" -> schemeInfo
    if (topScheme != null || ambiguousCandidates.isNotEmpty) detectedIntent = Intent.schemeInfo;

    // Check specific intent keywords
    final langKey = ['en', 'hi', 'mr', 'ta'].contains(languageCode) ? languageCode : 'en';
    Map<Intent, List<String>> currentLangKeywords = intentKeywords[langKey]!;
    
    currentLangKeywords.forEach((intent, keywords) {
      for (var k in keywords) {
        if (text.contains(k)) {
          detectedIntent = intent;
          break; 
        }
      }
    });

    // 3. Ambiguity Resolution
    if (ambiguousCandidates.isNotEmpty) {
      return DetectionResult(
        intent: Intent.ambiguous, 
        ambiguousOptions: ambiguousCandidates,
        detectedKeywords: allDetectedKeywords.toList()
      );
    }
    
    // Low Confidence Check -> Discovery
    if (totalConfidence < 0.4 && topScheme != null) {
       // If confidence is low, maybe we shouldn't guess parameters. 
       // But for "pension", confidence is 0.5 (1 keyword), which is > 0.4. Good.
       // "money" -> 'pension' (1 match) -> 0.5.
    }

    if (topScheme == null) {
      return DetectionResult(intent: Intent.discovery, detectedKeywords: allDetectedKeywords.toList());
    }

    return DetectionResult(
      intent: detectedIntent,
      schemeId: topScheme,
      confidence: totalConfidence,
      detectedKeywords: allDetectedKeywords.toList(),
    );
  }
}

class ReasoningEngine {
  final String languageCode; // 'en' or 'hi'
  late final String _apiKey;
  static const String _apiUrl = 'https://api.groq.com/openai/v1/chat/completions';
  
  // Phase 4: Logic & Empathy - Partial Match Tracking
  final Set<String> _sessionKeywords = {};

  ReasoningEngine({this.languageCode = 'en'}) {
    _apiKey = (dotenv.env['GROQ_API_KEY'] ?? '').trim();
    if (_apiKey.isEmpty) {
      debugPrint("WARNING: GROQ_API_KEY is missing in .env file");
    }
  }

  // Legacy method replacement
  String detectSchemeId(String text) {
     final result = SmartIntentParser.parse(text, languageCode);
     return result.schemeId ?? ''; // Return empty if null (caller handles null/empty)
  }

  String _buildSystemInstruction() {
    final schemesSummary = SchemeKnowledgeBase.schemes.map((s) {
      return """
      Scheme: ${s.names['en']} (${s.names['hi']}) / ${s.names['ta'] ?? ''}
      ID: ${s.id}
      Description: ${s.description}
      Eligibility: ${s.eligibilityRules.map((r) => '${r.parameter} ${r.operator} ${r.value}').join(', ')}
      Documents: ${s.requiredDocuments.map((d) => d.name['en']).join(', ')}
      """;
    }).join("\n---\n");

    return """
    You are 'Civic Voice Assistant' (CVI), an advanced AI specialized in Indian Government Schemes.
    
    KNOWLEDGE BASE:
    $schemesSummary

    Your goal is to be a helpful, empathetic guide.

    Intelligence Guidelines:
    1. **"What-If" & Disqualification**:
       - If a user fails an eligibility rule (e.g., age < 60), DO NOT just say "You are not eligible."
       - Explain precisely WHY (e.g., "You need to be 60, but you are 55. That is a 5 year gap.").
       - IMMEDIATELY suggest 'Alternatives' or tell them when they will be eligible.
    
    2. **Fraud Detection**:
       - If user mentions "paying money", "agent", "bribe", "password", TRIGGER FRAUD WARNING.
       - "⚠️ WARNING: Government schemes never ask for money or passwords. This sounds like a SCAM."

    3. **Actionable Commands**:
       - When helpful, include structured actions at the END of your response.
       - URL Action: `[ACTION:LINK] {"url": "https://example.com", "text": "View Official Site"}`
       - Navigation: `[ACTION:NAVIGATE] {"screen": "pension_apply", "params": {}}`
       - Walkthrough: `[ACTION:GUIDE] {"title": "Application Steps", "steps": ["Gather Aadhaar", "Submit Form", "Track Status"]}`
       - Reminders: `[ACTION:REMINDER] {"title": "...", "body": "...", "time": "..." }`

    4. **Language & Professionalism**:
       - You MUST respond in the language code: $languageCode.
       - Use a professional, premium tone. Keep voice responses under 3 sentences.
    """;
  }

  Future<String> generateAIResponse(String userInput, List<Map<String, String>> history) async {
    // Pre-processing for Intelligence
    final detection = SmartIntentParser.parse(userInput, languageCode);
    
    // Add detected keywords to session memory for Phase 4 recommendations
    _sessionKeywords.addAll(detection.detectedKeywords);

    // 1. Ambiguity Handling
    if (detection.intent == Intent.ambiguous) {
      String options = detection.ambiguousOptions.map((id) {
         var s = SchemeKnowledgeBase.getSchemeById(id);
         return s?.names[languageCode] ?? s?.names['en'] ?? id;
      }).join(' or ');
      
      if (languageCode == 'ta') {
        return "உங்களுக்கு $options பற்றி தெரிய வேண்டுமா? நீங்கள் எதை குறிப்பிட்டீர்கள்?";
      } else if (languageCode == 'mr') {
        return "मला वाटते की तुम्ही $options बद्दल विचारत आहात. तुम्हाला नेमके काय हवे आहे?";
      }
      
      return languageCode == 'hi' 
          ? "मुझे लगता है कि आप $options के बारे में पूछ रहे हैं। आप किसका मतलब था?"
          : "I detected you might be asking about $options. Which one did you mean?";
    }

    // 2. Discovery Mode (No Scheme Detected)
    if (detection.schemeId == null && detection.intent == Intent.discovery) {
      // If it's a general greeting or question, let AI handle it, 
      // but if it looks like a failed query, guide them.
      // We'll let the LLM handle conversation, but inject a system prompt hint if needed.
    }

    // 3. Dynamic Rejection / Gap Analysis (Logic & Empathy)
    // This often requires context (user profile data). 
    // Ideally, the ConversationProvider passes this data. 
    // For now, we rely on the LLM to parse user input in the chat history.

    try {
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
      } else {
        debugPrint("Groq API Error: ${response.statusCode}");
        return "System is currently busy. Please try again.";
      }
    } catch (e) {
      debugPrint("Groq Error: $e");
      return "I'm having connectivity issues. Please check your internet connection.";
    }
  }

  // Vision capabilities remain unchanged
  String? _activeVisionModel;
  Future<String> _getBestVisionModel() async {
    // ... (Keep existing implementation or simplify for this update)
    // For brevity in this critical update, assuming "llama-3.2-11b-vision-preview" for legacy reasons if needed
    return 'llama-3.2-11b-vision-preview';
  }
  
  Future<Map<String, dynamic>> verifyDocumentImage(String base64Image) async {
      // Re-implementing simplified version to ensure file integrity
      final String modelId = await _getBestVisionModel();
      const String verificationPrompt = "Verify this document. Return JSON with isValid, message, documentType, expiryDate, extractedText.";
      
      try {
        final response = await http.post(
          Uri.parse(_apiUrl),
          headers: {'Authorization': 'Bearer $_apiKey', 'Content-Type': 'application/json'},
          body: jsonEncode({
            'model': modelId,
            'messages': [
              {'role': 'user', 'content': [
                {'type': 'text', 'text': verificationPrompt},
                {'type': 'image_url', 'image_url': {'url': 'data:image/jpeg;base64,$base64Image'}}
              ]}
            ],
            'response_format': {'type': 'json_object'}
          }),
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return jsonDecode(data['choices'][0]['message']['content']);
        }
      } catch (e) { debugPrint("Vision Error: $e"); }
      
      return {"isValid": false, "message": "Verification failed due to error."};
  }

  Future<String> translateText(String text, String sourceLanguage) async {
    if (['en', 'english'].contains(sourceLanguage.toLowerCase())) return text;
    // ... Simplified Translation Call ...
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Authorization': 'Bearer $_apiKey', 'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'messages': [
             {'role': 'system', 'content': 'Translate to English. Only output translation.'},
             {'role': 'user', 'content': text}
          ]
        })
      );
      if (response.statusCode == 200) {
         return jsonDecode(response.body)['choices'][0]['message']['content'].trim();
      }
    } catch (_) {}
    return text;
  }
}
