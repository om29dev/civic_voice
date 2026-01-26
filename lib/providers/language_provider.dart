import 'package:flutter/material.dart';
import '../core/constants/app_strings.dart';

enum AppLanguage { english, hindi, marathi, tamil }

class LanguageProvider extends ChangeNotifier {
  AppLanguage _currentLanguage = AppLanguage.english;

  AppLanguage get currentLanguage => _currentLanguage;

  void setLanguage(AppLanguage language) {
    _currentLanguage = language;
    notifyListeners();
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
