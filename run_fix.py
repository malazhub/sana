import os

code_pharm_model = '''class Pharmacy {
  final String id;
  final String name;
  final String? phone;
  final String? address;

  Pharmacy({
    required this.id,
    required this.name,
    this.phone,
    this.address,
  });

  factory Pharmacy.fromJson(Map<String, dynamic> json) {
    return Pharmacy(
      id: json["id"]?.toString() ?? "",
      name: json["name"]?.toString() ?? "",
      phone: json["phone"]?.toString(),
      address: json["address"]?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      "name": name,
    };
    if (phone != null && phone!.isNotEmpty) map["phone"] = phone;
    if (address != null && address!.isNotEmpty) map["address"] = address;
    return map;
  }

  Map<String, dynamic> toMap() => toJson();
}
'''

code_pharm_prov = '''import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pharmacy.dart';

class PharmacyProvider with ChangeNotifier {
  final _supabase = Supabase.instance.client;
  List<Pharmacy> _pharmacies = [];
  bool _isLoading = false;

  List<Pharmacy> get pharmacies => List.unmodifiable(_pharmacies);
  bool get isLoading => _isLoading;

  Future<void> fetchPharmacies() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase.from('pharmacies').select().range(0, 2499);
      final List<dynamic> data = response as List<dynamic>;
      _pharmacies = data
          .map((item) => Pharmacy.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } catch (e) {
      debugPrint('Error loading pharmacies: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPharmacies() => fetchPharmacies();
  Future<void> recoverOldPharmacies() => fetchPharmacies();

  Future<void> addPharmacy(Pharmacy pharmacy) async {
    try {
      final response = await _supabase
          .from('pharmacies')
          .insert(pharmacy.toJson())
          .select()
          .single();
      _pharmacies.insert(
          0, Pharmacy.fromJson(Map<String, dynamic>.from(response as Map)));
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding pharmacy: $e');
      rethrow;
    }
  }

  Future<void> deletePharmacy(String id) async {
    try {
      await _supabase.from('pharmacies').delete().eq('id', id);
      _pharmacies.removeWhere((p) => p.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting pharmacy: $e');
      rethrow;
    }
  }
}
'''

code_pharm_screen = '''import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pharmacy.dart';
import '../providers/language_provider.dart';
import '../providers/pharmacy_provider.dart';

class AddPharmacyScreen extends StatefulWidget {
  const AddPharmacyScreen({super.key});

  @override
  State<AddPharmacyScreen> createState() => _AddPharmacyScreenState();
}

class _AddPharmacyScreenState extends State<AddPharmacyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _savePharmacy() async {
    if (!_formKey.currentState!.validate()) return;

    final pharmacy = Pharmacy(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
    );

    try {
      await Provider.of<PharmacyProvider>(context, listen: false).addPharmacy(pharmacy);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = Provider.of<LanguageProvider>(context);
    final code = language.locale.languageCode;

    String title = 'Add Pharmacy';
    String nameLabel = 'Pharmacy Name *';
    String phoneLabel = 'Phone Number';
    String addressLabel = 'Address';
    String saveButton = 'Save Pharmacy';
    String requiredError = 'Required';

    if (code == 'ar') {
      title = 'إضافة صيدلية';
      nameLabel = 'اسم الصيدلية *';
      phoneLabel = 'رقم الهاتف';
      addressLabel = 'العنوان';
      saveButton = 'حفظ الصيدلية';
      requiredError = 'مطلوب';
    } else if (code == 'es') {
      title = 'Añadir Farmacia';
      nameLabel = 'Nombre de la Farmacia *';
      phoneLabel = 'Número de Teléfono';
      addressLabel = 'Dirección';
      saveButton = 'Guardar Farmacia';
      requiredError = 'Requerido';
    } else if (code == 'fr') {
      title = 'Ajouter une Pharmacie';
      nameLabel = 'Nom de la Pharmacie *';
      phoneLabel = 'Numéro de Téléphone';
      addressLabel = 'Adresse';
      saveButton = 'Enregistrer la Pharmacie';
      requiredError = 'Requis';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: nameLabel,
                  border: const OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? requiredError : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: phoneLabel,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: addressLabel,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _savePharmacy,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    saveButton,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
'''

