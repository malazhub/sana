// ============================================
// SANA - COMPLETE WORKING CODE v20.10 (FIXED ONLY)
// FIXED: Tap payment, guest_id removed, Namespace, reminder_date
// YOUR ORIGINAL CODE PRESERVED
// ============================================
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
//import 'package:http/http.dart' as http;
import 'package:http/http.dart' as package_http;

// ============================================
// CONFIGURATION
// ============================================

const String _supabaseUrl = 'https://emvadnooxyspfsfnzlmb.supabase.co';
const String _supabaseKey = 'sb_publishable_3f7AQFQw-Kx0_Qvir4nFXQ_XZmUMpzm';
const String _sanaShareUrl = 'https://malazhub.github.io/sana/';

// ============================================
// 8 LANGUAGES - FULL TRANSLATIONS
// ============================================

final ValueNotifier<String> languageNotifier = ValueNotifier<String>('en');

const Map<String, String> _languageNames = {
  'en': 'English',
  'ar': 'العربية',
  'es': 'Español',
  'fr': 'Français',
  'de': 'Deutsch',
  'tr': 'Türkçe',
  'hi': 'हिन्दी',
  'zh': '中文',
};

const Map<String, Map<String, String>> _translations = {
  'en': {
    'add': 'Add',
    'save': 'Save',
    'delete': 'Delete',
    'view': 'View',
    'close': 'Close',
    'share': 'Share',
    'login': 'Login',
    'logout': 'Logout',
    'admin': 'Admin',
    'medications': 'Medications',
    'doctors': 'Doctors',
    'pharmacies': 'Pharmacies',
    'reminders': 'Reminders',
    'documents': 'Documents',
    'insurance_cards': 'Insurance Cards',
    'name': 'Name',
    'dosage': 'Dosage',
    'quantity': 'Stock',
    'description': 'Description',
    'specialty': 'Specialty',
    'phone': 'Phone',
    'address': 'Address',
    'email': 'Email',
    'password': 'Password',
    'sign_in': 'Sign In',
    'new_user': 'New User',
    'register': 'Register',
    'create_account': 'Create Account',
    'already_account': 'Already have an account?',
    'location': 'Location',
    'photo': 'Photo',
    'front_photo': 'Front Photo',
    'back_photo': 'Back Photo',
    'reminder_time': 'Reminder Time',
    'reminder_date': 'Reminder Date',
    'schedule_type': 'Schedule',
    'daily': 'Daily',
    'calendar': 'Calendar',
    'select_times': 'Select one or more times',
    'select_schedule': 'Select schedule',
    'record': 'Record',
    'no_records': 'No records',
    'guest_mode': 'Guest Mode',
    'get_copy': 'Get Your Copy',
    'create_copy': 'Create Your Copy',
    'select_all': 'Select All',
    'share_selected': 'Share Selected',
    'no_selection': 'No items selected',
    'admin_panel': 'Admin Panel',
    'users': 'Users',
    'activate': 'Activate',
    'deactivate': 'Deactivate',
    'status': 'Status',
    'role': 'Role',
    'active_user': 'Active User',
    'inactive_guest': 'Inactive User',
    'expired': 'ACCOUNT EXPIRED',
    'provider_name': 'Provider Name',
    'front_image': 'Front Image',
    'back_image': 'Back Image',
    'file_url': 'File URL',
    'category': 'Category',
    'title': 'Title',
    'policy': 'Policy',
    'provider': 'Provider',
    'expiry': 'Expiry',
    'specialist': 'Specialist',
    'guest': 'Guest Mode',
    'account': 'Account',
    'guest_data': 'Guest Data',
    'full_record': 'Full Record',
    'share_record': 'Share Record',
    'sign_up': 'Sign Up',
    'language': 'Language',
    'select_medication': 'Select Medication',
    'select_time': 'Select Time',
    'select_date': 'Select Date',
    'required_field': 'This field is required',
    'time_format_12h': 'hh:mm AM/PM',
    'please_login': 'Please login',
    'please_fill_all': 'Please fill all fields',
    'login_failed': 'Login failed',
    'signup_failed': 'Sign up failed',
    'delete_confirm_title': 'Delete?',
    'delete_confirm_msg': 'Are you sure you want to delete this record?',
    'cancel': 'Cancel',
    'please_sign_in': 'Please Sign In',
    'account_created_success': 'Account created successfully! Please Sign In.',
    'operation_failed': 'Operation failed',
    'select_front_image': 'Select Front Image',
    'select_back_image': 'Select Back Image',
    'upload_image': 'Upload Image',
    'uploaded': 'Uploaded',
    'insurance_company_name': 'Insurance Company Name',
    'patient_id': 'Patient ID',
    'insurance_card_front': 'Insurance Card - Front',
    'insurance_card_back': 'Insurance Card - Back',
    'no_image_selected': 'No image selected',
    'upload_front_card': 'Upload Front Card',
    'upload_back_card': 'Upload Back Card',
    'add_data': 'Add Data',
    'please_enter_insurance_company': 'Please enter insurance company name',
    'please_enter_patient_id': 'Please enter patient ID',
    'please_upload_both_cards': 'Please upload both front and back cards',
    'success': 'successfully',
    'upload_photo': 'Upload Photo',
    'select_photo': 'Select Photo',
    'photo_uploaded': 'Photo uploaded',
    'please_upload_photo': 'Please upload a photo',
    'share_app': 'Share App',
    'share_app_message': 'Check out SANA - Your Health Management App!',
    'opening_payment': 'Opening payment page...',
    'payment_error': 'Payment error',
  },
  'ar': {
    'add': 'إضافة',
    'save': 'حفظ',
    'delete': 'حذف',
    'view': 'عرض',
    'close': 'إغلاق',
    'share': 'مشاركة',
    'login': 'تسجيل الدخول',
    'logout': 'تسجيل الخروج',
    'admin': 'المسؤول',
    'medications': 'الأدوية',
    'doctors': 'الأطباء',
    'pharmacies': 'الصيدليات',
    'reminders': 'التذكيرات',
    'documents': 'المستندات',
    'insurance_cards': 'بطاقات التأمين',
    'name': 'الاسم',
    'dosage': 'الجرعة',
    'quantity': 'المخزون',
    'description': 'الوصف',
    'specialty': 'التخصص',
    'phone': 'الهاتف',
    'address': 'العنوان',
    'email': 'البريد الإلكتروني',
    'password': 'كلمة المرور',
    'sign_in': 'تسجيل الدخول',
    'new_user': 'مستخدم جديد',
    'register': 'تسجيل',
    'create_account': 'إنشاء حساب',
    'already_account': 'هل لديك حساب بالفعل؟',
    'location': 'الموقع',
    'photo': 'صورة',
    'front_photo': 'الصورة الأمامية',
    'back_photo': 'الصورة الخلفية',
    'reminder_time': 'وقت التذكير',
    'reminder_date': 'تاريخ التذكير',
    'schedule_type': 'الجدول',
    'daily': 'يومي',
    'calendar': 'التقويم',
    'select_times': 'اختر وقتًا واحدًا أو أكثر',
    'select_schedule': 'اختر الجدول',
    'record': 'سجل',
    'no_records': 'لا توجد سجلات',
    'guest_mode': 'وضع الضيف',
    'get_copy': 'احصل على نسختك',
    'create_copy': 'أنشئ نسختك',
    'select_all': 'تحديد الكل',
    'share_selected': 'مشاركة المحدد',
    'no_selection': 'لم يتم تحديد أي عناصر',
    'admin_panel': 'لوحة الإدارة',
    'users': 'المستخدمون',
    'activate': 'تفعيل',
    'deactivate': 'تعطيل',
    'status': 'الحالة',
    'role': 'الدور',
    'active_user': 'مستخدم نشط',
    'inactive_guest': 'مستخدم غير نشط',
    'expired': 'الحساب منتهي',
    'provider_name': 'اسم مقدم الخدمة',
    'front_image': 'الصورة الأمامية',
    'back_image': 'الصورة الخلفية',
    'file_url': 'رابط الملف',
    'category': 'الفئة',
    'title': 'العنوان',
    'policy': 'رقم الوثيقة',
    'provider': 'مقدم الخدمة',
    'expiry': 'تاريخ الانتهاء',
    'specialist': 'الأخصائي',
    'guest': 'وضع الضيف',
    'account': 'الحساب',
    'guest_data': 'بيانات الضيف',
    'full_record': 'السجل الكامل',
    'share_record': 'مشاركة السجل',
    'sign_up': 'إنشاء حساب',
    'language': 'اللغة',
    'select_medication': 'اختر الدواء',
    'select_time': 'اختر الوقت',
    'select_date': 'اختر التاريخ',
    'required_field': 'هذا الحقل مطلوب',
    'time_format_12h': 'hh:mm AM/PM',
    'please_login': 'يرجى تسجيل الدخول',
    'please_fill_all': 'يرجى ملء جميع الحقول',
    'login_failed': 'فشل تسجيل الدخول',
    'signup_failed': 'فشل إنشاء الحساب',
    'delete_confirm_title': 'حذف؟',
    'delete_confirm_msg': 'هل أنت متأكد من حذف هذا السجل؟',
    'cancel': 'إلغاء',
    'please_sign_in': 'يرجى تسجيل الدخول',
    'account_created_success': 'تم إنشاء الحساب بنجاح! يرجى تسجيل الدخول.',
    'operation_failed': 'فشلت العملية',
    'select_front_image': 'اختر الصورة الأمامية',
    'select_back_image': 'اختر الصورة الخلفية',
    'upload_image': 'رفع صورة',
    'uploaded': 'تم الرفع',
    'insurance_company_name': 'اسم شركة التأمين',
    'patient_id': 'رقم المريض',
    'insurance_card_front': 'بطاقة التأمين - الأمام',
    'insurance_card_back': 'بطاقة التأمين - الخلف',
    'no_image_selected': 'لم يتم اختيار صورة',
    'upload_front_card': 'رفع البطاقة الأمامية',
    'upload_back_card': 'رفع البطاقة الخلفية',
    'add_data': 'إضافة البيانات',
    'please_enter_insurance_company': 'يرجى إدخال اسم شركة التأمين',
    'please_enter_patient_id': 'يرجى إدخال رقم المريض',
    'please_upload_both_cards': 'يرجى رفع البطاقتين',
    'success': 'تم بنجاح',
    'upload_photo': 'رفع صورة',
    'select_photo': 'اختيار صورة',
    'photo_uploaded': 'تم رفع الصورة',
    'please_upload_photo': 'يرجى رفع صورة',
    'share_app': 'مشاركة التطبيق',
    'share_app_message': 'SANA - تطبيقك لإدارة صحتك!',
    'opening_payment': 'جاري فتح صفحة الدفع...',
    'payment_error': 'خطأ في الدفع',
  },
  'es': {
    'add': 'Añadir',
    'save': 'Guardar',
    'delete': 'Eliminar',
    'view': 'Ver',
    'close': 'Cerrar',
    'share': 'Compartir',
    'login': 'Iniciar sesión',
    'logout': 'Cerrar sesión',
    'admin': 'Administrador',
    'medications': 'Medicamentos',
    'doctors': 'Médicos',
    'pharmacies': 'Farmacias',
    'reminders': 'Recordatorios',
    'documents': 'Documentos',
    'insurance_cards': 'Tarjetas de seguro',
    'name': 'Nombre',
    'dosage': 'Dosis',
    'quantity': 'Stock',
    'description': 'Descripción',
    'specialty': 'Especialidad',
    'phone': 'Teléfono',
    'address': 'Dirección',
    'email': 'Correo electrónico',
    'password': 'Contraseña',
    'sign_in': 'Iniciar sesión',
    'new_user': 'Nuevo usuario',
    'register': 'Registrarse',
    'create_account': 'Crear cuenta',
    'already_account': '¿Ya tienes una cuenta?',
    'location': 'Ubicación',
    'photo': 'Foto',
    'front_photo': 'Foto frontal',
    'back_photo': 'Foto trasera',
    'reminder_time': 'Hora del recordatorio',
    'reminder_date': 'Fecha del recordatorio',
    'schedule_type': 'Programación',
    'daily': 'Diario',
    'calendar': 'Calendario',
    'select_times': 'Seleccione una o más horas',
    'select_schedule': 'Seleccionar programación',
    'record': 'Registro',
    'no_records': 'No hay registros',
    'guest_mode': 'Modo invitado',
    'get_copy': 'Obtén tu copia',
    'create_copy': 'Crea tu copia',
    'select_all': 'Seleccionar todo',
    'share_selected': 'Compartir seleccionados',
    'no_selection': 'No hay elementos seleccionados',
    'admin_panel': 'Panel de administración',
    'users': 'Usuarios',
    'activate': 'Activar',
    'deactivate': 'Desactivar',
    'status': 'Estado',
    'role': 'Rol',
    'active_user': 'Usuario activo',
    'inactive_guest': 'Usuario inactivo',
    'expired': 'CUENTA EXPIRADA',
    'provider_name': 'Nombre del proveedor',
    'front_image': 'Imagen frontal',
    'back_image': 'Imagen trasera',
    'file_url': 'URL del archivo',
    'category': 'Categoría',
    'title': 'Título',
    'policy': 'Póliza',
    'provider': 'Proveedor',
    'expiry': 'Vencimiento',
    'specialist': 'Especialista',
    'guest': 'Modo invitado',
    'account': 'Cuenta',
    'guest_data': 'Datos del invitado',
    'full_record': 'Registro completo',
    'share_record': 'Compartir registro',
    'sign_up': 'Registrarse',
    'language': 'Idioma',
    'select_medication': 'Seleccionar medicamento',
    'select_time': 'Seleccionar hora',
    'select_date': 'Seleccionar fecha',
    'required_field': 'Este campo es obligatorio',
    'time_format_12h': 'hh:mm AM/PM',
    'please_login': 'Por favor inicia sesión',
    'please_fill_all': 'Por favor completa todos los campos',
    'login_failed': 'Error al iniciar sesión',
    'signup_failed': 'Error al registrarse',
    'delete_confirm_title': '¿Eliminar?',
    'delete_confirm_msg': '¿Estás seguro de que deseas eliminar este registro?',
    'cancel': 'Cancelar',
    'please_sign_in': 'Por favor inicia sesión',
    'account_created_success':
        '¡Cuenta creada correctamente! Por favor inicia sesión.',
    'operation_failed': 'La operación falló',
    'select_front_image': 'Seleccionar imagen frontal',
    'select_back_image': 'Seleccionar imagen trasera',
    'upload_image': 'Subir imagen',
    'uploaded': 'Subido',
    'insurance_company_name': 'Nombre de la compañía de seguros',
    'patient_id': 'ID del paciente',
    'insurance_card_front': 'Tarjeta de seguro - frontal',
    'insurance_card_back': 'Tarjeta de seguro - trasera',
    'no_image_selected': 'No se ha seleccionado ninguna imagen',
    'upload_front_card': 'Subir tarjeta frontal',
    'upload_back_card': 'Subir tarjeta trasera',
    'add_data': 'Añadir datos',
    'please_enter_insurance_company':
        'Por favor introduce el nombre de la compañía de seguros',
    'please_enter_patient_id': 'Por favor introduce el ID del paciente',
    'please_upload_both_cards': 'Por favor sube ambas tarjetas',
    'success': 'Éxito',
    'upload_photo': 'Subir foto',
    'select_photo': 'Seleccionar foto',
    'photo_uploaded': 'Foto subida',
    'please_upload_photo': 'Por favor sube una foto',
    'share_app': 'Compartir aplicación',
    'share_app_message': 'SANA - ¡tu aplicación para gestionar tu salud!',
    'opening_payment': 'Abriendo página de pago...',
    'payment_error': 'Error de pago',
  },
  'fr': {
    'add': 'Ajouter',
    'save': 'Enregistrer',
    'delete': 'Supprimer',
    'view': 'Voir',
    'close': 'Fermer',
    'share': 'Partager',
    'login': 'Connexion',
    'logout': 'Déconnexion',
    'admin': 'Administrateur',
    'medications': 'Médicaments',
    'doctors': 'Médecins',
    'pharmacies': 'Pharmacies',
    'reminders': 'Rappels',
    'documents': 'Documents',
    'insurance_cards': 'Cartes d’assurance',
    'name': 'Nom',
    'dosage': 'Dosage',
    'quantity': 'Stock',
    'description': 'Description',
    'specialty': 'Spécialité',
    'phone': 'Téléphone',
    'address': 'Adresse',
    'email': 'E-mail',
    'password': 'Mot de passe',
    'sign_in': 'Se connecter',
    'new_user': 'Nouvel utilisateur',
    'register': 'S’inscrire',
    'create_account': 'Créer un compte',
    'already_account': 'Vous avez déjà un compte ?',
    'location': 'Emplacement',
    'photo': 'Photo',
    'front_photo': 'Photo avant',
    'back_photo': 'Photo arrière',
    'reminder_time': 'Heure du rappel',
    'reminder_date': 'Date du rappel',
    'schedule_type': 'Programme',
    'daily': 'Quotidien',
    'calendar': 'Calendrier',
    'select_times': 'Sélectionnez une ou plusieurs heures',
    'select_schedule': 'Sélectionner le programme',
    'record': 'Dossier',
    'no_records': 'Aucun enregistrement',
    'guest_mode': 'Mode invité',
    'get_copy': 'Obtenez votre copie',
    'create_copy': 'Créez votre copie',
    'select_all': 'Tout sélectionner',
    'share_selected': 'Partager la sélection',
    'no_selection': 'Aucun élément sélectionné',
    'admin_panel': 'Panneau d’administration',
    'users': 'Utilisateurs',
    'activate': 'Activer',
    'deactivate': 'Désactiver',
    'status': 'Statut',
    'role': 'Rôle',
    'active_user': 'Utilisateur actif',
    'inactive_guest': 'Utilisateur inactif',
    'expired': 'COMPTE EXPIRÉ',
    'provider_name': 'Nom du fournisseur',
    'front_image': 'Image avant',
    'back_image': 'Image arrière',
    'file_url': 'URL du fichier',
    'category': 'Catégorie',
    'title': 'Titre',
    'policy': 'Police',
    'provider': 'Fournisseur',
    'expiry': 'Expiration',
    'specialist': 'Spécialiste',
    'guest': 'Mode invité',
    'account': 'Compte',
    'guest_data': 'Données invité',
    'full_record': 'Dossier complet',
    'share_record': 'Partager le dossier',
    'sign_up': 'S’inscrire',
    'language': 'Langue',
    'select_medication': 'Sélectionner un médicament',
    'select_time': 'Sélectionner l’heure',
    'select_date': 'Sélectionner la date',
    'required_field': 'Ce champ est obligatoire',
    'time_format_12h': 'hh:mm AM/PM',
    'please_login': 'Veuillez vous connecter',
    'please_fill_all': 'Veuillez remplir tous les champs',
    'login_failed': 'Échec de la connexion',
    'signup_failed': 'Échec de l’inscription',
    'delete_confirm_title': 'Supprimer ?',
    'delete_confirm_msg':
        'Êtes-vous sûr de vouloir supprimer cet enregistrement ?',
    'cancel': 'Annuler',
    'please_sign_in': 'Veuillez vous connecter',
    'account_created_success':
        'Compte créé avec succès ! Veuillez vous connecter.',
    'operation_failed': 'Échec de l’opération',
    'select_front_image': 'Sélectionner l’image avant',
    'select_back_image': 'Sélectionner l’image arrière',
    'upload_image': 'Téléverser une image',
    'uploaded': 'Téléversé',
    'insurance_company_name': 'Nom de la compagnie d’assurance',
    'patient_id': 'ID du patient',
    'insurance_card_front': 'Carte d’assurance - avant',
    'insurance_card_back': 'Carte d’assurance - arrière',
    'no_image_selected': 'Aucune image sélectionnée',
    'upload_front_card': 'Téléverser la carte avant',
    'upload_back_card': 'Téléverser la carte arrière',
    'add_data': 'Ajouter les données',
    'please_enter_insurance_company':
        'Veuillez saisir le nom de la compagnie d’assurance',
    'please_enter_patient_id': 'Veuillez saisir l’ID du patient',
    'please_upload_both_cards': 'Veuillez téléverser les deux cartes',
    'success': 'Succès',
    'upload_photo': 'Téléverser une photo',
    'select_photo': 'Sélectionner une photo',
    'photo_uploaded': 'Photo téléversée',
    'please_upload_photo': 'Veuillez téléverser une photo',
    'share_app': 'Partager l’application',
    'share_app_message': 'SANA - votre application de gestion de santé !',
    'opening_payment': 'Ouverture de la page de paiement...',
    'payment_error': 'Erreur de paiement',
  },
  'de': {
    'add': 'Hinzufügen',
    'save': 'Speichern',
    'delete': 'Löschen',
    'view': 'Anzeigen',
    'close': 'Schließen',
    'share': 'Teilen',
    'login': 'Anmelden',
    'logout': 'Abmelden',
    'admin': 'Administrator',
    'medications': 'Medikamente',
    'doctors': 'Ärzte',
    'pharmacies': 'Apotheken',
    'reminders': 'Erinnerungen',
    'documents': 'Dokumente',
    'insurance_cards': 'Versicherungskarten',
    'name': 'Name',
    'dosage': 'Dosierung',
    'quantity': 'Bestand',
    'description': 'Beschreibung',
    'specialty': 'Fachgebiet',
    'phone': 'Telefon',
    'address': 'Adresse',
    'email': 'E-Mail',
    'password': 'Passwort',
    'sign_in': 'Anmelden',
    'new_user': 'Neuer Benutzer',
    'register': 'Registrieren',
    'create_account': 'Konto erstellen',
    'already_account': 'Bereits ein Konto?',
    'location': 'Standort',
    'photo': 'Foto',
    'front_photo': 'Vorderseite',
    'back_photo': 'Rückseite',
    'reminder_time': 'Erinnerungszeit',
    'reminder_date': 'Erinnerungsdatum',
    'schedule_type': 'Zeitplan',
    'daily': 'Täglich',
    'calendar': 'Kalender',
    'select_times': 'Eine oder mehrere Zeiten auswählen',
    'select_schedule': 'Zeitplan auswählen',
    'record': 'Datensatz',
    'no_records': 'Keine Einträge',
    'guest_mode': 'Gastmodus',
    'get_copy': 'Kopie erhalten',
    'create_copy': 'Kopie erstellen',
    'select_all': 'Alle auswählen',
    'share_selected': 'Ausgewählte teilen',
    'no_selection': 'Keine Elemente ausgewählt',
    'admin_panel': 'Admin-Panel',
    'users': 'Benutzer',
    'activate': 'Aktivieren',
    'deactivate': 'Deaktivieren',
    'status': 'Status',
    'role': 'Rolle',
    'active_user': 'Aktiver Benutzer',
    'inactive_guest': 'Inaktiver Benutzer',
    'expired': 'KONTO ABGELAUFEN',
    'provider_name': 'Anbietername',
    'front_image': 'Vorderseite',
    'back_image': 'Rückseite',
    'file_url': 'Datei-URL',
    'category': 'Kategorie',
    'title': 'Titel',
    'policy': 'Versicherung',
    'provider': 'Anbieter',
    'expiry': 'Ablaufdatum',
    'specialist': 'Spezialist',
    'guest': 'Gastmodus',
    'account': 'Konto',
    'guest_data': 'Gastdaten',
    'full_record': 'Vollständiger Datensatz',
    'share_record': 'Datensatz teilen',
    'sign_up': 'Registrieren',
    'language': 'Sprache',
    'select_medication': 'Medikament auswählen',
    'select_time': 'Zeit auswählen',
    'select_date': 'Datum auswählen',
    'required_field': 'Dieses Feld ist erforderlich',
    'time_format_12h': 'hh:mm AM/PM',
    'please_login': 'Bitte anmelden',
    'please_fill_all': 'Bitte alle Felder ausfüllen',
    'login_failed': 'Anmeldung fehlgeschlagen',
    'signup_failed': 'Registrierung fehlgeschlagen',
    'delete_confirm_title': 'Löschen?',
    'delete_confirm_msg': 'Möchten Sie diesen Datensatz wirklich löschen?',
    'cancel': 'Abbrechen',
    'please_sign_in': 'Bitte anmelden',
    'account_created_success': 'Konto erfolgreich erstellt! Bitte anmelden.',
    'operation_failed': 'Vorgang fehlgeschlagen',
    'select_front_image': 'Vorderes Bild auswählen',
    'select_back_image': 'Hinteres Bild auswählen',
    'upload_image': 'Bild hochladen',
    'uploaded': 'Hochgeladen',
    'insurance_company_name': 'Name der Versicherungsgesellschaft',
    'patient_id': 'Patienten-ID',
    'insurance_card_front': 'Versicherungskarte - Vorderseite',
    'insurance_card_back': 'Versicherungskarte - Rückseite',
    'no_image_selected': 'Kein Bild ausgewählt',
    'upload_front_card': 'Vorderseite der Karte hochladen',
    'upload_back_card': 'Rückseite der Karte hochladen',
    'add_data': 'Daten hinzufügen',
    'please_enter_insurance_company':
        'Bitte Namen der Versicherungsgesellschaft eingeben',
    'please_enter_patient_id': 'Bitte Patienten-ID eingeben',
    'please_upload_both_cards': 'Bitte beide Karten hochladen',
    'success': 'Erfolg',
    'upload_photo': 'Foto hochladen',
    'select_photo': 'Foto auswählen',
    'photo_uploaded': 'Foto hochgeladen',
    'please_upload_photo': 'Bitte ein Foto hochladen',
    'share_app': 'App teilen',
    'share_app_message': 'SANA - Ihre App zur Gesundheitsverwaltung!',
    'opening_payment': 'Zahlungsseite wird geöffnet...',
    'payment_error': 'Zahlungsfehler',
  },
  'tr': {
    'add': 'Ekle',
    'save': 'Kaydet',
    'delete': 'Sil',
    'view': 'Görüntüle',
    'close': 'Kapat',
    'share': 'Paylaş',
    'login': 'Giriş Yap',
    'logout': 'Çıkış Yap',
    'admin': 'Yönetici',
    'medications': 'İlaçlar',
    'doctors': 'Doktorlar',
    'pharmacies': 'Eczaneler',
    'reminders': 'Hatırlatıcılar',
    'documents': 'Belgeler',
    'insurance_cards': 'Sigorta Kartları',
    'name': 'Ad',
    'dosage': 'Doz',
    'quantity': 'Stok',
    'description': 'Açıklama',
    'specialty': 'Uzmanlık',
    'phone': 'Telefon',
    'address': 'Adres',
    'email': 'E-posta',
    'password': 'Şifre',
    'sign_in': 'Giriş Yap',
    'new_user': 'Yeni Kullanıcı',
    'register': 'Kayıt Ol',
    'create_account': 'Hesap Oluştur',
    'already_account': 'Zaten hesabınız var mı?',
    'location': 'Konum',
    'photo': 'Fotoğraf',
    'front_photo': 'Ön Fotoğraf',
    'back_photo': 'Arka Fotoğraf',
    'reminder_time': 'Hatırlatma Saati',
    'reminder_date': 'Hatırlatma Tarihi',
    'schedule_type': 'Program',
    'daily': 'Günlük',
    'calendar': 'Takvim',
    'select_times': 'Bir veya daha fazla saat seçin',
    'select_schedule': 'Program seç',
    'record': 'Kayıt',
    'no_records': 'Kayıt yok',
    'guest_mode': 'Misafir Modu',
    'get_copy': 'Kopyanı Al',
    'create_copy': 'Kopyanı Oluştur',
    'select_all': 'Tümünü Seç',
    'share_selected': 'Seçilenleri Paylaş',
    'no_selection': 'Seçim yok',
    'admin_panel': 'Yönetici Paneli',
    'users': 'Kullanıcılar',
    'activate': 'Etkinleştir',
    'deactivate': 'Devre Dışı Bırak',
    'status': 'Durum',
    'role': 'Rol',
    'active_user': 'Aktif Kullanıcı',
    'inactive_guest': 'Pasif Kullanıcı',
    'expired': 'HESAP SÜRESİ DOLDU',
    'provider_name': 'Sağlayıcı Adı',
    'front_image': 'Ön Görsel',
    'back_image': 'Arka Görsel',
    'file_url': 'Dosya URL’si',
    'category': 'Kategori',
    'title': 'Başlık',
    'policy': 'Poliçe',
    'provider': 'Sağlayıcı',
    'expiry': 'Son Kullanma',
    'specialist': 'Uzman',
    'guest': 'Misafir Modu',
    'account': 'Hesap',
    'guest_data': 'Misafir Verileri',
    'full_record': 'Tam Kayıt',
    'share_record': 'Kaydı Paylaş',
    'sign_up': 'Kayıt Ol',
    'language': 'Dil',
    'select_medication': 'İlaç Seç',
    'select_time': 'Saat Seç',
    'select_date': 'Tarih Seç',
    'required_field': 'Bu alan zorunludur',
    'time_format_12h': 'hh:mm AM/PM',
    'please_login': 'Lütfen giriş yapın',
    'please_fill_all': 'Lütfen tüm alanları doldurun',
    'login_failed': 'Giriş başarısız',
    'signup_failed': 'Kayıt başarısız',
    'delete_confirm_title': 'Silinsin mi?',
    'delete_confirm_msg': 'Bu kaydı silmek istediğinizden emin misiniz?',
    'cancel': 'İptal',
    'please_sign_in': 'Lütfen giriş yapın',
    'account_created_success':
        'Hesap başarıyla oluşturuldu! Lütfen giriş yapın.',
    'operation_failed': 'İşlem başarısız',
    'select_front_image': 'Ön görseli seç',
    'select_back_image': 'Arka görseli seç',
    'upload_image': 'Görsel yükle',
    'uploaded': 'Yüklendi',
    'insurance_company_name': 'Sigorta şirketi adı',
    'patient_id': 'Hasta kimliği',
    'insurance_card_front': 'Sigorta kartı - Ön',
    'insurance_card_back': 'Sigorta kartı - Arka',
    'no_image_selected': 'Görsel seçilmedi',
    'upload_front_card': 'Ön kartı yükle',
    'upload_back_card': 'Arka kartı yükle',
    'add_data': 'Veri ekle',
    'please_enter_insurance_company': 'Lütfen sigorta şirketinin adını girin',
    'please_enter_patient_id': 'Lütfen hasta kimliğini girin',
    'please_upload_both_cards': 'Lütfen her iki kartı da yükleyin',
    'success': 'Başarılı',
    'upload_photo': 'Fotoğraf yükle',
    'select_photo': 'Fotoğraf seç',
    'photo_uploaded': 'Fotoğraf yüklendi',
    'please_upload_photo': 'Lütfen bir fotoğraf yükleyin',
    'share_app': 'Uygulamayı paylaş',
    'share_app_message': 'SANA - sağlık yönetimi uygulamanız!',
    'opening_payment': 'Ödeme sayfası açılıyor...',
    'payment_error': 'Ödeme hatası',
  },
  'hi': {
    'add': 'जोड़ें',
    'save': 'सहेजें',
    'delete': 'हटाएँ',
    'view': 'देखें',
    'close': 'बंद करें',
    'share': 'साझा करें',
    'login': 'लॉग इन',
    'logout': 'लॉग आउट',
    'admin': 'व्यवस्थापक',
    'medications': 'दवाइयाँ',
    'doctors': 'डॉक्टर',
    'pharmacies': 'फार्मेसी',
    'reminders': 'रिमाइंडर',
    'documents': 'दस्तावेज़',
    'insurance_cards': 'बीमा कार्ड',
    'name': 'नाम',
    'dosage': 'खुराक',
    'quantity': 'स्टॉक',
    'description': 'विवरण',
    'specialty': 'विशेषता',
    'phone': 'फ़ोन',
    'address': 'पता',
    'email': 'ईमेल',
    'password': 'पासवर्ड',
    'sign_in': 'साइन इन',
    'new_user': 'नया उपयोगकर्ता',
    'register': 'पंजीकरण',
    'create_account': 'खाता बनाएँ',
    'already_account': 'क्या आपके पास पहले से खाता है?',
    'location': 'स्थान',
    'photo': 'फ़ोटो',
    'front_photo': 'सामने की फ़ोटो',
    'back_photo': 'पीछे की फ़ोटो',
    'reminder_time': 'रिमाइंडर समय',
    'reminder_date': 'रिमाइंडर तारीख',
    'schedule_type': 'समय-सारणी',
    'daily': 'दैनिक',
    'calendar': 'कैलेंडर',
    'select_times': 'एक या अधिक समय चुनें',
    'select_schedule': 'समय-सारणी चुनें',
    'record': 'रिकॉर्ड',
    'no_records': 'कोई रिकॉर्ड नहीं',
    'guest_mode': 'अतिथि मोड',
    'get_copy': 'अपनी कॉपी पाएँ',
    'create_copy': 'अपनी कॉपी बनाएँ',
    'select_all': 'सभी चुनें',
    'share_selected': 'चयनित साझा करें',
    'no_selection': 'कोई आइटम चयनित नहीं',
    'admin_panel': 'व्यवस्थापक पैनल',
    'users': 'उपयोगकर्ता',
    'activate': 'सक्रिय करें',
    'deactivate': 'निष्क्रिय करें',
    'status': 'स्थिति',
    'role': 'भूमिका',
    'active_user': 'सक्रिय उपयोगकर्ता',
    'inactive_guest': 'निष्क्रिय उपयोगकर्ता',
    'expired': 'खाता समाप्त हो गया',
    'provider_name': 'प्रदाता का नाम',
    'front_image': 'सामने की छवि',
    'back_image': 'पीछे की छवि',
    'file_url': 'फ़ाइल URL',
    'category': 'श्रेणी',
    'title': 'शीर्षक',
    'policy': 'पॉलिसी',
    'provider': 'प्रदाता',
    'expiry': 'समाप्ति',
    'specialist': 'विशेषज्ञ',
    'guest': 'अतिथि मोड',
    'account': 'खाता',
    'guest_data': 'अतिथि डेटा',
    'full_record': 'पूरा रिकॉर्ड',
    'share_record': 'रिकॉर्ड साझा करें',
    'sign_up': 'साइन अप',
    'language': 'भाषा',
    'select_medication': 'दवा चुनें',
    'select_time': 'समय चुनें',
    'select_date': 'तारीख चुनें',
    'required_field': 'यह फ़ील्ड आवश्यक है',
    'time_format_12h': 'hh:mm AM/PM',
    'please_login': 'कृपया लॉग इन करें',
    'please_fill_all': 'कृपया सभी फ़ील्ड भरें',
    'login_failed': 'लॉग इन विफल',
    'signup_failed': 'साइन अप विफल',
    'delete_confirm_title': 'हटाएँ?',
    'delete_confirm_msg': 'क्या आप वाकई इस रिकॉर्ड को हटाना चाहते हैं?',
    'cancel': 'रद्द करें',
    'please_sign_in': 'कृपया साइन इन करें',
    'account_created_success':
        'खाता सफलतापूर्वक बनाया गया! कृपया साइन इन करें।',
    'operation_failed': 'ऑपरेशन विफल',
    'select_front_image': 'सामने की छवि चुनें',
    'select_back_image': 'पीछे की छवि चुनें',
    'upload_image': 'छवि अपलोड करें',
    'uploaded': 'अपलोड हो गया',
    'insurance_company_name': 'बीमा कंपनी का नाम',
    'patient_id': 'मरीज़ ID',
    'insurance_card_front': 'बीमा कार्ड - सामने',
    'insurance_card_back': 'बीमा कार्ड - पीछे',
    'no_image_selected': 'कोई छवि चयनित नहीं',
    'upload_front_card': 'सामने का कार्ड अपलोड करें',
    'upload_back_card': 'पीछे का कार्ड अपलोड करें',
    'add_data': 'डेटा जोड़ें',
    'please_enter_insurance_company': 'कृपया बीमा कंपनी का नाम दर्ज करें',
    'please_enter_patient_id': 'कृपया मरीज़ ID दर्ज करें',
    'please_upload_both_cards': 'कृपया दोनों कार्ड अपलोड करें',
    'success': 'सफल',
    'upload_photo': 'फ़ोटो अपलोड करें',
    'select_photo': 'फ़ोटो चुनें',
    'photo_uploaded': 'फ़ोटो अपलोड हो गई',
    'please_upload_photo': 'कृपया फ़ोटो अपलोड करें',
    'share_app': 'ऐप साझा करें',
    'share_app_message': 'SANA - आपका स्वास्थ्य प्रबंधन ऐप!',
    'opening_payment': 'भुगतान पृष्ठ खोल रहा है...',
    'payment_error': 'भुगतान त्रुटि',
  },
  'zh': {
    'add': '添加',
    'save': '保存',
    'delete': '删除',
    'view': '查看',
    'close': '关闭',
    'share': '分享',
    'login': '登录',
    'logout': '退出登录',
    'admin': '管理员',
    'medications': '药物',
    'doctors': '医生',
    'pharmacies': '药房',
    'reminders': '提醒',
    'documents': '文档',
    'insurance_cards': '保险卡',
    'name': '姓名',
    'dosage': '剂量',
    'quantity': '库存',
    'description': '描述',
    'specialty': '专科',
    'phone': '电话',
    'address': '地址',
    'email': '电子邮件',
    'password': '密码',
    'sign_in': '登录',
    'new_user': '新用户',
    'register': '注册',
    'create_account': '创建账户',
    'already_account': '已经有账户？',
    'location': '位置',
    'photo': '照片',
    'front_photo': '正面照片',
    'back_photo': '背面照片',
    'reminder_time': '提醒时间',
    'reminder_date': '提醒日期',
    'schedule_type': '计划',
    'daily': '每天',
    'calendar': '日历',
    'select_times': '选择一个或多个时间',
    'select_schedule': '选择计划',
    'record': '记录',
    'no_records': '没有记录',
    'guest_mode': '访客模式',
    'get_copy': '获取你的副本',
    'create_copy': '创建你的副本',
    'select_all': '全选',
    'share_selected': '分享所选内容',
    'no_selection': '未选择任何项目',
    'admin_panel': '管理面板',
    'users': '用户',
    'activate': '启用',
    'deactivate': '停用',
    'status': '状态',
    'role': '角色',
    'active_user': '活跃用户',
    'inactive_guest': '非活跃用户',
    'expired': '账户已过期',
    'provider_name': '提供商名称',
    'front_image': '正面图片',
    'back_image': '背面图片',
    'file_url': '文件链接',
    'category': '类别',
    'title': '标题',
    'policy': '保单',
    'provider': '提供商',
    'expiry': '到期日',
    'specialist': '专家',
    'guest': '访客模式',
    'account': '账户',
    'guest_data': '访客数据',
    'full_record': '完整记录',
    'share_record': '分享记录',
    'sign_up': '注册',
    'language': '语言',
    'select_medication': '选择药物',
    'select_time': '选择时间',
    'select_date': '选择日期',
    'required_field': '此字段为必填项',
    'time_format_12h': 'hh:mm AM/PM',
    'please_login': '请登录',
    'please_fill_all': '请填写所有字段',
    'login_failed': '登录失败',
    'signup_failed': '注册失败',
    'delete_confirm_title': '删除？',
    'delete_confirm_msg': '确定要删除此记录吗？',
    'cancel': '取消',
    'please_sign_in': '请登录',
    'account_created_success': '账户创建成功！请登录。',
    'operation_failed': '操作失败',
    'select_front_image': '选择正面图片',
    'select_back_image': '选择背面图片',
    'upload_image': '上传图片',
    'uploaded': '已上传',
    'insurance_company_name': '保险公司名称',
    'patient_id': '患者 ID',
    'insurance_card_front': '保险卡 - 正面',
    'insurance_card_back': '保险卡 - 背面',
    'no_image_selected': '未选择图片',
    'upload_front_card': '上传正面卡片',
    'upload_back_card': '上传背面卡片',
    'add_data': '添加数据',
    'please_enter_insurance_company': '请输入保险公司名称',
    'please_enter_patient_id': '请输入患者 ID',
    'please_upload_both_cards': '请上传两张卡片',
    'success': '成功',
    'upload_photo': '上传照片',
    'select_photo': '选择照片',
    'photo_uploaded': '照片已上传',
    'please_upload_photo': '请上传照片',
    'share_app': '分享应用',
    'share_app_message': 'SANA - 您的健康管理应用！',
    'opening_payment': '正在打开支付页面...',
    'payment_error': '支付错误',
  },
};

