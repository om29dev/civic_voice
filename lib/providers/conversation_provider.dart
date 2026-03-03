import 'package:flutter/foundation.dart';
import '../models/conversation_model.dart';
import '../data/mock/services_data.dart';

import '../services/groq_service.dart';

// ─── Provider ─────────────────────────────────────────────────────────────────

class ConversationProvider extends ChangeNotifier {
  ConversationSession _session =
      ConversationSession.create(language: 'en');

  bool _isLoading = false;
  String _currentServiceId = '';
  String? _errorMessage;

  // ─── Getters ─────────────────────────────────────────────────────────────

  ConversationSession get session          => _session;
  List<MessageModel> get modernMessages   => _session.messages; // rename to avoid conflict
  bool get isLoading                       => _isLoading;
  String get currentServiceId             => _currentServiceId;
  String? get errorMessage                => _errorMessage;
  bool get hasMessages                    => _session.messages.isNotEmpty;

  // ─── Legacy Getters ─────────────────────────────────────────────────────
  
  /// Exposes modern MessageModels as legacy Messages for UI backwards compatibility.
  List<Message> get messages => _session.messages
      .map((m) => Message(
            text: m.text,
            isUser: m.isUser,
            timestamp: m.timestamp,
            // (Optional action mapping could occur here if needed by legacy screens)
          ))
      .toList();

  // ─── Session ─────────────────────────────────────────────────────────────

  void setLanguage(String langCode) {
    _session = _session.copyWith(language: langCode);
    notifyListeners();
  }

  void clearConversation() {
    _session = ConversationSession.create(language: _session.language);
    _currentServiceId = '';
    _errorMessage = null;
    notifyListeners();
  }

  /// Legacy alias for clearConversation.
  void clearMessages() => clearConversation();

  /// Legacy method to delete a specific message by index in the unified session.
  void deleteMessage(int index) {
    if (index >= 0 && index < _session.messages.length) {
      final updatedList = List<MessageModel>.from(_session.messages)..removeAt(index);
      _session = _session.copyWith(messages: updatedList);
      notifyListeners();
    }
  }

  // ─── Send Message ─────────────────────────────────────────────────────────

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    _errorMessage = null;

    // Add user message
    final userMsg = MessageModel.fromUser(text: trimmed);
    _session = _session.withMessage(userMsg);
    _isLoading = true;
    notifyListeners();

    // Simulate network/processing delay for natural feel
    await Future.delayed(const Duration(milliseconds: 600));

