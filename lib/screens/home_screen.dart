import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/medication.dart';
import '../providers/admin_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/document_provider.dart';
import '../providers/doctor_provider.dart';
import '../providers/insurance_provider.dart';
import '../providers/language_provider.dart';
import '../providers/medication_provider.dart';
import '../providers/pharmacy_provider.dart';

import 'about_sana_screen.dart';
import 'add_doctor_screen.dart';
import 'add_medication_screen.dart';
import 'add_pharmacy_screen.dart';
import 'admin_screen.dart';
import 'documents_screen.dart';
import 'insurance_screen.dart';
import 'medication_detail_screen.dart';
import 'sharing_screen.dart';

const String _sanaShareUrl = 'https://malazhub.github.io/sana/';

const String _getCopyPaymentUrl =
    'https://link.payoneer.com/Token?t=CA1D522054524AC081ACCB17B5D8571B&src=pl';

enum HomeAction {
  medications,
  doctors,
  pharmacies,
  reminders,
  documents,
  insurance,
  sharing,
}

class HomeItem {
  final IconData icon;
  final String label;
  final String count;
  final Color color;
  final HomeAction action;

  const HomeItem({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
    required this.action,
  });
}

class SanaTranslations {
  final String medications;
  final String doctors;
  final String pharmacies;
  final String reminders;
  final String documents;
  final String insuranceCards;
  final String shareRecords;
  final String active;
  final String select;
  final String smartHealth;
  final String about;
  final String admin;

  const SanaTranslations({
    required this.medications,
    required this.doctors,
    required this.pharmacies,
    required this.reminders,
    required this.documents,
    required this.insuranceCards,
    required this.shareRecords,
    required this.active,
    required this.select,
    required this.smartHealth,
    required this.about,
    required this.admin,
  });

  factory SanaTranslations.fromCode(String code) {
    switch (code) {
      case 'ar':
        return const SanaTranslations(
          medications: 'الأدوية',
          doctors: 'الأطباء',
          pharmacies: 'الصيدليات',
          reminders: 'التذكيرات',
          documents: 'المستندات',
          insuranceCards: 'بطاقات التأمين',
          shareRecords: 'مشاركة السجلات',
          active: 'نشط',
          select: 'تحديد',
          smartHealth: 'صحتك الذكية',
          about: 'حول',
          admin: 'مدير',
        );

      case 'es':
        return const SanaTranslations(
          medications: 'Medicamentos',
          doctors: 'Médicos',
          pharmacies: 'Farmacias',
          reminders: 'Recordatorios',
          documents: 'Documentos',
          insuranceCards: 'Tarjetas de Seguro',
          shareRecords: 'Compartir',
          active: 'Activo',
          select: 'Seleccionar',
          smartHealth: 'Tu salud inteligente',
          about: 'Acerca de',
          admin: 'Administrador',
        );

      case 'fr':
        return const SanaTranslations(
          medications: 'Médicaments',
          doctors: 'Médecins',
          pharmacies: 'Pharmacies',
          reminders: 'Rappels',
          documents: 'Documents',
          insuranceCards: 'Cartes d\'Assurance',
          shareRecords: 'Partager',
          active: 'Actif',
          select: 'Sélectionner',
          smartHealth: 'Votre santé intelligente',
          about: 'À propos',
          admin: 'Admin',
        );

      case 'de':
        return const SanaTranslations(
          medications: 'Medikamente',
          doctors: 'Ärzte',
          pharmacies: 'Apotheken',
          reminders: 'Erinnerungen',
          documents: 'Dokumente',
          insuranceCards: 'Versicherungskarten',
          shareRecords: 'Teilen',
          active: 'Aktiv',
          select: 'Auswählen',
          smartHealth: 'Ihre intelligente Gesundheit',
          about: 'Über',
          admin: 'Admin',
        );

      case 'tr':
        return const SanaTranslations(
          medications: 'İlaçlar',
          doctors: 'Doktorlar',
          pharmacies: 'Eczaneler',
          reminders: 'Hatırlatıcılar',
          documents: 'Belgeler',
          insuranceCards: 'Sigorta Kartları',
          shareRecords: 'Paylaş',
          active: 'Aktif',
          select: 'Seç',
          smartHealth: 'Akıllı sağlığınız',
          about: 'Hakkında',
          admin: 'Yönetici',
        );

      case 'hi':
        return const SanaTranslations(
          medications: 'दवाएं',
          doctors: 'डॉक्टर',
          pharmacies: 'फार्मेसी',
          reminders: 'अनुस्मारक',
          documents: 'दस्तावेज़',
          insuranceCards: 'बीमा कार्ड',
          shareRecords: 'रिकॉर्ड साझा करें',
          active: 'सक्रिय',
          select: 'चुनें',
          smartHealth: 'आपका स्मार्ट स्वास्थ्य',
          about: 'के बारे में',
          admin: 'व्यवस्थापक',
        );

      case 'zh':
        return const SanaTranslations(
          medications: '药物',
          doctors: '医生',
          pharmacies: '药房',
          reminders: '提醒',
          documents: '文档',
          insuranceCards: '保险卡',
          shareRecords: '共享记录',
          active: '活动',
          select: '选择',
          smartHealth: '您的智能健康',
          about: '关于',
          admin: '管理员',
        );

      case 'en':
      default:
        return const SanaTranslations(
          medications: 'Medications',
          doctors: 'Doctors',
          pharmacies: 'Pharmacies',
          reminders: 'Reminders',
          documents: 'Documents',
          insuranceCards: 'Insurance Cards',
          shareRecords: 'Share Records',
          active: 'Active',
          select: 'Select',
          smartHealth: 'Your smart health',
          about: 'About',
          admin: 'Admin',
        );
    }
  }