code_med_screen = '''import 'package:flutter/material.dart';
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
  final _quantityController = TextEditingController();
  final _instructionsController = TextEditingController();

  List<TimeOfDay> _selectedTimes = [const TimeOfDay(hour: 8, minute: 0)];
  String _repeatType = 'daily';
  DateTime? _specificDate;

  Future<void> _addTimeSlot() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 12, minute: 0),
    );
    if (picked != null && !_selectedTimes.any((t) => t.hour == picked.hour && t.minute == picked.minute)) {
      setState(() {
        _selectedTimes.add(picked);
      });
    }
  }

  void _togglePresetTime(TimeOfDay time) {
    setState(() {
      if (_selectedTimes.any((t) => t.hour == time.hour && t.minute == time.minute)) {
        if (_selectedTimes.length > 1) {
          _selectedTimes.removeWhere((t) => t.hour == time.hour && t.minute == time.minute);
        }
      } else {
        _selectedTimes.add(time);
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _specificDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _specificDate = picked;
      });
    }
  }

  String _formatTimeAMPM(TimeOfDay time) {
    final hour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _format24hTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _saveMedication() async {
    if (!_formKey.currentState!.validate()) return;

    final formattedTimes24h = _selectedTimes.map((t) => _format24hTime(t)).toList();

    final medication = Medication(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      dosage: _dosageController.text.trim().isEmpty ? '' : _dosageController.text.trim(),
      quantity: int.tryParse(_quantityController.text.trim()),
      instructions: _instructionsController.text.trim().isEmpty ? null : _instructionsController.text.trim(),
      reminderTimes: formattedTimes24h,
      repeatType: _repeatType,
      specificDate: _repeatType == 'specific_date' ? _specificDate : null,
    );

    try {
      await Provider.of<MedicationProvider>(context, listen: false).addMedication(medication);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _quantityController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final language = Provider.of<LanguageProvider>(context);
    final code = language.locale.languageCode;

    String addMedText = 'Add Medication';
    String medNameText = 'Medication Name';
    String dosageText = 'Dosage (e.g. 500mg)';
    String quantityText = 'Quantity (pills)';
    String instructionsText = 'Instructions';
    String reminderTimesText = 'Dose Times (Select 1 or more)';
    String addCustomTimeText = '+ Add Custom Time';
    String scheduleText = 'Schedule';
    String dailyText = 'Daily';
    String specificDateText = 'Select Date';

    if (code == 'ar') {
      addMedText = 'إضافة دواء';
      medNameText = 'اسم الدواء';
      dosageText = 'الجرعة (مثال: 500 ملغ)';
      quantityText = 'الكمية (حبات)';
      instructionsText = 'التعليمات';
      reminderTimesText = 'أوقات الجرعات (اختر 1 أو أكثر)';
      addCustomTimeText = '+ إضافة وقت آخر';
      scheduleText = 'جدول التكرار';
      dailyText = 'يومياً';
      specificDateText = 'تاريخ محدد';
    } else if (code == 'es') {
      addMedText = 'Añadir Medicamento';
      medNameText = 'Nombre del Medicamento';
      dosageText = 'Dosis (ej. 500mg)';
      quantityText = 'Cantidad (pastillas)';
      instructionsText = 'Instrucciones';
      reminderTimesText = 'Horarios de dosis';
      addCustomTimeText = '+ Añadir hora personalizada';
      scheduleText = 'Horario';
      dailyText = 'Diario';
      specificDateText = 'Fecha específica';
    } else if (code == 'fr') {
      addMedText = 'Ajouter un Médicament';
      medNameText = 'Nom du Médicament';
      dosageText = 'Dosage (ex. 500mg)';
      quantityText = 'Quantité (comprimés)';
      instructionsText = 'Instructions';
      reminderTimesText = 'Heures de prise';
      addCustomTimeText = '+ Ajouter une heure';
      scheduleText = 'Horaire';
      dailyText = 'Quotidien';
      specificDateText = 'Date spécifique';
    }

    final presets = [
      const TimeOfDay(hour: 8, minute: 0),
      const TimeOfDay(hour: 14, minute: 0),
      const TimeOfDay(hour: 20, minute: 0),
      const TimeOfDay(hour: 22, minute: 0),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(addMedText),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: '$medNameText *',
                  border: const OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dosageController,
                decoration: InputDecoration(
                  labelText: dosageText,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                decoration: InputDecoration(
                  labelText: quantityText,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _instructionsController,
                decoration: InputDecoration(
                  labelText: instructionsText,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              const Divider(),
              Text(
                reminderTimesText,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: presets.map((preset) {
                  final isSelected = _selectedTimes.any((t) => t.hour == preset.hour && t.minute == preset.minute);
                  return FilterChip(
                    selected: isSelected,
                    label: Text(_formatTimeAMPM(preset)),
                    selectedColor: Colors.teal.shade200,
                    onSelected: (_) => _togglePresetTime(preset),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._selectedTimes.where((t) => !presets.any((p) => p.hour == t.hour && p.minute == t.minute)).map((customTime) {
                    return Chip(
                      label: Text(_formatTimeAMPM(customTime)),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: _selectedTimes.length > 1 ? () {
                        setState(() {
                          _selectedTimes.remove(customTime);
                        });
                      } : null,
                    );
                  }),
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 18, color: Colors.teal),
                    label: Text(addCustomTimeText, style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                    onPressed: _addTimeSlot,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _repeatType,
                decoration: InputDecoration(
                  labelText: scheduleText,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(value: 'daily', child: Text(dailyText)),
                  DropdownMenuItem(value: 'specific_date', child: Text(specificDateText)),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _repeatType = val;
                    });
                  }
                },
              ),
              if (_repeatType == 'specific_date') ...[
                const SizedBox(height: 12),
                Card(
                  elevation: 1,
                  child: ListTile(
                    leading: const Icon(Icons.calendar_today, color: Colors.teal),
                    title: Text(
                      _specificDate == null
                          ? specificDateText
                          : '${_specificDate!.day}/${_specificDate!.month}/${_specificDate!.year}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onTap: _pickDate,
                  ),
                ),
              ],
              const SizedBox(height: 28),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _saveMedication,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    addMedText,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
'''

# Write all files
with open('lib/models/pharmacy.dart', 'w', encoding='utf-8') as f:
    f.write(code_pharm_model)

with open('lib/providers/pharmacy_provider.dart', 'w', encoding='utf-8') as f:
    f.write(code_pharm_prov)

with open('lib/screens/add_pharmacy_screen.dart', 'w', encoding='utf-8') as f:
    f.write(code_pharm_screen)

with open('lib/screens/add_medication_screen.dart', 'w', encoding='utf-8') as f:
    f.write(code_med_screen)

print('SUCCESS: All 4 files written cleanly to disk!')
print('Files created:')
print('  - lib/models/pharmacy.dart')
print('  - lib/providers/pharmacy_provider.dart')
print('  - lib/screens/add_pharmacy_screen.dart')
print('  - lib/screens/add_medication_screen.dart')
