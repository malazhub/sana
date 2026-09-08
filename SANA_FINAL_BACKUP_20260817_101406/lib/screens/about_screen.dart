import 'package:flutter/material.dart';
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
              'مركز بياناتك الصحي الخاص في جيبك. احفظ تقاريرك وأدويتك وأطباءك وصيدلياتك، وشارك ما تختاره، واحصل على تذكيرات الأدوية. تبقى بياناتك مع حسابك حتى عند تغيير الهاتف.',
          'fr':
              'Votre centre de données de santé privé dans votre poche. Enregistrez vos rapports, médicaments, médecins et pharmacies, partagez ce que vous choisissez et recevez vos rappels. Vos données restent liées à votre compte même si vous changez de téléphone.',
          'es':
              'Tu centro privado de datos de salud en tu bolsillo. Guarda informes, medicamentos, médicos y farmacias, comparte lo que quieras y recibe recordatorios. Tus données restent liées à votre compte.',
          'de':
              'Ihr privates Gesundheitszentrum in der Tasche. Speichern Sie Berichte, Medikamente, Ärzte und Apotheken, teilen Sie ausgewählte Daten und erhalten Sie Erinnerungen. Ihre Daten bleiben mit Ihrem Konto verbunden.',
          'tr':
              'Özel sağlık veri merkeziniz cebinizde. Raporları, ilaçları, doktorları ve eczaneleri kaydedin, seçtiklerinizi paylaşın ve hatırlatıcılar alın.',
          'hi':
              'आपका निजी स्वास्थ्य डेटा केंद्र आपकी जेब में। रिपोर्ट, दवाएं, डॉक्टर और फार्मेसी सुरक्षित रखें, साझा करें और दवा की याद दिलाने वाली सूचनाएं alın।',
          'zh': '您的私人健康数据中心就在口袋里。保存报告、药物、医生和药房信息，按需分享并接收用药提醒。'
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
