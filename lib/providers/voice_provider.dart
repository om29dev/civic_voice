import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:civic_voice_interface/core/services/translation_service.dart';


enum VoiceState { idle, listening, processing, responding, error }

class VoiceProvider extends ChangeNotifier {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final TranslationService _translationService = TranslationService();
  
  VoiceState _state = VoiceState.idle;
  String _lastWords = "";
  String _currentResponse = "";
  String _errorMessage = "";
  String _currentLocaleId = "en-IN";
  bool _isInitialized = false;
  
  VoiceState get state => _state;
  String get lastWords => _lastWords;
  String get currentResponse => _currentResponse;
  String get errorMessage => _errorMessage;
  bool get isListening => _state == VoiceState.listening;
  bool get isProcessing => _state == VoiceState.processing;
  bool get isResponding => _state == VoiceState.responding;

  VoiceProvider() {
    initVoice();
  }

  void setLocale(String localeId) {
    if (_currentLocaleId != localeId) {
      _currentLocaleId = localeId;
      notifyListeners();
    }
  }

  Future<bool> initVoice() async {
    try {
      _isInitialized = await _speech.initialize(
        onError: (val) => _handleError('Speech Error: ${val.errorMsg}'),
        onStatus: (val) => print('Speech Status: $val'),
      );
      
      if (!_isInitialized) {
        _handleError('Speech recognition not available on this device');
      } else {
        _state = VoiceState.idle;
        _errorMessage = "";
        notifyListeners();
      }
      
      await _tts.setLanguage("en-IN");
      await _tts.setSpeechRate(0.5);
      return _isInitialized;
    } catch (e) {
      _handleError('Failed to initialize voice engine');
      return false;
    }
  }

  Future<void> startListening({Function(String)? onFinalResult}) async {
    // Rely on speech_to_text to request permission on initialize/listen
    if (!_isInitialized) {
      bool success = await initVoice();
      if (!success) {
        _handleError('Microphone permission or service unavailable');
        return;
      }
    }

    if (_state == VoiceState.responding) {
      await _tts.stop();
      _state = VoiceState.idle;
      notifyListeners();
    }

    if (_state == VoiceState.idle || _state == VoiceState.error) {
      _state = VoiceState.listening;
      _lastWords = "";
      _errorMessage = "";
      notifyListeners();

      try {
        await _speech.listen(
          onResult: (result) async {
            _lastWords = result.recognizedWords;
            notifyListeners();
            
            if (result.finalResult) {
              _state = VoiceState.processing;
              notifyListeners();
              
              String sourceLang = _currentLocaleId.split('-').first;
              String textToProcess = await _translationService.translateToEnglish(
                result.recognizedWords, 
                sourceLang
              );
              
              if (onFinalResult != null) {
                onFinalResult(textToProcess);
              }
            }
          },
          localeId: _currentLocaleId,
          listenFor: const Duration(seconds: 10),
          pauseFor: const Duration(seconds: 3),
        );
      } catch (e) {
        _handleError('Microphone not available or permission denied');
      }
    }
  }

  void _handleError(String message) {
    _state = VoiceState.error;
    _errorMessage = message;
    notifyListeners();
    print(message);
  }

  Future<void> speak(String text) async {
    _state = VoiceState.responding;
    _currentResponse = text;
    notifyListeners();
    
    await _tts.speak(text);
    _tts.setCompletionHandler(() {
      _state = VoiceState.idle;
      notifyListeners();
    });
  }

  void stopSilently() {
    _speech.stop();
    _tts.stop(); // Stop text-to-speech playback
    _state = VoiceState.idle;
    notifyListeners();
  }
}
