import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/doctor.dart';
import '../models/medication.dart';
import '../models/pharmacy.dart';
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
  if (value.isEmpty) return;
  final uri = Uri.parse('tel:$value');
  await _launchExternalUrl(context, uri);
}

Future<void> _openWhatsApp(
  BuildContext context,
  String phone,
) async {
  final number = _cleanPhoneNumber(phone);
  if (number.isEmpty) return;
  final uri = Uri.https('wa.me', '/$number');
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
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
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
    final provider = Provider.of<InsuranceProvider>(context, listen: false);
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
              onPressed: () => Navigator.pop(dialogContext),
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
            color: isSelected ? Colors.amber.shade700 : Colors.white38,
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
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.teal.shade900 : Colors.white,
          ),
        ),
      ),
    );
  }

  List<HomeItem> _buildHomeItems(
    BuildContext context,
    SanaTranslations t,
  ) {
    final medications = Provider.of<MedicationProvider>(context);
    final doctors = Provider.of<DoctorProvider>(context);
    final pharmacies = Provider.of<PharmacyProvider>(context);
    final documents = Provider.of<DocumentProvider>(context);

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
          MaterialPageRoute(builder: (_) => const MedicationListScreen()),
        );
        break;
      case HomeAction.doctors:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DoctorListScreen()),
        );
        break;
      case HomeAction.pharmacies:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PharmacyListScreen()),
        );
        break;
      case HomeAction.reminders:
        _showReminderDialog(context);
        break;
      case HomeAction.documents:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DocumentsScreen()),
        );
        break;
      case HomeAction.insurance:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const InsuranceScreen()),
        );
        break;
      case HomeAction.sharing:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SharingScreen()),
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
        Expanded(child: _buildHomeCard(context, left)),
        const SizedBox(width: 8),
        Expanded(child: _buildHomeCard(context, right)),
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
        onTap: () => _openHomeAction(context, item.action),
        child: Container(
          constraints: const BoxConstraints(minHeight: 105),
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
              Icon(item.icon, color: item.color, size: 30),
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
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
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
    final medProvider = Provider.of<MedicationProvider>(context, listen: false);
    final language = Provider.of<LanguageProvider>(context, listen: false);
    final code = language.locale.languageCode;

    String title = 'Active Reminders';
    String noData = 'No active reminders.';
    String dosage = 'Dosage';

    switch (code) {
      case 'ar':
        title = 'التذكيرات النشطة';
        noData = 'لا توجد تذكيرات نشطة.';
        dosage = 'الجرعة';
        break;
      case 'es':
        title = 'Recordatorios Activos';
        noData = 'No hay recordatorios activos.';
        dosage = 'Dosis';
        break;
      case 'fr':
        title = 'Rappels Actifs';
        noData = 'Aucun rappel actif.';
        dosage = 'Dosage';
        break;
      case 'de':
        title = 'Aktive Erinnerungen';
        noData = 'Keine aktiven Erinnerungen.';
        dosage = 'Dosierung';
        break;
      case 'tr':
        title = 'Aktif Hatırlatıcılar';
        noData = 'Aktif hatırlatıcı yok.';
        dosage = 'Doz';
        break;
      case 'hi':
        title = 'सक्रिय अनुस्मारक';
        noData = 'कोई सक्रिय अनुस्मारक नहीं।';
        dosage = 'खुराक';
        break;
      case 'zh':
        title = '活动提醒';
        noData = '暂无活动提醒。';
        dosage = '剂量';
        break;
    }

    final alarms = <Map<String, dynamic>>[];
    for (final medication in medProvider.medications) {
      for (final time in medication.reminderTimes) {
        alarms.add({'medication': medication, 'time': time});
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
                ? Center(child: Text(noData))
                : ListView.builder(
                    itemCount: alarms.length,
                    itemBuilder: (context, index) {
                      final item = alarms[index];
                      final medication = item['medication'] as Medication;
                      final timeDisplay = item['time'] as String;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.teal.shade50,
                          child: const Icon(Icons.alarm, color: Colors.teal),
                        ),
                        title: Text(
                          medication.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('$timeDisplay - $dosage: ${medication.dosage}'),
                        trailing: IconButton(
                          tooltip: 'Inspect',
                          icon: const Icon(Icons.visibility, color: Colors.teal),
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MedicationDetailScreen(medication: medication),
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
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final language = Provider.of<LanguageProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final activeCode = language.locale.languageCode;
    final translations = SanaTranslations.fromCode(activeCode);
    final items = _buildHomeItems(context, translations);

    return Scaffold(
      backgroundColor: const Color(0xFFE6F3F1),
      appBar: AppBar(
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
        elevation: 2,
        title: Row(
          children: [
            const Icon(Icons.health_and_safety, color: Colors.white, size: 26),
            const SizedBox(width: 8),
            Text(
              'SANA',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const Spacer(),
            if (auth.isAdmin)
              IconButton(
                tooltip: 'Admin Panel',
                icon: const Icon(Icons.admin_panel_settings, color: Colors.amber),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminScreen()),
                  );
                },
              ),
            IconButton(
              tooltip: 'Share Sana',
              icon: const Icon(Icons.share, color: Colors.white),
              onPressed: () {
                Share.share('Check out SANA smart health tracker: $_sanaShareUrl');
              },
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildLangChip(context, 'en', 'English', activeCode),
                _buildLangChip(context, 'ar', 'العربية', activeCode),
                _buildLangChip(context, 'es', 'Español', activeCode),
                _buildLangChip(context, 'fr', 'Français', activeCode),
                _buildLangChip(context, 'de', 'Deutsch', activeCode),
                _buildLangChip(context, 'tr', 'Türkçe', activeCode),
                _buildLangChip(context, 'hi', 'हिन्दी', activeCode),
                _buildLangChip(context, 'zh', '中文', activeCode),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          child: Column(
            children: [
              SizedBox(
                height: 108,
                child: _buildHomeRow(context, items[0], items[1]),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 108,
                child: _buildHomeRow(context, items[2], items[3]),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 108,
                child: _buildHomeRow(context, items[4], items[5]),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 108,
                child: _buildHomeCard(context, items[6]),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      icon: const Icon(Icons.admin_panel_settings, size: 16),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AdminScreen()),
                        );
                      },
                      label: Text(
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
                    child: TextButton.icon(
                      icon: const Icon(Icons.info_outline, size: 16),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AboutSanaScreen()),
                        );
                      },
                      label: Text(
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
                  onPressed: () => _openGetCopyLink(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade800,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                  label: Text(translations.getCopyButton(activeCode)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// MEDICATION LIST SCREEN
// ============================================================================
class MedicationListScreen extends StatefulWidget {
  const MedicationListScreen({super.key});

  @override
  State<MedicationListScreen> createState() => _MedicationListScreenState();
}

class _MedicationListScreenState extends State<MedicationListScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final medProvider = Provider.of<MedicationProvider>(context);
    final medications = medProvider.medications.where((m) {
      return m.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          m.purpose.toLowerCase().contains(_searchQuery.toLowerCase());
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
                hintText: 'Search medications or purpose...',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          Expanded(
            child: medications.isEmpty
                ? const Center(
                    child: Text(
                      'No medications added yet.',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: medications.length,
                    itemBuilder: (context, index) {
                      final med = medications[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade50,
                            child: const Icon(Icons.medication, color: Colors.blue),
                          ),
                          title: Text(
                            med.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('Dosage: ${med.dosage} • ${med.frequency}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () async {
                                  final confirm = await _confirmDelete(
                                    context,
                                    title: 'Delete Medication',
                                    message: 'Are you sure you want to delete ${med.name}?',
                                  );
                                  if (confirm && context.mounted) {
                                    medProvider.deleteMedication(med.id);
                                  }
                                },
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MedicationDetailScreen(medication: med),
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
            MaterialPageRoute(builder: (_) => const AddMedicationScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ============================================================================
// DOCTOR LIST SCREEN
// ============================================================================
class DoctorListScreen extends StatelessWidget {
  const DoctorListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final docProvider = Provider.of<DoctorProvider>(context);
    final doctors = docProvider.doctors;

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
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: doctors.length,
              itemBuilder: (context, index) {
                final doc = doctors[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.green.shade50,
                              child: const Icon(Icons.person, color: Colors.green),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    doc.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    doc.specialty,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () async {
                                final confirm = await _confirmDelete(
                                  context,
                                  title: 'Delete Doctor',
                                  message: 'Are you sure you want to remove Dr. ${doc.name}?',
                                );
                                if (confirm && context.mounted) {
                                  docProvider.deleteDoctor(doc.id);
                                }
                              },
                            ),
                          ],
                        ),
                        if (doc.phone.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              OutlinedButton.icon(
                                icon: const Icon(Icons.phone, size: 16),
                                label: const Text('Call'),
                                onPressed: () => _callPhone(context, doc.phone),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.chat, size: 16),
                                label: const Text('WhatsApp'),
                                onPressed: () => _openWhatsApp(context, doc.phone),
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
            MaterialPageRoute(builder: (_) => const AddDoctorScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ============================================================================
// PHARMACY LIST SCREEN
// ============================================================================
class PharmacyListScreen extends StatelessWidget {
  const PharmacyListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pharmProvider = Provider.of<PharmacyProvider>(context);
    final pharmacies = pharmProvider.pharmacies;

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
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: pharmacies.length,
              itemBuilder: (context, index) {
                final pharm = pharmacies[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.orange.shade50,
                              child: const Icon(Icons.local_pharmacy, color: Colors.orange),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pharm.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (pharm.address.isNotEmpty)
                                    Text(
                                      pharm.address,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 13,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () async {
                                final confirm = await _confirmDelete(
                                  context,
                                  title: 'Delete Pharmacy',
                                  message: 'Are you sure you want to remove ${pharm.name}?',
                                );
                                if (confirm && context.mounted) {
                                  pharmProvider.deletePharmacy(pharm.id);
                                }
                              },
                            ),
                          ],
                        ),
                        if (pharm.phone.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              OutlinedButton.icon(
                                icon: const Icon(Icons.phone, size: 16),
                                label: const Text('Call'),
                                onPressed: () => _callPhone(context, pharm.phone),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.chat, size: 16),
                                label: const Text('WhatsApp'),
                                onPressed: () => _openWhatsApp(context, pharm.phone),
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
            MaterialPageRoute(builder: (_) => const AddPharmacyScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}