import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/conversation_model.dart';
import '../data/mock/services_data.dart';

/// Service to interact with the Groq API for generating AI responses.
class GroqService {
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  
  static const String _model = 'llama-3.3-70b-versatile';

  /// Timeout for the HTTP request to avoid infinite loading.
  static const Duration _timeout = Duration(seconds: 15);

  /// Generate a chat response using the Groq API.
  /// Passes the conversation history for context.
  static Future<String> chat(List<MessageModel> history, String language) async {
    final apiKey = dotenv.env['GROQ_API_KEY'];
    
    if (apiKey == null || apiKey.isEmpty) {
      dev.log('GROQ_API_KEY not found in .env file', name: 'GroqService');
      throw Exception('Missing Groq API Key. Please add GROQ_API_KEY to your .env file.');
    }

    dev.log('Sending request to Groq API (model: $_model, messages: ${history.length + 1})', name: 'GroqService');

    try {
      final messages = [
        {'role': 'system', 'content': _buildSystemPrompt(language)},
        ...history.map((msg) => {
          'role': msg.isUser ? 'user' : 'assistant',
          'content': msg.text,
        }).toList(),
      ];

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 1024,
          'top_p': 0.9,
        }),
      ).timeout(_timeout);

      dev.log('Groq API response status: ${response.statusCode}', name: 'GroqService');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        return content.trim();
      } else {
        dev.log('Groq API Error: ${response.statusCode} - ${response.body}', name: 'GroqService');
        throw Exception('Groq API returned error ${response.statusCode}');
      }
    } on TimeoutException {
      dev.log('Groq API request timed out after ${_timeout.inSeconds}s', name: 'GroqService');
      throw Exception('Request timed out. Please check your internet connection and try again.');
    } catch (e) {
      dev.log('Groq API Exception: $e', name: 'GroqService');
      rethrow;
    }
  }

  /// Extracts potential service keywords from the AI's response to link to app screens.
  static String? extractServiceId(String text) {
    final lower = text.toLowerCase();
    
    // Check against all known services
    for (final service in MockServicesData.all) {
      // Check exact English name match
      if (lower.contains((service.name['en'] ?? '').toLowerCase())) {
        return service.id;
      }
      // Check ID match
      final idKeyword = service.id.replaceAll('_', ' ');
      if (lower.contains(idKeyword)) {
        return service.id;
      }
    }
    
    // Common aliases mapping
    final aliases = {
      'aadhaar': 'aadhaar_card',
      'pan': 'pan_card',
      'passport': 'passport',
      'driving license': 'driving_license',
      'dl ': 'driving_license',
      'voter': 'voter_id',
      'ration': 'ration_card',
      'birth certificate': 'birth_certificate',
      'ayushman': 'ayushman_bharat',
      'pm kisan': 'pm_kisan',
    };
    
    for (final entry in aliases.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }
    
    return null;
  }

  static String _buildSystemPrompt(String language) {
    String langInstruction = '';
    switch (language) {
      case 'hi':
        langInstruction = 'You must respond ONLY in clear, conversational Hindi (Devanagari script). Keep technical terms in English if commonly used (like PAN, Aadhaar).';
        break;
      case 'mr':
        langInstruction = 'You must respond ONLY in clear, conversational Marathi. Keep technical terms in English if commonly used.';
        break;
      case 'ta':
        langInstruction = 'You must respond ONLY in clear, conversational Tamil. Keep technical terms in English if commonly used.';
        break;
      default:
        langInstruction = 'You must respond in clear, conversational English.';
    }

    return '''
You are "Civic Voice" (CVI), a friendly and helpful voice assistant built for citizens of India to navigate government services.

Your primary goal is to guide users through government schemes, eligibility, required documents, fees, application processes, and timelines.

CRITICAL INSTRUCTIONS:
1. $langInstruction
2. You are a VOICE assistant. Your responses will be READ ALOUD by text-to-speech. Therefore:
   - Do NOT use any markdown formatting whatsoever. No asterisks, no bold, no italics, no bullet points, no numbered lists, no headers, no special characters for formatting.
   - Write in plain, natural spoken language — as if you are a helpful person talking on a phone call.
   - Use short sentences. Pause naturally with commas and periods.
   - Instead of bullet lists, say things like "First... Second... Third..." or "You will need your Aadhaar card, a passport photo, and an address proof."
3. Keep answers concise and practical. No more than 3-4 sentences for simple questions.
4. If a user asks about a service, give a brief spoken overview: what it is, key documents needed, and how to apply.
5. If you don't know a specific answer, suggest checking the official government portal.
6. Never mention you are an AI, language model, or from Groq, OpenAI, or Meta. You are "Civic Voice."
7. Sound warm, natural, and helpful — like a knowledgeable friend who works in a government office.
''';
  }
}
