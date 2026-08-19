import 'package:flutter/material.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  bool _isInitialized = false;

  Locale get locale => _locale;

  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    if (_isInitialized) {
      return;
    }

    // Language persistence can be added here later.
    // For now, English is the safe default.
    _isInitialized = true;

    notifyListeners();
  }

  void setLanguage(String code) {
    if (code.trim().isEmpty) {
      return;
    }

    _locale = Locale(code);
    notifyListeners();
  }

  void toggleLanguage() {
    _locale = _locale.languageCode == 'en'
        ? const Locale('ar')
        : const Locale('en');

    notifyListeners();
  }

  List<String> getSupportedLanguages() {
    return const [
      'en',
      'ar',
      'es',
      'fr',
      'de',
      'tr',
      'hi',
      'zh',
    ];
  }

  String getLanguageName(String code) {
    const names = {
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