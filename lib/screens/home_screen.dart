
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/doctor.dart';
import '../models/medication.dart';
import '../models/pharmacy.dart';

import '../providers/document_provider.dart';
import '../providers/doctor_provider.dart';
import '../providers/insurance_provider.dart';
import '../providers/language_provider.dart';
import '../providers/medication_provider.dart';
import '../providers/pharmacy_provider.dart';

import 'about_sana_screen.dart';
import 'add_medication_screen.dart';
import 'admin_screen.dart';
import 'documents_screen.dart';
import 'insurance_screen.dart';
import 'medication_detail_screen.dart';
import 'sharing_screen.dart';

// ============================================================================
// CONSTANTS
// ============================================================================

const String _sanaShareUrl = 'https://malazhub.github.io/sana/';

const String _getCopyPaymentUrl =
    'https://link.payoneer.com/Token?t=CA1D522054524AC081ACCB17B5D8571B&src=pl';

// ============================================================================
// HOME ACTION
// ============================================================================

enum HomeAction {
  medications,
  doctors,
  pharmacies,
  reminders,
  documents,
  insurance,
  sharing,
}

// ============================================================================
// HOME ITEM
// ============================================================================

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

// ============================================================================
// TRANSLATIONS
// ============================================================================

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

// ============================================================================
// COMMON HELPERS
// ============================================================================

String _cleanPhoneNumber(String phone) {
  return phone.replaceAll(RegExp(r'[^\d]'), '');
}

Future<void> _launchExternalUrl(
  BuildContext context,
  Uri uri,
) async {
  try {
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched && context.mounted) {
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

  final uri = Uri.parse('tel:$value');
  await _launchExternalUrl(context, uri);
}

Future<void> _openWhatsApp(
  BuildContext context,
  String phone,
) async {
  final number = _cleanPhoneNumber(phone);

  if (number.isEmpty) {
    return;
  }

  final uri = Uri.https(
    'wa.me',
    '/$number',
  );

  await _launchExternalUrl(context, uri);
}

Future<bool> _confirmDelete(
  BuildContext context, {
  required String title,
  required String message,
  String deleteText = 'Delete',
  String cancelText = 'Cancel',
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
            child: Text(cancelText),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(dialogContext, true);
            },
            child: Text(deleteText),
          ),
        ],
      );
    },
  );

  return result ?? false;
}

