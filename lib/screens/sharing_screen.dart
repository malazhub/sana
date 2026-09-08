import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/insurance_card.dart';
import '../providers/document_provider.dart';
import '../providers/doctor_provider.dart';
import '../providers/insurance_provider.dart';
import '../providers/language_provider.dart';
import '../providers/medication_provider.dart';
import '../providers/pharmacy_provider.dart';
import '../services/sharing_service.dart';

class SharingScreen extends StatefulWidget {
  const SharingScreen({super.key});

  @override
  State<SharingScreen> createState() => _SharingScreenState();
}

class _SharingScreenState extends State<SharingScreen> {
  final Set<String> _selectedMedIds = {};
  final Set<String> _selectedDocIds = {};
  final Set<String> _selectedPharmIds = {};
  final Set<String> _selectedDocuIds = {};
  final Set<String> _selectedInsurIds = {};

  void _selectAll() {
    final medP = Provider.of<MedicationProvider>(
      context,
      listen: false,
    );
    final docP = Provider.of<DoctorProvider>(
      context,
      listen: false,
    );
    final pharmP = Provider.of<PharmacyProvider>(
      context,
      listen: false,
    );
    final docsP = Provider.of<DocumentProvider>(
      context,
      listen: false,
    );
    final insP = Provider.of<InsuranceProvider>(
      context,
      listen: false,
    );

    setState(() {
      _selectedMedIds.addAll(
        medP.medications.map((m) => m.id),
      );

      _selectedDocIds.addAll(
        docP.doctors.map((d) => d.id),
      );

      _selectedPharmIds.addAll(
        pharmP.pharmacies.map((p) => p.id),
      );

      _selectedDocuIds.addAll(
        docsP.documents.map((d) => d.id),
      );

      _selectedInsurIds.addAll(
        insP.cards.map((c) => c.id).whereType<String>(),
      );
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedMedIds.clear();
      _selectedDocIds.clear();
      _selectedPharmIds.clear();
      _selectedDocuIds.clear();
      _selectedInsurIds.clear();
    });
  }

  void _showEnlargedImage(
    Uint8List bytes,
    String title,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  bytes,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) {
                    return const Icon(
                      Icons.broken_image,
                      size: 80,
                    );
                  },
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  String _getInsPolicy(InsuranceCard card) {
    try {
      final dynamic dynamicCard = card;

      return dynamicCard.policyNumber?.toString() ??
          dynamicCard.cardNumber?.toString() ??
          dynamicCard.policyNo?.toString() ??
          'N/A';
    } catch (_) {
      return 'N/A';
    }
  }

  Map<String, dynamic> _toMapWithPhotos(dynamic item) {
    if (item == null) {
      return {};
    }

    if (item is Map<String, dynamic>) {
      return Map<String, dynamic>.from(item);
    }

    if (item is Map) {
      return Map<String, dynamic>.from(item);
    }

    try {
      final dynamic map = item.toMap();

      if (map is Map) {
        return Map<String, dynamic>.from(map);
      }
    } catch (_) {
      // Try JSON below.
    }

    try {
      final dynamic json = item.toJson();

      if (json is Map) {
        return Map<String, dynamic>.from(json);
      }
    } catch (_) {
      // Nothing else to convert.
    }

    return {};
  }

