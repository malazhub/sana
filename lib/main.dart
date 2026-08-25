import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher_string.dart';

const String _supabaseUrl = 'https://emvadnooxyspfsfnzlmb.supabase.co';
const String _supabaseKey = 'sb_publishable_3f7AQFQw-Kx0_Qvir4nFXQ_XZmUMpzm';

const String _payoneerUrl =
    'https://link.payoneer.com/Token?t=CA1D522054524AC081ACCB17B5D8571B&src=pl';

const Map<String, Map<String, String>> _translations = {
  'en': {
    'language': 'Language',
    'get_copy': 'Get Your Own Copy',
    'medications': 'Medications',
    'doctors': 'Doctors',
    'pharmacies': 'Pharmacies',
    'reminders': 'Reminders',
    'documents': 'Documents',
    'share': 'Share',
    'login': 'LOGIN',
    'logout': 'LOGOUT',
    'admin': 'Admin',
    'guest': 'Guest Mode',
    'add': 'Add',
    'view': 'View',
    'preview': 'Preview',
    'delete': 'Delete',
    'close': 'Close',
    'save': 'Save',
    'name': 'Name',
    'phone': 'Phone',
    'address': 'Address',
    'specialty': 'Specialty',
    'title': 'Title',
    'category': 'Category',
    'file_url': 'File URL',
    'dosage': 'Dosage',
    'reminder_time': 'Reminder Time',
    'provider': 'Provider',
    'policy': 'Policy Number',
    'expiry': 'Expiry',
    'email': 'Email',
    'password': 'Password',
    'sign_in': 'Sign In',
    'account': 'Account',
    'guest_data': 'Guest data',
    'active_user': 'Active user',
    'inactive_guest': 'Inactive user — Guest Mode',
    'no_records': 'No records',
    'share_record': 'Share record',
    'full_record': 'Full record',
    'admin_panel': 'SANA Admin Panel',
    'users': 'Users',
    'activate': 'Activate',
    'deactivate': 'Deactivate',
    'status': 'Status',
    'role': 'Role',
    'expired': 'ACCOUNT EXPIRED - GUEST MODE',
  },
  'ar': {
    'language': 'اللغة',
    'get_copy': 'احصل على نسختك الخاصة',
    'medications': 'الأدوية',
    'doctors': 'الأطباء',
    'pharmacies': 'الصيدليات',
    'reminders': 'التذكيرات',
    'documents': 'المستندات',
    'share': 'مشاركة',
    'login': 'تسجيل الدخول',
    'logout': 'تسجيل الخروج',
    'admin': 'المسؤول',
    'guest': 'وضع الضيف',
    'add': 'إضافة',
    'view': 'عرض',
    'preview': 'معاينة',
    'delete': 'حذف',
    'close': 'إغلاق',
    'save': 'حفظ',
    'name': 'الاسم',
    'phone': 'الهاتف',
    'address': 'العنوان',
    'specialty': 'التخصص',
    'title': 'العنوان',
    'category': 'الفئة',
    'file_url': 'رابط الملف',
    'dosage': 'الجرعة',
    'reminder_time': 'وقت التذكير',
    'provider': 'شركة التأمين',
    'policy': 'رقم الوثيقة',
    'expiry': 'تاريخ الانتهاء',
    'email': 'البريد الإلكتروني',
    'password': 'كلمة المرور',
    'sign_in': 'دخول',
    'account': 'الحساب',
    'guest_data': 'بيانات الضيف',
    'active_user': 'المستخدم النشط',
    'inactive_guest': 'مستخدم غير نشط — وضع الضيف',
    'no_records': 'لا توجد سجلات',
    'share_record': 'مشاركة السجل',
    'full_record': 'السجل الكامل',
    'admin_panel': 'لوحة إدارة SANA',
    'users': 'المستخدمون',
    'activate': 'تفعيل',
    'deactivate': 'تعطيل',
    'status': 'الحالة',
    'role': 'الدور',
    'expired': 'الحساب منتهي - وضع الضيف',
  },
  'es': {
    'language': 'Idioma',
    'get_copy': 'Obtén tu propia copia',
    'medications': 'Medicamentos',
    'doctors': 'Médicos',
    'pharmacies': 'Farmacias',
    'reminders': 'Recordatorios',
    'documents': 'Documentos',
    'share': 'Compartir',
    'login': 'INICIAR SESIÓN',
    'logout': 'CERRAR SESIÓN',
    'admin': 'Administrador',
    'guest': 'Modo invitado',
    'add': 'Añadir',
    'view': 'Ver',
    'preview': 'Vista previa',
    'delete': 'Eliminar',
    'close': 'Cerrar',
    'save': 'Guardar',
    'name': 'Nombre',
    'phone': 'Teléfono',
    'address': 'Dirección',
    'specialty': 'Especialidad',
    'title': 'Título',
    'category': 'Categoría',
    'file_url': 'URL del archivo',
    'dosage': 'Dosis',
    'reminder_time': 'Hora del recordatorio',
    'provider': 'Proveedor',
    'policy': 'Número de póliza',
    'expiry': 'Vencimiento',
    'email': 'Correo',
    'password': 'Contraseña',
    'sign_in': 'Entrar',
    'account': 'Cuenta',
    'guest_data': 'Datos de invitado',
    'active_user': 'Usuario activo',
    'inactive_guest': 'Usuario inactivo — Modo invitado',
    'no_records': 'Sin registros',
    'share_record': 'Compartir registro',
    'full_record': 'Registro completo',
    'admin_panel': 'Panel de administración SANA',
    'users': 'Usuarios',
    'activate': 'Activar',
    'deactivate': 'Desactivar',
    'status': 'Estado',
    'role': 'Rol',
    'expired': 'CUENTA EXPIRADA - MODO INVITADO',
  },
  'fr': {
    'language': 'Langue',
    'get_copy': 'Obtenez votre propre copie',
    'medications': 'Médicaments',
    'doctors': 'Médecins',
    'pharmacies': 'Pharmacies',
    'reminders': 'Rappels',
    'documents': 'Documents',
    'share': 'Partager',
    'login': 'CONNEXION',
    'logout': 'DÉCONNEXION',
    'admin': 'Administrateur',
    'guest': 'Mode invité',
    'add': 'Ajouter',
    'view': 'Voir',
    'preview': 'Aperçu',
    'delete': 'Supprimer',
    'close': 'Fermer',
    'save': 'Enregistrer',
    'name': 'Nom',
    'phone': 'Téléphone',
    'address': 'Adresse',
    'specialty': 'Spécialité',
    'title': 'Titre',
    'category': 'Catégorie',
    'file_url': 'URL du fichier',
    'dosage': 'Dosage',
    'reminder_time': 'Heure du rappel',
    'provider': 'Assureur',
    'policy': 'Numéro de police',
    'expiry': 'Expiration',
    'email': 'E-mail',
    'password': 'Mot de passe',
    'sign_in': 'Se connecter',
    'account': 'Compte',
    'guest_data': 'Données invité',
    'active_user': 'Utilisateur actif',
    'inactive_guest': 'Utilisateur inactif — Mode invité',
    'no_records': 'Aucun enregistrement',
    'share_record': 'Partager le dossier',
    'full_record': 'Dossier complet',
    'admin_panel': 'Panneau administrateur SANA',
    'users': 'Utilisateurs',
    'activate': 'Activer',
    'deactivate': 'Désactiver',
    'status': 'Statut',
    'role': 'Rôle',
    'expired': 'COMPTE EXPIRÉ - MODE INVITÉ',
  },
  'de': {
    'language': 'Sprache',
    'get_copy': 'Eigene Kopie erhalten',
    'medications': 'Medikamente',
    'doctors': 'Ärzte',
    'pharmacies': 'Apotheken',
    'reminders': 'Erinnerungen',
    'documents': 'Dokumente',
    'share': 'Teilen',
    'login': 'ANMELDEN',
    'logout': 'ABMELDEN',
    'admin': 'Administrator',
    'guest': 'Gastmodus',
    'add': 'Hinzufügen',
    'view': 'Anzeigen',
    'preview': 'Vorschau',
    'delete': 'Löschen',
    'close': 'Schließen',
    'save': 'Speichern',
    'name': 'Name',
    'phone': 'Telefon',
    'address': 'Adresse',
    'specialty': 'Fachgebiet',
    'title': 'Titel',
    'category': 'Kategorie',
    'file_url': 'Datei-URL',
    'dosage': 'Dosierung',
    'reminder_time': 'Erinnerungszeit',
    'provider': 'Anbieter',
    'policy': 'Versicherungsnummer',
    'expiry': 'Ablauf',
    'email': 'E-Mail',
    'password': 'Passwort',
    'sign_in': 'Anmelden',
    'account': 'Konto',
    'guest_data': 'Gastdaten',
    'active_user': 'Aktiver Benutzer',
    'inactive_guest': 'Inaktiver Benutzer — Gastmodus',
    'no_records': 'Keine Einträge',
    'share_record': 'Eintrag teilen',
    'full_record': 'Gesamter Datensatz',
    'admin_panel': 'SANA Admin-Panel',
    'users': 'Benutzer',
    'activate': 'Aktivieren',
    'deactivate': 'Deaktivieren',
    'status': 'Status',
    'role': 'Rolle',
    'expired': 'KONTO ABGELAUFEN - GASTMODUS',
  },
  'tr': {
    'language': 'Dil',
    'get_copy': 'Kendi kopyanı al',
    'medications': 'İlaçlar',
    'doctors': 'Doktorlar',
    'pharmacies': 'Eczaneler',
    'reminders': 'Hatırlatıcılar',
    'documents': 'Belgeler',
    'share': 'Paylaş',
    'login': 'GİRİŞ',
    'logout': 'ÇIKIŞ',
    'admin': 'Yönetici',
    'guest': 'Misafir Modu',
    'add': 'Ekle',
    'view': 'Görüntüle',
    'preview': 'Önizleme',
    'delete': 'Sil',
    'close': 'Kapat',
    'save': 'Kaydet',
    'name': 'Ad',
    'phone': 'Telefon',
    'address': 'Adres',
    'specialty': 'Uzmanlık',
    'title': 'Başlık',
    'category': 'Kategori',
    'file_url': 'Dosya URL',
    'dosage': 'Doz',
    'reminder_time': 'Hatırlatma zamanı',
    'provider': 'Sağlayıcı',
    'policy': 'Poliçe numarası',
    'expiry': 'Son kullanma',
    'email': 'E-posta',
    'password': 'Şifre',
    'sign_in': 'Giriş',
    'account': 'Hesap',
    'guest_data': 'Misafir verileri',
    'active_user': 'Aktif kullanıcı',
    'inactive_guest': 'Pasif kullanıcı — Misafir Modu',
    'no_records': 'Kayıt yok',
    'share_record': 'Kaydı paylaş',
    'full_record': 'Tam kayıt',
    'admin_panel': 'SANA Yönetici Paneli',
    'users': 'Kullanıcılar',
    'activate': 'Etkinleştir',
    'deactivate': 'Devre dışı bırak',
    'status': 'Durum',
    'role': 'Rol',
    'expired': 'HESAP SÜRESİ DOLDU - MİSAFİR MODU',
  },
  'hi': {
    'language': 'भाषा',
    'get_copy': 'अपनी प्रति प्राप्त करें',
    'medications': 'दवाइयाँ',
    'doctors': 'डॉक्टर',
    'pharmacies': 'फार्मेसी',
    'reminders': 'रिमाइंडर',
    'documents': 'दस्तावेज़',
    'share': 'साझा करें',
    'login': 'लॉगिन',
    'logout': 'लॉगआउट',
    'admin': 'एडमिन',
    'guest': 'अतिथि मोड',
    'add': 'जोड़ें',
    'view': 'देखें',
    'preview': 'पूर्वावलोकन',
    'delete': 'हटाएँ',
    'close': 'बंद करें',
    'save': 'सहेजें',
    'name': 'नाम',
    'phone': 'फ़ोन',
    'address': 'पता',
    'specialty': 'विशेषता',
    'title': 'शीर्षक',
    'category': 'श्रेणी',
    'file_url': 'फ़ाइल URL',
    'dosage': 'खुराक',
    'reminder_time': 'रिमाइंडर समय',
    'provider': 'प्रदाता',
    'policy': 'पॉलिसी नंबर',
    'expiry': 'समाप्ति',
    'email': 'ईमेल',
    'password': 'पासवर्ड',
    'sign_in': 'साइन इन',
    'account': 'खाता',
    'guest_data': 'अतिथि डेटा',
    'active_user': 'सक्रिय उपयोगकर्ता',
    'inactive_guest': 'निष्क्रिय उपयोगकर्ता — अतिथि मोड',
    'no_records': 'कोई रिकॉर्ड नहीं',
    'share_record': 'रिकॉर्ड साझा करें',
    'full_record': 'पूरा रिकॉर्ड',
    'admin_panel': 'SANA एडमिन पैनल',
    'users': 'उपयोगकर्ता',
    'activate': 'सक्रिय करें',
    'deactivate': 'निष्क्रिय करें',
    'status': 'स्थिति',
    'role': 'भूमिका',
    'expired': 'खाता समाप्त - अतिथि मोड',
  },
  'zh': {
    'language': '语言',
    'get_copy': '获取自己的副本',
    'medications': '药物',
    'doctors': '医生',
    'pharmacies': '药房',
    'reminders': '提醒',
    'documents': '文件',
    'share': '分享',
    'login': '登录',
    'logout': '退出',
    'admin': '管理员',
    'guest': '访客模式',
    'add': '添加',
    'view': '查看',
    'preview': '预览',
    'delete': '删除',
    'close': '关闭',
    'save': '保存',
    'name': '姓名',
    'phone': '电话',
    'address': '地址',
    'specialty': '专科',
    'title': '标题',
    'category': '类别',
    'file_url': '文件链接',
    'dosage': '剂量',
    'reminder_time': '提醒时间',
    'provider': '保险提供商',
    'policy': '保单号码',
    'expiry': '到期',
    'email': '电子邮件',
    'password': '密码',
    'sign_in': '登录',
    'account': '账户',
    'guest_data': '访客数据',
    'active_user': '活跃用户',
    'inactive_guest': '非活跃用户 — 访客模式',
    'no_records': '没有记录',
    'share_record': '分享记录',
    'full_record': '完整记录',
    'admin_panel': 'SANA 管理面板',
    'users': '用户',
    'activate': '启用',
    'deactivate': '停用',
    'status': '状态',
    'role': '角色',
    'expired': '账户已过期 - 访客模式',
  },
};