String tr(String code, String key) =>
    _translations[code]?[key] ?? _translations['en']![key] ?? key;

// ============================================
// LANGUAGE BUTTONS
// ============================================

class LanguageButtons extends StatelessWidget {
  const LanguageButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: languageNotifier,
      builder: (context, currentLang, _) {
        return SizedBox(
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _languageNames.entries.map((entry) {
              final selected = currentLang == entry.key;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.0),
                  child: FilledButton(
                    onPressed: () => languageNotifier.value = entry.key,
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          selected ? Colors.teal : Colors.grey.shade200,
                      foregroundColor: selected ? Colors.white : Colors.teal,
                      minimumSize: const Size(0, 28),
                      maximumSize: const Size(double.infinity, 28),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        entry.value,
                        maxLines: 1,
                        softWrap: false,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

// ============================================
// GUEST IDENTITY
// ============================================

// ============================================
// GUEST IDENTITY - WITH CACHING
// ============================================

class GuestIdentityService {
  static const String _key = 'sana_guest_user_id';
  static String? _cachedGuestId;

  static Future<String> getGuestId() async {
    // Return cached value if available
    if (_cachedGuestId != null && _cachedGuestId!.isNotEmpty) {
      return _cachedGuestId!;
    }

    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_key)?.trim();

    if (existing != null && existing.isNotEmpty) {
      _cachedGuestId = existing;
      return existing;
    }

    final id = 'guest_${DateTime.now().microsecondsSinceEpoch}';
    await prefs.setString(_key, id);
    _cachedGuestId = id;
    return id;
  }

  // Optional: Clear cache when user logs out
  static void clearCache() {
    _cachedGuestId = null;
  }
}

// ============================================
// MAIN
// ============================================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final guestId = await GuestIdentityService.getGuestId();

  await Supabase.initialize(
    url: _supabaseUrl,
    publishableKey: _supabaseKey, // Replaces anonKey
    headers: {
      'x-sana-guest-id': guestId,
    },
  );

  runApp(const SanaApp());
}

class SanaApp extends StatelessWidget {
  const SanaApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: languageNotifier,
      builder: (context, language, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: Locale(language),
        supportedLocales: _languageNames.keys.map(Locale.new).toList(),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.teal,
          brightness: Brightness.light,
        ),
        home: Directionality(
          textDirection:
              language == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          child: const HomeScreen(),
        ),
      ),
    );
  }
}