  Widget _buildItemPhotoWidget(
    Uint8List bytes,
    String title,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => _showEnlargedImage(
            bytes,
            title,
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  bytes,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return const SizedBox(
                      height: 140,
                      child: Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 60,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(
                      alpha: 0.7,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.zoom_in,
                        color: Colors.white,
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Tap to Enlarge',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Future<void> _shareRecord() async {
    final totalSelected = _selectedMedIds.length +
        _selectedDocIds.length +
        _selectedPharmIds.length +
        _selectedDocuIds.length +
        _selectedInsurIds.length;

    if (totalSelected == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select at least one item to share.',
          ),
        ),
      );
      return;
    }

    final medP = Provider.of<MedicationProvider>(
      context,
      listen: false,
    );

    final docP = Provider.of<DoctorProvider>(
      context,
      listen: false,
    );

    final pharmP = Provider.of<PharmacyProvider>(
      context,
      listen: false,
    );

    final docsP = Provider.of<DocumentProvider>(
      context,
      listen: false,
    );

    final insP = Provider.of<InsuranceProvider>(
      context,
      listen: false,
    );

    final selectedMedications = medP.medications
        .where(
          (m) => _selectedMedIds.contains(m.id),
        )
        .toList();

    final selectedDoctors = docP.doctors
        .where(
          (d) => _selectedDocIds.contains(d.id),
        )
        .toList();

    final selectedPharmacies = pharmP.pharmacies
        .where(
          (p) => _selectedPharmIds.contains(p.id),
        )
        .toList();

    final selectedDocuments = docsP.documents
        .where(
          (d) => _selectedDocuIds.contains(d.id),
        )
        .toList();

    final selectedInsurance = insP.cards
        .where(
          (c) => c.id != null && _selectedInsurIds.contains(c.id),
        )
        .toList();

    try {
      await SharingService.shareRecord(
        name: 'My Medical Record',
        medications: selectedMedications.map(_toMapWithPhotos).toList(),
        doctors: selectedDoctors.map(_toMapWithPhotos).toList(),
        pharmacies: selectedPharmacies.map(_toMapWithPhotos).toList(),
        documents: selectedDocuments.map(_toMapWithPhotos).toList(),
        insuranceCards: selectedInsurance.map(_toMapWithPhotos).toList(),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to share the selected records: $error',
          ),
        ),
      );