String tr(String code, String key) =>
    _translations[code]?[key] ?? _translations['en']![key] ?? key;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: _supabaseUrl,
    publishableKey: _supabaseKey,
  );

  runApp(const SanaApp());
}

class SanaApp extends StatefulWidget {
  const SanaApp({super.key});

  @override
  State<SanaApp> createState() => _SanaAppState();
}

class _SanaAppState extends State<SanaApp> {
  String _language = 'en';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: Locale(_language),
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.light,
      ),
      home: HomeScreen(
        language: _language,
        onLanguageChanged: (value) => setState(() => _language = value),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.language,
    required this.onLanguageChanged,
  });

  final String language;
  final ValueChanged<String> onLanguageChanged;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _client = Supabase.instance.client;

  Map<String, dynamic>? _profile;
  bool _loading = true;
  bool _isGuest = true;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    try {
      final user = _client.auth.currentUser;

      if (user == null) {
        await _client.auth.signInAnonymously();
      }

      final current = _client.auth.currentUser;

      if (current == null) {
        if (mounted) {
          setState(() => _loading = false);
        }
        return;
      }

      final data = await _client
          .from('users')
          .select()
          .eq('id', current.id)
          .maybeSingle();

      if (!mounted) return;

      final active = data?['is_active'] == true;
      final role = (data?['role'] ?? '').toString().toLowerCase();

      setState(() {
        _profile = data;
        _isGuest = data == null || !active || role == 'guest';
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String get _ownerId => Supabase.instance.client.auth.currentUser!.id;

  Future<void> _openCard(String type) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecordListScreen(
          type: type,
          language: widget.language,
          ownerId: _ownerId,
          guestMode: _isGuest,
        ),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _shareAll() async {
    final rows = <String>[];

    for (final type in [
      'medications',
      'doctors',
      'pharmacies',
      'reminders',
      'documents',
      'insurance_cards',
    ]) {
      final data = await _query(type);

      rows.add(
        '${tr(widget.language, _titleKey(type))}:\n'
        '${data.map((e) => _compact(e)).join('\n')}',
      );
    }

    await SharePlus.instance.share(
      ShareParams(text: rows.join('\n\n')),
    );
  }

  Future<List<Map<String, dynamic>>> _query(String type) async {
    final field = _isGuest ? 'guest_id' : 'user_id';
    final table = type == 'reminders' ? 'medications' : type;

    final result = await _client.from(table).select().eq(field, _ownerId);

    final rows = List<Map<String, dynamic>>.from(result);

    if (type == 'reminders') {
      return rows
          .where(
            (r) => (r['reminder_time'] ?? '').toString().isNotEmpty,
          )
          .toList();
    }

    return rows;
  }

  String _titleKey(String type) {
    switch (type) {
      case 'medications':
        return 'medications';
      case 'doctors':
        return 'doctors';
      case 'pharmacies':
        return 'pharmacies';
      case 'reminders':
        return 'reminders';
      case 'documents':
        return 'documents';
      default:
        return 'share';
    }
  }

  String _compact(Map<String, dynamic> r) =>
      r.entries.map((e) => '${e.key}: ${e.value}').join(' | ');

  Future<void> _logout() async {
    await _client.auth.signOut();
    await _client.auth.signInAnonymously();
    await _loadSession();
  }

  Future<void> _getOwnCopy() async {
    await launchUrlString(
      _payoneerUrl,
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final isAdmin =
        (_profile?['role'] ?? '').toString().toLowerCase() == 'admin';

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compactWidth = constraints.maxWidth < 500;

            // FIX: explicitly make the result a double.
            final cardWidth =
                ((constraints.maxWidth - (compactWidth ? 32 : 48)) / 4)
                    .toDouble();

            // FIX: explicitly make the result a double.
            final cardHeight =
                ((constraints.maxHeight.clamp(500, 1000) * 0.075).clamp(54, 76))
                    .toDouble();

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    const Icon(
                      Icons.health_and_safety,
                      color: Colors.teal,
                      size: 48,
                    ),
                    const Text(
                      'SANA',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: widget.language,
                      decoration: InputDecoration(
                        labelText: tr(
                          widget.language,
                          'language',
                        ),
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.language),
                      ),
                      items: _translations.keys
                          .map(
                            (code) => DropdownMenuItem(
                              value: code,
                              child: Text(code.toUpperCase()),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          widget.onLanguageChanged(value);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: _getOwnCopy,
                      icon: const Icon(Icons.copy),
                      label: Text(
                        tr(widget.language, 'get_copy'),
                      ),
                    ),
                    if (_isGuest)
                      Chip(
                        avatar: const Icon(Icons.person_outline),
                        label: Text(
                          tr(widget.language, 'guest_data'),
                        ),
                      )
                    else
                      Chip(
                        avatar: const Icon(Icons.verified_user),
                        label: Text(
                          tr(widget.language, 'active_user'),
                        ),
                      ),
                    if (_profile?['expiry_date'] != null &&
                        !_isGuest &&
                        _daysLeft(_profile!['expiry_date']) <= 20)
                      _buildExpiryBanner(),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        _smallCard(
                          cardWidth,
                          cardHeight,
                          'medications',
                          Icons.medication,
                          Colors.blue,
                        ),
                        _smallCard(
                          cardWidth,
                          cardHeight,
                          'doctors',
                          Icons.person,
                          Colors.green,
                        ),
                        _smallCard(
                          cardWidth,
                          cardHeight,
                          'pharmacies',
                          Icons.local_pharmacy,
                          Colors.orange,
                        ),
                        _smallCard(
                          cardWidth,
                          cardHeight,
                          'reminders',
                          Icons.alarm,
                          Colors.red,
                        ),
                        _smallCard(
                          cardWidth,
                          cardHeight,
                          'documents',
                          Icons.folder,
                          Colors.purple,
                        ),
                        _smallCard(
                          cardWidth,
                          cardHeight,
                          'share',
                          Icons.share,
                          Colors.teal,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _shareAll,
                            icon: const Icon(Icons.share),
                            label: Text(
                              tr(widget.language, 'share'),
                            ),
                          ),
                        ),
                        if (isAdmin) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AdminScreen(
                                      language: widget.language,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.admin_panel_settings,
                              ),
                              label: Text(
                                tr(widget.language, 'admin'),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _isGuest ? _openLogin : _logout,
                      icon: Icon(
                        _isGuest ? Icons.login : Icons.logout,
                      ),
                      label: Text(
                        _isGuest
                            ? tr(widget.language, 'login')
                            : tr(widget.language, 'logout'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _smallCard(
    double width,
    double height,
    String type,
    IconData icon,
    Color color,
  ) {
    return SizedBox(
      width: width.clamp(58, 120),
      height: height,
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 2,
        child: InkWell(
          onTap: () => _openCard(type),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: color,
                ),
                const SizedBox(height: 2),
                Text(
                  tr(widget.language, _titleKey(type)),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpiryBanner() {
    final days = _daysLeft(_profile!['expiry_date']);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      color: Colors.red,
      child: Text(
        days < 0 ? tr(widget.language, 'expired') : '⚠️ $days days',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  int _daysLeft(dynamic date) =>
      DateTime.parse(date.toString()).difference(DateTime.now()).inDays;

  Future<void> _openLogin() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => LoginScreen(
          language: widget.language,
          onLanguageChanged: widget.onLanguageChanged,
        ),
      ),
    );

    if (result == true) {
      await _loadSession();
    }
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.language,
    required this.onLanguageChanged,
  });

  final String language;
  final ValueChanged<String> onLanguageChanged;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _busy = false;

  Future<void> _login() async {
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      return;
    }

    setState(() => _busy = true);

    try {
      final client = Supabase.instance.client;

      await client.auth.signInWithPassword(
        email: _email.text.trim(),
        password: _password.text,
      );

      final user = client.auth.currentUser!;

      final profile =
          await client.from('users').select().eq('id', user.id).maybeSingle();

      final role = (profile?['role'] ?? '').toString().toLowerCase();

      final active = profile?['is_active'] == true;

      if (!mounted) return;

      if (role == 'admin') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => AdminScreen(
              language: widget.language,
            ),
          ),
          (_) => false,
        );
      } else {
        Navigator.pop(context, active);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          tr(widget.language, 'sign_in'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: tr(widget.language, 'email'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: InputDecoration(
                labelText: tr(widget.language, 'password'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _login,
              child: _busy
                  ? const CircularProgressIndicator()
                  : Text(
                      tr(widget.language, 'sign_in'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class RecordListScreen extends StatefulWidget {
  const RecordListScreen({
    super.key,
    required this.type,
    required this.language,
    required this.ownerId,
    required this.guestMode,
  });

  final String type;
  final String language;
  final String ownerId;
  final bool guestMode;

  @override
  State<RecordListScreen> createState() => _RecordListScreenState();
}

class _RecordListScreenState extends State<RecordListScreen> {
  final _client = Supabase.instance.client;

  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;

  String get _table => widget.type == 'reminders' ? 'medications' : widget.type;

  String get _scope => widget.guestMode ? 'guest_id' : 'user_id';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result =
          await _client.from(_table).select().eq(_scope, widget.ownerId);

      var rows = List<Map<String, dynamic>>.from(result);

      if (widget.type == 'reminders') {
        rows = rows
            .where(
              (r) => (r['reminder_time'] ?? '').toString().isNotEmpty,
            )
            .toList();
      }

      if (mounted) {
        setState(() => _rows = rows);
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _delete(Map<String, dynamic> row) async {
    final id = row['id'];

    if (id == null) return;

    await _client.from(_table).delete().eq('id', id).eq(_scope, widget.ownerId);

    await _load();
  }

  Future<void> _share(Map<String, dynamic> row) async {
    await SharePlus.instance.share(
      ShareParams(
        text: row.entries.map((e) => '${e.key}: ${e.value}').join('\n'),
      ),
    );
  }

  Future<void> _add() async {
    final values = await _showEditor();

    if (values == null) return;

    values[_scope] = widget.ownerId;

    // FIX:
    // The editor intentionally returns Map<String, String>.
    // Create a dynamic copy only for Supabase so integer/bool
    // fields can keep their correct database types.
    final insertValues = <String, dynamic>{...values};

    if (_table == 'medications') {
      insertValues['quantity'] = int.tryParse(
            insertValues['quantity']?.toString() ?? '',
          ) ??
          1;

      insertValues['description'] ??= '';
      insertValues['file_type'] ??= 'image';
      insertValues['is_active'] ??= true;
    } else if (_table == 'doctors') {
      insertValues['is_active'] ??= true;
    } else if (_table == 'pharmacies') {
      insertValues['phone'] ??= '';
      insertValues['is_active'] ??= true;
    } else if (_table == 'documents') {
      insertValues['file_type'] ??= 'file';
    } else if (_table == 'insurance_cards') {
      insertValues['provider_name'] ??= 'Insurance Card';
    }

    await _client.from(_table).insert(insertValues);

    await _load();
  }

  Future<Map<String, String>?> _showEditor() async {
    final controllers = <String, TextEditingController>{};

    final fields = switch (widget.type) {
      'medications' => [
          'name',
          'dosage',
          'quantity',
          'reminder_time',
          'description',
        ],
      'doctors' => [
          'name',
          'specialty',
          'phone',
          'email',
          'address',
        ],
      'pharmacies' => [
          'name',
          'phone',
          'address',
        ],
      'reminders' => [
          'name',
          'dosage',
          'reminder_time',
        ],
      'documents' => [
          'title',
          'category',
          'file_url',
        ],
      _ => [
          'provider_name',
          'front_image_url',
          'back_image_url',
        ],
    };

    for (final field in fields) {
      controllers[field] = TextEditingController();
    }

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          '${tr(widget.language, 'add')} '
          '${tr(widget.language, _titleKey(widget.type))}',
        ),
        content: SingleChildScrollView(
          child: Column(
            children: fields
                .map(
                  (field) => Padding(
                    padding: const EdgeInsets.only(
                      bottom: 8,
                    ),
                    child: TextField(
                      controller: controllers[field],
                      decoration: InputDecoration(
                        labelText: field,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              tr(widget.language, 'close'),
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(
                dialogContext,
                {
                  for (final e in controllers.entries)
                    e.key: e.value.text.trim(),
                },
              );
            },
            child: Text(
              tr(widget.language, 'save'),
            ),
          ),
        ],
      ),
    );

    for (final controller in controllers.values) {
      controller.dispose();
    }

    return result;
  }

  String _titleKey(String type) {
    switch (type) {
      case 'medications':
        return 'medications';
      case 'doctors':
        return 'doctors';
      case 'pharmacies':
        return 'pharmacies';
      case 'reminders':
        return 'reminders';
      case 'documents':
        return 'documents';
      default:
        return 'share';
    }
  }

  Future<void> _preview(Map<String, dynamic> row) async {
    final photo = row['photo_url'] ?? row['front_image_url'];

    final base64Photo = row['photo_base64'];
    final url = row['file_url'];

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          (row['name'] ?? row['title'] ?? row['provider_name'] ?? 'Record')
              .toString(),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (base64Photo != null && base64Photo.toString().isNotEmpty)
                Image.memory(
                  base64Decode(
                    base64Photo.toString(),
                  ),
                  height: 160,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              if (photo != null && photo.toString().isNotEmpty)
                Image.network(
                  photo.toString(),
                  height: 160,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              if (url != null && url.toString().isNotEmpty)
                ListTile(
                  title: Text(url.toString()),
                  trailing: const Icon(
                    Icons.open_in_new,
                  ),
                  onTap: () => launchUrlString(url.toString()),
                ),
              ...row.entries.map(
                (e) => Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${e.key}: ${e.value}',
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              tr(widget.language, 'close'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          tr(
            widget.language,
            _titleKey(widget.type),
          ),
        ),
        actions: [
          IconButton(
            onPressed: _add,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _rows.isEmpty
              ? Center(
                  child: Text(
                    tr(
                      widget.language,
                      'no_records',
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: _rows.length,
                  itemBuilder: (context, index) {
                    final row = _rows[index];

                    final title = (row['name'] ??
                            row['title'] ??
                            row['provider_name'] ??
                            'Record')
                        .toString();

                    final subtitle = _subtitle(row);

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      child: ListTile(
                        title: Text(title),
                        subtitle: Text(subtitle),
                        onTap: () => _preview(row),
                        trailing: PopupMenuButton<String>(
                          onSelected: (action) async {
                            if (action == 'view') {
                              await _preview(row);
                            }

                            if (action == 'share') {
                              await _share(row);
                            }

                            if (action == 'delete') {
                              await _delete(row);
                            }
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'view',
                              child: Text(
                                tr(
                                  widget.language,
                                  'view',
                                ),
                              ),
                            ),
                            PopupMenuItem(
                              value: 'share',
                              child: Text(
                                tr(
                                  widget.language,
                                  'share',
                                ),
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text(
                                tr(
                                  widget.language,
                                  'delete',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  String _subtitle(Map<String, dynamic> row) {
    if (widget.type == 'medications') {
      return '${row['dosage'] ?? ''}'
          '  ${row['reminder_time'] ?? ''}';
    }

    if (widget.type == 'doctors') {
      return '${row['specialty'] ?? ''}'
          '  ${row['phone'] ?? ''}';
    }

    if (widget.type == 'pharmacies') {
      return '${row['phone'] ?? ''}'
          '  ${row['address'] ?? ''}';
    }

    if (widget.type == 'documents') {
      return '${row['category'] ?? ''}'
          '  ${row['file_type'] ?? ''}';
    }

    return '${row['provider_name'] ?? ''}';
  }
}

class AdminScreen extends StatefulWidget {
  const AdminScreen({
    super.key,
    required this.language,
  });

  final String language;

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _client = Supabase.instance.client;

  List<Map<String, dynamic>> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final result = await _client.rpc('admin_list_users');

      if (mounted) {
        setState(() {
          _users = List<Map<String, dynamic>>.from(result);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _setActive(
    Map<String, dynamic> user,
    bool active,
  ) async {
    final id = user['id'];

    try {
      await _client.rpc(
        'admin_set_user_active',
        params: {
          'target_user': id,
          'activate': active,
        },
      );
    } catch (_) {
      await _client.from('profiles').update({'is_active': active}).eq('id', id);
    }

    await _loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          tr(
            widget.language,
            'admin_panel',
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  DataColumn(
                    label: Text(
                      tr(
                        widget.language,
                        'name',
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      tr(
                        widget.language,
                        'email',
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      tr(
                        widget.language,
                        'phone',
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      tr(
                        widget.language,
                        'role',
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      tr(
                        widget.language,
                        'status',
                      ),
                    ),
                  ),
                  const DataColumn(
                    label: Text(''),
                  ),
                ],
                rows: _users.map((u) {
                  final active = u['is_active'] == true;
                  final role = (u['role'] ?? 'user').toString();

                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          (u['name'] ?? 'Guest').toString(),
                        ),
                      ),
                      DataCell(
                        Text(
                          (u['email'] ?? '').toString(),
                        ),
                      ),
                      DataCell(
                        Text(
                          (u['phone'] ?? 'N/A').toString(),
                        ),
                      ),
                      DataCell(
                        Text(role),
                      ),
                      DataCell(
                        Text(
                          active
                              ? tr(
                                  widget.language,
                                  'active_user',
                                )
                              : tr(
                                  widget.language,
                                  'inactive_guest',
                                ),
                        ),
                      ),
                      DataCell(
                        ElevatedButton(
                          onPressed: role.toLowerCase() == 'admin'
                              ? null
                              : () => _setActive(
                                    u,
                                    !active,
                                  ),
                          child: Text(
                            active
                                ? tr(
                                    widget.language,
                                    'deactivate',
                                  )
                                : tr(
                                    widget.language,
                                    'activate',
                                  ),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
    );
  }
}