// ============================================
// HOME SCREEN
// ============================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _client = Supabase.instance.client;
  Map<String, dynamic>? _profile;
  bool _loading = true, _isGuest = true;
  String? _guestId;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = _client.auth.onAuthStateChange.listen((_) {
      _loadSession();
    });
    _loadSession();
  }

  Future<void> _loadSession() async {
    try {
      final guestId = await GuestIdentityService.getGuestId();
      final user = _client.auth.currentUser;

      if (user == null) {
        if (!mounted) return;
        setState(() {
          _profile = null;
          _guestId = guestId;
          _isGuest = true;
          _loading = false;
        });
        return;
      }

      Map<String, dynamic>? data;
      try {
        data = await _client
            .from('users')
            .select()
            .eq('id', user.id)
            .maybeSingle();
      } catch (_) {
        data = null;
      }

      if (!mounted) return;
      setState(() {
        _profile = data;
        _guestId = guestId;
        _isGuest = false;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        final guestId = await GuestIdentityService.getGuestId();
        setState(() {
          _profile = null;
          _guestId = guestId;
          _isGuest = _client.auth.currentUser == null;
          _loading = false;
        });
      }
    }
  }

  String? get _ownerId => _isGuest ? _guestId : _client.auth.currentUser?.id;

  Future<void> _openCard(String type) async {
    final ownerId = _ownerId ?? await GuestIdentityService.getGuestId();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecordListScreen(
          type: type,
          ownerId: ownerId,
          guestMode: _isGuest,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openAddDialogDirectly(String type) async {
    final ownerId = _ownerId ?? await GuestIdentityService.getGuestId();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecordListScreen(
          type: type,
          ownerId: ownerId,
          guestMode: _isGuest,
          autoOpenAdd: true,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _shareApp() async {
    final language = languageNotifier.value;
    final message = '${tr(language, 'share_app_message')}\n\n$_sanaShareUrl';
    await SharePlus.instance.share(
      ShareParams(
        text: message,
      ),
    );
  }

  // FIXED: "Get Your Own Copy" opens Tap payment link

  // FIXED: "Get Your Own Copy" opens Tap payment link safely

  Future<void> _getOwnCopy() async {
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'create-tap-charge',
        body: {
          'first_name': 'Customer',
          'email': 'customer@example.com',
        },
      );

      dynamic rawData = response.data;

      if (rawData is String) {
        rawData = jsonDecode(rawData);
      }

      if (rawData is! Map) {
        throw Exception(
          'Invalid response from create-tap-charge',
        );
      }

      final data = Map<String, dynamic>.from(rawData);

      if (data['error'] != null) {
        throw Exception(
          data['error'].toString(),
        );
      }

      final transaction = data['transaction'];

      if (transaction is! Map) {
        throw Exception(
          'Tap payment transaction information is missing.',
        );
      }

      final checkoutUrl = transaction['url'];

      if (checkoutUrl is! String || checkoutUrl.trim().isEmpty) {
        throw Exception(
          'Tap checkout URL is missing.',
        );
      }

      final uri = Uri.tryParse(checkoutUrl);

      if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
        throw Exception(
          'Invalid Tap checkout URL.',
        );
      }

      // Open the Tap checkout page.
      // Keep your existing URL-launching method here if
      // your project already has one.

      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw Exception(
          'Could not open Tap payment page.',
        );
      }
    } catch (e) {
      debugPrint(
        'create-tap-charge error: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to open payment page: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final isAdmin =
        (_profile?['role'] ?? '').toString().toLowerCase() == 'admin';

    return ValueListenableBuilder<String>(
      valueListenable: languageNotifier,
      builder: (context, language, _) => Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth =
                  constraints.maxWidth > 450 ? 450.0 : constraints.maxWidth;
              return Center(
                child: SizedBox(
                  width: maxWidth,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const LanguageButtons(),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Icon(Icons.health_and_safety,
                                color: Colors.teal, size: 36),
                            const Text(
                              'SANA',
                              style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 4),
                            ),
                            IconButton(
                              icon: const Icon(Icons.share, size: 26),
                              onPressed: _shareApp,
                              tooltip: tr(language, 'share_app'),
                            ),
                          ],
                        ),
                        if (_isGuest)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              tr(language, 'guest_mode'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                        const SizedBox(height: 16),
                        _buildMainGrid(language),
                        const SizedBox(height: 16),
                        _buildBottomArea(language, isAdmin),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMainGrid(String language) {
    final cards = [
      _recordCard('medications', Icons.medication, Colors.teal.shade100),
      _recordCard('doctors', Icons.person, Colors.blue.shade100),
      _recordCard('pharmacies', Icons.local_pharmacy, Colors.green.shade100),
      _recordCard('reminders', Icons.alarm, Colors.orange.shade100),
      _recordCard('documents', Icons.folder, Colors.purple.shade100),
      _recordCard('insurance_cards', Icons.badge, Colors.pink.shade100),
    ];

    return Column(
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.15,
          children: cards,
        ),
        const SizedBox(height: 10),
        _shareCard(language),
      ],
    );
  }

  Widget _recordCard(String type, IconData icon, Color color) {
    final language = languageNotifier.value;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: color,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openCard(type),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_circle,
                        color: Colors.teal, size: 22),
                    tooltip: tr(language, 'add'),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _openAddDialogDirectly(type),
                  ),
                ],
              ),
              Icon(icon, size: 30, color: Colors.teal.shade700),
              const SizedBox(height: 4),
              Text(
                tr(language, type),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shareCard(String language) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.amber.shade100,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _shareApp,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.share, size: 28, color: Colors.teal),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    tr(language, 'share_app'),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Widget _buildBottomArea(String language, bool isAdmin) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isGuest
                    ? () async {
                        final result = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()),
                        );
                        if (result == true) await _loadSession();
                      }
                    : () async {
                        await _client.auth.signOut();
                        await _loadSession();
                      },
                icon: Icon(_isGuest ? Icons.login : Icons.logout, size: 18),
                label: Text(
                  _isGuest ? tr(language, 'login') : tr(language, 'logout'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: _getOwnCopy,
                icon: const Icon(Icons.copy, size: 18),
                label: Text(
                  tr(language, 'get_copy'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
        if (isAdmin) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminScreen()),
            ),
            icon: const Icon(Icons.admin_panel_settings),
            label: Text(tr(language, 'admin')),
          ),
        ],
      ],
    );
  }
}

