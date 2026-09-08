import 'package:flutter/material.dart';

class LanguageProvider extends ChangeNotifier {
  static const List<String> supportedLanguages = [
    'en',
    'ar',
    'es',
    'fr',
    'de',
    'tr',
    'hi',
    'zh',
  ];

  static const Map<String, String> languageNames = {
    'en': 'English ðŸ‡ºðŸ‡¸',
    'ar': 'Ø§Ù„Ø¹Ø±Ø¨ÙŠØ© ðŸ‡¸ðŸ‡¦',
    'es': 'EspaÃ±ol ðŸ‡ªðŸ‡¸',
    'fr': 'FranÃ§ais ðŸ‡«ðŸ‡·',
    'de': 'Deutsch ðŸ‡©ðŸ‡ª',
    'tr': 'TÃ¼rkÃ§e ðŸ‡¹ðŸ‡·',
    'hi': 'à¤¹à¤¿à¤¨à¥à¤¦à¥€ ðŸ‡®ðŸ‡³',
    'zh': 'ä¸­æ–‡ ðŸ‡¨ðŸ‡³',
  };

  Locale _locale = const Locale('en');

  bool _isInitialized = false;

  Locale get locale => _locale;

  String get languageCode => _locale.languageCode;

  bool get isInitialized => _isInitialized;

  List<String> get languages => List.unmodifiable(supportedLanguages);

  Future<void> init() async {
    if (_isInitialized) {
      return;
    }

    // English remains the safe default.
    //
    // Language persistence can be connected here later
    // without changing the rest of the application.
    _isInitialized = true;

    notifyListeners();
  }

  void setLanguage(String code) {
    final normalizedCode = code.trim().toLowerCase();

    if (normalizedCode.isEmpty) {
      return;
    }

    if (!supportedLanguages.contains(normalizedCode)) {
      return;
    }

    if (_locale.languageCode == normalizedCode) {
      return;
    }

    _locale = Locale(normalizedCode);

    notifyListeners();
  }

  void toggleLanguage() {
    if (_locale.languageCode == 'en') {
      setLanguage('ar');
    } else {
      setLanguage('en');
    }
  }

  List<String> getSupportedLanguages() {
    return List.unmodifiable(
      supportedLanguages,
    );
  }

  String getLanguageName(String code) {
    final normalizedCode = code.trim().toLowerCase();

    return languageNames[normalizedCode] ?? normalizedCode;
  }
}
