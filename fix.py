doc_code = '''class Doctor {
  final String id;
  final String name;
  final String? phone;
  final String? specialty;
  final String? address;

  Doctor({
    required this.id,
    required this.name,
    this.phone,
    this.specialty,
    this.address,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString(),
      specialty: json['specialty']?.toString() ?? json['speciality']?.toString(),
      address: json['address']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (phone != null && phone!.isNotEmpty) 'phone': phone,
      if (specialty != null && specialty!.isNotEmpty) 'specialty': specialty,
      if (address != null && address!.isNotEmpty) 'address': address,
    };
  }

  Map<String, dynamic> toMap() => toJson();
}
'''
with open(r'lib\models\doctor.dart', 'w', encoding='utf-8') as f:
    f.write(doc_code)

prov_code = '''import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/doctor.dart';

class DoctorProvider with ChangeNotifier {
  final _supabase = Supabase.instance.client;
  List<Doctor> _doctors = [];
  bool _isLoading = false;

  List<Doctor> get doctors => List.unmodifiable(_doctors);
  bool get isLoading => _isLoading;

  Future<void> fetchDoctors() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase.from('doctors').select().range(0, 2499);
      final List<dynamic> data = response as List<dynamic>;
      _doctors = data
          .map((item) => Doctor.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } catch (e) {
      debugPrint('Error loading doctors: ');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadDoctors() => fetchDoctors();
  Future<void> recoverOldDoctors() => fetchDoctors();

  Future<void> addDoctor(Doctor doctor) async {
    try {
      final response = await _supabase.from('doctors').insert(doctor.toJson()).select().single();
      _doctors.insert(0, Doctor.fromJson(Map<String, dynamic>.from(response as Map)));
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding doctor: ');
      rethrow;
    }
  }

  Future<void> deleteDoctor(String id) async {
    try {
      await _supabase.from('doctors').delete().eq('id', id);
      _doctors.removeWhere((d) => d.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting doctor: ');
      rethrow;
    }
  }
}
'''
with open(r'lib\providers\doctor_provider.dart', 'w', encoding='utf-8') as f:
    f.write(prov_code)

screen_code = '''import 'package:flutter/material.dart';
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
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      specialty: _specialtyController.text.trim().isEmpty ? null : _specialtyController.text.trim(),
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
    );

    try {
      await Provider.of<DoctorProvider>(context, listen: false).addDoctor(doctor);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add doctor: ')),
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
      appBar: AppBar(title: const Text('Add Doctor')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Doctor Name *'),
                validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _specialtyController,
                decoration: const InputDecoration(labelText: 'Specialty (e.g. Cardiology)'),
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
              ),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveDoctor,
                child: const Text('Save Doctor'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
'''
with open(r'lib\screens\add_doctor_screen.dart', 'w', encoding='utf-8') as f:
    f.write(screen_code)

print("SUCCESS: Doctor model, provider, and screen updated!")
