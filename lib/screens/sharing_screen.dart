import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final medP = Provider.of<MedicationProvider>(context, listen: false);
    final docP = Provider.of<DoctorProvider>(context, listen: false);
    final pharmP = Provider.of<PharmacyProvider>(context, listen: false);
    final docsP = Provider.of<DocumentProvider>(context, listen: false);

    setState(() {
      _selectedMedIds.addAll(medP.medications.map((m) => m.id));
      _selectedDocIds.addAll(docP.doctors.map((d) => d.id));
      _selectedPharmIds.addAll(pharmP.pharmacies.map((p) => p.id));
      _selectedDocuIds.addAll(docsP.documents.map((d) => d.id));

      try {
        final insP = Provider.of<InsuranceProvider>(context, listen: false);
        _selectedInsurIds.addAll(insP.cards.map((c) => c.id).whereType<String>());
      } catch (_) {}
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

  void _showEnlargedImage(Uint8List bytes, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: SizedBox(
          width: double.maxFinite,
          child: InteractiveViewer(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(bytes, fit: BoxFit.contain),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _getInsPolicy(InsuranceCard c) {
    try {
      final dyn = c as dynamic;
      return dyn.policyNumber?.toString() ??
          dyn.cardNumber?.toString() ??
          dyn.policyNo?.toString() ??
          'N/A';
    } catch (_) {
      return 'N/A';
    }
  }

  Map<String, dynamic> _toMapWithPhotos(dynamic item) {
    if (item == null) return {};
    if (item is Map<String, dynamic>) return Map.from(item);
    if (item is Map) return Map<String, dynamic>.from(item);
    try {
      return Map<String, dynamic>.from((item as dynamic).toMap());
    } catch (_) {
      try {
        return Map<String, dynamic>.from((item as dynamic).toJson());
      } catch (_) {
        return {};
      }
    }
  }

  Widget _buildItemPhotoWidget(Uint8List bytes, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => _showEnlargedImage(bytes, title),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  bytes,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.zoom_in, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text('Tap to Enlarge', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
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

  void _shareRecord() {
    final totalSelected = _selectedMedIds.length +
        _selectedDocIds.length +
        _selectedPharmIds.length +
        _selectedDocuIds.length +
        _selectedInsurIds.length;

    if (totalSelected == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one item to share.')),
      );
      return;
    }

    final medP = Provider.of<MedicationProvider>(context, listen: false);
    final docP = Provider.of<DoctorProvider>(context, listen: false);
    final pharmP = Provider.of<PharmacyProvider>(context, listen: false);
    final docsP = Provider.of<DocumentProvider>(context, listen: false);

    final selMeds = medP.medications.where((m) => _selectedMedIds.contains(m.id)).toList();
    final selDocs = docP.doctors.where((d) => _selectedDocIds.contains(d.id)).toList();
    final selPharms = pharmP.pharmacies.where((p) => _selectedPharmIds.contains(p.id)).toList();
    final selDocus = docsP.documents.where((d) => _selectedDocuIds.contains(d.id)).toList();

    List<InsuranceCard> selIns = [];
    try {
      final insP = Provider.of<InsuranceProvider>(context, listen: false);
      selIns = insP.cards.where((c) => c.id != null && _selectedInsurIds.contains(c.id)).toList();
    } catch (_) {}

    // System share execution
    SharingService.shareMedications(
      name: 'My Medical Record',
      medications: selMeds.map((m) => _toMapWithPhotos(m)).toList(),
      doctors: selDocs.map((d) => _toMapWithPhotos(d)).toList(),
      pharmacies: selPharms.map((p) => _toMapWithPhotos(p)).toList(),
      history: medP.logs.map((l) => _toMapWithPhotos(l)).toList(),
      documents: selDocus.map((d) => _toMapWithPhotos(d)).toList(),
      insuranceCards: selIns.map((c) => _toMapWithPhotos(c)).toList(),
    );

    // Show Preview Modal formatted Text + Photo under each item
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Share Preview (Text + Related Photos)'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selMeds.isNotEmpty) ...[
                  const Text('💊 MEDICATIONS:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
                  const SizedBox(height: 6),
                  ...selMeds.map((m) {
                    Uint8List? bytes;
                    if (m.photoUrl != null && m.photoUrl!.startsWith('data:image')) {
                      try {
                        bytes = Uri.parse(m.photoUrl!).data?.contentAsBytes();
                      } catch (_) {}
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• ${m.name} - Dosage: ${m.dosage} (${m.repeatType})', style: const TextStyle(fontWeight: FontWeight.w600)),
                          if (bytes != null) _buildItemPhotoWidget(bytes, 'Medication: ${m.name}'),
                        ],
                      ),
                    );
                  }),
                ],
                if (selDocs.isNotEmpty) ...[
                  const Divider(),
                  const Text('👨‍⚕️ DOCTORS:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                  const SizedBox(height: 6),
                  ...selDocs.map((d) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Text('• ${d.name} ${d.specialty != null && d.specialty!.isNotEmpty ? "(${d.specialty})" : ""} ${d.phone != null && d.phone!.isNotEmpty ? "📞 ${d.phone}" : ""}'),
                    );
                  }),
                ],
                if (selPharms.isNotEmpty) ...[
                  const Divider(),
                  const Text('🏥 PHARMACIES:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange)),
                  const SizedBox(height: 6),
                  ...selPharms.map((p) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Text('• ${p.name} ${p.address != null && p.address!.isNotEmpty ? "📍 ${p.address}" : ""} ${p.phone != null && p.phone!.isNotEmpty ? "📞 ${p.phone}" : ""}'),
                    );
                  }),
                ],
                if (selDocus.isNotEmpty) ...[
                  const Divider(),
                  const Text('📁 MEDICAL DOCUMENTS:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.purple)),
                  const SizedBox(height: 6),
                  ...selDocus.map((d) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• ${d.name} (${d.fileType.toUpperCase()})', style: const TextStyle(fontWeight: FontWeight.w600)),
                          if (d.bytes != null && d.bytes!.isNotEmpty) _buildItemPhotoWidget(d.bytes!, 'Document: ${d.name}'),
                        ],
                      ),
                    );
                  }),
                ],
                if (selIns.isNotEmpty) ...[
                  const Divider(),
                  const Text('💳 INSURANCE CARDS:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.indigo)),
                  const SizedBox(height: 6),
                  ...selIns.map((c) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Text('• ${c.providerName} - Policy: ${_getInsPolicy(c)}'),
                    );
                  }),
                ],
              ],
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final language = Provider.of<LanguageProvider>(context);
    final code = language.locale.languageCode;

    final medP = Provider.of<MedicationProvider>(context);
    final docP = Provider.of<DoctorProvider>(context);
    final pharmP = Provider.of<PharmacyProvider>(context);
    final docsP = Provider.of<DocumentProvider>(context);

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
      insuranceCategory = 'Cartes d\'Assurance';
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

    List<InsuranceCard> insCards = [];
    try {
      final insP = Provider.of<InsuranceProvider>(context);
      insCards = insP.cards;
    } catch (_) {}

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subTitle,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Select All / Deselect All Toolbar
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _selectAll,
                  child: Text(selectAllBtn, style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                ),
                TextButton(
                  onPressed: _deselectAll,
                  child: Text(deselectAllBtn, style: const TextStyle(color: Colors.grey)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Medications Expansion
            ExpansionTile(
              leading: const Icon(Icons.medication, color: Colors.blue),
              title: Text('$medsCategory (${_selectedMedIds.length}/${medP.medications.length})'),
              children: medP.medications.isEmpty
                  ? [const ListTile(title: Text('No medications available'))]
                  : medP.medications.map((m) {
                      return CheckboxListTile(
                        secondary: const Icon(Icons.photo_library, color: Colors.blue),
                        title: Text(m.name),
                        subtitle: Text('Dosage: ${m.dosage}'),
                        value: _selectedMedIds.contains(m.id),
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedMedIds.add(m.id);
                            } else {
                              _selectedMedIds.remove(m.id);
                            }
                          });
                        },
                      );
                    }).toList(),
            ),

            // Doctors Expansion
            ExpansionTile(
              leading: const Icon(Icons.person, color: Colors.green),
              title: Text('$docsCategory (${_selectedDocIds.length}/${docP.doctors.length})'),
              children: docP.doctors.isEmpty
                  ? [const ListTile(title: Text('No doctors available'))]
                  : docP.doctors.map((d) {
                      return CheckboxListTile(
                        title: Text(d.name),
                        subtitle: Text(d.specialty ?? 'General'),
                        value: _selectedDocIds.contains(d.id),
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedDocIds.add(d.id);
                            } else {
                              _selectedDocIds.remove(d.id);
                            }
                          });
                        },
                      );
                    }).toList(),
            ),

            // Pharmacies Expansion
            ExpansionTile(
              leading: const Icon(Icons.local_pharmacy, color: Colors.orange),
              title: Text('$pharmsCategory (${_selectedPharmIds.length}/${pharmP.pharmacies.length})'),
              children: pharmP.pharmacies.isEmpty
                  ? [const ListTile(title: Text('No pharmacies available'))]
                  : pharmP.pharmacies.map((p) {
                      return CheckboxListTile(
                        title: Text(p.name),
                        subtitle: Text(p.address ?? 'Address N/A'),
                        value: _selectedPharmIds.contains(p.id),
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedPharmIds.add(p.id);
                            } else {
                              _selectedPharmIds.remove(p.id);
                            }
                          });
                        },
                      );
                    }).toList(),
            ),

            // Documents Expansion
            ExpansionTile(
              leading: const Icon(Icons.folder, color: Colors.purple),
              title: Text('$docusCategory (${_selectedDocuIds.length}/${docsP.documents.length})'),
              children: docsP.documents.isEmpty
                  ? [const ListTile(title: Text('No documents available'))]
                  : docsP.documents.map((d) {
                      return CheckboxListTile(
                        secondary: const Icon(Icons.file_present, color: Colors.purple),
                        title: Text(d.name),
                        subtitle: Text(d.fileType.toUpperCase()),
                        value: _selectedDocuIds.contains(d.id),
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedDocuIds.add(d.id);
                            } else {
                              _selectedDocuIds.remove(d.id);
                            }
                          });
                        },
                      );
                    }).toList(),
            ),

            // Insurance Cards Expansion
            if (insCards.isNotEmpty)
              ExpansionTile(
                leading: const Icon(Icons.credit_card, color: Colors.indigo),
                title: Text('$insuranceCategory (${_selectedInsurIds.length}/${insCards.length})'),
                children: insCards.map((c) {
                  final cardId = c.id;
                  if (cardId == null) return const SizedBox();
                  return CheckboxListTile(
                    secondary: const Icon(Icons.image, color: Colors.indigo),
                    title: Text(c.providerName),
                    subtitle: Text('Policy: ${_getInsPolicy(c)}'),
                    value: _selectedInsurIds.contains(cardId),
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedInsurIds.add(cardId);
                        } else {
                          _selectedInsurIds.remove(cardId);
                        }
                      });
                    },
                  );
                }).toList(),
              ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _shareRecord,
                icon: const Icon(Icons.share),
                label: Text(
                  shareBtn,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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