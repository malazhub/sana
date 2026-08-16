import 'package:flutter/material.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  void setLanguage(String code) {
    _locale = Locale(code);
    notifyListeners();
  }

  void toggleLanguage() {
    _locale = _locale.languageCode == 'en' ? const Locale('ar') : const Locale('en');
    notifyListeners();
  }

  List<String> getSupportedLanguages() => ['en', 'ar', 'es', 'fr', 'de', 'tr', 'hi', 'zh'];
  
  String getLanguageName(String code) {
    final names = {
      'en': 'English 🇺🇸',
      'ar': 'العربية 🇸🇦',
      'es': 'Español 🇪🇸',
      'fr': 'Français 🇫🇷',
      'de': 'Deutsch 🇩🇪',
      'tr': 'Türkçe 🇹🇷',
      'hi': 'हिन्दी 🇮🇳',
      'zh': '中文 🇨🇳',
    };
    return names[code] ?? code;
  }
}