    try {
      final responseText = await GroqService.chat(_session.messages, _session.language);
      final linkedServiceId = GroqService.extractServiceId(responseText);

      final botMsg = MessageModel.fromBot(
        text: responseText,
        serviceTag: linkedServiceId,
        isServiceCard: linkedServiceId != null,
        confidence: 0.95,
      );
      _session = _session.withMessage(botMsg);

      if (linkedServiceId != null) {
        _currentServiceId = linkedServiceId;
      }
    } catch (e) {
      _errorMessage = e.toString();
      final errMsg = MessageModel.fromBot(
        text: _errorText(_session.language),
      );
      _session = _session.withMessage(errMsg);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Fallback Strings ─────────────────────────────────────────────────────

  String _localizedGreeting(String lang) => switch (lang) {
        'hi' => 'नमस्ते! मैं Civic Voice हूँ। आप किस सरकारी सेवा के बारे में जानना चाहते हैं?\n\nमैं आपकी मदद कर सकता हूँ: आधार, पैन, पासपोर्ट, ड्राइविंग लाइसेंस, राशन कार्ड, जन्म प्रमाण पत्र, भूमि अभिलेख, और वृद्धावस्था पेंशन।',
        'mr' => 'नमस्कार! मी Civic Voice आहे. तुम्हाला कोणत्या सरकारी सेवेबद्दल जाणून घ्यायचे आहे?\n\nमी मदत करू शकतो: आधार, पॅन, पासपोर्ट, वाहन परवाना, रेशन कार्ड, जन्म दाखला, जमीन नोंदी, आणि वृद्धापकाळ निवृत्तीवेतन.',
        'ta' => 'வணக்கம்! நான் Civic Voice. நீங்கள் எந்த அரசு சேவையைப் பற்றி அறிய விரும்புகிறீர்கள்?\n\nஆதார், பான், கடவுச்சீட்டு, வாகன உரிமம், ரேஷன் அட்டை, பிறப்பு சான்றிதழ், நில பதிவுகள், முதியோர் ஓய்வூதியம் பற்றி உதவலாம்.',
        _    => 'Namaste! I\'m Civic Voice — your AI guide for Indian government services. 🇮🇳\n\nI can help you with:\n• Aadhaar Card\n• PAN Card\n• Passport\n• Driving License\n• Land Records\n• Birth Certificate\n• Ration Card\n• Senior Citizen Pension\n\nJust tell me what you need!',
      };

  String _localizedGoodbye(String lang) => switch (lang) {
        'hi' => 'धन्यवाद! यदि आपको और सहायता की आवश्यकता हो तो वापस आएं। जय हिन्द! 🇮🇳',
        'mr' => 'धन्यवाद! आणखी मदत हवी असल्यास परत या. जय हिंद! 🇮🇳',
        'ta' => 'நன்றி! மீண்டும் உதவி தேவைப்பட்டால் வாருங்கள். ஜய் ஹிந்த்! 🇮🇳',
        _    => 'Thank you for using Civic Voice! Come back anytime you need help with government services. Jai Hind! 🇮🇳',
      };

  String _localizedUnknown(String lang) => switch (lang) {
        'hi' => 'मुझे खेद है, मैं आपका प्रश्न समझ नहीं पाया। कृपया किसी सरकारी सेवा का नाम बताएं जैसे "आधार", "पैन", "पासपोर्ट" आदि।',
        'mr' => 'मला माफ करा, मला तुमचा प्रश्न समजला नाही. कृपया एखाद्या सरकारी सेवेचे नाव सांगा जसे "आधार", "पॅन", "पासपोर्ट" इ.',
        'ta' => 'மன்னிக்கவும், உங்கள் கேள்வி புரியவில்லை. "ஆதார்", "பான்", "கடவுச்சீட்டு" போன்ற அரசு சேவையின் பெயரை சொல்லுங்கள்.',
        _    => 'I\'m not sure I understood that. Try asking about a specific service like "Aadhaar", "PAN card", or "Passport" — or ask about eligibility, documents, fees, or steps.',
      };

  String _localizedAskService(String lang) => switch (lang) {
        'hi' => 'कृपया बताएं कि आप किस सेवा के बारे में जानना चाहते हैं? जैसे: आधार, पैन, पासपोर्ट, ड्राइविंग लाइसेंस, इत्यादि।',
        'mr' => 'कृपया सांगा तुम्हाला कोणत्या सेवेबद्दल माहिती हवी आहे? उदा: आधार, पॅन, पासपोर्ट, वाहन परवाना.',
        'ta' => 'நீங்கள் எந்த சேவையைப் பற்றி தெரிந்துகொள்ள விரும்புகிறீர்கள்? உதாரணம்: ஆதார், பான், கடவுச்சீட்டு.',
        _    => 'Which service are you asking about? Please specify — e.g. Aadhaar, PAN, Passport, Driving License, etc.',
      };

  String _errorText(String lang) => switch (lang) {
        'hi' => 'कुछ गलत हो गया। कृपया पुनः प्रयास करें।',
        'mr' => 'काहीतरी चुकीचे झाले. कृपया पुन्हा प्रयत्न करा.',
        'ta' => 'ஏதோ தவறு நடந்தது. மீண்டும் முயற்சிக்கவும்.',
        _    => 'Something went wrong. Please try again.',
      };

  // ─── Legacy API Stubs ───────────────────────────────────────────────────────
  void startNewChat()             => clearConversation();
  Future<void> loadSession(String id) async { /* single-session app */ }
  Future<void> deleteSession(String id) async { /* single-session app */ }
  void updateVoiceProvider(dynamic vp) { /* no-op */ }
  List<ConversationSession> get sessions        => [_session];
  String get currentSessionId                   => _session.id;
}
