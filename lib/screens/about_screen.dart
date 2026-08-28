// ignore_for_file: deprecated_member_use, unused_import, unused_element
import 'package:flutter/material.dart';
import '../services/sharing_service.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final c = Provider.of<LanguageProvider>(context).locale.languageCode;
    final t = {
          'en':
              'Your private pocket health data center. Save reports, medicines, doctors and pharmacies, share what you choose, and receive medication reminders. Your data stays with your account even when you change your phone.',
          'ar':
              'Ù…Ø±ÙƒØ² Ø¨ÙŠØ§Ù†Ø§ØªÙƒ Ø§Ù„ØµØ­ÙŠ Ø§Ù„Ø®Ø§Øµ ÙÙŠ Ø¬ÙŠØ¨Ùƒ. Ø§Ø­ÙØ¸ ØªÙ‚Ø§Ø±ÙŠØ±Ùƒ ÙˆØ£Ø¯ÙˆÙŠØªÙƒ ÙˆØ£Ø·Ø¨Ø§Ø¡Ùƒ ÙˆØµÙŠØ¯Ù„ÙŠØ§ØªÙƒØŒ ÙˆØ´Ø§Ø±Ùƒ Ù…Ø§ ØªØ®ØªØ§Ø±Ù‡ØŒ ÙˆØ§Ø­ØµÙ„ Ø¹Ù„Ù‰ ØªØ°ÙƒÙŠØ±Ø§Øª Ø§Ù„Ø£Ø¯ÙˆÙŠØ©. ØªØ¨Ù‚Ù‰ Ø¨ÙŠØ§Ù†Ø§ØªÙƒ Ù…Ø¹ Ø­Ø³Ø§Ø¨Ùƒ Ø­ØªÙ‰ Ø¹Ù†Ø¯ ØªØºÙŠÙŠØ± Ø§Ù„Ù‡Ø§ØªÙ.',
          'fr':
              'Votre centre de donnÃ©es de santÃ© privÃ© dans votre poche. Enregistrez vos rapports, mÃ©dicaments, mÃ©decins et pharmacies, partagez ce que vous choisissez et recevez vos rappels. Vos donnÃ©es restent liÃ©es Ã  votre compte mÃªme si vous changez de tÃ©lÃ©phone.',
          'es':
              'Tu centro privado de datos de salud en tu bolsillo. Guarda informes, medicamentos, mÃ©dicos y farmacias, comparte lo que quieras y recibe recordatorios. Tus donnÃ©es restent liÃ©es Ã  votre compte.',
          'de':
              'Ihr privates Gesundheitszentrum in der Tasche. Speichern Sie Berichte, Medikamente, Ã„rzte und Apotheken, teilen Sie ausgewÃ¤hlte Daten und erhalten Sie Erinnerungen. Ihre Daten bleiben mit Ihrem Konto verbunden.',
          'tr':
              'Ã–zel saÄŸlÄ±k veri merkeziniz cebinizde. RaporlarÄ±, ilaÃ§larÄ±, doktorlarÄ± ve eczaneleri kaydedin, seÃ§tiklerinizi paylaÅŸÄ±n ve hatÄ±rlatÄ±cÄ±lar alÄ±n.',
          'hi':
              'à¤†à¤ªà¤•à¤¾ à¤¨à¤¿à¤œà¥€ à¤¸à¥à¤µà¤¾à¤¸à¥à¤¥à¥à¤¯ à¤¡à¥‡à¤Ÿà¤¾ à¤•à¥‡à¤‚à¤¦à¥à¤° à¤†à¤ªà¤•à¥€ à¤œà¥‡à¤¬ à¤®à¥‡à¤‚à¥¤ à¤°à¤¿à¤ªà¥‹à¤°à¥à¤Ÿ, à¤¦à¤µà¤¾à¤à¤‚, à¤¡à¥‰à¤•à¥à¤Ÿà¤° à¤”à¤° à¤«à¤¾à¤°à¥à¤®à¥‡à¤¸à¥€ à¤¸à¥à¤°à¤•à¥à¤·à¤¿à¤¤ à¤°à¤–à¥‡à¤‚, à¤¸à¤¾à¤à¤¾ à¤•à¤°à¥‡à¤‚ à¤”à¤° à¤¦à¤µà¤¾ à¤•à¥€ à¤¯à¤¾à¤¦ à¤¦à¤¿à¤²à¤¾à¤¨à¥‡ à¤µà¤¾à¤²à¥€ à¤¸à¥‚à¤šà¤¨à¤¾à¤à¤‚ alÄ±nà¥¤',
          'zh':
              'æ‚¨çš„ç§äººå¥åº·æ•°æ®ä¸­å¿ƒå°±åœ¨å£è¢‹é‡Œã€‚ä¿å­˜æŠ¥å‘Šã€è¯ç‰©ã€åŒ»ç”Ÿå’Œè¯æˆ¿ä¿¡æ¯ï¼ŒæŒ‰éœ€åˆ†äº«å¹¶æŽ¥æ”¶ç”¨è¯æé†’ã€‚'
        }[c] ??
        '';
    return Scaffold(
        appBar: AppBar(
            title: const Text('SANA'),
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white),
        body: Center(
            child: Padding(
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                    child: Text(t,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18, height: 1.5))))));
  }
}