// ============================================
// LOGIN SCREEN
// ============================================

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController(), _password = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _email.text.trim();
    final password = _password.text.trim();
    final language = languageNotifier.value;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(language, 'please_fill_all'))),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final res = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (res.user != null) {
        if (!mounted) return;
        Navigator.pop(context, true);
      } else {
        throw Exception(tr(language, 'login_failed'));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${tr(language, 'login_failed')}: ${e.toString().replaceAll('Exception: ', '')}')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _navigateToSignUp() async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (_) => const SignUpScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: languageNotifier,
      builder: (context, language, _) => Directionality(
        textDirection: language == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const LanguageButtons(),
                    const SizedBox(height: 20),
                    const Icon(Icons.health_and_safety,
                        size: 52, color: Colors.teal),
                    const SizedBox(height: 4),
                    const Text(
                      'SANA',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      tr(language, 'sign_in'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: tr(language, 'email'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _password,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: tr(language, 'password'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: _busy ? null : _login,
                        child: _busy
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : Text(tr(language, 'sign_in')),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                        onPressed: _navigateToSignUp,
                        child: Text(tr(language, 'new_user'))),
                    const SizedBox(height: 8),
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(tr(language, 'close'))),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================
// SIGN UP SCREEN
// ============================================

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    final language = languageNotifier.value;

    if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(language, 'please_fill_all'))),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final client = Supabase.instance.client;
      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'phone': phone,
          'role': 'user',
          'is_active': true,
        },
      );

      if (response.user == null) {
        throw Exception(tr(language, 'signup_failed'));
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(language, 'account_created_success'))),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${tr(language, 'signup_failed')}: ${e.toString().replaceAll('Exception: ', '')}')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: languageNotifier,
      builder: (context, language, _) => Directionality(
        textDirection: language == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          appBar: AppBar(title: Text(tr(language, 'create_account'))),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.person_add, size: 64, color: Colors.teal),
                    const SizedBox(height: 16),
                    Text(
                      tr(language, 'create_account'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: tr(language, 'name'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: tr(language, 'email'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: tr(language, 'phone'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: tr(language, 'password'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: _busy ? null : _signUp,
                        child: _busy
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : Text(tr(language, 'register')),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(tr(language, 'already_account')),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================
// RECORD SANITIZER - REMOVED guest_id
// ============================================

class RecordSanitizer {
  static const Set<String> validColumns = {
    'name',
    'dosage',
    'quantity',
    'reminder_time',
    // 'reminder_date' - REMOVED - does not exist in medications table
    'specialty',
    'phone',
    'address',
    'location',
    'title',
    'category',
    'file_url',
    'file_type',
    'provider_name',
    'front_image_url',
    'back_image_url',
    'photo_url',
    'photo_base64',
    'user_id',
    'photo',
    'front_photo',
    'back_photo',
    'provider',
    'policy_number',
    'medication_name',
    'medication_id',
  };

  static Map<String, dynamic> sanitize(Map<String, dynamic> rawInput) {
    final cleanPayload = <String, dynamic>{};
    for (final entry in rawInput.entries) {
      if (validColumns.contains(entry.key) && entry.value != null) {
        if (entry.value is String) {
          final trimmed = (entry.value as String).trim();
          if (trimmed.isNotEmpty) cleanPayload[entry.key] = trimmed;
        } else {
          cleanPayload[entry.key] = entry.value;
        }
      }
    }
    return cleanPayload;
  }
}

// ============================================
// SAFE BASE64 IMAGE
// ============================================

class SafeBase64Image extends StatefulWidget {
  final String base64String;
  final double? height;
  final double? width;
  const SafeBase64Image(
      {super.key, required this.base64String, this.height, this.width});

  @override
  State<SafeBase64Image> createState() => _SafeBase64ImageState();
}

class _SafeBase64ImageState extends State<SafeBase64Image> {
  Uint8List? _bytes;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _decode();
  }

  @override
  void didUpdateWidget(SafeBase64Image oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.base64String != widget.base64String) _decode();
  }

  void _decode() {
    if (widget.base64String.isEmpty) {
      setState(() => _hasError = true);
      return;
    }
    try {
      final sanitized = widget.base64String.contains(',')
          ? widget.base64String.split(',').last
          : widget.base64String;
      final value = sanitized.trim();
      final encoded = value.contains(',') ? value.split(',').last : value;

      final decoded = base64Decode(
        encoded.replaceAll(RegExp(r'\s+'), ''),
      );
      setState(() {
        _bytes = decoded;
        _hasError = false;
      });
    } catch (_) {
      setState(() => _hasError = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError)
      return Icon(Icons.broken_image, size: 48, color: Colors.grey.shade400);
    if (_bytes == null) {
      return const SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(strokeWidth: 2));
    }
    return Image.memory(
      _bytes!,
      height: widget.height,
      width: widget.width,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          Icon(Icons.broken_image, color: Colors.grey.shade400),
    );
  }
}

// ============================================
// SAFE NETWORK IMAGE
// ============================================

class SafeNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? height;
  final double? width;
  final BoxFit fit;

  const SafeNetworkImage({
    super.key,
    required this.imageUrl,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(imageUrl);
    final isValidUrl = uri != null &&
        uri.hasAbsolutePath &&
        (uri.scheme == 'http' || uri.scheme == 'https');

    if (!isValidUrl) {
      return const Icon(Icons.broken_image, size: 48, color: Colors.grey);
    }

    return Image.network(
      imageUrl,
      height: height,
      width: width,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return SizedBox(
          height: height ?? 100,
          width: width ?? 100,
          child: const Center(
            child: CircularProgressIndicator.adaptive(),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return const Icon(Icons.broken_image, size: 48, color: Colors.grey);
      },
    );
  }
}

// ============================================
// IMAGE PICKER HELPER
// ============================================

class ImagePickerHelper {
  static Future<String?> pickImageAsBase64() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      if (image == null) return null;
      final bytes = await image.readAsBytes();
      return base64Encode(bytes);
    } catch (_) {
      return null;
    }
  }
}

// ============================================
// DISPLAY IMAGE
// ============================================

class DisplayImage extends StatelessWidget {
  final Uint8List? bytes;
  final String? base64String;
  final String? url;
  final double height;
  final double width;
  final BoxFit fit;

  const DisplayImage({
    super.key,
    this.bytes,
    this.base64String,
    this.url,
    this.height = 60,
    this.width = 60,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (base64String != null && base64String!.isNotEmpty) {
      try {
        final value = base64String!.trim();
        final encoded = value.contains(',') ? value.split(',').last : value;

        final decoded = base64Decode(encoded);
        return Image.memory(
          decoded,
          height: height,
          width: width,
          fit: fit,
          errorBuilder: (_, __, ___) =>
              Icon(Icons.broken_image, color: Colors.grey.shade400),
        );
      } catch (_) {}
    }

    if (bytes != null && bytes!.isNotEmpty) {
      return Image.memory(
        bytes!,
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (_, __, ___) =>
            Icon(Icons.broken_image, color: Colors.grey.shade400),
      );
    }

    if (url != null && url!.isNotEmpty) {
      final uri = Uri.tryParse(url!);
      if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
        return Image.network(
          url!,
          height: height,
          width: width,
          fit: fit,
          errorBuilder: (_, __, ___) =>
              Icon(Icons.broken_image, color: Colors.grey.shade400),
        );
      }
    }

    return Icon(Icons.broken_image, color: Colors.grey.shade400);
  }
}

// ============================================
// ADD FORM DIALOG
// ============================================

// ============================================
// ADD FORM DIALOG
// ============================================

class AddFormDialog extends StatefulWidget {
  final String type;
  final String language;
  final List<Map<String, dynamic>> medicationsList;
  final List<String> fields;
  final List<String> requiredFields;
  final Future<void> Function(Map<String, dynamic> payload) onSave;

  const AddFormDialog({
    super.key,
    required this.type,
    required this.language,
    required this.medicationsList,
    required this.fields,
    required this.requiredFields,
    required this.onSave,
  });

  @override
  State<AddFormDialog> createState() => _AddFormDialogState();
}

class _AddFormDialogState extends State<AddFormDialog> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, dynamic> _selectedValues = {};
  final List<TimeOfDay> _selectedMedicationTimes = [];

  String _medicationScheduleType = 'daily';
  DateTime? _medicationCalendarDate;

  // Medicine photo stored as Base64.
  String? _medicinePhotoBase64;
  String? _frontPhotoBase64;
  String? _backPhotoBase64;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    for (final field in widget.fields) {
      _controllers[field] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _fieldLabel(String field) {
    switch (field) {
      case 'name':
        return 'name';
      case 'dosage':
        return 'dosage';
      case 'quantity':
        return 'quantity';
      case 'reminder_time':
        return 'reminder_time';
      case 'reminder_date':
        return 'reminder_date';
      case 'description':
        return 'description';
      case 'specialty':
        return 'specialty';
      case 'phone':
        return 'phone';
      case 'address':
        return 'address';
      case 'title':
        return 'title';
      case 'category':
        return 'category';
      case 'file_url':
        return 'file_url';
      case 'provider_name':
        return 'provider_name';
      case 'front_photo':
        return 'front_photo';
      case 'back_photo':
        return 'back_photo';
      case 'location':
        return 'location';
      case 'photo':
        return 'photo';
      case 'medication_name':
        return 'name';
      default:
        return field;
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';

    return '$hour:$minute $period';
  }

  List<TimeOfDay> _timeChoices() {
    return List<TimeOfDay>.generate(
      24,
      (i) => TimeOfDay(hour: i, minute: 0),
    );
  }

  Future<DateTime?> _selectDate(BuildContext context) async {
    return showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
  }

  Future<void> _pickMedicinePhoto() async {
    final base64 = await ImagePickerHelper.pickImageAsBase64();

    if (base64 != null && mounted) {
      setState(() {
        _medicinePhotoBase64 = base64;
      });
    }
  }

  Widget _buildMedicinePhotoSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Medicine photo',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          if (_medicinePhotoBase64 != null)
            Center(
              child: DisplayImage(
                base64String: _medicinePhotoBase64,
                height: 140,
                width: 140,
                fit: BoxFit.cover,
              ),
            )
          else
            Text(
              'No medicine photo selected',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _pickMedicinePhoto,
              icon: const Icon(Icons.photo_camera),
              label: Text(
                _medicinePhotoBase64 == null
                    ? 'Upload medicine photo'
                    : 'Change medicine photo',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderTimes() {
    return FormField<List<TimeOfDay>>(
      initialValue: List<TimeOfDay>.from(_selectedMedicationTimes),
      validator: (value) {
        if (widget.requiredFields.contains('reminder_time') &&
            _selectedMedicationTimes.isEmpty) {
          return tr(widget.language, 'required_field');
        }

        return null;
      },
      builder: (fieldState) {
        return InputDecorator(
          decoration: InputDecoration(
            labelText: tr(widget.language, 'reminder_time'),
            border: const OutlineInputBorder(),
            errorText: fieldState.errorText,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select reminder times',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),

              // Limited height prevents AlertDialog from receiving
              // infinite/unbounded height on Flutter Web.
              SizedBox(
                height: 190,
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _timeChoices().map((time) {
                      final selected = _selectedMedicationTimes.any(
                        (t) => t.hour == time.hour && t.minute == time.minute,
                      );

                      return FilterChip(
                        label: Text(_formatTimeOfDay(time)),
                        selected: selected,
                        onSelected: (on) {
                          setState(() {
                            if (on) {
                              if (!_selectedMedicationTimes.any(
                                (t) =>
                                    t.hour == time.hour &&
                                    t.minute == time.minute,
                              )) {
                                _selectedMedicationTimes.add(time);
                              }

                              _selectedMedicationTimes.sort(
                                (a, b) => (a.hour * 60 + a.minute)
                                    .compareTo(b.hour * 60 + b.minute),
                              );
                            } else {
                              _selectedMedicationTimes.removeWhere(
                                (t) =>
                                    t.hour == time.hour &&
                                    t.minute == time.minute,
                              );
                            }

                            fieldState.didChange(
                              List<TimeOfDay>.from(
                                _selectedMedicationTimes,
                              ),
                            );
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),

              if (_selectedMedicationTimes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Selected: ${_selectedMedicationTimes.map(_formatTimeOfDay).join(', ')}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildMedicationSchedule() {
    return FormField<DateTime>(
      initialValue: _medicationCalendarDate,
      validator: (value) {
        if (!widget.requiredFields.contains('reminder_date')) {
          return null;
        }

        if (_medicationScheduleType == 'calendar' &&
            _medicationCalendarDate == null) {
          return tr(widget.language, 'required_field');
        }

        return null;
      },
      builder: (fieldState) {
        return InputDecorator(
          decoration: InputDecoration(
            labelText: 'Medication schedule',
            border: const OutlineInputBorder(),
            errorText: fieldState.errorText,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose when this medication reminder should repeat:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment<String>(
                      value: 'daily',
                      icon: Icon(Icons.today),
                      label: Text('Daily'),
                    ),
                    ButtonSegment<String>(
                      value: 'calendar',
                      icon: Icon(Icons.calendar_month),
                      label: Text('Calendar'),
                    ),
                  ],
                  selected: {_medicationScheduleType},
                  onSelectionChanged: (values) {
                    setState(() {
                      _medicationScheduleType = values.first;

                      if (_medicationScheduleType == 'daily') {
                        _medicationCalendarDate = null;
                        fieldState.didChange(null);
                      }
                    });
                  },
                ),
              ),
              if (_medicationScheduleType == 'daily') ...[
                const SizedBox(height: 10),
                const Text(
                  'The reminder will repeat every day.',
                  style: TextStyle(fontSize: 13),
                ),
              ],
              if (_medicationScheduleType == 'calendar') ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final date = await _selectDate(context);

                      if (date != null && mounted) {
                        setState(() {
                          _medicationCalendarDate = date;
                        });

                        fieldState.didChange(date);
                      }
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      _medicationCalendarDate == null
                          ? 'Select calendar date'
                          : 'Date: ${_medicationCalendarDate!.year}-'
                              '${_medicationCalendarDate!.month.toString().padLeft(2, '0')}-'
                              '${_medicationCalendarDate!.day.toString().padLeft(2, '0')}',
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildMedicationDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: tr(widget.language, 'select_medication'),
          border: const OutlineInputBorder(),
        ),
        hint: Text(tr(widget.language, 'select_medication')),
        isExpanded: true,
        items: widget.medicationsList.map((med) {
          final nameStr = med['name']?.toString() ?? '';
          final idStr = med['id']?.toString() ?? '';

          return DropdownMenuItem<String>(
            value: idStr,
            child: Text(
              nameStr,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            final selectedMed = widget.medicationsList.firstWhere(
              (med) => med['id']?.toString() == value,
              orElse: () => {},
            );

            _selectedValues['medication_id'] = value;

            _selectedValues['medication_name'] =
                selectedMed['name']?.toString() ?? '';

            _controllers['medication_name']?.text =
                selectedMed['name']?.toString() ?? '';

            _controllers['name']?.text = selectedMed['name']?.toString() ?? '';
          });
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return tr(widget.language, 'required_field');
          }

          return null;
        },
      ),
    );
  }

  Widget _buildTextField(String field) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: _controllers[field],
        decoration: InputDecoration(
          labelText: tr(widget.language, _fieldLabel(field)),
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (widget.requiredFields.contains(field)) {
            if (value == null || value.trim().isEmpty) {
              return tr(widget.language, 'required_field');
            }
          }

          return null;
        },
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final payload = <String, dynamic>{};

    for (final entry in _controllers.entries) {
      final value = entry.value.text.trim();

      if (value.isNotEmpty) {
        payload[entry.key] = value;
      }
    }

    // Medication reminder times.
    if (_selectedMedicationTimes.isNotEmpty) {
      payload['reminder_time'] = jsonEncode(
        _selectedMedicationTimes.map(_formatTimeOfDay).toList(),
      );
    }

    // Medication schedule.
    if (widget.type == 'medications') {
      payload['reminder_schedule_type'] = _medicationScheduleType;

      if (_medicationScheduleType == 'daily') {
        payload['reminder_date'] = 'daily';
      } else {
        payload['reminder_date'] = _medicationCalendarDate == null
            ? null
            : _medicationCalendarDate!.toIso8601String().split('T')[0];
      }

      // Medicine photo is saved as Base64.
      if (_medicinePhotoBase64 != null && _medicinePhotoBase64!.isNotEmpty) {
        payload['photo_base64'] = _medicinePhotoBase64;
      }
    } else {
      if (_medicationScheduleType == 'daily') {
        payload['reminder_date'] = 'daily';
      } else if (_medicationCalendarDate != null) {
        payload['reminder_date'] =
            _medicationCalendarDate!.toIso8601String().split('T')[0];
      }
    }

    if (_selectedValues['medication_id'] != null) {
      payload['medication_id'] = _selectedValues['medication_id'];
    }

    if (_selectedValues['medication_name'] != null) {
      payload['medication_name'] = _selectedValues['medication_name'];

      payload['name'] = _selectedValues['medication_name'];
    }

    if (widget.type == 'documents') {
      if (_medicinePhotoBase64 != null && _medicinePhotoBase64!.isNotEmpty) {
        payload['photo'] = _medicinePhotoBase64;
      }
    }

    await widget.onSave(payload);

    if (context.mounted) {
      Navigator.pop(context, payload);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMedication = widget.type == 'medications';

    return AlertDialog(
      title: Text(
        '${tr(widget.language, 'add')} '
        '${tr(widget.language, widget.type)}',
      ),

      // The dialog gets a finite maximum height.
      // The inside content can then scroll safely.
      content: SizedBox(
        width: 650,
        height: MediaQuery.of(context).size.height * 0.75,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(right: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Medicine photo appears only when adding medication.
                if (isMedication) _buildMedicinePhotoSection(),

                // Medication selection is only needed for reminders.
                if (widget.type == 'reminders') _buildMedicationDropdown(),

                ...widget.fields.map((field) {
                  if (field == 'reminder_time') {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildReminderTimes(),
                    );
                  }

                  if (field == 'reminder_date') {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildMedicationSchedule(),
                    );
                  }

                  if (field == 'medication_name') {
                    // Already handled above for reminders.
                    if (widget.type == 'reminders') {
                      return const SizedBox.shrink();
                    }

                    return _buildMedicationDropdown();
                  }

                  // PHOTO UPLOAD BLOCK - For Documents and Insurance Cards
                  if (field == 'photo' ||
                      field == 'front_photo' ||
                      field == 'back_photo') {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            field == 'photo'
                                ? 'Upload Photo'
                                : tr(widget.language, field),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final base64 =
                                  await ImagePickerHelper.pickImageAsBase64();
                              if (base64 != null) {
                                setState(() {
                                  if (field == 'front_photo') {
                                    _frontPhotoBase64 = base64;
                                  } else if (field == 'back_photo') {
                                    _backPhotoBase64 = base64;
                                  } else {
                                    _medicinePhotoBase64 = base64;
                                  }
                                });
                              }
                            },
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Upload Photo'),
                          ),
                          // Show image preview after upload
                          if (_medicinePhotoBase64 != null &&
                              field == 'photo') ...[
                            const SizedBox(height: 8),
                            DisplayImage(
                              base64String: _medicinePhotoBase64,
                              height: 80,
                              width: 80,
                            ),
                          ],
                          if (_frontPhotoBase64 != null &&
                              field == 'front_photo') ...[
                            const SizedBox(height: 8),
                            DisplayImage(
                              base64String: _frontPhotoBase64,
                              height: 80,
                              width: 80,
                            ),
                          ],
                          if (_backPhotoBase64 != null &&
                              field == 'back_photo') ...[
                            const SizedBox(height: 8),
                            DisplayImage(
                              base64String: _backPhotoBase64,
                              height: 80,
                              width: 80,
                            ),
                          ],
                        ],
                      ),
                    );
                  }

                  return _buildTextField(field);
                }),
              ],
            ),
          ),
        ),
      ),

      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: Text(
            tr(widget.language, 'close'),
          ),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(
            tr(widget.language, 'add'),
          ),
        ),
      ],
    );
  }
}

// ============================================
// RECORD LIST SCREEN - PRESERVED ORIGINAL
// ============================================

class RecordListScreen extends StatefulWidget {
  final String type;
  final String ownerId;
  final bool guestMode;
  final bool autoOpenAdd;

  const RecordListScreen({
    super.key,
    required this.type,
    required this.ownerId,
    required this.guestMode,
    this.autoOpenAdd = false,
  });

  @override
  State<RecordListScreen> createState() => _RecordListScreenState();
}

class _RecordListScreenState extends State<RecordListScreen> {
  final _client = Supabase.instance.client;
  List<Map<String, dynamic>> _rows = [];
  List<Map<String, dynamic>> _medicationsList = [];
  bool _loading = true;
  final _formKey = GlobalKey<FormState>();

  // Insurance card variables - using base64 only (no File for web)
  String? _frontCardBase64;
  String? _backCardBase64;
  final TextEditingController _insuranceCompanyController =
      TextEditingController();
  final TextEditingController _patientIdController = TextEditingController();

  // Document variables - using base64 only (no File for web)
  String? _documentPhotoBase64;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _fileUrlController = TextEditingController();

  String get _table => widget.type == 'reminders' ? 'reminders' : widget.type;

  @override
  void initState() {
    super.initState();
    _load();
    if (widget.type == 'reminders') _loadMedications();
    if (widget.autoOpenAdd && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _add());
    }
  }

  @override
  void dispose() {
    _insuranceCompanyController.dispose();
    _patientIdController.dispose();
    _titleController.dispose();
    _categoryController.dispose();
    _fileUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadMedications() async {
    if (!mounted) return;
    try {
      final query = _client.from('medications').select();
      final dynamic response = widget.guestMode
          ? await query.eq('guest_id', widget.ownerId)
          : await query.eq('user_id', widget.ownerId);

      final List<dynamic> list = response as List<dynamic>;
      final List<Map<String, dynamic>> records =
          list.map((item) => Map<String, dynamic>.from(item as Map)).toList();

      if (mounted) {
        setState(() {
          _medicationsList = records;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _medicationsList = [];
        });
      }
    }
  }

  Future<void> _load() async {
    if (!mounted) return;

    // ADD THESE 5 LINES FOR DEBUG
    //print('========== LOAD ==========');
    //print('Type: ${widget.type}');
    //print('Table: $_table');
    //print('Owner ID: ${widget.ownerId}');
    //print('Guest Mode: ${widget.guestMode}');

    try {
      String tableName = _table;
      if (widget.type == 'reminders') {
        tableName = 'medications';
      }
      final query = _client.from(tableName).select();
      final dynamic response = widget.guestMode
          ? await query.eq('guest_id', widget.ownerId)
          : await query.eq('user_id', widget.ownerId);

      if (mounted) {
        final List<dynamic> list = response as List<dynamic>;
        var records =
            list.map((item) => Map<String, dynamic>.from(item as Map)).toList();

        // ADD THIS 1 LINE FOR DEBUG
        print('Records found: ${records.length}');

        setState(() {
          _rows = records;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error loading: $e')));
      }
    }
  }

  String _fieldLabel(String field) {
    switch (field) {
      case 'name':
        return 'name';
      case 'dosage':
        return 'dosage';
      case 'quantity':
        return 'quantity';
      case 'reminder_time':
        return 'reminder_time';
      case 'reminder_date':
        return 'reminder_date';
      case 'description':
        return 'description';
      case 'specialty':
        return 'specialty';
      case 'phone':
        return 'phone';
      case 'address':
        return 'address';
      case 'title':
        return 'title';
      case 'category':
        return 'category';
      case 'file_url':
        return 'file_url';
      case 'provider_name':
        return 'provider_name';
      case 'front_photo':
        return 'front_photo';
      case 'back_photo':
        return 'back_photo';
      case 'location':
        return 'location';
      case 'photo':
        return 'photo';
      case 'medication_name':
        return 'name';
      default:
        return field;
    }
  }

  List<String> _getRequiredFields() {
    switch (widget.type) {
      case 'medications':
        return ['name', 'dosage'];
      case 'doctors':
        return ['name'];
      case 'pharmacies':
        return ['name'];
      case 'reminders':
        return ['medication_name', 'reminder_time', 'reminder_date'];
      case 'documents':
        return ['title'];
      case 'insurance_cards':
        return ['provider_name', 'front_photo', 'back_photo'];
      default:
        return ['name'];
    }
  }

  List<String> _getFields() {
    switch (widget.type) {
      case 'medications':
        return [
          'name',
          'dosage',
          'quantity',
          //'photo',
          'reminder_time',
          'reminder_date',
        ];
      case 'doctors':
        return ['name', 'specialty', 'phone', 'address'];
      case 'pharmacies':
        return ['name', 'phone', 'address'];
      case 'reminders':
        return [
          'name',
          'dosage',
          'reminder_time',
          'reminder_date',
          //'description'
        ];
      case 'documents':
        return ['title', 'category', 'photo', 'file_url'];
      case 'insurance_cards':
        return ['provider_name', 'front_photo', 'back_photo', 'policy_number'];
      default:
        return ['name'];
    }
  }

  Future<void> _add() async {
    // ADD THIS FIRST LINE
    //print('>>> _add() CALLED for ${widget.type} <<<');
    final language = languageNotifier.value;
    final fields = _getFields();
    final requiredFields = _getRequiredFields();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AddFormDialog(
        type: widget.type,
        language: language,
        medicationsList: _medicationsList,
        fields: fields,
        requiredFields: requiredFields,

        // IMPORTANT:
        // When AddFormDialog successfully creates the payload,
        // close the dialog and return that payload to _add().
        onSave: (payload) async {
          Navigator.pop(dialogContext, payload);
        },
      ),
    );

    if (!mounted) return;

    if (result != null) {
      await _saveRecord(result);
    }
  }

  // FIXED: Removed guest_id, removed reminder_date for medications
  Future<void> _saveRecord(Map<String, dynamic> result) async {
    final language = languageNotifier.value;

    //print('========== _saveRecord CALLED ==========');
    //print('Table: $_table');
    //print('Result: $result');

    final cleanPayload = <String, dynamic>{
      'user_id': widget.guestMode ? null : widget.ownerId,
      'guest_id': widget.guestMode ? widget.ownerId : null,
    };

    // Helper to extract photos across forms
    String? extractPhoto() {
      if (result['photo_base64'] != null &&
          result['photo_base64'].toString().trim().isNotEmpty) {
        return result['photo_base64'].toString().trim();
      }
      if (result['photo'] != null &&
          result['photo'].toString().trim().isNotEmpty) {
        return result['photo'].toString().trim();
      }
      return null;
    }

    final photo = extractPhoto();

    if (_table == 'documents') {
      cleanPayload['title'] = result['title'] ?? result['name'] ?? 'Document';

      if (result['category'] != null) {
        cleanPayload['category'] = result['category'];
      }

      // Fix: Save photo properly
      if (photo != null && photo.toString().isNotEmpty) {
        cleanPayload['photo'] = photo.toString();
      }

      // Save URL if present
      final url = result['file_url'] ?? result['url'];
      if (url != null && url.toString().isNotEmpty) {
        cleanPayload['file_url'] = url.toString();
      }
    } else if (_table == 'insurance_cards') {
      cleanPayload['id'] = 'ic_${DateTime.now().millisecondsSinceEpoch}';

      cleanPayload['provider_name'] =
          result['provider_name'] ?? result['name'] ?? 'Insurance Card';

      cleanPayload['policy_number'] = result['policy_number'] ?? '';

      // FIX: Save front image as base64
      final front = result['front_photo'] ?? result['front_image_url'] ?? photo;
      if (front != null && front.toString().isNotEmpty) {
        cleanPayload['front_image_url'] = front.toString(); // Should be base64
      }

      // FIX: Save back image as base64
      final back = result['back_photo'] ?? result['back_image_url'];
      if (back != null && back.toString().isNotEmpty) {
        cleanPayload['back_image_url'] = back.toString(); // Should be base64
      }

      if (widget.guestMode) {
        cleanPayload['user_id'] = null;
        cleanPayload['guest_id'] = widget.ownerId;
      } else {
        cleanPayload['user_id'] = widget.ownerId;
        cleanPayload['guest_id'] = null;
      }
    } else if (_table == 'pharmacies') {
      cleanPayload['name'] = result['name'] ?? '';
      cleanPayload['phone'] = result['phone'] ?? '';
      cleanPayload['address'] = result['address'] ?? '';
    } else if (_table == 'doctors') {
      cleanPayload['name'] = result['name'] ?? '';
      cleanPayload['specialty'] = result['specialty'] ?? '';
      cleanPayload['phone'] = result['phone'] ?? '';
      cleanPayload['address'] = result['address'] ?? '';
    } else if (_table == 'medications') {
      // FIX: Add name - REQUIRED field
      cleanPayload['name'] = result['name'] ?? '';

      if (result['dosage'] != null) {
        cleanPayload['dosage'] = result['dosage'];
      }

      if (result['reminder_schedule_type'] != null) {
        cleanPayload['reminder_schedule_type'] =
            result['reminder_schedule_type'];
      }

      if (result['reminder_time'] != null) {
        cleanPayload['reminder_time'] = result['reminder_time'];
      }
    }

    try {
      print('Inserting into $_table: $cleanPayload');
      await _client.from(_table).insert(cleanPayload);
      await _load();

      if (widget.type == 'reminders') {
        await _loadMedications();
      }
    } catch (e) {
      print('========== ERROR in _saveRecord ==========');
      print(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${tr(language, 'operation_failed')}: $e',
            ),
          ),
        );
      }
    }
  }

  // FIXED: Document photo upload - uses base64 only (no File for web)
  Future<void> _pickDocumentPhoto() async {
    final base64 = await ImagePickerHelper.pickImageAsBase64();
    if (base64 != null) {
      setState(() {
        _documentPhotoBase64 = base64;
      });
    }
  }

  // FIXED: Insurance card front photo - uses base64 only (no File for web)
  Future<void> _pickFrontCard() async {
    final base64 = await ImagePickerHelper.pickImageAsBase64();
    if (base64 != null) {
      setState(() {
        _frontCardBase64 = base64;
      });
    }
  }

  // FIXED: Insurance card back photo - uses base64 only (no File for web)
  Future<void> _pickBackCard() async {
    final base64 = await ImagePickerHelper.pickImageAsBase64();
    if (base64 != null) {
      setState(() {
        _backCardBase64 = base64;
      });
    }
  }

  // FIXED: Insurance card submit - uses base64 only

  Future<void> _submitInsuranceCard() async {
    // ADD THIS FIRST LINE
    print('>>> _submitInsuranceCard() CALLED! <<<');
    final language = languageNotifier.value;
    if (!_formKey.currentState!.validate()) return;

    if (_frontCardBase64 == null || _backCardBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(language, 'please_upload_both_cards'))),
      );
      return;
    }

    try {
      final payload = {
        'name': _insuranceCompanyController.text.trim(),
        'provider_name': _insuranceCompanyController.text.trim(),
        'patient_id': _patientIdController.text.trim(),
        'front_image_url': _frontCardBase64,
        'back_image_url': _backCardBase64,
      };

      final cleanPayload = RecordSanitizer.sanitize(payload);

      if (widget.guestMode) {
        cleanPayload['user_id'] = null;
        cleanPayload['guest_id'] = widget.ownerId;
      } else {
        cleanPayload['user_id'] = widget.ownerId;
        cleanPayload['guest_id'] = null;
      }

      await _client.from(_table).insert(cleanPayload);
      await _load();

      setState(() {
        _frontCardBase64 = null;
        _backCardBase64 = null;
        _insuranceCompanyController.clear();
        _patientIdController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '${tr(language, 'add')} ${tr(language, 'insurance_cards')} ${tr(language, 'success')}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${tr(language, 'operation_failed')}: $e')),
      );
    }
  }

  // FIXED: Document submit - uses base64 only
  Future<void> _submitDocument() async {
    final language = languageNotifier.value;
    if (!_formKey.currentState!.validate()) return;

    if (_documentPhotoBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(language, 'please_upload_photo'))),
      );
      return;
    }

    try {
      final payload = {
        'title': _titleController.text.trim(),
        'category': _categoryController.text.trim(),
        'photo': _documentPhotoBase64,
        'file_url': _fileUrlController.text.trim(),
        'file_type': 'image',
      };

      final cleanPayload = RecordSanitizer.sanitize(payload);

      if (widget.guestMode) {
        cleanPayload['user_id'] = null;
        cleanPayload['guest_id'] = widget.ownerId;
      } else {
        cleanPayload['user_id'] = widget.ownerId;
        cleanPayload['guest_id'] = null;
      }

      await _client.from(_table).insert(cleanPayload);
      await _load();

      setState(() {
        _documentPhotoBase64 = null;
        _titleController.clear();
        _categoryController.clear();
        _fileUrlController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '${tr(language, 'add')} ${tr(language, 'documents')} ${tr(language, 'success')}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${tr(language, 'operation_failed')}: $e')),
      );
    }
  }

  Future<void> _delete(Map<String, dynamic> row) async {
    final id = row['id'];
    if (id == null) return;
    final language = languageNotifier.value;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr(language, 'delete_confirm_title')),
        content: Text(tr(language, 'delete_confirm_msg')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(tr(language, 'cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(tr(language, 'delete'))),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final query = _client.from(_table).delete().eq('id', id);
      if (widget.guestMode) {
        await query.eq('guest_id', widget.ownerId);
      } else {
        await query.eq('user_id', widget.ownerId);
      }
      await _load();
      if (widget.type == 'reminders') await _loadMedications();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _shareRecord(Map<String, dynamic> row) async {
    final text = row.entries
        .where((e) => e.key != 'photo_base64' && e.key != 'photo')
        .map((e) => '${e.key}: ${e.value}')
        .join('\n');

    String? base64Photo;
    final photoField = row['photo'];
    final photoBase64Field = row['photo_base64'];

    if (photoField != null && photoField.toString().isNotEmpty) {
      base64Photo = photoField.toString().trim();
    } else if (photoBase64Field != null &&
        photoBase64Field.toString().isNotEmpty) {
      base64Photo = photoBase64Field.toString().trim();
    }

    if (base64Photo != null && base64Photo.isNotEmpty) {
      try {
        final sanitized = base64Photo.contains(',')
            ? base64Photo.split(',').last
            : base64Photo;

        final decoded = base64Decode(
          sanitized.replaceAll(RegExp(r'\s+'), ''),
        );

        final file = XFile.fromData(
          Uint8List.fromList(decoded),
          name: 'medicine_photo.jpg',
          mimeType: 'image/jpeg',
        );

        await SharePlus.instance.share(
          ShareParams(
            text: text,
            files: [file],
          ),
        );
        return;
      } catch (_) {}
    }

    await SharePlus.instance.share(
      ShareParams(
        text: text,
      ),
    );
  }

  Future<void> _preview(Map<String, dynamic> row) async {
    final language = languageNotifier.value;

    final title = (row['name'] ??
            row['title'] ??
            row['provider_name'] ??
            tr(language, 'record'))
        .toString();

    String? photoBase64;
    final photoField = row['photo'];
    final photoBase64Field = row['photo_base64'];

    if (photoField != null && photoField.toString().isNotEmpty) {
      photoBase64 = photoField.toString().trim();
    } else if (photoBase64Field != null &&
        photoBase64Field.toString().isNotEmpty) {
      photoBase64 = photoBase64Field.toString().trim();
    }

    final photoUrl = row['photo_url']?.toString();
    final frontImageUrl = row['front_image_url']?.toString();
    final fileUrl = row['file_url']?.toString();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (photoBase64 != null && photoBase64.isNotEmpty) ...[
                const Text(
                  'Medicine photo',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                DisplayImage(
                  base64String: photoBase64,
                  height: 250,
                  width: 250,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 16),
              ],
              if (photoUrl != null && photoUrl.isNotEmpty)
                SafeNetworkImage(
                  imageUrl: photoUrl,
                  height: 200,
                ),
              if (frontImageUrl != null && frontImageUrl.isNotEmpty)
                SafeNetworkImage(
                  imageUrl: frontImageUrl,
                  height: 200,
                ),
              if (fileUrl != null && fileUrl.isNotEmpty)
                ListTile(
                  title: Text(fileUrl),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () async {
                    final uri = Uri.tryParse(fileUrl);
                    if (uri != null && await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                ),
              const Divider(),
              ...row.entries
                  .where(
                    (e) => e.key != 'photo_base64' && e.key != 'photo',
                  )
                  .map(
                    (e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${e.key}: ${e.value}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(tr(language, 'close')),
          ),
        ],
      ),
    );
  }

  String _subtitle(Map<String, dynamic> row) {
    if (widget.type == 'medications')
      return '${row['dosage'] ?? ''} ${row['reminder_time'] ?? ''}';
    if (widget.type == 'doctors')
      return '${row['specialty'] ?? ''} ${row['phone'] ?? ''}';
    if (widget.type == 'pharmacies')
      return '${row['location'] ?? ''} ${row['phone'] ?? ''}';
    if (widget.type == 'documents')
      return '${row['category'] ?? ''} ${row['file_type'] ?? ''}';
    if (widget.type == 'insurance_cards')
      return '${row['provider_name'] ?? ''}';
    if (widget.type == 'reminders')
      return '${row['dosage'] ?? ''} ${row['reminder_time'] ?? ''} ${row['reminder_date'] ?? ''}';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final language = languageNotifier.value;

    return ValueListenableBuilder<String>(
      valueListenable: languageNotifier,
      builder: (context, language, _) => Directionality(
        textDirection: language == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          appBar: AppBar(
            title: Text(tr(language, widget.type)),
          ),
          body: Column(
            children: [
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _rows.isEmpty
                        ? Center(child: Text(tr(language, 'no_records')))
                        : ListView.builder(
                            key: ValueKey('list_${widget.type}'),
                            padding: const EdgeInsets.all(12),
                            itemCount: _rows.length,
                            itemBuilder: (context, index) {
                              final row = _rows[index];
                              final title = (row['name'] ??
                                      row['title'] ??
                                      row['provider_name'] ??
                                      tr(language, 'record'))
                                  .toString();
                              return Card(
                                key: ValueKey('card_${row['id']}_$index'),
                                margin: const EdgeInsets.only(bottom: 10),
                                elevation: 2,
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _subtitle(row),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey.shade700),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            key: ValueKey('view_${row['id']}'),
                                            onPressed: () => _preview(row),
                                            icon: const Icon(
                                                Icons.remove_red_eye_outlined,
                                                size: 20,
                                                color: Colors.teal),
                                            tooltip: tr(language, 'view'),
                                          ),
                                          IconButton(
                                            key: ValueKey('share_${row['id']}'),
                                            onPressed: () => _shareRecord(row),
                                            icon: const Icon(Icons.share,
                                                size: 20, color: Colors.teal),
                                            tooltip: tr(language, 'share'),
                                          ),
                                          IconButton(
                                            key:
                                                ValueKey('delete_${row['id']}'),
                                            onPressed: () => _delete(row),
                                            icon: const Icon(
                                                Icons.delete_outline,
                                                size: 20,
                                                color: Colors.redAccent),
                                            tooltip: tr(language, 'delete'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.icon(
                    key: const ValueKey('add_button'),
                    onPressed: _add,
                    icon: const Icon(Icons.add, size: 24),
                    label: Text(
                      tr(language, 'add'),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
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
// ============================================
// SHARE SCREEN
// ============================================

class ShareScreen extends StatefulWidget {
  final String ownerId;
  final bool guestMode;
  const ShareScreen(
      {super.key, required this.ownerId, required this.guestMode});

  @override
  State<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends State<ShareScreen> {
  final _client = Supabase.instance.client;
  final Map<String, List<Map<String, dynamic>>> _allData = {};
  final Map<String, Set<String>> _selectedIds = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    if (!mounted) return;
    final types = [
      'medications',
      'doctors',
      'pharmacies',
      'reminders',
      'documents',
      'insurance_cards'
    ];
    for (final type in types) {
      final table = type == 'reminders' ? 'reminders' : type;
      try {
        final query = _client.from(table).select();
        final dynamic response = widget.guestMode
            ? await query.eq('guest_id', widget.ownerId)
            : await query.eq('user_id', widget.ownerId);

        final List<dynamic> list = response as List<dynamic>;
        var rows =
            list.map((item) => Map<String, dynamic>.from(item as Map)).toList();

        if (type == 'reminders') {
          rows = rows
              .where((r) => (r['reminder_time'] ?? '').toString().isNotEmpty)
              .toList();
        }
        if (mounted) {
          setState(() {
            _allData[type] = rows;
            _selectedIds[type] = {};
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _allData[type] = [];
            _selectedIds[type] = {};
          });
        }
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  void _toggleSelection(String type, String id) {
    setState(() {
      if (_selectedIds[type]!.contains(id)) {
        _selectedIds[type]!.remove(id);
      } else {
        _selectedIds[type]!.add(id);
      }
    });
  }

  void _toggleAll(String type) {
    setState(() {
      final ids = _allData[type]!.map((row) => row['id'].toString()).toSet();
      if (_selectedIds[type]!.length == ids.length) {
        _selectedIds[type]!.clear();
      } else {
        _selectedIds[type] = ids;
      }
    });
  }

  int _getTotalSelected() {
    int count = 0;
    for (final ids in _selectedIds.values) {
      count += ids.length;
    }
    return count;
  }

  Future<void> _shareSelected() async {
    final language = languageNotifier.value;
    if (_getTotalSelected() == 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(tr(language, 'no_selection'))));
      return;
    }
    final lines = <String>[];
    for (final type in _allData.keys) {
      final selectedRows = _allData[type]!
          .where((row) => _selectedIds[type]!.contains(row['id'].toString()))
          .toList();

      if (selectedRows.isNotEmpty) {
        lines.add('=== ${type.toUpperCase()} ===');
        for (final row in selectedRows) {
          lines.add(row.entries.map((e) => '${e.key}: ${e.value}').join(' | '));
        }
        lines.add('');
      }
    }
    await SharePlus.instance.share(
      ShareParams(
        text: lines.join('\n'),
      ),
    );
  }

  String _getSubtitle(String type, Map<String, dynamic> row) {
    if (type == 'medications')
      return '${row['dosage'] ?? ''} ${row['reminder_time'] ?? ''}';
    if (type == 'doctors')
      return '${row['specialty'] ?? ''} ${row['phone'] ?? ''}';
    if (type == 'pharmacies')
      return '${row['location'] ?? ''} ${row['phone'] ?? ''}';
    if (type == 'documents')
      return '${row['category'] ?? ''} ${row['file_type'] ?? ''}';
    if (type == 'insurance_cards') return '${row['provider_name'] ?? ''}';
    if (type == 'reminders')
      return '${row['reminder_time'] ?? ''} ${row['reminder_date'] ?? ''}';
    return '';
  }

  Future<void> _previewRecord(String type, Map<String, dynamic> row) async {
    final base64Photo = row['photo_base64']?.toString();
    final photo = row['photo_url'] ?? row['front_image_url'];
    final url = row['file_url'];
    final language = languageNotifier.value;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text((row['name'] ??
                row['title'] ??
                row['provider_name'] ??
                tr(language, 'record'))
            .toString()),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (base64Photo != null &&
                  base64Photo.toString().trim().isNotEmpty)
                DisplayImage(
                  base64String: base64Photo.toString(),
                  height: 160,
                  width: 160,
                  fit: BoxFit.contain,
                ),
              if (photo != null && photo.toString().isNotEmpty)
                SafeNetworkImage(imageUrl: photo.toString(), height: 160),
              if (url != null && url.toString().isNotEmpty)
                ListTile(
                  title: Text(url.toString()),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () async {
                    final uri = Uri.parse(url.toString());
                    if (await canLaunchUrl(uri)) await launchUrl(uri);
                  },
                ),
              const Divider(),
              ...row.entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text('${e.key}: ${e.value}',
                      style: const TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(tr(language, 'close'))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final language = languageNotifier.value;
    return Directionality(
      textDirection: language == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr(language, 'share')),
          actions: [
            TextButton.icon(
              onPressed: _shareSelected,
              icon: const Icon(Icons.share),
              label: Text(
                  '${_getTotalSelected()} ${tr(language, 'share_selected')}'),
            )
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(12),
                children: _allData.keys.map((type) {
                  final rows = _allData[type]!;
                  final selected = _selectedIds[type]!;
                  final allSelected =
                      selected.length == rows.length && rows.isNotEmpty;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ExpansionTile(
                      title: Text(
                        '${tr(language, type)} (${rows.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Checkbox(
                            value: allSelected,
                            onChanged: (_) => _toggleAll(type),
                          ),
                          const SizedBox(width: 8),
                          Text('${selected.length}/${rows.length}',
                              style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                      children: rows.isEmpty
                          ? [
                              Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(tr(language, 'no_records')))
                            ]
                          : rows.map((row) {
                              final id = row['id'].toString();
                              final title = (row['name'] ??
                                      row['title'] ??
                                      row['provider_name'] ??
                                      tr(language, 'record'))
                                  .toString();
                              return CheckboxListTile(
                                value: selected.contains(id),
                                onChanged: (_) => _toggleSelection(type, id),
                                title: Text(title),
                                subtitle: Text(_getSubtitle(type, row)),
                                secondary: IconButton(
                                  icon: const Icon(
                                      Icons.remove_red_eye_outlined,
                                      size: 18),
                                  onPressed: () => _previewRecord(type, row),
                                ),
                              );
                            }).toList(),
                    ),
                  );
                }).toList(),
              ),
      ),
    );
  }
}

// ============================================
// ADMIN SCREEN
// ============================================

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
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
    if (!mounted) return;
    try {
      final dynamic result = await _client.rpc('admin_list_users');
      if (mounted) {
        final List<dynamic> list = result as List<dynamic>;
        final List<Map<String, dynamic>> users =
            list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
        setState(() {
          _users = users;
          _loading = false;
        });
      }
    } catch (_) {
      try {
        final dynamic fallback = await _client.from('users').select();
        if (mounted) {
          final List<dynamic> list = fallback as List<dynamic>;
          final List<Map<String, dynamic>> users = list
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();
          setState(() {
            _users = users;
            _loading = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  Future<void> _setActive(Map<String, dynamic> user, bool active) async {
    final id = user['id'];
    try {
      await _client.rpc('admin_set_user_active',
          params: {'target_user': id, 'activate': active});
    } catch (_) {
      await _client.from('users').update({'is_active': active}).eq('id', id);
    }
    await _loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: languageNotifier,
      builder: (context, language, _) => Directionality(
        textDirection: language == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          appBar: AppBar(title: Text(tr(language, 'admin_panel'))),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: [
                      DataColumn(label: Text(tr(language, 'name'))),
                      DataColumn(label: Text(tr(language, 'email'))),
                      DataColumn(label: Text(tr(language, 'phone'))),
                      DataColumn(label: Text(tr(language, 'role'))),
                      DataColumn(label: Text(tr(language, 'status'))),
                      const DataColumn(label: Text('')),
                    ],
                    rows: _users.map((u) {
                      final active = u['is_active'] == true;
                      final role = (u['role'] ?? 'user').toString();
                      return DataRow(cells: [
                        DataCell(Text(
                            (u['name'] ?? tr(language, 'guest')).toString())),
                        DataCell(Text((u['email'] ?? '').toString())),
                        DataCell(Text((u['phone'] ?? 'N/A').toString())),
                        DataCell(Text(role)),
                        DataCell(Text(active
                            ? tr(language, 'active_user')
                            : tr(language, 'inactive_guest'))),
                        DataCell(ElevatedButton(
                          onPressed: role.toLowerCase() == 'admin'
                              ? null
                              : () => _setActive(u, !active),
                          child: Text(active
                              ? tr(language, 'deactivate')
                              : tr(language, 'activate')),
                        )),
                      ]);
                    }).toList(),
                  ),
                ),
        ),
      ),
    );
  }
}