  String getCopyButton(String code) {
    switch (code) {
      case 'ar':
        return '🔓 احصل على نسختك الخاصة';
      case 'de':
        return '🔓 Holen Sie sich Ihre eigene Kopie';
      case 'tr':
        return '🔓 Kendi kopyanızı alın';
      case 'hi':
        return '🔓 अपनी खुद की प्रति प्राप्त करें';
      case 'zh':
        return '🔓 获取您自己的副本';
      case 'es':
        return '🔓 Obtén tu propia copia';
      case 'fr':
        return '🔓 Obtenez votre propre copie';
      case 'en':
      default:
        return '🔓 Get your own copy';
    }
  }
}

String _cleanPhoneNumber(String phone) {
  return phone.replaceAll(RegExp(r'[^\d]'), '');
}

Future<void> _launchExternalUrl(
  BuildContext context,
  Uri uri,
) async {
  try {
    final result = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!result && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open this link.'),
        ),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open this link.'),
        ),
      );
    }
  }
}

Future<void> _callPhone(
  BuildContext context,
  String phone,
) async {
  final value = phone.trim();

  if (value.isEmpty) {
    return;
  }

  await _launchExternalUrl(
    context,
    Uri.parse('tel:$value'),
  );
}

Future<void> _openWhatsApp(
  BuildContext context,
  String phone,
) async {
  final number = _cleanPhoneNumber(phone);

  if (number.isEmpty) {
    return;
  }

  await _launchExternalUrl(
    context,
    Uri.parse('https://wa.me/$number'),
  );
}

