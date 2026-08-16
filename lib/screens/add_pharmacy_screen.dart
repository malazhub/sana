import 'package:flutter/material.dart';
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
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      address: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
    );

    try {
      await Provider.of<PharmacyProvider>(context, listen: false)
          .addPharmacy(pharmacy);
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
        title: Text(
          title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
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
                style: const TextStyle(fontSize: 18),
                decoration: InputDecoration(
                  labelText: nameLabel,
                  labelStyle: const TextStyle(fontSize: 16),
                  errorStyle: const TextStyle(fontSize: 14),
                  prefixIcon: const Icon(Icons.local_pharmacy, size: 28),
                  border: const OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? requiredError : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                style: const TextStyle(fontSize: 18),
                decoration: InputDecoration(
                  labelText: phoneLabel,
                  labelStyle: const TextStyle(fontSize: 16),
                  prefixIcon: const Icon(Icons.phone, size: 28),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                style: const TextStyle(fontSize: 18),
                decoration: InputDecoration(
                  labelText: addressLabel,
                  labelStyle: const TextStyle(fontSize: 16),
                  prefixIcon: const Icon(Icons.location_on, size: 28),
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _savePharmacy,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.save, size: 26),
                  label: Text(
                    saveButton,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
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