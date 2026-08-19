import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/medication.dart';
import '../providers/language_provider.dart';
import '../providers/medication_provider.dart';

class MedicationDetailScreen extends StatelessWidget {
  final Medication medication;

  const MedicationDetailScreen({
    super.key,
    required this.medication,
  });

  String _repeatDescription(Medication medication, String code) {
    final repeat = medication.repeatType;

    if (repeat == 'Daily') {
      if (code == 'ar') return 'يومياً';
      if (code == 'es') return 'Diario';
      if (code == 'fr') return 'Quotidien';
      if (code == 'de') return 'Täglich';
      if (code == 'tr') return 'Günlük';
      if (code == 'hi') return 'दैनिक';
      if (code == 'zh') return '每天';
    }

    return repeat;
  }

  String _getPropString(
    Medication med,
    String prop, [
    String fallback = '',
  ]) {
    try {
      final val =
          (med as dynamic).toMap()[prop] ?? (med as dynamic).toJson()[prop];

      return val?.toString() ?? fallback;
    } catch (_) {
      return fallback;
    }
  }

  String getFormattedStatus(
    Medication medication,
    String code,
  ) {
    final status = _getPropString(
      medication,
      'status',
      'active',
    ).toLowerCase();

    if (status == 'taken') {
      if (code == 'ar') return 'تم التناول';
      if (code == 'es') return 'TOMADO';
      if (code == 'fr') return 'PRIS';
      if (code == 'de') return 'EINGENOMMEN';
      if (code == 'tr') return 'ALINDI';
      if (code == 'hi') return 'ली गई';
      if (code == 'zh') return '已服用';

      return 'TAKEN';
    } else if (status == 'not_taken') {
      if (code == 'ar') return 'لم يتم التناول';
      if (code == 'es') return 'NO TOMADO';
      if (code == 'fr') return 'NON PRIS';
      if (code == 'de') return 'NICHT EINGENOMMEN';
      if (code == 'tr') return 'ALINMADI';
      if (code == 'hi') return 'नहीं ली गई';
      if (code == 'zh') return '未服用';

      return 'NOT TAKEN';
    }

    if (code == 'ar') return 'نشط';
    if (code == 'es') return 'ACTIVO';
    if (code == 'fr') return 'ACTIF';
    if (code == 'de') return 'AKTIV';
    if (code == 'tr') return 'AKTİF';
    if (code == 'hi') return 'सक्रिय';
    if (code == 'zh') return '活跃';

    return 'ACTIVE';
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'taken':
        return Colors.green;
      case 'not_taken':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Widget _buildPhotoPreview(String photoUrl) {
    final cleanUrl = photoUrl.trim();

    if (cleanUrl.isEmpty) {
      return const SizedBox.shrink();
    }

    if (cleanUrl.startsWith('data:image')) {
      try {
        final UriData? data = Uri.parse(cleanUrl).data;

        if (data != null) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                data.contentAsBytes(),
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) {
                  return const Icon(
                    Icons.broken_image,
                    size: 80,
                  );
                },
              ),
            ),
          );
        }
      } catch (_) {}
    }

    if (cleanUrl.startsWith('http://') || cleanUrl.startsWith('https://')) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            cleanUrl,
            height: 220,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (ctx, err, stack) {
              return const Icon(
                Icons.broken_image,
                size: 80,
              );
            },
          ),
        ),
      );
    }

    try {
      final bytes = base64Decode(cleanUrl);

      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            bytes,
            height: 220,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (ctx, err, stack) {
              return const Icon(
                Icons.broken_image,
                size: 80,
              );
            },
          ),
        ),
      );
    } catch (_) {}

    return const SizedBox.shrink();
  }

  Future<void> _shareMedicationDetails(
    BuildContext context, {
    required String dosageLbl,
    required String qtyLbl,
    required String reminderLbl,
    required String repeatLbl,
    required String notesLbl,
  }) async {
    final String photoUrl = medication.photoUrl ??
        _getPropString(
          medication,
          'photoUrl',
        );

    final String description = _getPropString(
      medication,
      'description',
    );

    final String reminderText = medication.reminderTimes.isNotEmpty
        ? medication.reminderTimes.join(', ')
        : 'None';

    final StringBuffer textBuffer = StringBuffer();

    textBuffer.writeln(
      '📋 Medication Details: ${medication.name}',
    );

    textBuffer.writeln(
      '• $dosageLbl: ${medication.dosage}',
    );

    textBuffer.writeln(
      '• $qtyLbl: ${medication.quantity}',
    );

    textBuffer.writeln(
      '• $reminderLbl: $reminderText',
    );

    textBuffer.writeln(
      '• $repeatLbl: ${medication.repeatType}',
    );

    if (description.isNotEmpty) {
      textBuffer.writeln(
        '• $notesLbl: $description',
      );
    }

    final String textToShare = textBuffer.toString();

    try {
      final String cleanUrl = photoUrl.trim();

      XFile? imageXFile;

      if (cleanUrl.isNotEmpty) {
        Uint8List? imageBytes;

        if (cleanUrl.startsWith('data:image')) {
          try {
            final UriData? data = Uri.parse(cleanUrl).data;

            if (data != null) {
              imageBytes = data.contentAsBytes();
            }
          } catch (_) {
            imageBytes = null;
          }
        } else if (!cleanUrl.startsWith('http://') &&
            !cleanUrl.startsWith('https://')) {
          try {
            imageBytes = base64Decode(cleanUrl);
          } catch (_) {
            imageBytes = null;
          }
        }

        if (imageBytes != null && imageBytes.isNotEmpty) {
          imageXFile = XFile.fromData(
            imageBytes,
            mimeType: 'image/png',
            name: 'medication_share.png',
          );
        }
      }

      if (imageXFile != null) {
        await SharePlus.instance.share(ShareParams(
            files: [imageXFile], text: textToShare, subject: medication.name));
      } else {
        await SharePlus.instance
            .share(ShareParams(text: textToShare, subject: medication.name));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error sharing: $e',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = Provider.of<LanguageProvider>(context);

    final code = language.locale.languageCode;

    String deleteTitle = 'Delete Medication';
    String deleteConfirm = 'Are you sure you want to delete this medication?';
    String cancelLabel = 'Cancel';
    String deleteLabel = 'Delete';
    String dosageLbl = 'Dosage';
    String qtyLbl = 'Stock';
    String reminderLbl = 'Reminder Time';
    String repeatLbl = 'Repeat Pattern';
    String statusLbl = 'Status';
    String notesLbl = 'Notes / Description';
    String shareLbl = 'Share Medication';
    String activeStatusText = 'Active';

    if (code == 'ar') {
      deleteTitle = 'حذف الدواء';
      deleteConfirm = 'هل أنت تأكد من حذف هذا الدواء؟';
      cancelLabel = 'إلغاء';
      deleteLabel = 'حذف';
      dosageLbl = 'الجرعة';
      qtyLbl = 'المخزون';
      reminderLbl = 'وقت التذكير';
      repeatLbl = 'نمط التكرار';
      statusLbl = 'الحالة';
      notesLbl = 'ملاحظات / الوصف';
      shareLbl = 'مشاركة الدواء';
      activeStatusText = 'نشط';
    } else if (code == 'es') {
      deleteTitle = 'Eliminar Medicamento';
      deleteConfirm = '¿Estás seguro de eliminar este medicamento?';
      cancelLabel = 'Cancelar';
      deleteLabel = 'Eliminar';
      dosageLbl = 'Dosis';
      qtyLbl = 'Stock';
      reminderLbl = 'Hora de Recordatorio';
      repeatLbl = 'Patrón de Repetición';
      statusLbl = 'Estado';
      notesLbl = 'Notas / Descripción';
      shareLbl = 'Compartir Medicamento';
      activeStatusText = 'Activo';
    } else if (code == 'fr') {
      deleteTitle = 'Supprimer le Médicament';
      deleteConfirm = 'Voulez-vous vraiment supprimer ce médicament ?';
      cancelLabel = 'Annuler';
      deleteLabel = 'Supprimer';
      dosageLbl = 'Dosage';
      qtyLbl = 'Stock disponible';
      reminderLbl = 'Heure de Rappel';
      repeatLbl = 'Répétition';
      statusLbl = 'Statut';
      notesLbl = 'Notes / Description';
      shareLbl = 'Partager le médicament';
      activeStatusText = 'Actif';
    } else if (code == 'de') {
      deleteTitle = 'Medikament löschen';
      deleteConfirm = 'Möchten Sie dieses Medikament wirklich löschen?';
      cancelLabel = 'Abbrechen';
      deleteLabel = 'Löschen';
      dosageLbl = 'Dosierung';
      qtyLbl = 'Bestand';
      reminderLbl = 'Erinnerungszeit';
      repeatLbl = 'Wiederholung';
      statusLbl = 'Status';
      notesLbl = 'Hinweise / Beschreibung';
      shareLbl = 'Medikament teilen';
      activeStatusText = 'Aktiv';
    } else if (code == 'tr') {
      deleteTitle = 'İlacı Sil';
      deleteConfirm = 'Bu ilacı silmek istediğinizden emin misiniz?';
      cancelLabel = 'İptal';
      deleteLabel = 'Sil';
      dosageLbl = 'Doz';
      qtyLbl = 'Stok';
      reminderLbl = 'Hatırlatma Zamanı';
      repeatLbl = 'Tekrar Düzeni';
      statusLbl = 'Durum';
      notesLbl = 'Notlar / Açıklama';
      shareLbl = 'İlacı Paylaş';
      activeStatusText = 'Aktif';
    } else if (code == 'hi') {
      deleteTitle = 'दवा हटाएं';
      deleteConfirm = 'क्या आप वाकई इस दवा को हटाना चाहते हैं?';
      cancelLabel = 'रद्द करें';
      deleteLabel = 'हताएं';
      dosageLbl = 'खुराक';
      qtyLbl = 'स्टॉक';
      reminderLbl = 'अलार्म समय';
      repeatLbl = 'दोहराव पैटर्न';
      statusLbl = 'स्थिति';
      notesLbl = 'नोट्स / विवरण';
      shareLbl = 'दवा साझा करें';
      activeStatusText = 'सक्रिय';
    } else if (code == 'zh') {
      deleteTitle = '删除药物';
      deleteConfirm = '您确定要删除此药物吗？';
      cancelLabel = '取消';
      deleteLabel = '删除';
      dosageLbl = '剂量';
      qtyLbl = '库存';
      reminderLbl = '提醒时间';
      repeatLbl = '重复模式';
      statusLbl = '状态';
      notesLbl = '备注 / 描述';
      shareLbl = '分享药物';
      activeStatusText = '活跃';
    }

    final String photoUrl = medication.photoUrl ??
        _getPropString(
          medication,
          'photoUrl',
        );

    final String description = _getPropString(
      medication,
      'description',
    );

    final String statusText = _getPropString(
      medication,
      'medicationStatus',
      activeStatusText,
    );

    final String reminderText = medication.reminderTimes.isNotEmpty
        ? medication.reminderTimes.join(', ')
        : 'No reminder set';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          medication.name,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.delete,
              size: 28,
            ),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(
                    deleteTitle,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: Text(
                    deleteConfirm,
                    style: const TextStyle(
                      fontSize: 18,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: Text(
                        cancelLabel,
                        style: const TextStyle(
                          fontSize: 18,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: Text(
                        deleteLabel,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                if (context.mounted) {
                  try {
                    (Provider.of<MedicationProvider>(
                      context,
                      listen: false,
                    ) as dynamic)
                        .deleteMedication(
                      medication.id,
                    );
                  } catch (_) {}

                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPhotoPreview(photoUrl),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            medication.name,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              _getPropString(
                                medication,
                                'status',
                              ),
                            ).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(
                              16,
                            ),
                          ),
                          child: Text(
                            getFormattedStatus(
                              medication,
                              code,
                            ),
                            style: TextStyle(
                              fontSize: 16,
                              color: _getStatusColor(
                                _getPropString(
                                  medication,
                                  'status',
                                ),
                              ),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    ListTile(
                      leading: const Icon(
                        Icons.medical_services,
                        color: Colors.teal,
                        size: 30,
                      ),
                      title: Text(
                        dosageLbl,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        medication.dosage,
                        style: const TextStyle(
                          fontSize: 18,
                        ),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.inventory,
                        color: Colors.teal,
                        size: 30,
                      ),
                      title: Text(
                        qtyLbl,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '${medication.quantity}',
                        style: const TextStyle(
                          fontSize: 18,
                        ),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.access_time,
                        color: Colors.teal,
                        size: 30,
                      ),
                      title: Text(
                        reminderLbl,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        reminderText,
                        style: const TextStyle(
                          fontSize: 18,
                        ),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.repeat,
                        color: Colors.teal,
                        size: 30,
                      ),
                      title: Text(
                        repeatLbl,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        _repeatDescription(
                          medication,
                          code,
                        ),
                        style: const TextStyle(
                          fontSize: 18,
                        ),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.info_outline,
                        color: Colors.teal,
                        size: 30,
                      ),
                      title: Text(
                        statusLbl,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        statusText,
                        style: const TextStyle(
                          fontSize: 18,
                        ),
                      ),
                    ),
                    if (description.isNotEmpty) ...[
                      const Divider(height: 24),
                      Text(
                        notesLbl,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                  ),
                ),
                onPressed: () => _shareMedicationDetails(
                  context,
                  dosageLbl: dosageLbl,
                  qtyLbl: qtyLbl,
                  reminderLbl: reminderLbl,
                  repeatLbl: repeatLbl,
                  notesLbl: notesLbl,
                ),
                icon: const Icon(
                  Icons.share,
                  size: 28,
                ),
                label: Text(
                  shareLbl,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
