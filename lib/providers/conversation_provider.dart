import 'dart:convert';
import 'package:flutter/material.dart' hide Intent;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:civic_voice_interface/models/conversation_model.dart';
import 'package:civic_voice_interface/models/scheme_model.dart';
import 'package:civic_voice_interface/core/services/reasoning_engine.dart';
import 'package:civic_voice_interface/core/services/scheme_knowledge_base.dart';
import 'package:civic_voice_interface/core/services/offline_mode_service.dart';
import 'package:civic_voice_interface/core/services/supabase_service.dart';
import 'voice_provider.dart';
import 'notes_provider.dart';

class ConversationProvider extends ChangeNotifier {
  List<ChatSession> _sessions = [];
  String? _currentSessionId;
  
  ReasoningEngine _reasoningEngine = ReasoningEngine();
  final List<Map<String, String>> _conversationHistory = [];
  VoiceProvider? _voiceProvider;
  NotesProvider? _notesProvider;
  
  // Getters
  List<ChatSession> get sessions => List.unmodifiable(_sessions);
  String? get currentSessionId => _currentSessionId;
  
  List<Message> get messages {
    if (_currentSessionId == null) return [];
    try {
      return _sessions.firstWhere((s) => s.id == _currentSessionId).messages;
    } catch (_) {
      return [];
    }
  }

