import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/doctor.dart';
import '../providers/doctor_provider.dart';

class AddDoctorScreen extends StatefulWidget {
  const AddDoctorScreen({super.key});

  @override
  State<AddDoctorScreen> createState() => _AddDoctorScreenState();
}

class _AddDoctorScreenState extends State<AddDoctorScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _addressController = TextEditingController();

  Future<void> _saveDoctor() async {
    if (!_formKey.currentState!.validate()) return;

    final doctor = Doctor(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      specialty: _specialtyController.text.trim().isEmpty
          ? null
          : _specialtyController.text.trim(),
    );

    final addressText = _addressController.text.trim();
    if (addressText.isNotEmpty) {
      try {
        (doctor as dynamic).address = addressText;
      } catch (_) {}
    }

    try {
      await Provider.of<DoctorProvider>(
        context,
        listen: false,
      ).addDoctor(doctor);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add doctor: $e'),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _specialtyController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Doctor',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
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
                decoration: const InputDecoration(
                  labelText: 'Doctor Name *',
                  labelStyle: TextStyle(fontSize: 16),
                  errorStyle: TextStyle(fontSize: 14),
                  prefixIcon: Icon(
                    Icons.person,
                    size: 28,
                  ),
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _specialtyController,
                style: const TextStyle(fontSize: 18),
                decoration: const InputDecoration(
                  labelText: 'Specialty (e.g. Cardiology)',
                  labelStyle: TextStyle(fontSize: 16),
                  prefixIcon: Icon(
                    Icons.medical_services,
                    size: 28,
                  ),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                style: const TextStyle(fontSize: 18),
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  labelStyle: TextStyle(fontSize: 16),
                  prefixIcon: Icon(
                    Icons.phone,
                    size: 28,
                  ),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                style: const TextStyle(fontSize: 18),
                decoration: const InputDecoration(
                  labelText: 'Address',
                  labelStyle: TextStyle(fontSize: 16),
                  prefixIcon: Icon(
                    Icons.location_on,
                    size: 28,
                  ),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _saveDoctor,
                  icon: const Icon(
                    Icons.save,
                    size: 26,
                  ),
                  label: const Text(
                    'Save Doctor',
                    style: TextStyle(
                      fontSize: 18,
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
}
