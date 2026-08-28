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

  String _repeatChoice = 'Daily';

  final List<String> _selectedTimes = ['8:00 AM'];

  Uint8List? _photoBytes;
  String? _photoName;

  bool _isSaving = false;

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
    if (_isSaving) {
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result == null || result.files.isEmpty || !mounted) {
        return;
      }

      final file = result.files.single;

      if (file.bytes == null || file.bytes!.isEmpty) {
        _showMessage(
          'The selected image could not be read.',
          isError: true,
        );
        return;
      }

      setState(() {
        _photoBytes = file.bytes;
        _photoName = file.name;
      });
    } catch (error, stackTrace) {
      debugPrint(
        'Could not pick medication photo: '
        '$error\n$stackTrace',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Could not select the medication photo.',
        isError: true,
      );
    }
  }

  Future<void> _pickDate() async {
    if (_isSaving) {
      return;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(
        const Duration(days: 3650),
      ),
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _selectedDate = picked;
      _repeatChoice = 'Select Date';
    });
  }

  Future<void> _saveMedication() async {
    if (_isSaving) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedTimes.isEmpty) {
      _showMessage(
        'Please select at least one reminder time.',
        isError: true,
      );
      return;
    }

    final quantity = int.tryParse(
      _quantityController.text.trim(),
    );

    if (quantity == null || quantity <= 0) {
      _showMessage(
        'Quantity must be greater than zero.',
        isError: true,
      );
      return;
    }

    final repeatValue = _repeatChoice == 'Select Date'
        ? 'Date: ${_selectedDate.day}/'
            '${_selectedDate.month}/'
            '${_selectedDate.year}'
        : 'Daily';

    final medication = Medication(
      id: DateTime.now().microsecondsSinceEpoch.toString(),

      // MedicationProvider replaces this with the
      // authenticated user's ID before saving.
      userId: '',

      name: _nameController.text.trim(),
      dosage: _dosageController.text.trim(),
      quantity: quantity,
      reminderTimes: List<String>.from(_selectedTimes),
      repeatType: repeatValue,

      // Do not store the image as a base64/data URL
      // inside the medication database row.
      //
      // The selected image remains available here for
      // the future private-storage photo flow.
      photoUrl: null,
    );

    setState(() {
      _isSaving = true;
    });

    try {
      await context.read<MedicationProvider>().addMedication(medication);

      if (!mounted) {
        return;
      }

      Navigator.pop(context, true);
    } catch (error, stackTrace) {
      debugPrint(
        'Failed to save medication: '
        '$error\n$stackTrace',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to save medication. Please try again.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  String _photoButtonText(String fallback) {
    if (_photoName == null || _photoName!.trim().isEmpty) {
      return fallback;
    }

    return _photoName!;
  }

  @override
  Widget build(BuildContext context) {
    final language = context.watch<LanguageProvider>();

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
      title = 'Ø¥Ø¶Ø§ÙØ© Ø¯ÙˆØ§Ø¡';
      nameLabel = 'Ø§Ø³Ù… Ø§Ù„Ø¯ÙˆØ§Ø¡ *';
      dosageLabel = 'Ø§Ù„Ø¬Ø±Ø¹Ø© (Ù…Ø«Ø§Ù„ 500 Ù…Ù„Ø¬Ù…) *';
      qtyLabel = 'Ø§Ù„ÙƒÙ…ÙŠØ© *';
      repeatLabel = 'Ù†Ù…Ø· Ø§Ù„ØªÙƒØ±Ø§Ø±';
      dailyOpt = 'ÙŠÙˆÙ…ÙŠØ§Ù‹';
      dateOpt = 'ØªØ­Ø¯ÙŠØ¯ Ø§Ù„ØªØ§Ø±ÙŠØ®';
      timesLabel = 'Ø§Ø®ØªØ± Ø£ÙˆÙ‚Ø§Øª Ø§Ù„ØªØ°ÙƒÙŠØ±';
      photoBtn = 'Ø¥Ø¶Ø§ÙØ© ØµÙˆØ±Ø© Ø§Ù„Ø¯ÙˆØ§Ø¡';
      saveBtn = 'Ø­ÙØ¸ Ø§Ù„Ø¯ÙˆØ§Ø¡';
    } else if (code == 'es') {
      title = 'AÃ±adir Medicamento';
      nameLabel = 'Nombre del Medicamento *';
      dosageLabel = 'Dosis (ej. 500mg) *';
      qtyLabel = 'Cantidad *';
      repeatLabel = 'PatrÃ³n de RepeticiÃ³n';
      dailyOpt = 'Diario';
      dateOpt = 'Seleccionar Fecha';
      timesLabel = 'Seleccionar Horarios';
      photoBtn = 'AÃ±adir Foto del Medicamento';
      saveBtn = 'Guardar Medicamento';
    } else if (code == 'fr') {
      title = 'Ajouter un MÃ©dicament';
      nameLabel = 'Nom du MÃ©dicament *';
      dosageLabel = 'Dosage (ex. 500mg) *';
      qtyLabel = 'QuantitÃ© *';
      repeatLabel = 'RÃ©pÃ©tition';
      dailyOpt = 'Quotidien';
      dateOpt = 'SÃ©lectionner une Date';
      timesLabel = 'Horaires de Rappel';
      photoBtn = 'Ajouter Photo du MÃ©dicament';
      saveBtn = 'Enregistrer';
    } else if (code == 'de') {
      title = 'Medikament hinzufÃ¼gen';
      nameLabel = 'Medikamentenname *';
      dosageLabel = 'Dosierung (z.B. 500mg) *';
      qtyLabel = 'Menge *';
      repeatLabel = 'Wiederholung';
      dailyOpt = 'TÃ¤glich';
      dateOpt = 'Datum WÃ¤hlen';
      timesLabel = 'Erinnerungszeiten wÃ¤hlen';
      photoBtn = 'Medikamentenfoto hinzufÃ¼gen';
      saveBtn = 'Speichern';
    } else if (code == 'tr') {
      title = 'Ä°laÃ§ Ekle';
      nameLabel = 'Ä°laÃ§ AdÄ± *';
      dosageLabel = 'Doz (Ã¶rn. 500mg) *';
      qtyLabel = 'Miktar *';
      repeatLabel = 'Tekrar DÃ¼zeni';
      dailyOpt = 'GÃ¼nlÃ¼k';
      dateOpt = 'Tarih SeÃ§';
      timesLabel = 'HatÄ±rlatma ZamanlarÄ±nÄ± SeÃ§in';
      photoBtn = 'Ä°laÃ§ FotoÄŸrafÄ± Ekle';
      saveBtn = 'Ä°lacÄ± Kaydet';
    } else if (code == 'hi') {
      title = 'à¤¦à¤µà¤¾ à¤œà¥‹à¤¡à¤¼à¥‡à¤‚';
      nameLabel = 'à¤¦à¤µà¤¾ à¤•à¤¾ à¤¨à¤¾à¤® *';
      dosageLabel = 'à¤–à¥à¤°à¤¾à¤• (à¤œà¥ˆà¤¸à¥‡ 500mg) *';
      qtyLabel = 'à¤®à¤¾à¤¤à¥à¤°à¤¾ *';
      repeatLabel = 'à¤¦à¥‹à¤¹à¤°à¤¾à¤µ à¤ªà¥ˆà¤Ÿà¤°à¥à¤¨';
      dailyOpt = 'à¤¦à¥ˆà¤¨à¤¿à¤•';
      dateOpt = 'à¤¤à¤¿à¤¥à¤¿ à¤šà¥à¤¨à¥‡à¤‚';
      timesLabel = 'à¤…à¤²à¤¾à¤°à¥à¤® à¤¸à¤®à¤¯ à¤šà¥à¤¨à¥‡à¤‚';
      photoBtn = 'à¤¦à¤µà¤¾ à¤•à¥€ à¤¤à¤¸à¥à¤µà¥€à¤° à¤œà¥‹à¤¡à¤¼à¥‡à¤‚';
      saveBtn = 'à¤¦à¤µà¤¾ à¤¸à¤¹à¥‡à¤œà¥‡à¤‚';
    } else if (code == 'zh') {
      title = 'æ·»åŠ è¯ç‰©';
      nameLabel = 'è¯ç‰©åç§° *';
      dosageLabel = 'å‰‚é‡ (ä¾‹å¦‚ 500mg) *';
      qtyLabel = 'æ•°é‡ *';
      repeatLabel = 'é‡å¤æ¨¡å¼';
      dailyOpt = 'æ¯å¤©';
      dateOpt = 'é€‰æ‹©æ—¥æœŸ';
      timesLabel = 'é€‰æ‹©æé†’æ—¶é—´';
      photoBtn = 'æ·»åŠ è¯ç‰©ç…§ç‰‡';
      saveBtn = 'ä¿å­˜è¯ç‰©';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                enabled: !_isSaving,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: nameLabel,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(
                    Icons.medication,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Required';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dosageController,
                enabled: !_isSaving,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: dosageLabel,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(
                    Icons.straighten,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Required';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _quantityController,
                enabled: !_isSaving,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: qtyLabel,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(
                    Icons.numbers,
                  ),
                ),
                validator: (value) {
                  final quantity = int.tryParse(
                    value?.trim() ?? '',
                  );

                  if (quantity == null || quantity <= 0) {
                    return 'Enter a valid quantity';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isSaving ? null : _pickPhoto,
                      icon: const Icon(
                        Icons.camera_alt,
                        color: Colors.teal,
                      ),
                      label: Text(
                        _photoButtonText(
                          photoBtn,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
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
              Text(
                repeatLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: Center(
                        child: Text(dailyOpt),
                      ),
                      selected: _repeatChoice == 'Daily',
                      selectedColor: Colors.teal.shade100,
                      onSelected: _isSaving
                          ? null
                          : (selected) {
                              if (!selected) {
                                return;
                              }

                              setState(() {
                                _repeatChoice = 'Daily';
                              });
                            },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: Center(
                        child: Text(
                          _repeatChoice == 'Select Date'
                              ? '${_selectedDate.day}/'
                                  '${_selectedDate.month}/'
                                  '${_selectedDate.year}'
                              : dateOpt,
                        ),
                      ),
                      selected: _repeatChoice == 'Select Date',
                      selectedColor: Colors.teal.shade100,
                      onSelected: _isSaving
                          ? null
                          : (_) {
                              _pickDate();
                            },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                timesLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _hourlyTimes.map(
                  (time) {
                    final selected = _selectedTimes.contains(time);

                    return FilterChip(
                      label: Text(time),
                      selected: selected,
                      selectedColor: Colors.teal.shade100,
                      checkmarkColor: Colors.teal,
                      onSelected: _isSaving
                          ? null
                          : (value) {
                              setState(() {
                                if (value) {
                                  if (!_selectedTimes.contains(time)) {
                                    _selectedTimes.add(
                                      time,
                                    );
                                  }
                                } else {
                                  _selectedTimes.remove(
                                    time,
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
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveMedication,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          saveBtn,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _quantityController.dispose();
    super.dispose();
  }
}
