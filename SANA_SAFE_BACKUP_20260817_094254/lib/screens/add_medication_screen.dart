import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/medication.dart';
import '../providers/language_provider.dart';
import '../providers/medication_provider.dart';

class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');

  DateTime _selectedDate = DateTime.now();
  String _repeatChoice = 'Daily'; // 'Daily' or 'Select Date'
  final List<String> _selectedTimes = ['8:00 AM'];

  Uint8List? _photoBytes;
  String? _photoName;

  static const List<String> _hourlyTimes = [
    '12:00 AM',
    '1:00 AM',
    '2:00 AM',
    '3:00 AM',
    '4:00 AM',
    '5:00 AM',
    '6:00 AM',
    '7:00 AM',
    '8:00 AM',
    '9:00 AM',
    '10:00 AM',
    '11:00 AM',
    '12:00 PM',
    '1:00 PM',
    '2:00 PM',
    '3:00 PM',
    '4:00 PM',
    '5:00 PM',
    '6:00 PM',
    '7:00 PM',
    '8:00 PM',
    '9:00 PM',
    '10:00 PM',
    '11:00 PM',
  ];

  Future<void> _pickPhoto() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;
        if (file.bytes != null) {
          setState(() {
            _photoBytes = file.bytes;
            _photoName = file.name;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not pick photo: $e')),
      );
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
        _repeatChoice = 'Select Date';
      });
    }
  }

  void _saveMedication() {
    if (_formKey.currentState!.validate()) {
      if (_selectedTimes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please select at least one reminder time.')),
        );
        return;
      }

      final String repeatVal = _repeatChoice == 'Select Date'
          ? 'Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'
          : 'Daily';

      final String photoDataUrl = _photoBytes != null
          ? Uri.dataFromBytes(_photoBytes!, mimeType: 'image/png').toString()
          : '';

      final newMed = Medication(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        dosage: _dosageController.text.trim(),
        quantity: int.tryParse(_quantityController.text.trim()) ?? 1,
        reminderTimes: List.from(_selectedTimes),
        repeatType: repeatVal,
        photoUrl: photoDataUrl,
      );

      Provider.of<MedicationProvider>(context, listen: false)
          .addMedication(newMed);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = Provider.of<LanguageProvider>(context);
    final code = language.locale.languageCode;

    String title = 'Add Medication';
    String nameLabel = 'Medication Name *';
    String dosageLabel = 'Dosage (e.g. 500mg) *';
    String qtyLabel = 'Quantity *';
    String repeatLabel = 'Repeat Pattern';
    String dailyOpt = 'Daily';
    String dateOpt = 'Select Date';
    String timesLabel = 'Select Reminder Times';
    String photoBtn = 'Add Medicine Photo';
    String saveBtn = 'Save Medication';

    if (code == 'ar') {
      title = 'إضافة دواء';
      nameLabel = 'اسم الدواء *';
      dosageLabel = 'الجرعة (مثال 500 ملجم) *';
      qtyLabel = 'الكمية *';
      repeatLabel = 'نمط التكرار';
      dailyOpt = 'يومياً';
      dateOpt = 'تحديد التاريخ';
      timesLabel = 'اختر أوقات التذكير';
      photoBtn = 'إضافة صورة الدواء';
      saveBtn = 'حفظ الدواء';
    } else if (code == 'es') {
      title = 'Añadir Medicamento';
      nameLabel = 'Nombre del Medicamento *';
      dosageLabel = 'Dosis (ej. 500mg) *';
      qtyLabel = 'Cantidad *';
      repeatLabel = 'Patrón de Repetición';
      dailyOpt = 'Diario';
      dateOpt = 'Seleccionar Fecha';
      timesLabel = 'Seleccionar Horarios';
      photoBtn = 'Añadir Foto del Medicamento';
      saveBtn = 'Guardar Medicamento';
    } else if (code == 'fr') {
      title = 'Ajouter un Médicament';
      nameLabel = 'Nom du Médicament *';
      dosageLabel = 'Dosage (ex. 500mg) *';
      qtyLabel = 'Quantité *';
      repeatLabel = 'Répétition';
      dailyOpt = 'Quotidien';
      dateOpt = 'Sélectionner une Date';
      timesLabel = 'Horaires de Rappel';
      photoBtn = 'Ajouter Photo du Médicament';
      saveBtn = 'Enregistrer';
    } else if (code == 'de') {
      title = 'Medikament hinzufügen';
      nameLabel = 'Medikamentenname *';
      dosageLabel = 'Dosierung (z.B. 500mg) *';
      qtyLabel = 'Menge *';
      repeatLabel = 'Wiederholung';
      dailyOpt = 'Täglich';
      dateOpt = 'Datum Wählen';
      timesLabel = 'Erinnerungszeiten wählen';
      photoBtn = 'Medikamentenfoto hinzufügen';
      saveBtn = 'Speichern';
    } else if (code == 'tr') {
      title = 'İlaç Ekle';
      nameLabel = 'İlaç Adı *';
      dosageLabel = 'Doz (örn. 500mg) *';
      qtyLabel = 'Miktar *';
      repeatLabel = 'Tekrar Düzeni';
      dailyOpt = 'Günlük';
      dateOpt = 'Tarih Seç';
      timesLabel = 'Hatırlatma Zamanlarını Seçin';
      photoBtn = 'İlaç Fotoğrafı Ekle';
      saveBtn = 'İlacı Kaydet';
    } else if (code == 'hi') {
      title = 'दवा जोड़ें';
      nameLabel = 'दवा का नाम *';
      dosageLabel = 'खुराक (जैसे 500mg) *';
      qtyLabel = 'मात्रा *';
      repeatLabel = 'दोहराव पैटर्न';
      dailyOpt = 'दैनिक';
      dateOpt = 'तिथि चुनें';
      timesLabel = 'अलार्म समय चुनें';
      photoBtn = 'दवा की तस्वीर जोड़ें';
      saveBtn = 'दवा सहेजें';
    } else if (code == 'zh') {
      title = '添加药物';
      nameLabel = '药物名称 *';
      dosageLabel = '剂量 (例如 500mg) *';
      qtyLabel = '数量 *';
      repeatLabel = '重复模式';
      dailyOpt = '每天';
      dateOpt = '选择日期';
      timesLabel = '选择提醒时间';
      photoBtn = '添加药物照片';
      saveBtn = '保存药物';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: nameLabel,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.medication),
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dosageController,
                decoration: InputDecoration(
                  labelText: dosageLabel,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.straighten),
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: qtyLabel,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.numbers),
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Medicine Photo Row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickPhoto,
                      icon: const Icon(Icons.camera_alt, color: Colors.teal),
                      label: Text(_photoName ?? photoBtn),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  if (_photoBytes != null) ...[
                    const SizedBox(width: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.memory(
                        _photoBytes!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              // Repeat Pattern Choices: Daily vs Select Date
              Text(
                repeatLabel,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: Center(child: Text(dailyOpt)),
                      selected: _repeatChoice == 'Daily',
                      selectedColor: Colors.teal.shade100,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _repeatChoice = 'Daily');
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: Center(
                        child: Text(
                          _repeatChoice == 'Select Date'
                              ? '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'
                              : dateOpt,
                        ),
                      ),
                      selected: _repeatChoice == 'Select Date',
                      selectedColor: Colors.teal.shade100,
                      onSelected: (selected) {
                        _pickDate();
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              Text(
                timesLabel,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _hourlyTimes.map((timeStr) {
                  final isSelected = _selectedTimes.contains(timeStr);
                  return FilterChip(
                    label: Text(timeStr),
                    selected: isSelected,
                    selectedColor: Colors.teal.shade100,
                    checkmarkColor: Colors.teal,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedTimes.add(timeStr);
                        } else {
                          _selectedTimes.remove(timeStr);
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
                child: ElevatedButton(
                  onPressed: _saveMedication,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    saveBtn,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _quantityController.dispose();
    super.dispose();
  }
}
