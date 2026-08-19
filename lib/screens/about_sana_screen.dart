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
              'مركز بياناتك الصحي الخاص في جيبك. احفظ تقاريرك وأدويتك وأطباءك وصيدلياتك، وشارك ما تختاره، واحصل على تذكيرات الأدوية. تبقى بياناتك مع حسابك حتى عند تغيير هاتفك. هذه نسختك الخاصة من مركزك الصحي.',
          'fr':
              'Votre centre de données de santé privé dans votre poche. Enregistrez vos rapports, médicaments, médecins et pharmacies, partagez ce que vous choisissez et recevez vos rappels de médicaments. Vos données restent liées à votre compte même si vous changez de téléphone.',
          'es':
              'Tu centro privado de datos de salud en tu bolsillo. Guarda informes, medicamentos, médicos y farmacias, comparte lo que quieras y recibe recordatorios. Tus datos permanecen en tu cuenta aunque cambies de teléfono.',
          'de':
              'Ihr privates Gesundheitszentrum in der Tasche. Speichern Sie Berichte, Medikamente, Ärzte und Apotheken, teilen Sie ausgewählte Daten und erhalten Sie Medikamentenerinnerungen. Ihre Daten bleiben bei Ihrem Konto, auch wenn Sie Ihr Telefon wechseln.',
          'tr':
              'Özel sağlık veri merkeziniz cebinizde. Raporlarınızı, ilaçlarınızı, doktorlarınızı ve eczanelerinizi saklayın, seçtiklerinizi paylaşın ve ilaç hatırlatmaları alın. Telefonunuzu değiştirseniz bile verileriniz hesabınızda kalır.',
          'hi':
              'आपका निजी स्वास्थ्य डेटा केंद्र आपकी जेब में। रिपोर्ट, दवाएं, डॉक्टर और फार्मेसी सुरक्षित रखें, जरूरत के अनुसार साझा करें और दवा की याद दिलाने वाली सूचनाएं प्राप्त करें। फोन बदलने पर भी डेटा आपके खाते में रहता है।',
          'zh':
              '您的私人健康数据中心就在口袋里。保存报告、药物、医生和药房信息，按需分享，并接收用药提醒。即使更换手机，您的数据仍保留在账户中。'
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
