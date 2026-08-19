import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/medication.dart';
import '../providers/language_provider.dart';
import '../providers/medication_provider.dart';
String notesLbl = 'Notes / Description';

class MedicationDetailScreen extends StatelessWidget {
  final Medication medication;

  const MedicationDetailScreen({super.key, required this.medication});

  @override
  Widget build(BuildContext context) {
    final language = Provider.of<LanguageProvider>(context);
    final code = language.locale.languageCode;

    String title = 'Medication Details';
    String dosageLbl = 'Dosage';
    String qtyLbl = 'Stock';
    String timesLbl = 'Reminder Times';
    String repeatLbl = 'Repeat Type';
    //String notesLbl = 'Notes';
    String deleteBtn = 'Delete Medication';
    String shareBtn = 'Share Details';

    if (code == 'ar') {
      // ...
      notesLbl = 'ملاحظات / الوصف';
    } else if (code == 'es') {
      // ...
      notesLbl = 'Notas / Descripción';
    } else if (code == 'fr') {
      // ...
      notesLbl = 'Notes / Description';
    } else if (code == 'de') {
      // ...
      notesLbl = 'Hinweise / Beschreibung';
    } else if (code == 'tr') {
      // ...
      notesLbl = 'Notlar / Açıklama';
    } else if (code == 'hi') {
      // ...
      notesLbl = 'नोट्स / विवरण';
    } else if (code == 'zh') {
      // ...
      notesLbl = '备注 / 描述';
    }
    Widget imageWidget;
    if (medication.photoUrl != null && medication.photoUrl!.startsWith('data:image')) {
      try {
        final base64Str = medication.photoUrl!.split(',').last;
        final bytes = base64Decode(base64Str);
        imageWidget = ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(bytes, width: double.infinity, height: 200, fit: BoxFit.cover));
      } catch (_) {
        imageWidget = Container(width: double.infinity, height: 150, decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.medication, size: 80, color: Colors.blue));
      }
    } else {
      imageWidget = Container(width: double.infinity, height: 150, decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.medication, size: 80, color: Colors.blue));
    }

    final shareText = 'SANA Medical Record\nMedication: ${medication.name}\nDosage: ${medication.dosage}\nStock: ${medication.quantity}\nReminders: ${medication.reminderTimes.join(', ')}\nRepeat: ${medication.repeatType}';

    return Scaffold(
      appBar: AppBar(title: Text(title), backgroundColor: Colors.teal, foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            imageWidget,
            const SizedBox(height: 20),
            Text(medication.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal)),
            const Divider(height: 30),
            _buildDetailTile(Icons.medical_information, dosageLbl, medication.dosage),
            _buildDetailTile(Icons.numbers, qtyLbl, medication.quantity.toString()),
            _buildDetailTile(Icons.access_time, timesLbl, medication.reminderTimes.isEmpty ? 'N/A' : medication.reminderTimes.join(', ')),
            _buildDetailTile(Icons.repeat, repeatLbl, medication.repeatType),
            const SizedBox(height: 30),
            
            SizedBox(
              width: double.infinity, height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                icon: const Icon(Icons.share),
                label: Text(shareBtn, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: () {
                  SharePlus.instance.share(ShareParams(text: shareText));
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity, height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                icon: const Icon(Icons.delete),
                label: Text(deleteBtn, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: () {
                  Provider.of<MedicationProvider>(context, listen: false).deleteMedication(medication.id);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.teal, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}