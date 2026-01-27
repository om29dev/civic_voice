import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:civic_voice_interface/core/constants/app_strings.dart';

enum AppLanguage { english, hindi, marathi, tamil }

class LanguageProvider extends ChangeNotifier {
  static const String _langKey = 'app_language';
  AppLanguage _currentLanguage = AppLanguage.english;

  AppLanguage get currentLanguage => _currentLanguage;

  LanguageProvider() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_langKey) ?? 0;
    _currentLanguage = AppLanguage.values[index];
    notifyListeners();
  }

  Future<void> setLanguage(AppLanguage language) async {
    _currentLanguage = language;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_langKey, language.index);
  }

  String get languageCode {
    switch (_currentLanguage) {
      case AppLanguage.english: return 'en';
      case AppLanguage.hindi: return 'hi';
      case AppLanguage.marathi: return 'mr';
      case AppLanguage.tamil: return 'ta';
    }
  }

  String get languageName {
    switch (_currentLanguage) {
      case AppLanguage.english: return 'English';
      case AppLanguage.hindi: return 'हिन्दी (Hindi)';
      case AppLanguage.marathi: return 'मराठी (Marathi)';
      case AppLanguage.tamil: return 'தமிழ் (Tamil)';
    }
  }

  String get fullLocaleId {
    switch (_currentLanguage) {
      case AppLanguage.english: return 'en-IN';
      case AppLanguage.hindi: return 'hi-IN';
      case AppLanguage.marathi: return 'mr-IN';
      case AppLanguage.tamil: return 'ta-IN';
    }
  }

  // Translation helper method
  String translate(String key) {
    return AppStrings.get(key, languageCode);
  }
}
