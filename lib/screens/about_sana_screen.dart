import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

class AboutSanaScreen extends StatelessWidget {
  const AboutSanaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final code = Provider.of<LanguageProvider>(context).locale.languageCode;

    // Multilingual Content Reconstructed from Project Logs
    final text = <String, String>{
          'en':
              'Your private pocket health data center. Save reports, medicines, doctors and pharmacies, keep your records with you, share what you choose, and receive medication reminders. Your data stays with your account even when you change your phone. This is your own private copy of your health center.',
          'ar':
              'Ù…Ø±ÙƒØ² Ø¨ÙŠØ§Ù†Ø§ØªÙƒ Ø§Ù„ØµØ­ÙŠ Ø§Ù„Ø®Ø§Øµ ÙÙŠ Ø¬ÙŠØ¨Ùƒ. Ø§Ø­ÙØ¸ ØªÙ‚Ø§Ø±ÙŠØ±Ùƒ ÙˆØ£Ø¯ÙˆÙŠØªÙƒ ÙˆØ£Ø·Ø¨Ø§Ø¡Ùƒ ÙˆØµÙŠØ¯Ù„ÙŠØ§ØªÙƒØŒ ÙˆØ´Ø§Ø±Ùƒ Ù…Ø§ ØªØ®ØªØ§Ø±Ù‡ØŒ ÙˆØ§Ø­ØµÙ„ Ø¹Ù„Ù‰ ØªØ°ÙƒÙŠØ±Ø§Øª Ø§Ù„Ø£Ø¯ÙˆÙŠØ©. ØªØ¨Ù‚Ù‰ Ø¨ÙŠØ§Ù†Ø§ØªÙƒ Ù…Ø¹ Ø­Ø³Ø§Ø¨Ùƒ Ø­ØªÙ‰ Ø¹Ù†Ø¯ ØªØºÙŠÙŠØ± Ù‡Ø§ØªÙÙƒ. Ù‡Ø°Ù‡ Ù†Ø³Ø®ØªÙƒ Ø§Ù„Ø®Ø§ØµØ© Ù…Ù† Ù…Ø±ÙƒØ²Ùƒ Ø§Ù„ØµØ­ÙŠ.',
          'fr':
              'Votre centre de donnÃ©es de santÃ© privÃ© dans votre poche. Enregistrez vos rapports, mÃ©dicaments, mÃ©decins et pharmacies, partagez ce que vous choisissez et recevez vos rappels de mÃ©dicaments. Vos donnÃ©es restent liÃ©es Ã  votre compte mÃªme si vous changez de tÃ©lÃ©phone.',
          'es':
              'Tu centro privado de datos de salud en tu bolsillo. Guarda informes, medicamentos, mÃ©dicos y farmacias, comparte lo que quieras y recibe recordatorios. Tus datos permanecen en tu cuenta aunque cambies de telÃ©fono.',
          'de':
              'Ihr privates Gesundheitszentrum in der Tasche. Speichern Sie Berichte, Medikamente, Ã„rzte und Apotheken, teilen Sie ausgewÃ¤hlte Daten und erhalten Sie Medikamentenerinnerungen. Ihre Daten bleiben bei Ihrem Konto, auch wenn Sie Ihr Telefon wechseln.',
          'tr':
              'Ã–zel saÄŸlÄ±k veri merkeziniz cebinizde. RaporlarÄ±nÄ±zÄ±, ilaÃ§larÄ±nÄ±zÄ±, doktorlarÄ±nÄ±zÄ± ve eczanelerinizi saklayÄ±n, seÃ§tiklerinizi paylaÅŸÄ±n ve ilaÃ§ hatÄ±rlatmalarÄ± alÄ±n. Telefonunuzu deÄŸiÅŸtirseniz bile verileriniz hesabÄ±nÄ±zda kalÄ±r.',
          'hi':
              'à¤†à¤ªà¤•à¤¾ à¤¨à¤¿à¤œà¥€ à¤¸à¥à¤µà¤¾à¤¸à¥à¤¥à¥à¤¯ à¤¡à¥‡à¤Ÿà¤¾ à¤•à¥‡à¤‚à¤¦à¥à¤° à¤†à¤ªà¤•à¥€ à¤œà¥‡à¤¬ à¤®à¥‡à¤‚à¥¤ à¤°à¤¿à¤ªà¥‹à¤°à¥à¤Ÿ, à¤¦à¤µà¤¾à¤à¤‚, à¤¡à¥‰à¤•à¥à¤Ÿà¤° à¤”à¤° à¤«à¤¾à¤°à¥à¤®à¥‡à¤¸à¥€ à¤¸à¥à¤°à¤•à¥à¤·à¤¿à¤¤ à¤°à¤–à¥‡à¤‚, à¤œà¤°à¥‚à¤°à¤¤ à¤•à¥‡ à¤…à¤¨à¥à¤¸à¤¾à¤° à¤¸à¤¾à¤à¤¾ à¤•à¤°à¥‡à¤‚ à¤”à¤° à¤¦à¤µà¤¾ à¤•à¥€ à¤¯à¤¾à¤¦ à¤¦à¤¿à¤²à¤¾à¤¨à¥‡ à¤µà¤¾à¤²à¥€ à¤¸à¥‚à¤šà¤¨à¤¾à¤à¤‚ à¤ªà¥à¤°à¤¾à¤ªà¥à¤¤ à¤•à¤°à¥‡à¤‚à¥¤ à¤«à¥‹à¤¨ à¤¬à¤¦à¤²à¤¨à¥‡ à¤ªà¤° à¤­à¥€ à¤¡à¥‡à¤Ÿà¤¾ à¤†à¤ªà¤•à¥‡ à¤–à¤¾à¤¤à¥‡ à¤®à¥‡à¤‚ à¤°à¤¹à¤¤à¤¾ à¤¹à¥ˆà¥¤',
          'zh':
              'æ‚¨çš„ç§äººå¥åº·æ•°æ®ä¸­å¿ƒå°±åœ¨å£è¢‹é‡Œã€‚ä¿å­˜æŠ¥å‘Šã€è¯ç‰©ã€åŒ»ç”Ÿå’Œè¯æˆ¿ä¿¡æ¯ï¼ŒæŒ‰éœ€åˆ†äº«ï¼Œå¹¶æŽ¥æ”¶ç”¨è¯æé†’ã€‚å³ä½¿æ›´æ¢æ‰‹æœºï¼Œæ‚¨çš„æ•°æ®ä»ä¿ç•™åœ¨è´¦æˆ·ä¸­ã€‚'
        }[code] ??
        'Your private pocket health data center.';

    return Scaffold(
      appBar: AppBar(
        title: const Text('SANA'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.health_and_safety,
                    size: 80, color: Colors.teal),
                const SizedBox(height: 24),
                const Text(
                  'SANA',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 18,
                    height: 1.6,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