// ============================================================================
// HOME SCREEN
// ============================================================================

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  int _getInsuranceCount(BuildContext context) {
    final provider = Provider.of<InsuranceProvider>(
      context,
      listen: false,
    );

    return provider.cards.length;
  }

  Future<void> _openGetCopyLink(BuildContext context) async {
    final uri = Uri.parse(_getCopyPaymentUrl);

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && context.mounted) {
        _showCopyModal(context);
      }
    } catch (_) {
      if (context.mounted) {
        _showCopyModal(context);
      }
    }
  }

  void _showCopyModal(BuildContext context) {
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

  Widget _buildLangChip(
    BuildContext context,
    String langCode,
    String label,
    String activeCode,
  ) {
    final isSelected = langCode == activeCode;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Provider.of<LanguageProvider>(
          context,
          listen: false,
        ).setLanguage(langCode);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(
          horizontal: 9,
          vertical: 5,
        ),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.teal.shade700,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.amber.shade700
                : Colors.white38,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight:
                isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? Colors.teal.shade900
                : Colors.white,
          ),
        ),
      ),
    );
  }

  List<HomeItem> _buildHomeItems(
    BuildContext context,
    SanaTranslations t,
  ) {
    final medications = Provider.of<MedicationProvider>(
      context,
      listen: false,
    );

    final doctors = Provider.of<DoctorProvider>(
      context,
      listen: false,
    );

    final pharmacies = Provider.of<PharmacyProvider>(
      context,
      listen: false,
    );

    final documents = Provider.of<DocumentProvider>(
      context,
      listen: false,
    );

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
        count: _getInsuranceCount(context).toString(),
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

  void _openHomeAction(
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

  Widget _buildHomeRow(
    BuildContext context,
    HomeItem left,
    HomeItem right,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _buildHomeCard(context, left),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildHomeCard(context, right),
        ),
      ],
    );
  }

  Widget _buildHomeCard(
    BuildContext context,
    HomeItem item,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          _openHomeAction(context, item.action);
        },
        child: Container(
          constraints: const BoxConstraints(
            minHeight: 105,
          ),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: item.color.withValues(alpha: 0.65),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: item.color.withValues(alpha: 0.10),
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
              Flexible(
                child: Text(
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
              ),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.12),
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

  void _showReminderDialog(BuildContext context) {
    final medProvider = Provider.of<MedicationProvider>(
      context,
      listen: false,
    );

    final language = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );

    final code = language.locale.languageCode;

    String title = 'Active Reminders';
    String noData = 'No active reminders.';
    String close = 'Close';
    String dosage = 'Dosage';

    switch (code) {
      case 'ar':
        title = 'التذكيرات النشطة';
        noData = 'لا توجد تذكيرات نشطة.';
        close = 'إغلاق';
        dosage = 'الجرعة';
        break;

      case 'es':
        title = 'Recordatorios Activos';
        noData = 'No hay recordatorios activos.';
        close = 'Cerrar';
        dosage = 'Dosis';
        break;

      case 'fr':
        title = 'Rappels Actifs';
        noData = 'Aucun rappel actif.';
        close = 'Fermer';
        dosage = 'Dosage';
        break;

      case 'de':
        title = 'Aktive Erinnerungen';
        noData = 'Keine aktiven Erinnerungen.';
        close = 'Schließen';
        dosage = 'Dosierung';
        break;

      case 'tr':
        title = 'Aktif Hatırlatıcılar';
        noData = 'Aktif hatırlatıcı yok.';
        close = 'Kapat';
        dosage = 'Doz';
        break;

      case 'hi':
        title = 'सक्रिय अनुस्मारक';
        noData = 'कोई सक्रिय अनुस्मारक नहीं।';
        close = 'बंद करें';
        dosage = 'खुराक';
        break;

      case 'zh':
        title = '活动提醒';
        noData = '暂无活动提醒。';
        close = '关闭';
        dosage = '剂量';
        break;
    }

    final alarms = <Map<String, dynamic>>[];

    for (final medication in medProvider.medications) {
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
                    child: Text(noData),
                  )
                : ListView.builder(
                    itemCount: alarms.length,
                    itemBuilder: (context, index) {
                      final item = alarms[index];

                      final medication =
                          item['medication'] as Medication;

                      final timeDisplay =
                          item['time'] as String;

                      return ListTile(
                        leading: _buildMedicationReminderAvatar(
                          medication,
                        ),
                        title: Text(
                          medication.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '$timeDisplay - $dosage: ${medication.dosage}',
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
                        onTap: () {
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
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text(close),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMedicationReminderAvatar(
    Medication medication,
  ) {
    if (medication.photoUrl != null &&
        medication.photoUrl!.startsWith('data:image')) {
      try {
        final data = Uri.parse(medication.photoUrl!).data;

        if (data != null) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.memory(
              data.contentAsBytes(),
              width: 40,
              height: 40,
              fit: BoxFit.cover,
            ),
          );
        }
      } catch (_) {
        // Fall through to default avatar.
      }
    }

    return const CircleAvatar(
      backgroundColor: Colors.teal,
      child: Icon(
        Icons.alarm,
        color: Colors.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final language = Provider.of<LanguageProvider>(context);

    final code = language.locale.languageCode;

    final translations = SanaTranslations.fromCode(code);

    final items = _buildHomeItems(
      context,
      translations,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        toolbarHeight: 52,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.health_and_safety,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(width: 8),
            const Text(
              'SANA',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(
                Icons.share,
                color: Colors.orange,
                size: 22,
              ),
              onPressed: () {
                SharePlus.instance.share(
                  ShareParams(
                    text: _sanaShareUrl,
                  ),
                );
              },
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(36),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 4,
            ),
            child: Row(
              children: [
                _buildLangChip(
                  context,
                  'en',
                  'English',
                  code,
                ),
                _buildLangChip(
                  context,
                  'ar',
                  'العربية',
                  code,
                ),
                _buildLangChip(
                  context,
                  'es',
                  'Español',
                  code,
                ),
                _buildLangChip(
                  context,
                  'fr',
                  'Français',
                  code,
                ),
                _buildLangChip(
                  context,
                  'de',
                  'Deutsch',
                  code,
                ),
                _buildLangChip(
                  context,
                  'tr',
                  'Türkçe',
                  code,
                ),
                _buildLangChip(
                  context,
                  'hi',
                  'हिन्दी',
                  code,
                ),
                _buildLangChip(
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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE0F2FE),
              Color(0xFFE0F7FA),
              Color(0xFFFFF8E1),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    translations.smartHealth,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.teal.shade900,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 108,
                  child: _buildHomeRow(
                    context,
                    items[0],
                    items[1],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 108,
                  child: _buildHomeRow(
                    context,
                    items[2],
                    items[3],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 108,
                  child: _buildHomeRow(
                    context,
                    items[4],
                    items[5],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 108,
                  child: _buildHomeCard(
                    context,
                    items[6],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const AdminScreen(),
                            ),
                          );
                        },
                        child: Text(
                          translations.admin,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.teal,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const AboutSanaScreen(),
                            ),
                          );
                        },
                        child: Text(
                          translations.about,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.teal,
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
                  height: 42,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _openGetCopyLink(context);
                    },
                    icon: const Icon(
                      Icons.lock_open,
                      size: 18,
                    ),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        translations.getCopyButton(code),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// MEDICATION LIST SCREEN
// ============================================================================

class MedicationListScreen extends StatelessWidget {
  const MedicationListScreen({super.key});

  String _formatRepeatType(
    String repeat,
    String code,
  ) {
    if (repeat == 'Daily') {
      switch (code) {
        case 'ar':
          return 'يومياً';
        case 'es':
          return 'Diario';
        case 'fr':
          return 'Quotidien';
        case 'de':
          return 'Täglich';
        case 'tr':
          return 'Günlük';
        case 'hi':
          return 'दैनिक';
        case 'zh':
          return '每天';
        default:
          return 'Daily';
      }
    }

    return repeat;
  }

  Future<void> _deleteMedication(
    BuildContext context,
    MedicationProvider provider,
    Medication medication,
    String code,
  ) async {
    String title = 'Delete medication?';
    String message =
        'Are you sure you want to delete "${medication.name}"?';
    String deleteText = 'Delete';
    String cancelText = 'Cancel';

    switch (code) {
      case 'ar':
        title = 'حذف الدواء؟';
        message =
            'هل أنت متأكد أنك تريد حذف "${medication.name}"؟';
        deleteText = 'حذف';
        cancelText = 'إلغاء';
        break;

      case 'es':
        title = '¿Eliminar medicamento?';
        message =
            '¿Está seguro de que desea eliminar "${medication.name}"?';
        deleteText = 'Eliminar';
        cancelText = 'Cancelar';
        break;

      case 'fr':
        title = 'Supprimer le médicament ?';
        message =
            'Voulez-vous supprimer "${medication.name}" ?';
        deleteText = 'Supprimer';
        cancelText = 'Annuler';
        break;

      case 'de':
        title = 'Medikament löschen?';
        message =
            'Möchten Sie "${medication.name}" wirklich löschen?';
        deleteText = 'Löschen';
        cancelText = 'Abbrechen';
        break;

      case 'tr':
        title = 'İlaç silinsin mi?';
        message =
            '"${medication.name}" adlı ilaç silinsin mi?';
        deleteText = 'Sil';
        cancelText = 'İptal';
        break;

      case 'hi':
        title = 'दवा हटाएं?';
        message =
            'क्या आप "${medication.name}" को हटाना चाहते हैं?';
        deleteText = 'हटाएं';
        cancelText = 'रद्द करें';
        break;

      case 'zh':
        title = '删除药物？';
        message =
            '确定要删除“${medication.name}”吗？';
        deleteText = '删除';
        cancelText = '取消';
        break;
    }

    final confirmed = await _confirmDelete(
      context,
      title: title,
      message: message,
      deleteText: deleteText,
      cancelText: cancelText,
    );

    if (confirmed) {
      provider.deleteMedication(medication.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MedicationProvider>(context);
    final language = Provider.of<LanguageProvider>(context);

    final code = language.locale.languageCode;

    String title = 'Medications';
    String addButton = '+ Add Medication';
    String emptyText = 'No medications added yet.';
    String dosageLabel = 'Dosage';
    String remindersLabel = 'Reminders';
    String repeatLabel = 'Repeat';

    switch (code) {
      case 'ar':
        title = 'الأدوية';
        addButton = '+ إضافة دواء';
        emptyText = 'لم يتم إضافة أدوية بعد.';
        dosageLabel = 'الجرعة';
        remindersLabel = 'التذكيرات';
        repeatLabel = 'التكرار';
        break;

      case 'es':
        title = 'Medicamentos';
        addButton = '+ Añadir Medicamento';
        emptyText = 'Aún no se han añadido medicamentos.';
        dosageLabel = 'Dosis';
        remindersLabel = 'Recordatorios';
        repeatLabel = 'Repetir';
        break;

      case 'fr':
        title = 'Médicaments';
        addButton = '+ Ajouter un Médicament';
        emptyText = 'Aucun médicament ajouté pour le moment.';
        dosageLabel = 'Dosage';
        remindersLabel = 'Rappels';
        repeatLabel = 'Répétition';
        break;

      case 'de':
        title = 'Medikamente';
        addButton = '+ Medikament hinzufügen';
        emptyText = 'Noch keine Medikamente hinzugefügt.';
        dosageLabel = 'Dosierung';
        remindersLabel = 'Erinnerungen';
        repeatLabel = 'Wiederholung';
        break;

      case 'tr':
        title = 'İlaçlar';
        addButton = '+ İlaç Ekle';
        emptyText = 'Henüz ilaç eklenmedi.';
        dosageLabel = 'Doz';
        remindersLabel = 'Hatırlatıcılar';
        repeatLabel = 'Tekrar';
        break;

      case 'hi':
        title = 'दवाएं';
        addButton = '+ दवा जोड़ें';
        emptyText = 'अभी तक कोई दवा नहीं जोड़ी गई है।';
        dosageLabel = 'खुराक';
        remindersLabel = 'अनुस्मारक';
        repeatLabel = 'दोहराना';
        break;

      case 'zh':
        title = '药物';
        addButton = '+ 添加药物';
        emptyText = '尚未添加药物。';
        dosageLabel = '剂量';
        remindersLabel = '提醒';
        repeatLabel = '重复';
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(addButton),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddMedicationScreen(),
            ),
          );
        },
      ),
      body: provider.medications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.medication,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    emptyText,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: provider.medications.length,
              itemBuilder: (context, index) {
                final medication =
                    provider.medications[index];

                final repeatText = _formatRepeatType(
                  medication.repeatType,
                  code,
                );

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: const Icon(
                        Icons.medication,
                        color: Colors.blue,
                      ),
                    ),
                    title: Text(
                      medication.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          '$dosageLabel: ${medication.dosage}',
                        ),
                        if (medication.reminderTimes.isNotEmpty)
                          Text(
                            '$remindersLabel: '
                            '${medication.reminderTimes.join(", ")}',
                          ),
                        Text(
                          '$repeatLabel: $repeatText',
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Share',
                          icon: const Icon(
                            Icons.share,
                            color: Colors.orange,
                          ),
                          onPressed: () {
                            SharePlus.instance.share(
                              ShareParams(
                                text:
                                    'Medication: ${medication.name}\n'
                                    'Dosage: ${medication.dosage}\n'
                                    'Repeat: $repeatText',
                              ),
                            );
                          },
                        ),
                        IconButton(
                          tooltip: 'Inspect',
                          icon: const Icon(
                            Icons.visibility,
                            color: Colors.teal,
                          ),
                          onPressed: () {
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
                        IconButton(
                          tooltip: 'Delete',
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            _deleteMedication(
                              context,
                              provider,
                              medication,
                              code,
                            );
                          },
                        ),
                      ],
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
    );
  }
}

// ============================================================================
// DOCTOR LIST SCREEN
// ============================================================================

class DoctorListScreen extends StatelessWidget {
  const DoctorListScreen({super.key});

  void _showEnlargedDoctor(
    BuildContext context,
    Doctor doctor,
    String code,
  ) {
    String specialtyLabel = 'Specialty';
    String phoneLabel = 'Phone Number';
    String callButton = 'Call Doctor';
    String whatsappButton = 'WhatsApp';
    String closeButton = 'Close';

    switch (code) {
      case 'ar':
        specialtyLabel = 'التخصص';
        phoneLabel = 'رقم الهاتف';
        callButton = 'اتصال بالطبيب';
        whatsappButton = 'واتساب';
        closeButton = 'إغلاق';
        break;

      case 'es':
        specialtyLabel = 'Especialidad';
        phoneLabel = 'Teléfono';
        callButton = 'Llamar al Médico';
        whatsappButton = 'WhatsApp';
        closeButton = 'Cerrar';
        break;

      case 'fr':
        specialtyLabel = 'Spécialité';
        phoneLabel = 'Téléphone';
        callButton = 'Appeler le Médecin';
        whatsappButton = 'WhatsApp';
        closeButton = 'Fermer';
        break;

      case 'de':
        specialtyLabel = 'Fachgebiet';
        phoneLabel = 'Telefonnummer';
        callButton = 'Arzt Anrufen';
        whatsappButton = 'WhatsApp';
        closeButton = 'Schließen';
        break;

      case 'tr':
        specialtyLabel = 'Uzmanlık';
        phoneLabel = 'Telefon Numarası';
        callButton = 'Doktoru Ara';
        whatsappButton = 'WhatsApp';
        closeButton = 'Kapat';
        break;

      case 'hi':
        specialtyLabel = 'विशेषता';
        phoneLabel = 'फ़ोन नंबर';
        callButton = 'डॉक्टर को कॉल करें';
        whatsappButton = 'व्हाट्सएप';
        closeButton = 'बंद करें';
        break;

      case 'zh':
        specialtyLabel = '专业';
        phoneLabel = '电话号码';
        callButton = '呼叫医生';
        whatsappButton = 'WhatsApp';
        closeButton = '关闭';
        break;
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundColor: Colors.teal,
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  doctor.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(height: 20),
              if (doctor.specialty != null &&
                  doctor.specialty!.isNotEmpty) ...[
                Text(
                  specialtyLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  doctor.specialty!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (doctor.phone != null &&
                  doctor.phone!.isNotEmpty) ...[
                Text(
                  phoneLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  doctor.phone!,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.teal,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            if (doctor.phone != null &&
                doctor.phone!.isNotEmpty)
              ElevatedButton.icon(
                icon: const Icon(Icons.phone),
                label: Text(callButton),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  _callPhone(
                    context,
                    doctor.phone!,
                  );
                },
              ),
            if (doctor.phone != null &&
                doctor.phone!.isNotEmpty)
              ElevatedButton.icon(
                icon: const Icon(Icons.chat),
                label: Text(whatsappButton),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  _openWhatsApp(
                    context,
                    doctor.phone!,
                  );
                },
              ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text(closeButton),
            ),
          ],
        );
      },
    );
  }

  void _showAddDoctorDialog(
    BuildContext context,
    String code,
  ) {
    final nameController = TextEditingController();
    final specialtyController = TextEditingController();
    final phoneController = TextEditingController();

    String title = 'Add Doctor';
    String nameLabel = 'Doctor Name *';
    String specialtyLabel = 'Specialty';
    String phoneLabel = 'Phone Number';
    String cancelLabel = 'Cancel';
    String saveLabel = 'Save';

    switch (code) {
      case 'ar':
        title = 'إضافة طبيب';
        nameLabel = 'اسم الطبيب *';
        specialtyLabel = 'التخصص';
        phoneLabel = 'رقم الهاتف';
        cancelLabel = 'إلغاء';
        saveLabel = 'حفظ';
        break;

      case 'es':
        title = 'Añadir Médico';
        nameLabel = 'Nombre del Médico *';
        specialtyLabel = 'Especialidad';
        phoneLabel = 'Teléfono';
        cancelLabel = 'Cancelar';
        saveLabel = 'Guardar';
        break;

      case 'fr':
        title = 'Ajouter un Médecin';
        nameLabel = 'Nom du Médecin *';
        specialtyLabel = 'Spécialité';
        phoneLabel = 'Téléphone';
        cancelLabel = 'Annuler';
        saveLabel = 'Enregistrer';
        break;

      case 'de':
        title = 'Arzt hinzufügen';
        nameLabel = 'Name des Arztes *';
        specialtyLabel = 'Fachgebiet';
        phoneLabel = 'Telefonnummer';
        cancelLabel = 'Abbrechen';
        saveLabel = 'Speichern';
        break;

      case 'tr':
        title = 'Doktor Ekle';
        nameLabel = 'Doktor Adı *';
        specialtyLabel = 'Uzmanlık';
        phoneLabel = 'Telefon Numarası';
        cancelLabel = 'İptal';
        saveLabel = 'Kaydet';
        break;

      case 'hi':
        title = 'डॉक्टर जोड़ें';
        nameLabel = 'डॉक्टर का नाम *';
        specialtyLabel = 'विशेषता';
        phoneLabel = 'फ़ोन नंबर';
        cancelLabel = 'रद्द करें';
        saveLabel = 'सहेजें';
        break;

      case 'zh':
        title = '添加医生';
        nameLabel = '医生姓名 *';
        specialtyLabel = '专业';
        phoneLabel = '电话号码';
        cancelLabel = '取消';
        saveLabel = '保存';
        break;
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: nameLabel,
                  ),
                  textInputAction: TextInputAction.next,
                ),
                TextField(
                  controller: specialtyController,
                  decoration: InputDecoration(
                    labelText: specialtyLabel,
                  ),
                  textInputAction: TextInputAction.next,
                ),
                TextField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: phoneLabel,
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text(cancelLabel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final name =
                    nameController.text.trim();

                if (name.isEmpty) {
                  return;
                }

                final doctor = Doctor(
                  id: DateTime.now()
                      .millisecondsSinceEpoch
                      .toString(),
                  name: name,
                  specialty:
                      specialtyController.text.trim(),
                  phone: phoneController.text.trim(),
                );

                Provider.of<DoctorProvider>(
                  context,
                  listen: false,
                ).addDoctor(doctor);

                Navigator.pop(dialogContext);
              },
              child: Text(saveLabel),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteDoctor(
    BuildContext context,
    DoctorProvider provider,
    Doctor doctor,
    String code,
  ) async {
    String title = 'Delete doctor?';
    String message =
        'Are you sure you want to delete "${doctor.name}"?';
    String deleteText = 'Delete';
    String cancelText = 'Cancel';

    switch (code) {
      case 'ar':
        title = 'حذف الطبيب؟';
        message =
            'هل أنت متأكد أنك تريد حذف "${doctor.name}"؟';
        deleteText = 'حذف';
        cancelText = 'إلغاء';
        break;

      case 'es':
        title = '¿Eliminar médico?';
        message =
            '¿Está seguro de que desea eliminar "${doctor.name}"?';
        deleteText = 'Eliminar';
        cancelText = 'Cancelar';
        break;

      case 'fr':
        title = 'Supprimer le médecin ?';
        message =
            'Voulez-vous supprimer "${doctor.name}" ?';
        deleteText = 'Supprimer';
        cancelText = 'Annuler';
        break;

      case 'de':
        title = 'Arzt löschen?';
        message =
            'Möchten Sie "${doctor.name}" wirklich löschen?';
        deleteText = 'Löschen';
        cancelText = 'Abbrechen';
        break;

      case 'tr':
        title = 'Doktor silinsin mi?';
        message =
            '"${doctor.name}" adlı doktor silinsin mi?';
        deleteText = 'Sil';
        cancelText = 'İptal';
        break;

      case 'hi':
        title = 'डॉक्टर हटाएं?';
        message =
            'क्या आप "${doctor.name}" को हटाना चाहते हैं?';
        deleteText = 'हटाएं';
        cancelText = 'रद्द करें';
        break;

      case 'zh':
        title = '删除医生？';
        message =
            '确定要删除“${doctor.name}”吗？';
        deleteText = '删除';
        cancelText = '取消';
        break;
    }

    final confirmed = await _confirmDelete(
      context,
      title: title,
      message: message,
      deleteText: deleteText,
      cancelText: cancelText,
    );

    if (confirmed) {
      provider.deleteDoctor(doctor.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DoctorProvider>(context);
    final language = Provider.of<LanguageProvider>(context);

    final code = language.locale.languageCode;

    String title = 'Doctors';
    String addButton = '+ Add Doctor';
    String emptyText = 'No doctors added yet.';
    String specialtyLabel = 'Specialty';

    switch (code) {
      case 'ar':
        title = 'الأطباء';
        addButton = '+ إضافة طبيب';
        emptyText = 'لم يتم إضافة أطباء بعد.';
        specialtyLabel = 'التخصص';
        break;

      case 'es':
        title = 'Médicos';
        addButton = '+ Añadir Médico';
        emptyText = 'Aún no se han añadido médicos.';
        specialtyLabel = 'Especialidad';
        break;

      case 'fr':
        title = 'Médecins';
        addButton = '+ Ajouter un Médecin';
        emptyText = 'Aucun médecin ajouté pour le moment.';
        specialtyLabel = 'Spécialité';
        break;

      case 'de':
        title = 'Ärzte';
        addButton = '+ Arzt hinzufügen';
        emptyText = 'Noch keine Ärzte hinzugefügt.';
        specialtyLabel = 'Fachgebiet';
        break;

      case 'tr':
        title = 'Doktorlar';
        addButton = '+ Doktor Ekle';
        emptyText = 'Henüz doktor eklenmedi.';
        specialtyLabel = 'Uzmanlık';
        break;

      case 'hi':
        title = 'डॉक्टर';
        addButton = '+ डॉक्टर जोड़ें';
        emptyText = 'अभी तक कोई डॉक्टर नहीं जोड़ा गया है।';
        specialtyLabel = 'विशेषता';
        break;

      case 'zh':
        title = '医生';
        addButton = '+ 添加医生';
        emptyText = '尚未添加医生。';
        specialtyLabel = '专业';
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(addButton),
        onPressed: () {
          _showAddDoctorDialog(
            context,
            code,
          );
        },
      ),
      body: provider.doctors.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    emptyText,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: provider.doctors.length,
              itemBuilder: (context, index) {
                final doctor = provider.doctors[index];

                final specialty = doctor.specialty;
                final phone = doctor.phone;

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green.shade100,
                      child: const Icon(
                        Icons.person,
                        color: Colors.green,
                      ),
                    ),
                    title: Text(
                      doctor.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        if (specialty != null &&
                            specialty.isNotEmpty)
                          Text(
                            '$specialtyLabel: $specialty',
                          ),
                        if (phone != null &&
                            phone.isNotEmpty)
                          Text(phone),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Call',
                          icon: const Icon(
                            Icons.phone,
                            color: Colors.green,
                          ),
                          onPressed: () {
                            if (phone != null &&
                                phone.isNotEmpty) {
                              _callPhone(
                                context,
                                phone,
                              );
                            } else {
                              _showEnlargedDoctor(
                                context,
                                doctor,
                                code,
                              );
                            }
                          },
                        ),
                        IconButton(
                          tooltip: 'WhatsApp',
                          icon: const Icon(
                            Icons.chat,
                            color: Colors.green,
                          ),
                          onPressed: () {
                            if (phone != null &&
                                phone.isNotEmpty) {
                              _openWhatsApp(
                                context,
                                phone,
                              );
                            }
                          },
                        ),
                        IconButton(
                          tooltip: 'Delete',
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            _deleteDoctor(
                              context,
                              provider,
                              doctor,
                              code,
                            );
                          },
                        ),
                      ],
                    ),
                    onTap: () {
                      _showEnlargedDoctor(
                        context,
                        doctor,
                        code,
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

// ============================================================================
// PHARMACY LIST SCREEN
// ============================================================================

class PharmacyListScreen extends StatelessWidget {
  const PharmacyListScreen({super.key});

  void _showEnlargedPharmacy(
    BuildContext context,
    Pharmacy pharmacy,
    String code,
  ) {
    String addressLabel = 'Address';
    String phoneLabel = 'Phone Number';
    String callButton = 'Call Pharmacy';
    String whatsappButton = 'WhatsApp';
    String closeButton = 'Close';

    switch (code) {
      case 'ar':
        addressLabel = 'العنوان';
        phoneLabel = 'رقم الهاتف';
        callButton = 'اتصال بالصيدلية';
        whatsappButton = 'واتساب';
        closeButton = 'إغلاق';
        break;

      case 'es':
        addressLabel = 'Dirección';
        phoneLabel = 'Teléfono';
        callButton = 'Llamar a la Farmacia';
        whatsappButton = 'WhatsApp';
        closeButton = 'Cerrar';
        break;

      case 'fr':
        addressLabel = 'Adresse';
        phoneLabel = 'Téléphone';
        callButton = 'Appeler la Pharmacie';
        whatsappButton = 'WhatsApp';
        closeButton = 'Fermer';
        break;

      case 'de':
        addressLabel = 'Adresse';
        phoneLabel = 'Telefonnummer';
        callButton = 'Apotheke Anrufen';
        whatsappButton = 'WhatsApp';
        closeButton = 'Schließen';
        break;

      case 'tr':
        addressLabel = 'Adres';
        phoneLabel = 'Telefon Numarası';
        callButton = 'Eczaneyi Ara';
        whatsappButton = 'WhatsApp';
        closeButton = 'Kapat';
        break;

      case 'hi':
        addressLabel = 'पता';
        phoneLabel = 'फ़ोन नंबर';
        callButton = 'फार्मेसी को कॉल करें';
        whatsappButton = 'व्हाट्सएप';
        closeButton = 'बंद करें';
        break;

      case 'zh':
        addressLabel = '地址';
        phoneLabel = '电话号码';
        callButton = '呼叫药房';
        whatsappButton = 'WhatsApp';
        closeButton = '关闭';
        break;
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundColor: Colors.orange,
                child: Icon(
                  Icons.local_pharmacy,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  pharmacy.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(height: 20),
              if (pharmacy.address != null &&
                  pharmacy.address!.isNotEmpty) ...[
                Text(
                  addressLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  pharmacy.address!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (pharmacy.phone != null &&
                  pharmacy.phone!.isNotEmpty) ...[
                Text(
                  phoneLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  pharmacy.phone!,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.teal,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            if (pharmacy.phone != null &&
                pharmacy.phone!.isNotEmpty)
              ElevatedButton.icon(
                icon: const Icon(Icons.phone),
                label: Text(callButton),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  _callPhone(
                    context,
                    pharmacy.phone!,
                  );
                },
              ),
            if (pharmacy.phone != null &&
                pharmacy.phone!.isNotEmpty)
              ElevatedButton.icon(
                icon: const Icon(Icons.chat),
                label: Text(whatsappButton),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  _openWhatsApp(
                    context,
                    pharmacy.phone!,
                  );
                },
              ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text(closeButton),
            ),
          ],
        );
      },
    );
  }

  void _showAddPharmacyDialog(
    BuildContext context,
    String code,
  ) {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final phoneController = TextEditingController();

    String title = 'Add Pharmacy';
    String nameLabel = 'Pharmacy Name *';
    String addressLabel = 'Address';
    String phoneLabel = 'Phone Number';
    String cancelLabel = 'Cancel';
    String saveLabel = 'Save';

    switch (code) {
      case 'ar':
        title = 'إضافة صيدلية';
        nameLabel = 'اسم الصيدلية *';
        addressLabel = 'العنوان';
        phoneLabel = 'رقم الهاتف';
        cancelLabel = 'إلغاء';
        saveLabel = 'حفظ';
        break;

      case 'es':
        title = 'Añadir Farmacia';
        nameLabel = 'Nombre de la Farmacia *';
        addressLabel = 'Dirección';
        phoneLabel = 'Teléfono';
        cancelLabel = 'Cancelar';
        saveLabel = 'Guardar';
        break;

      case 'fr':
        title = 'Ajouter une Pharmacie';
        nameLabel = 'Nom de la Pharmacie *';
        addressLabel = 'Adresse';
        phoneLabel = 'Téléphone';
        cancelLabel = 'Annuler';
        saveLabel = 'Enregistrer';
        break;

      case 'de':
        title = 'Apotheke hinzufügen';
        nameLabel = 'Name der Apotheke *';
        addressLabel = 'Adresse';
        phoneLabel = 'Telefonnummer';
        cancelLabel = 'Abbrechen';
        saveLabel = 'Speichern';
        break;

      case 'tr':
        title = 'Eczane Ekle';
        nameLabel = 'Eczane Adı *';
        addressLabel = 'Adres';
        phoneLabel = 'Telefon Numarası';
        cancelLabel = 'İptal';
        saveLabel = 'Kaydet';
        break;

      case 'hi':
        title = 'फार्मेसी जोड़ें';
        nameLabel = 'फार्मेसी का नाम *';
        addressLabel = 'पता';
        phoneLabel = 'फ़ोन नंबर';
        cancelLabel = 'रद्द करें';
        saveLabel = 'सहेजें';
        break;

      case 'zh':
        title = '添加药房';
        nameLabel = '药房名称 *';
        addressLabel = '地址';
        phoneLabel = '电话号码';
        cancelLabel = '取消';
        saveLabel = '保存';
        break;
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: nameLabel,
                  ),
                  textInputAction: TextInputAction.next,
                ),
                TextField(
                  controller: addressController,
                  decoration: InputDecoration(
                    labelText: addressLabel,
                  ),
                  textInputAction: TextInputAction.next,
                ),
                TextField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: phoneLabel,
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text(cancelLabel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final name =
                    nameController.text.trim();

                if (name.isEmpty) {
                  return;
                }

                final pharmacy = Pharmacy(
                  id: DateTime.now()
                      .millisecondsSinceEpoch
                      .toString(),
                  name: name,
                  address:
                      addressController.text.trim(),
                  phone:
                      phoneController.text.trim(),
                );

                Provider.of<PharmacyProvider>(
                  context,
                  listen: false,
                ).addPharmacy(pharmacy);

                Navigator.pop(dialogContext);
              },
              child: Text(saveLabel),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deletePharmacy(
    BuildContext context,
    PharmacyProvider provider,
    Pharmacy pharmacy,
    String code,
  ) async {
    String title = 'Delete pharmacy?';
    String message =
        'Are you sure you want to delete "${pharmacy.name}"?';
    String deleteText = 'Delete';
    String cancelText = 'Cancel';

    switch (code) {
      case 'ar':
        title = 'حذف الصيدلية؟';
        message =
            'هل أنت متأكد أنك تريد حذف "${pharmacy.name}"؟';
        deleteText = 'حذف';
        cancelText = 'إلغاء';
        break;

      case 'es':
        title = '¿Eliminar farmacia?';
        message =
            '¿Está seguro de que desea eliminar "${pharmacy.name}"?';
        deleteText = 'Eliminar';
        cancelText = 'Cancelar';
        break;

      case 'fr':
        title = 'Supprimer la pharmacie ?';
        message =
            'Voulez-vous supprimer "${pharmacy.name}" ?';
        deleteText = 'Supprimer';
        cancelText = 'Annuler';
        break;

      case 'de':
        title = 'Apotheke löschen?';
        message =
            'Möchten Sie "${pharmacy.name}" wirklich löschen?';
        deleteText = 'Löschen';
        cancelText = 'Abbrechen';
        break;

      case 'tr':
        title = 'Eczane silinsin mi?';
        message =
            '"${pharmacy.name}" adlı eczane silinsin mi?';
        deleteText = 'Sil';
        cancelText = 'İptal';
        break;

      case 'hi':
        title = 'फार्मेसी हटाएं?';
        message =
            'क्या आप "${pharmacy.name}" को हटाना चाहते हैं?';
        deleteText = 'हटाएं';
        cancelText = 'रद्द करें';
        break;

      case 'zh':
        title = '删除药房？';
        message =
            '确定要删除“${pharmacy.name}”吗？';
        deleteText = '删除';
        cancelText = '取消';
        break;
    }

    final confirmed = await _confirmDelete(
      context,
      title: title,
      message: message,
      deleteText: deleteText,
      cancelText: cancelText,
    );

    if (confirmed) {
      provider.deletePharmacy(pharmacy.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PharmacyProvider>(context);
    final language = Provider.of<LanguageProvider>(context);

    final code = language.locale.languageCode;

    String title = 'Pharmacies';
    String addButton = '+ Add Pharmacy';
    String emptyText = 'No pharmacies added yet.';

    switch (code) {
      case 'ar':
        title = 'الصيدليات';
        addButton = '+ إضافة صيدلية';
        emptyText = 'لم يتم إضافة صيدليات بعد.';
        break;

      case 'es':
        title = 'Farmacias';
        addButton = '+ Añadir Farmacia';
        emptyText = 'Aún no se han añadido farmacias.';
        break;

      case 'fr':
        title = 'Pharmacies';
        addButton = '+ Ajouter une Pharmacie';
        emptyText = 'Aucune pharmacie ajoutée pour le moment.';
        break;

      case 'de':
        title = 'Apotheken';
        addButton = '+ Apotheke hinzufügen';
        emptyText = 'Noch keine Apotheken hinzugefügt.';
        break;

      case 'tr':
        title = 'Eczaneler';
        addButton = '+ Eczane Ekle';
        emptyText = 'Henüz eczane eklenmedi.';
        break;

      case 'hi':
        title = 'फार्मेसी';
        addButton = '+ फार्मेसी जोड़ें';
        emptyText = 'अभी तक कोई फार्मेसी नहीं जोड़ी गई है।';
        break;

      case 'zh':
        title = '药房';
        addButton = '+ 添加药房';
        emptyText = '尚未添加药房。';
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(addButton),
        onPressed: () {
          _showAddPharmacyDialog(
            context,
            code,
          );
        },
      ),
      body: provider.pharmacies.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_pharmacy,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    emptyText,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: provider.pharmacies.length,
              itemBuilder: (context, index) {
                final pharmacy =
                    provider.pharmacies[index];

                final address = pharmacy.address;
                final phone = pharmacy.phone;

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          Colors.orange.shade100,
                      child: const Icon(
                        Icons.local_pharmacy,
                        color: Colors.orange,
                      ),
                    ),
                    title: Text(
                      pharmacy.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        if (address != null &&
                            address.isNotEmpty)
                          Text(address),
                        if (phone != null &&
                            phone.isNotEmpty)
                          Text(phone),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Call',
                          icon: const Icon(
                            Icons.phone,
                            color: Colors.green,
                          ),
                          onPressed: () {
                            if (phone != null &&
                                phone.isNotEmpty) {
                              _callPhone(
                                context,
                                phone,
                              );
                            } else {
                              _showEnlargedPharmacy(
                                context,
                                pharmacy,
                                code,
                              );
                            }
                          },
                        ),
                        IconButton(
                          tooltip: 'WhatsApp',
                          icon: const Icon(
                            Icons.chat,
                            color: Colors.green,
                          ),
                          onPressed: () {
                            if (phone != null &&
                                phone.isNotEmpty) {
                              _openWhatsApp(
                                context,
                                phone,
                              );
                            }
                          },
                        ),
                        IconButton(
                          tooltip: 'Delete',
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            _deletePharmacy(
                              context,
                              provider,
                              pharmacy,
                              code,
                            );
                          },
                        ),
                      ],
                    ),
                    onTap: () {
                      _showEnlargedPharmacy(
                        context,
                        pharmacy,
                        code,
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