Future<bool> _confirmDelete(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, false);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(dialogContext, true);
            },
            child: const Text('Delete'),
          ),
        ],
      );
    },
  );

  return result ?? false;
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  int _insuranceCount(BuildContext context) {
    return context.read<InsuranceProvider>().cards.length;
  }

  void _openGetCopyLink(BuildContext context) async {
    try {
      final launched = await launchUrl(
        Uri.parse(_getCopyPaymentUrl),
        mode: LaunchMode.externalApplication,
      );

      if (!launched && context.mounted) {
        _showCopyDialog(context);
      }
    } catch (_) {
      if (context.mounted) {
        _showCopyDialog(context);
      }
    }
  }

  void _showCopyDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Get Your Own Copy'),
          content: const Text(
            'Unlock the full source code and personal license for SANA.\n\n'
            'Contact support or complete payment to receive your standalone copy.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _languageChip(
    BuildContext context,
    String code,
    String label,
    String activeCode,
  ) {
    final selected = code == activeCode;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        context.read<LanguageProvider>().setLanguage(code);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.teal.shade700,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? Colors.amber.shade700
                : Colors.white38,
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight:
                selected ? FontWeight.bold : FontWeight.w500,
            color: selected
                ? Colors.teal.shade900
                : Colors.white,
          ),
        ),
      ),
    );
  }

  List<HomeItem> _items(
    BuildContext context,
    SanaTranslations t,
  ) {
    final medications = context.watch<MedicationProvider>();
    final doctors = context.watch<DoctorProvider>();
    final pharmacies = context.watch<PharmacyProvider>();
    final documents = context.watch<DocumentProvider>();

    return [
      HomeItem(
        icon: Icons.medication,
        label: t.medications,
        count: medications.medications.length.toString(),
        color: Colors.blue,
        action: HomeAction.medications,
      ),
      HomeItem(
        icon: Icons.person,
        label: t.doctors,
        count: doctors.doctors.length.toString(),
        color: Colors.green,
        action: HomeAction.doctors,
      ),
      HomeItem(
        icon: Icons.local_pharmacy,
        label: t.pharmacies,
        count: pharmacies.pharmacies.length.toString(),
        color: Colors.orange,
        action: HomeAction.pharmacies,
      ),
      HomeItem(
        icon: Icons.notifications_active,
        label: t.reminders,
        count: t.active,
        color: Colors.red,
        action: HomeAction.reminders,
      ),
      HomeItem(
        icon: Icons.folder,
        label: t.documents,
        count: documents.documents.length.toString(),
        color: Colors.purple,
        action: HomeAction.documents,
      ),
      HomeItem(
        icon: Icons.credit_card,
        label: t.insuranceCards,
        count: _insuranceCount(context).toString(),
        color: Colors.indigo,
        action: HomeAction.insurance,
      ),
      HomeItem(
        icon: Icons.share,
        label: t.shareRecords,
        count: t.select,
        color: Colors.orange,
        action: HomeAction.sharing,
      ),
    ];
  }

  void _openAction(
    BuildContext context,
    HomeAction action,
  ) {
    switch (action) {
      case HomeAction.medications:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const MedicationListScreen(),
          ),
        );
        break;

      case HomeAction.doctors:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const DoctorListScreen(),
          ),
        );
        break;

      case HomeAction.pharmacies:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const PharmacyListScreen(),
          ),
        );
        break;

      case HomeAction.reminders:
        _showReminderDialog(context);
        break;

      case HomeAction.documents:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const DocumentsScreen(),
          ),
        );
        break;

      case HomeAction.insurance:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const InsuranceScreen(),
          ),
        );
        break;

      case HomeAction.sharing:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const SharingScreen(),
          ),
        );
        break;
    }
  }

  Widget _homeCard(
    BuildContext context,
    HomeItem item,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          _openAction(context, item.action);
        },
        child: Container(
          constraints: const BoxConstraints(
            minHeight: 105,
          ),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: item.color.withOpacity(0.65),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: item.color.withOpacity(0.10),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                item.icon,
                color: item.color,
                size: 30,
              ),
              const SizedBox(height: 5),
              Text(
                item.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: item.color,
                ),
              ),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  item.count,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: item.color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _homeRow(
    BuildContext context,
    HomeItem left,
    HomeItem right,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _homeCard(context, left),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _homeCard(context, right),
        ),
      ],
    );
  }

  void _showReminderDialog(BuildContext context) {
    final medicationProvider = context.read<MedicationProvider>();
    final languageProvider = context.read<LanguageProvider>();

    final code = languageProvider.locale.languageCode;

    String title = 'Active Reminders';
    String empty = 'No active reminders.';
    String dosage = 'Dosage';

    switch (code) {
      case 'ar':
        title = 'التذكيرات النشطة';
        empty = 'لا توجد تذكيرات نشطة.';
        dosage = 'الجرعة';
        break;

      case 'es':
        title = 'Recordatorios Activos';
        empty = 'No hay recordatorios activos.';
        dosage = 'Dosis';
        break;

      case 'fr':
        title = 'Rappels Actifs';
        empty = 'Aucun rappel actif.';
        dosage = 'Dosage';
        break;

      case 'de':
        title = 'Aktive Erinnerungen';
        empty = 'Keine aktiven Erinnerungen.';
        dosage = 'Dosierung';
        break;

      case 'tr':
        title = 'Aktif Hatırlatıcılar';
        empty = 'Aktif hatırlatıcı yok.';
        dosage = 'Doz';
        break;

      case 'hi':
        title = 'सक्रिय अनुस्मारक';
        empty = 'कोई सक्रिय अनुस्मारक नहीं।';
        dosage = 'खुराक';
        break;

      case 'zh':
        title = '活动提醒';
        empty = '暂无活动提醒。';
        dosage = '剂量';
        break;
    }

    final alarms = <Map<String, dynamic>>[];

    for (final medication in medicationProvider.medications) {
      for (final time in medication.reminderTimes) {
        alarms.add({
          'medication': medication,
          'time': time,
        });
      }
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: double.maxFinite,
            height: 320,
            child: alarms.isEmpty
                ? Center(
                    child: Text(empty),
                  )
                : ListView.builder(
                    itemCount: alarms.length,
                    itemBuilder: (context, index) {
                      final alarm = alarms[index];

                      final medication =
                          alarm['medication'] as Medication;

                      final time =
                          alarm['time'] as String;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.teal.shade50,
                          child: const Icon(
                            Icons.alarm,
                            color: Colors.teal,
                          ),
                        ),
                        title: Text(
                          medication.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '$time - $dosage: ${medication.dosage}',
                        ),
                        trailing: IconButton(
                          tooltip: 'Inspect',
                          icon: const Icon(
                            Icons.visibility,
                            color: Colors.teal,
                          ),
                          onPressed: () {
                            Navigator.pop(dialogContext);

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    MedicationDetailScreen(
                                  medication: medication,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final language = context.watch<LanguageProvider>();
    final auth = context.watch<AuthProvider>();

    final code = language.locale.languageCode;
    final t = SanaTranslations.fromCode(code);
    final items = _items(context, t);

    return Scaffold(
      backgroundColor: const Color(0xFFE6F3F1),
      appBar: AppBar(
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
        elevation: 2,
        title: Row(
          children: [
            const Icon(
              Icons.health_and_safety,
              size: 26,
            ),
            const SizedBox(width: 8),
            const Text(
              'SANA',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const Spacer(),

            if (auth.isAdmin)
              IconButton(
                tooltip: 'Admin Panel',
                icon: const Icon(
                  Icons.admin_panel_settings,
                  color: Colors.amber,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminScreen(),
                    ),
                  );
                },
              ),

            IconButton(
              tooltip: 'Share Sana',
              icon: const Icon(Icons.share),
              onPressed: () {
                Share.share(
                  'Check out SANA smart health tracker:\n'
                  '$_sanaShareUrl',
                );
              },
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
              ),
              children: [
                _languageChip(
                  context,
                  'en',
                  'English',
                  code,
                ),
                _languageChip(
                  context,
                  'ar',
                  'العربية',
                  code,
                ),
                _languageChip(
                  context,
                  'es',
                  'Español',
                  code,
                ),
                _languageChip(
                  context,
                  'fr',
                  'Français',
                  code,
                ),
                _languageChip(
                  context,
                  'de',
                  'Deutsch',
                  code,
                ),
                _languageChip(
                  context,
                  'tr',
                  'Türkçe',
                  code,
                ),
                _languageChip(
                  context,
                  'hi',
                  'हिन्दी',
                  code,
                ),
                _languageChip(
                  context,
                  'zh',
                  '中文',
                  code,
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            12,
            12,
            12,
            24,
          ),
          child: Column(
            children: [
              SizedBox(
                height: 108,
                child: _homeRow(
                  context,
                  items[0],
                  items[1],
                ),
              ),
              const SizedBox(height: 8),

              SizedBox(
                height: 108,
                child: _homeRow(
                  context,
                  items[2],
                  items[3],
                ),
              ),
              const SizedBox(height: 8),

              SizedBox(
                height: 108,
                child: _homeRow(
                  context,
                  items[4],
                  items[5],
                ),
              ),
              const SizedBox(height: 8),

              SizedBox(
                height: 108,
                child: _homeCard(
                  context,
                  items[6],
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  if (auth.isAdmin)
                    Expanded(
                      child: TextButton.icon(
                        icon: const Icon(
                          Icons.admin_panel_settings,
                          size: 16,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const AdminScreen(),
                            ),
                          );
                        },
                        label: Text(
                          t.admin,
                          style: const TextStyle(
                            color: Colors.teal,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  Expanded(
                    child: TextButton.icon(
                      icon: const Icon(
                        Icons.info_outline,
                        size: 16,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const AboutSanaScreen(),
                          ),
                        );
                      },
                      label: Text(
                        t.about,
                        style: const TextStyle(
                          color: Colors.teal,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _openGetCopyLink(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade800,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(
                    Icons.shopping_bag_outlined,
                    size: 18,
                  ),
                  label: Text(
                    t.getCopyButton(code),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// MEDICATIONS
// ============================================================

class MedicationListScreen extends StatefulWidget {
  const MedicationListScreen({super.key});

  @override
  State<MedicationListScreen> createState() =>
      _MedicationListScreenState();
}

class _MedicationListScreenState
    extends State<MedicationListScreen> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MedicationProvider>();

    final query = searchQuery.trim().toLowerCase();

    final medications = provider.medications.where((med) {
      return med.name.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medications'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search medications...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),

          Expanded(
            child: medications.isEmpty
                ? const Center(
                    child: Text(
                      'No medications added yet.',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                    ),
                    itemCount: medications.length,
                    itemBuilder: (context, index) {
                      final medication = medications[index];

                      return Card(
                        margin: const EdgeInsets.only(
                          bottom: 10,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                Colors.blue.shade50,
                            child: const Icon(
                              Icons.medication,
                              color: Colors.blue,
                            ),
                          ),
                          title: Text(
                            medication.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            'Dosage: ${medication.dosage}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () async {
                              final confirmed =
                                  await _confirmDelete(
                                context,
                                title: 'Delete Medication',
                                message:
                                    'Are you sure you want to delete '
                                    '${medication.name}?',
                              );

                              if (confirmed &&
                                  context.mounted) {
                                await context
                                    .read<MedicationProvider>()
                                    .deleteMedication(
                                      medication.id,
                                    );
                              }
                            },
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    MedicationDetailScreen(
                                  medication: medication,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddMedicationScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ============================================================
// DOCTORS
// ============================================================

class DoctorListScreen extends StatelessWidget {
  const DoctorListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DoctorProvider>();
    final doctors = provider.doctors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctors'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: doctors.isEmpty
          ? const Center(
              child: Text(
                'No doctors registered yet.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: doctors.length,
              itemBuilder: (context, index) {
                final doctor = doctors[index];

                final specialty =
                    doctor.specialty?.trim() ?? '';

                final phone =
                    doctor.phone?.trim() ?? '';

                return Card(
                  margin: const EdgeInsets.only(
                    bottom: 12,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor:
                                  Colors.green.shade50,
                              child: const Icon(
                                Icons.person,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    doctor.name,
                                    style: const TextStyle(
                                      fontWeight:
                                          FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (specialty.isNotEmpty)
                                    Text(
                                      specialty,
                                      style: TextStyle(
                                        color:
                                            Colors.grey.shade600,
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: () async {
                                final confirmed =
                                    await _confirmDelete(
                                  context,
                                  title: 'Delete Doctor',
                                  message:
                                      'Are you sure you want to remove '
                                      'Dr. ${doctor.name}?',
                                );

                                if (confirmed &&
                                    context.mounted) {
                                  await context
                                      .read<DoctorProvider>()
                                      .deleteDoctor(
                                        doctor.id,
                                      );
                                }
                              },
                            ),
                          ],
                        ),

                        if (phone.isNotEmpty) ...[
                          const SizedBox(height: 10),

                          Row(
                            children: [
                              OutlinedButton.icon(
                                icon: const Icon(
                                  Icons.phone,
                                  size: 16,
                                ),
                                label: const Text('Call'),
                                onPressed: () {
                                  _callPhone(
                                    context,
                                    phone,
                                  );
                                },
                              ),

                              const SizedBox(width: 8),

                              OutlinedButton.icon(
                                icon: const Icon(
                                  Icons.chat,
                                  size: 16,
                                ),
                                label: const Text(
                                  'WhatsApp',
                                ),
                                onPressed: () {
                                  _openWhatsApp(
                                    context,
                                    phone,
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddDoctorScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ============================================================
// PHARMACIES
// ============================================================

class PharmacyListScreen extends StatelessWidget {
  const PharmacyListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PharmacyProvider>();
    final pharmacies = provider.pharmacies;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pharmacies'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: pharmacies.isEmpty
          ? const Center(
              child: Text(
                'No pharmacies registered yet.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: pharmacies.length,
              itemBuilder: (context, index) {
                final pharmacy = pharmacies[index];

                final address =
                    pharmacy.address?.trim() ?? '';

                final phone =
                    pharmacy.phone?.trim() ?? '';

                return Card(
                  margin: const EdgeInsets.only(
                    bottom: 12,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor:
                                  Colors.orange.shade50,
                              child: const Icon(
                                Icons.local_pharmacy,
                                color: Colors.orange,
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pharmacy.name,
                                    style: const TextStyle(
                                      fontWeight:
                                          FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),

                                  if (address.isNotEmpty)
                                    Text(
                                      address,
                                      style: TextStyle(
                                        color:
                                            Colors.grey.shade600,
                                        fontSize: 13,
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: () async {
                                final confirmed =
                                    await _confirmDelete(
                                  context,
                                  title: 'Delete Pharmacy',
                                  message:
                                      'Are you sure you want to remove '
                                      '${pharmacy.name}?',
                                );

                                if (confirmed &&
                                    context.mounted) {
                                  await context
                                      .read<PharmacyProvider>()
                                      .deletePharmacy(
                                        pharmacy.id,
                                      );
                                }
                              },
                            ),
                          ],
                        ),

                        if (phone.isNotEmpty) ...[
                          const SizedBox(height: 10),

                          Row(
                            children: [
                              OutlinedButton.icon(
                                icon: const Icon(
                                  Icons.phone,
                                  size: 16,
                                ),
                                label: const Text('Call'),
                                onPressed: () {
                                  _callPhone(
                                    context,
                                    phone,
                                  );
                                },
                              ),

                              const SizedBox(width: 8),

                              OutlinedButton.icon(
                                icon: const Icon(
                                  Icons.chat,
                                  size: 16,
                                ),
                                label: const Text(
                                  'WhatsApp',
                                ),
                                onPressed: () {
                                  _openWhatsApp(
                                    context,
                                    phone,
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddPharmacyScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}