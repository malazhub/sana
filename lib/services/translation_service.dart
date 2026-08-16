import 'package:translator/translator.dart';

class TranslationService {
  final GoogleTranslator _translator = GoogleTranslator();

  Future<String> translate(String text, String targetLanguage) async {
    if (targetLanguage == 'en') return text;

    try {
      final result = await _translator.translate(text, to: targetLanguage);
      return result.text;
    } catch (e) {
      return text;
    }
  }

  Future<Map<String, String>> translateAll(
    Map<String, String> texts,
    String targetLanguage,
  ) async {
    if (targetLanguage == 'en') return texts;

    Map<String, String> translated = {};

    for (var entry in texts.entries) {
      try {
        final result = await _translator.translate(
          entry.value,
          to: targetLanguage,
        );
        translated[entry.key] = result.text;
      } catch (e) {
        translated[entry.key] = entry.value;
      }
    }

    return translated;
  }
}