  ConversationProvider() {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load Sessions
      final String? sessionsJson = prefs.getString('chat_sessions');
      if (sessionsJson != null) {
        final List<dynamic> decoded = jsonDecode(sessionsJson);
        _sessions = decoded.map((s) => ChatSession.fromJson(s)).toList();
        
        // Sort by date (newest first)
        _sessions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }

      // Restore last session if available
      if (_sessions.isNotEmpty) {
        _currentSessionId = _sessions.first.id;
      } else {
        startNewChat();
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading history: $e");
    }
  }

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('chat_sessions', jsonEncode(_sessions.map((s) => s.toJson()).toList()));
    } catch (e) {
      debugPrint("Error saving history: $e");
    }
  }
  
  void startNewChat() {
    _currentSessionId = null;
    _currentActiveScheme = null;
    _collectedData = {};
    _missingField = null;
    _conversationHistory.clear();
    notifyListeners();
  }

  void loadSession(String sessionId) {
    if (_sessions.any((s) => s.id == sessionId)) {
      _currentSessionId = sessionId;
      _currentActiveScheme = null;
      _collectedData = {};
      
      // Restore AI context
      try {
        final session = _sessions.firstWhere((s) => s.id == sessionId);
        _updateConversationHistoryFromSession(session);
      } catch (_) {}
      
      notifyListeners();
    }
  }

  void deleteSession(String sessionId) {
    _sessions.removeWhere((s) => s.id == sessionId);
    if (_currentSessionId == sessionId) {
      _currentSessionId = null;
      startNewChat();
    } else {
      _saveHistory();
      notifyListeners();
    }
  }

  // ... (providers update methods are fine, keep them or let them be)
  // Wait, I am replacing a block that includes startNewChat... to clearConversation.
  // The block in the file (Step 61) is split. lines 70-103 and 463-486.
  // I should do two replaces or one big one? The file is large. Two replaces is safer.
  
  // Actually, I can just replace the implementation of the methods I see in the file.
  // But wait, the previous `replace_file_content` call (Step 56) INSERTED `startNewChat`, `loadSession`, `deleteSession` around line 55 (before `sendMessage`).
  // AND there was `startNewChat` at line 70 in original text?
  // No, in Step 56 I *replaced* lines 55 (end of _saveHistory) to.. wait.
  // In Step 56 I replaced `_saveHistory`'s closing brace? No.
  // Effectively I appended the new methods after `_saveHistory` and BEFORE `updateVoiceProvider`.
  // So lines 70-103 in View (Step 61) ARE the new methods I inserted.
  // AND `clearMessages` / `deleteMessage` / `clearConversation` are at the BOTTOM (lines 463+).
  
  // So I have to fix:
  // 1. `startNewChat` at line 70 (remove `_messages.clear`).
  // 2. `deleteMessage` and `clearConversation` at bottom.

  // Let's fix startNewChat first.


  void loadSession(String sessionId) {
    if (_sessions.any((s) => s.id == sessionId)) {
      _currentSessionId = sessionId;
      // Reset State Machine when switching chats (optional, but safer)
      _currentActiveScheme = null;
      _collectedData = {};
      notifyListeners();
    }
  }

  void deleteSession(String sessionId) {
    _sessions.removeWhere((s) => s.id == sessionId);
    if (_currentSessionId == sessionId) {
      _currentSessionId = null;
      startNewChat();
    } else {
      _saveHistory();
      notifyListeners();
    }
  }

  void updateVoiceProvider(VoiceProvider vp) {
    _voiceProvider = vp;
  }

  void updateNotesProvider(NotesProvider np) {
    _notesProvider = np;
  }

  void sendMessage(String text, {bool isUser = true}) async {
    // 1. Ensure Session Exists
    ChatSession? session;
    if (_currentSessionId == null) {
      // Create new session
      final newId = DateTime.now().millisecondsSinceEpoch.toString();
      session = ChatSession(
        id: newId, 
        title: text.length > 30 ? '${text.substring(0, 30)}...' : text, // Auto-title
        createdAt: DateTime.now(), 
        messages: []
      );
      _sessions.insert(0, session); // Add to top
      _currentSessionId = newId;
    } else {
      try {
        session = _sessions.firstWhere((s) => s.id == _currentSessionId);
      } catch (_) {
        // Fallback if ID is invalid
        startNewChat();
        sendMessage(text, isUser: isUser);
        return;
      }
    }

    final message = Message(
      text: text, 
      isUser: isUser, 
      timestamp: DateTime.now()
    );
    
    session.messages.add(message);
    
    // Sort sessions to move active one to top?
    // _sessions.remove(session);
    // _sessions.insert(0, session);
    
    notifyListeners();
    _saveHistory();

    // Sync user message to Supabase
    if (isUser && SupabaseService.isLoggedIn) {
      _syncMessageToSupabase(message);
    }

    if (isUser) {
      // Pass the *full* history of this session to the AI?
      // reasoningEngine expects List<Map<String,String>> history.
      // We should construct it from the session messages.
      _updateConversationHistoryFromSession(session);
      
      await _processUserMessage(text);
    }
  }
  
  void _updateConversationHistoryFromSession(ChatSession session) {
    _conversationHistory.clear();
    for (var msg in session.messages) {
      _conversationHistory.add({
        'role': msg.isUser ? 'user' : 'assistant',
        'content': msg.text
      });
    }
  }

  Future<void> _syncMessageToSupabase(Message msg) async {
    try {
      await SupabaseService.from('messages').insert({
        'user_id': SupabaseService.userId,
        'session_id': _currentSessionId, // Add session ID support if DB has it, else it might just log flat
        'text': msg.text,
        'is_user': msg.isUser,
        'timestamp': msg.timestamp.toIso8601String(),
        'action': msg.action,
      });
    } catch (e) {
      debugPrint("Supabase Sync Error: $e");
    }
  }

  // State Variables
  String? _currentActiveScheme;
  Map<String, dynamic> _collectedData = {};
  String? _missingField;

  Future<void> _processUserMessage(String text) async {
    final offlineService = OfflineModeService();
    String responseText = "";

    if (await offlineService.isOnline()) {
       // ONLINE MODE: State Machine + AI
       
       // 1. Extraction: Try to get data from user input if we are in a flow
       if (_currentActiveScheme != null) {
         _extractData(text);
       } else {
         // Try to detect scheme trigger
         String detectedId = _reasoningEngine.detectSchemeId(text);
         if (detectedId.isNotEmpty) {
           _currentActiveScheme = detectedId;
           _collectedData = {};
           _missingField = null;
         }
       }

       // 2. Process Next Step or AI Chat
       if (_currentActiveScheme != null) {
         responseText = _processNextStep();
         // If processNextStep returns null/empty (meaning it's done or confused), fall back to AI? 
         // Actually processNextStep should handle the flow.
       } 
       
       if (responseText.isEmpty) {
         // Fallback to General AI (Phase 1 Ambiguity/Discovery handled here too)
         responseText = await _reasoningEngine.generateAIResponse(text, _conversationHistory);
         
         // If AI suggests a scheme (ambiguity resolution), we might want to catch that?
         // For now, let the AI handle the natural conversation.
       }

    } else {
       // OFFLINE MODE: Local Regex Matcher
       responseText = "📡 [OFFLINE MODE] " + offlineService.processQuery(text);
    }
    
    // Check for ACTIONS (Online only usually, but structure might suffice)
    if (responseText.contains('[ACTION:REMINDER]')) {
      try {
        final parts = responseText.split('|');
        final actionPart = parts[0].replaceAll('[ACTION:REMINDER]', '').trim();
        final startJson = actionPart.indexOf('{');
        final endJson = actionPart.lastIndexOf('}');
        final jsonStr = actionPart.substring(startJson, endJson + 1);
        final actionData = jsonDecode(jsonStr);
        
        // Execute Action
        if (_notesProvider != null) {
          DateTime reminderTime = DateTime.now().add(const Duration(minutes: 5)); // Default 5 mins
          _notesProvider!.addNote(
             actionData['title'], 
             actionData['body'], 
             reminderTime: reminderTime
          );
        }
        
        // Clean text for display
        responseText = parts.length > 1 ? parts[1].trim() : "Reminder set.";
      } catch (e) {
        debugPrint("Action Parsing Error: $e");
        responseText = "I tried to set a reminder but something went wrong.";
      }
    }

    // Update history for multi-turn (format for Groq API)
    _conversationHistory.add({'role': 'user', 'content': text});
    _conversationHistory.add({'role': 'assistant', 'content': responseText});

    _addSystemMessage(responseText);
  }

  void _extractData(String text) {
    text = text.toLowerCase();
    
    // Extract Age
    if (text.contains('years') || text.contains('age') || text.contains('old')) {
      final ageReg = RegExp(r'(\d{2})');
      final match = ageReg.firstMatch(text);
      if (match != null) {
        _collectedData['age'] = int.tryParse(match.group(1)!);
      }
    }

    // Extract Income
    if (text.contains('income') || text.contains('earn') || text.contains('salary') || text.contains('rupees') || text.contains('rs') || text.contains('₹')) {
       // Remove commas and k (10k -> 10000) handling if needed, simplified for now
       String clean = text.replaceAll(',', '');
       final incomeReg = RegExp(r'(\d{4,})'); // Look for 4+ digits
       final match = incomeReg.firstMatch(clean);
       if (match != null) {
         _collectedData['income'] = int.tryParse(match.group(1)!);
       }
    }
    
    // Extract Boolean (Yes/No)
    if (text.contains('yes') || text.contains('haan') || text.contains('have') || text.contains('own')) {
       // This is contextual. If missingField is 'land', 'yes' means true.
       if (_missingField != null) {
         _collectedData[_missingField!] = true;
       }
    }
    if (text.contains('no') || text.contains('nahi') || text.contains('dont')) {
       if (_missingField != null) {
         _collectedData[_missingField!] = false;
       }
    }
  }

  String _processNextStep() {
    final scheme = SchemeKnowledgeBase.getSchemeById(_currentActiveScheme!);
    if (scheme == null) return ""; // Should not happen

    // Check each rule
    for (var rule in scheme.eligibilityRules) {
      if (!_collectedData.containsKey(rule.parameter)) {
        _missingField = rule.parameter;
        // Check if we already have this in UserProfile? 
        // For now, ask the user.
        return _voiceProvider?.languageCode == 'hi' 
            ? rule.question['hi']! 
            : rule.question['en']!;
      }
    }

    // All data detected! Run Eligibility.
    return _checkEligibility(scheme);
  }

  String _checkEligibility(GovernmentScheme scheme) {
    bool eligible = true;
    String reason = "";
    
    for (var rule in scheme.eligibilityRules) {
      if (!rule.check(_collectedData[rule.parameter])) {
        eligible = false;
        // Phase 4: Dynamic Rejection Logic
        reason = _formatRejectionWithGap(rule, _collectedData[rule.parameter]);
        break;
      }
    }
    
    // Reset state after determination
    _currentActiveScheme = null;
    _collectedData = {};
    _missingField = null;

    if (eligible) {
      return _voiceProvider?.languageCode == 'hi'
          ? "बधाई हो! आप ${scheme.names['hi']} के लिए पात्र हैं। क्या आप आवेदन प्रक्रिया जानना चाहते हैं?"
          : "Congratulations! You are eligible for ${scheme.names['en']}. Would you like to know the application process?";
    } else {
      // Phase 4: Partial Match Advice / Alternatives
      String suggestion = "";
      if (scheme.alternativeSchemeIds?.isNotEmpty == true) {
        final alts = scheme.alternativeSchemeIds!.map((id) {
            final s = SchemeKnowledgeBase.getSchemeById(id);
            return s?.names[_voiceProvider?.languageCode ?? 'en'] ?? s?.names['en'];
        }).where((n) => n != null).join(", ");
        
        if (alts.isNotEmpty) {
           suggestion = _voiceProvider?.languageCode == 'hi'
               ? " हालाँकि, आप $alts के लिए पात्र हो सकते हैं।"
               : " However, you might be eligible for $alts.";
        }
      }
      return reason + suggestion; 
    }
  }

  String _formatRejectionWithGap(EligibilityRule rule, dynamic userValue) {
    // Phase 4: Gap Analysis
    bool isHindi = _voiceProvider?.languageCode == 'hi';
    
    if (rule.parameter == 'age' && rule.operator == '>=') {
      int required = rule.value as int;
      int userAge = userValue as int;
      int gap = required - userAge;
      if (gap > 0) {
        return isHindi 
            ? "आपकी आयु $userAge वर्ष है, लेकिन इसके लिए $required वर्ष होनी चाहिए। आप $gap वर्षों में पात्र होंगे।"
            : "You are $userAge years old, but you need to be at least $required. You'll be eligible in $gap years.";
      }
    }
    
    if (rule.parameter == 'income' && rule.operator == '<=') {
      int limit = rule.value as int;
      int userIncome = userValue as int;
      int excess = userIncome - limit;
      if (excess > 0) {
        return isHindi
            ? "आपकी आय ₹$userIncome है, लेकिन सीमा ₹$limit है। आप सीमा से ₹$excess ऊपर हैं।"
            : "Your income is ₹$userIncome, but the limit is ₹$limit. You exceed the limit by ₹$excess.";
      }
    }

    // Default explanation
    return isHindi 
        ? "क्षमा करें, आप पात्र नहीं हैं। ${rule.explanation['hi']}"
        : "I am sorry, you are not eligible. ${rule.explanation['en']}";
  }

  void _addSystemMessage(String text) {
    Map<String, dynamic>? detectedAction;
    String cleanText = text;

    // Parse Actions
    final List<String> actionTags = ['LINK', 'NAVIGATE', 'GUIDE', 'REMINDER'];
    for (var tag in actionTags) {
      final String tagStr = '[ACTION:$tag]';
      if (cleanText.contains(tagStr)) {
        try {
          final parts = cleanText.split(tagStr);
          cleanText = parts[0].trim();
          final String jsonStr = parts[1].trim();
          
          // Find actual JSON if there's trailing text
          final firstBrace = jsonStr.indexOf('{');
          final lastBrace = jsonStr.lastIndexOf('}');
          if (firstBrace != -1 && lastBrace != -1) {
            final String finalJson = jsonStr.substring(firstBrace, lastBrace + 1);
            detectedAction = jsonDecode(finalJson);
            detectedAction?['type'] = tag.toLowerCase();
          }
        } catch (e) {
          debugPrint("Error parsing $tag action: $e");
        }
      }
    }

    // Special handling for legacy/immediate reminders in current turn
    if (detectedAction != null && detectedAction['type'] == 'reminder' && _notesProvider != null) {
      DateTime reminderTime = DateTime.now().add(const Duration(minutes: 5));
      _notesProvider!.addNote(
        detectedAction['title'] ?? 'Reminder',
        detectedAction['body'] ?? '',
        reminderTime: reminderTime,
      );
    }

    final message = Message(
      text: cleanText, 
      isUser: false, 
      timestamp: DateTime.now(),
      action: detectedAction,
    );
    
    // Add to current session
    if (_currentSessionId != null) {
       try {
         final session = _sessions.firstWhere((s) => s.id == _currentSessionId);
         session.messages.add(message);
       } catch (_) {}
    } else {
       // Should not happen if flow is correct, but safe fallback:
       // If system speaks without user context (e.g. welcome), create session?
       // For now, ignore or create temp session? 
       // Let's create session if null, assuming auto-start.
       final newId = DateTime.now().millisecondsSinceEpoch.toString();
       final session = ChatSession(id: newId, title: "New Chat", createdAt: DateTime.now(), messages: [message]);
       _sessions.insert(0, session);
       _currentSessionId = newId;
    }

    notifyListeners();
    
    if (_voiceProvider != null) {
      _voiceProvider!.speak(cleanText);
    }

    // Sync AI response to Supabase
    if (SupabaseService.isLoggedIn) {
      _syncMessageToSupabase(message);
    }

    _saveHistory();
  }

  void clearMessages() {
    clearConversation();
  }

  void deleteMessage(int index) {
    if (_currentSessionId != null) {
      try {
        final session = _sessions.firstWhere((s) => s.id == _currentSessionId);
        if (index >= 0 && index < session.messages.length) {
          session.messages.removeAt(index);
          notifyListeners();
          _saveHistory();
        }
      } catch (_) {}
    }
  }

  void clearConversation() async {
    _sessions.clear();
    startNewChat();
    _saveHistory();
  }

  void setLanguage(String code) {
    _reasoningEngine = ReasoningEngine(languageCode: code);
  }
}
}