      return;
    }

    if (!mounted) {
      return;
    }

    _showSharePreview(
      selectedMedications,
      selectedDoctors,
      selectedPharmacies,
      selectedDocuments,
      selectedInsurance,
    );
  }

  void _showSharePreview(
    List<dynamic> medications,
    List<dynamic> doctors,
    List<dynamic> pharmacies,
    List<dynamic> documents,
    List<InsuranceCard> insuranceCards,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Share Preview'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (medications.isNotEmpty) ...[
                    const Text(
                      '💊 MEDICATIONS:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...medications.map(
                      (medication) {
                        final bytes = _getMedicationPhoto(
                          medication,
                        );

                        final name = _value(
                          medication,
                          'name',
                        );

                        final dosage = _value(
                          medication,
                          'dosage',
                        );

                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: 12,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '• $name'
                                '${dosage.isNotEmpty ? ' - Dosage: $dosage' : ''}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (bytes != null)
                                _buildItemPhotoWidget(
                                  bytes,
                                  'Medication: $name',
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                  if (doctors.isNotEmpty) ...[
                    const Divider(),
                    const Text(
                      '👨‍⚕️ DOCTORS:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...doctors.map(
                      (doctor) {
                        final name = _value(
                          doctor,
                          'name',
                        );

                        final specialty = _value(
                          doctor,
                          'specialty',
                        );

                        final phone = _value(
                          doctor,
                          'phone',
                        );

                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: 6,
                          ),
                          child: Text(
                            '• $name'
                            '${specialty.isNotEmpty ? ' ($specialty)' : ''}'
                            '${phone.isNotEmpty ? ' 📞 $phone' : ''}',
                          ),
                        );
                      },
                    ),
                  ],
                  if (pharmacies.isNotEmpty) ...[
                    const Divider(),
                    const Text(
                      '🏥 PHARMACIES:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...pharmacies.map(
                      (pharmacy) {
                        final name = _value(
                          pharmacy,
                          'name',
                        );

                        final address = _value(
                          pharmacy,
                          'address',
                        );

                        final phone = _value(
                          pharmacy,
                          'phone',
                        );

                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: 6,
                          ),
                          child: Text(
                            '• $name'
                            '${address.isNotEmpty ? ' 📍 $address' : ''}'
                            '${phone.isNotEmpty ? ' 📞 $phone' : ''}',
                          ),
                        );
                      },
                    ),
                  ],
                  if (documents.isNotEmpty) ...[
                    const Divider(),
                    const Text(
                      '📁 DOCUMENTS:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...documents.map(
                      (document) {
                        final name = _value(
                          document,
                          'name',
                        );

                        final fileType = _value(
                          document,
                          'fileType',
                        );

                        final bytes = _getDocumentBytes(
                          document,
                        );

                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: 12,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '• $name'
                                '${fileType.isNotEmpty ? ' (${fileType.toUpperCase()})' : ''}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (bytes != null)
                                _buildItemPhotoWidget(
                                  bytes,
                                  'Document: $name',
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                  if (insuranceCards.isNotEmpty) ...[
                    const Divider(),
                    const Text(
                      '💳 INSURANCE:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...insuranceCards.map(
                      (card) => Padding(
                        padding: const EdgeInsets.only(
                          bottom: 6,
                        ),
                        child: Text(
                          '• ${card.providerName}'
                          ' - Policy: ${_getInsPolicy(card)}',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  String _value(
    dynamic item,
    String key,
  ) {
    if (item == null) {
      return '';
    }

    if (item is Map) {
      return item[key]?.toString() ?? '';
    }

    try {
      switch (key) {
        case 'name':
          return item.name?.toString() ?? '';

        case 'dosage':
          return item.dosage?.toString() ?? '';

        case 'specialty':
          return item.specialty?.toString() ?? '';

        case 'phone':
          return item.phone?.toString() ?? '';

        case 'address':
          return item.address?.toString() ?? '';

        case 'fileType':
          return item.fileType?.toString() ?? '';

        case 'photoUrl':
          return item.photoUrl?.toString() ?? '';

        default:
          return '';
      }
    } catch (_) {
      return '';
    }
  }

  Uint8List? _getMedicationPhoto(
    dynamic medication,
  ) {
    final photoUrl = _value(
      medication,
      'photoUrl',
    ).trim();

    if (photoUrl.isEmpty) {
      return null;
    }

    if (!photoUrl.startsWith('data:image')) {
      return null;
    }

    try {
      final UriData? data = Uri.parse(photoUrl).data;

      if (data == null) {
        return null;
      }

      final bytes = data.contentAsBytes();

      if (bytes.isEmpty) {
        return null;
      }

      return bytes;
    } catch (_) {
      return null;
    }
  }

  Uint8List? _getDocumentBytes(
    dynamic document,
  ) {
    try {
      final dynamic value = document.bytes;

      if (value is Uint8List && value.isNotEmpty) {
        return value;
      }

      if (value is List<int> && value.isNotEmpty) {
        return Uint8List.fromList(value);
      }
    } catch (_) {
      // No document bytes available.
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final language = Provider.of<LanguageProvider>(context);

    final code = language.locale.languageCode;

    final medP = Provider.of<MedicationProvider>(context);

    final docP = Provider.of<DoctorProvider>(context);

    final pharmP = Provider.of<PharmacyProvider>(context);

    final docsP = Provider.of<DocumentProvider>(context);

    final insP = Provider.of<InsuranceProvider>(context);

    String title = 'Share Records';

    String subTitle = 'Select specific items to include in your shared record:';

    String shareBtn = 'Share Selected Items';

    String selectAllBtn = 'Select All';

    String deselectAllBtn = 'Deselect All';

    String medsCategory = 'Medications';

    String docsCategory = 'Doctors';

    String pharmsCategory = 'Pharmacies';

    String docusCategory = 'Medical Documents';

    String insuranceCategory = 'Insurance Cards';

    if (code == 'ar') {
      title = 'مشاركة السجلات';
      subTitle = 'حدد العناصر التي تريد تضمينها في تقريرك:';
      shareBtn = 'مشاركة العناصر المحددة';
      selectAllBtn = 'تحديد الكل';
      deselectAllBtn = 'إلغاء تحديد الكل';
      medsCategory = 'الأدوية';
      docsCategory = 'الأطباء';
      pharmsCategory = 'الصيدليات';
      docusCategory = 'المستندات الطبية';
      insuranceCategory = 'بطاقات التأمين';
    } else if (code == 'es') {
      title = 'Compartir Registros';
      subTitle = 'Selecciona elementos específicos para compartir:';
      shareBtn = 'Compartir Seleccionados';
      selectAllBtn = 'Seleccionar Todo';
      deselectAllBtn = 'Desmarcar Todo';
      medsCategory = 'Medicamentos';
      docsCategory = 'Médicos';
      pharmsCategory = 'Farmacias';
      docusCategory = 'Documentos Médicos';
      insuranceCategory = 'Tarjetas de Seguro';
    } else if (code == 'fr') {
      title = 'Partager les Dossiers';
      subTitle = 'Sélectionnez les éléments à inclure dans votre rapport:';
      shareBtn = 'Partager la Sélection';
      selectAllBtn = 'Tout Sélectionner';
      deselectAllBtn = 'Tout Déselectionner';
      medsCategory = 'Médicaments';
      docsCategory = 'Médecins';
      pharmsCategory = 'Pharmacies';
      docusCategory = 'Documents Médicaux';
      insuranceCategory = 'Cartes d’Assurance';
    } else if (code == 'de') {
      title = 'Teilen';
      subTitle = 'Wählen Sie die zu teilenden Elemente aus:';
      shareBtn = 'Ausgewählte Elemente Teilen';
      selectAllBtn = 'Alle Auswählen';
      deselectAllBtn = 'Alle Abwählen';
      medsCategory = 'Medikamente';
      docsCategory = 'Ärzte';
      pharmsCategory = 'Apotheken';
      docusCategory = 'Dokumente';
      insuranceCategory = 'Versicherungskarten';
    } else if (code == 'tr') {
      title = 'Paylaş';
      subTitle = 'Paylaşılacak öğeleri seçin:';
      shareBtn = 'Seçilen Öğeleri Paylaş';
      selectAllBtn = 'Tümünü Seç';
      deselectAllBtn = 'Tümünü Kaldır';
      medsCategory = 'İlaçlar';
      docsCategory = 'Doktorlar';
      pharmsCategory = 'Eczaneler';
      docusCategory = 'Belgeler';
      insuranceCategory = 'Sigorta Kartları';
    } else if (code == 'hi') {
      title = 'साझा करें';
      subTitle = 'साझा करने के लिए आइटम चुनें:';
      shareBtn = 'चयनित आइटम साझा करें';
      selectAllBtn = 'सभी चुनें';
      deselectAllBtn = 'सभी हटाएं';
      medsCategory = 'दवाइयाँ';
      docsCategory = 'डॉक्टर';
      pharmsCategory = 'फार्मेसी';
      docusCategory = 'दस्तावेज़';
      insuranceCategory = 'बीमा कार्ड';
    } else if (code == 'zh') {
      title = '分享记录';
      subTitle = '选择要包含在分享报告中的项目:';
      shareBtn = '分享选定项目';
      selectAllBtn = '全选';
      deselectAllBtn = '取消全选';
      medsCategory = '药物';
      docsCategory = '医生';
      pharmsCategory = '药房';
      docusCategory = '医疗文档';
      insuranceCategory = '保险卡';
    }

    final insuranceCards = insP.cards;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subTitle,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _selectAll,
                  child: Text(
                    selectAllBtn,
                    style: const TextStyle(
                      color: Colors.teal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _deselectAll,
                  child: Text(
                    deselectAllBtn,
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // MEDICATIONS
            ExpansionTile(
              leading: const Icon(
                Icons.medication,
                color: Colors.blue,
              ),
              title: Text(
                '$medsCategory '
                '(${_selectedMedIds.length}/'
                '${medP.medications.length})',
              ),
              children: medP.medications.isEmpty
                  ? const [
                      ListTile(
                        title: Text(
                          'No medications available',
                        ),
                      ),
                    ]
                  : medP.medications
                      .map(
                        (medication) => CheckboxListTile(
                          secondary: const Icon(
                            Icons.photo_library,
                            color: Colors.blue,
                          ),
                          title: Text(
                            medication.name,
                          ),
                          subtitle: Text(
                            'Dosage: ${medication.dosage}',
                          ),
                          value: _selectedMedIds.contains(
                            medication.id,
                          ),
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedMedIds.add(
                                  medication.id,
                                );
                              } else {
                                _selectedMedIds.remove(
                                  medication.id,
                                );
                              }
                            });
                          },
                        ),
                      )
                      .toList(),
            ),

            // DOCTORS
            ExpansionTile(
              leading: const Icon(
                Icons.person,
                color: Colors.green,
              ),
              title: Text(
                '$docsCategory '
                '(${_selectedDocIds.length}/'
                '${docP.doctors.length})',
              ),
              children: docP.doctors.isEmpty
                  ? const [
                      ListTile(
                        title: Text(
                          'No doctors available',
                        ),
                      ),
                    ]
                  : docP.doctors
                      .map(
                        (doctor) => CheckboxListTile(
                          title: Text(
                            doctor.name,
                          ),
                          subtitle: Text(
                            doctor.specialty ?? 'General',
                          ),
                          value: _selectedDocIds.contains(
                            doctor.id,
                          ),
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedDocIds.add(
                                  doctor.id,
                                );
                              } else {
                                _selectedDocIds.remove(
                                  doctor.id,
                                );
                              }
                            });
                          },
                        ),
                      )
                      .toList(),
            ),

            // PHARMACIES
            ExpansionTile(
              leading: const Icon(
                Icons.local_pharmacy,
                color: Colors.orange,
              ),
              title: Text(
                '$pharmsCategory '
                '(${_selectedPharmIds.length}/'
                '${pharmP.pharmacies.length})',
              ),
              children: pharmP.pharmacies.isEmpty
                  ? const [
                      ListTile(
                        title: Text(
                          'No pharmacies available',
                        ),
                      ),
                    ]
                  : pharmP.pharmacies
                      .map(
                        (pharmacy) => CheckboxListTile(
                          title: Text(
                            pharmacy.name,
                          ),
                          subtitle: Text(
                            pharmacy.address ?? 'Address N/A',
                          ),
                          value: _selectedPharmIds.contains(
                            pharmacy.id,
                          ),
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedPharmIds.add(
                                  pharmacy.id,
                                );
                              } else {
                                _selectedPharmIds.remove(
                                  pharmacy.id,
                                );
                              }
                            });
                          },
                        ),
                      )
                      .toList(),
            ),

            // DOCUMENTS
            ExpansionTile(
              leading: const Icon(
                Icons.folder,
                color: Colors.purple,
              ),
              title: Text(
                '$docusCategory '
                '(${_selectedDocuIds.length}/'
                '${docsP.documents.length})',
              ),
              children: docsP.documents.isEmpty
                  ? const [
                      ListTile(
                        title: Text(
                          'No documents available',
                        ),
                      ),
                    ]
                  : docsP.documents
                      .map(
                        (document) => CheckboxListTile(
                          secondary: const Icon(
                            Icons.file_present,
                            color: Colors.purple,
                          ),
                          title: Text(
                            document.name,
                          ),
                          subtitle: Text(
                            document.fileType.toUpperCase(),
                          ),
                          value: _selectedDocuIds.contains(
                            document.id,
                          ),
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedDocuIds.add(
                                  document.id,
                                );
                              } else {
                                _selectedDocuIds.remove(
                                  document.id,
                                );
                              }
                            });
                          },
                        ),
                      )
                      .toList(),
            ),

            // INSURANCE
            if (insuranceCards.isNotEmpty)
              ExpansionTile(
                leading: const Icon(
                  Icons.credit_card,
                  color: Colors.indigo,
                ),
                title: Text(
                  '$insuranceCategory '
                  '(${_selectedInsurIds.length}/'
                  '${insuranceCards.length})',
                ),
                children: insuranceCards.map(
                  (card) {
                    final String? cardId = card.id;

                    if (cardId == null || cardId.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return CheckboxListTile(
                      secondary: const Icon(
                        Icons.image,
                        color: Colors.indigo,
                      ),
                      title: Text(
                        card.providerName,
                      ),
                      subtitle: Text(
                        'Policy: '
                        '${_getInsPolicy(card)}',
                      ),
                      value: _selectedInsurIds.contains(
                        cardId,
                      ),
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedInsurIds.add(
                              cardId,
                            );
                          } else {
                            _selectedInsurIds.remove(
                              cardId,
                            );
                          }
                        });
                      },
                    );
                  },
                ).toList(),
              ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _shareRecord,
                icon: const Icon(
                  Icons.share,
                ),
                label: Text(
                  shareBtn,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
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
