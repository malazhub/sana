import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/payment_service.dart';
import '../providers/auth_provider.dart';
import '../providers/medication_provider.dart';
import '../providers/doctor_provider.dart';
import '../providers/pharmacy_provider.dart';
import '../providers/document_provider.dart';
import '../providers/insurance_provider.dart';
import '../providers/language_provider.dart';
import '../services/sharing_service.dart';
import 'documents_screen.dart';
import 'insurance_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _wantsPrivate = false;
  bool _privateRequested = false;
  bool _privatePaid = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        (Provider.of<DocumentProvider>(context, listen: false) as dynamic).loadDocuments();
      } catch (_) {}

      Provider.of<InsuranceProvider>(context, listen: false).loadCards();

      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _privateRequested = prefs.getBool('private_requested') ?? false;
        _privatePaid = prefs.getBool('private_paid') ?? false;
      });
    });
  }

  Map<String, dynamic> _toMap(dynamic item) {
    if (item == null) return {};
    if (item is Map<String, dynamic>) return item;
    if (item is Map) return Map<String, dynamic>.from(item);
    try {
      return (item as dynamic).toMap();
    } catch (_) {
      try {
        return (item as dynamic).toJson();
      } catch (_) {
        return {};
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final language = Provider.of<LanguageProvider>(context);
    final medProvider = Provider.of<MedicationProvider>(context);
    final docProvider = Provider.of<DoctorProvider>(context);
    final pharmProvider = Provider.of<PharmacyProvider>(context);
    final docsProvider = Provider.of<DocumentProvider>(context);
    final insuranceProvider = Provider.of<InsuranceProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Language',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      isExpanded: true,
                      value: language.locale.languageCode,
                      items: language.getSupportedLanguages().map((code) {
                        return DropdownMenuItem(
                          value: code,
                          child: Text(language.getLanguageName(code)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          language.setLanguage(value);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Account Type',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      value: _wantsPrivate,
                      title: const Text('Private Account (Paid)'),
                      subtitle:
                          const Text('Requires sign up with name and phone'),
                      onChanged: (v) {
                        setState(() {
                          _wantsPrivate = v;
                          if (v) {
                            _isLogin = false;
                          }
                        });
                      },
                    ),
                    if (!_wantsPrivate)
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0, top: 8.0),
                        child: Text(
                          'Guest (Free, no sign-in required)',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      auth.isAuthenticated
                          ? 'Signed in as ${auth.user?.email}'
                          : auth.isGuest
                              ? 'Guest Mode'
                              : 'Not signed in',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (!auth.isAuthenticated) _buildAuthForm(auth),
                    if (auth.isAuthenticated) _buildUserActions(auth),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading:
                        const Icon(Icons.folder_shared, color: Colors.teal),
                    title: const Text('Medical Documents'),
                    subtitle: const Text('Scans, PDFs, and videos'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DocumentsScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.credit_card, color: Colors.teal),
                    title: const Text('Insurance Cards'),
                    subtitle: const Text('Front and back photos'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const InsuranceScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (auth.isAuthenticated && _privateRequested && !_privatePaid)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Private Account Pending',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text(
                            'To activate private features please pay USD 50.'),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                const payUrl =
                                    'https://link.payoneer.com/Token?t=CA1D522054524AC081ACCB17B5D8571B&src=pl';
                                final opened =
                                    await PaymentService.openPaymentUrl(payUrl);
                                if (!opened && mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Could not open payment link.'),
                                    ),
                                  );
                                  return;
                                }

                                if (!mounted) return;
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Confirm Payment'),
                                    content: const Text(
                                        'Did you complete the USD 50 payment in the opened Payoneer tab?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('No'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('Yes'),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirmed == true) {
                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  await prefs.setBool('private_paid', true);
                                  setState(() {
                                    _privatePaid = true;
                                  });
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Payment recorded. Private features enabled.'),
                                      ),
                                    );
                                  }
                                }
                              },
                              child: const Text('Pay USD 50'),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () async {
                                final prefs =
                                    await SharedPreferences.getInstance();
                                await prefs.setBool('private_requested', false);
                                setState(() {
                                  _privateRequested = false;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey),
                              child: const Text('Cancel Request'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Row(
              children: [
                _buildStatCard(
                  'Medications',
                  '${medProvider.medications.length}',
                  Icons.medication,
                  Colors.blue,
                ),
                const SizedBox(width: 8),
                _buildStatCard(
                  'Doctors',
                  '${docProvider.doctors.length}',
                  Icons.medical_services,
                  Colors.green,
                ),
                const SizedBox(width: 8),
                _buildStatCard(
                  'Pharmacies',
                  '${pharmProvider.pharmacies.length}',
                  Icons.local_pharmacy,
                  Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  SharingService.shareMedications(
                    name: auth.user?.email ?? 'My Record',
                    medications:
                        medProvider.medications.map((m) => _toMap(m)).toList(),
                    doctors: docProvider.doctors.map((d) => _toMap(d)).toList(),
                    pharmacies:
                        pharmProvider.pharmacies.map((p) => _toMap(p)).toList(),
                    history: medProvider.logs.map((l) => _toMap(l)).toList(),
                    documents:
                        docsProvider.documents.map((d) => _toMap(d)).toList(),
                    insuranceCards:
                        insuranceProvider.cards.map((c) => _toMap(c)).toList(),
                  );
                },
                icon: const Icon(Icons.share),
                label: const Text(
                  'Export & Share Record',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String count, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                count,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuthForm(AuthProvider auth) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!_isLogin) ...[
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v!.isEmpty ? 'Enter name' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v!.isEmpty ? 'Enter phone' : null,
            ),
            const SizedBox(height: 8),
          ],
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
            validator: (v) => v!.isEmpty ? 'Enter email' : null,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
            validator: (v) => v!.length < 6 ? 'Min 6 characters' : null,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: auth.isLoading
                ? null
                : () async {
                    if (!_formKey.currentState!.validate()) return;
                    try {
                      if (_isLogin) {
                        await auth.signIn(
                          email: _emailController.text.trim(),
                          password: _passwordController.text.trim(),
                        );
                      } else {
                        await auth.signUp(
                          name: _nameController.text.trim(),
                          phone: _phoneController.text.trim(),
                          email: _emailController.text.trim(),
                          password: _passwordController.text.trim(),
                        );

                        if (_wantsPrivate) {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('private_requested', true);

                          if (mounted) {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Private Account Requested'),
                                content: const Text(
                                    'Your private account request has been recorded. To activate your private account please complete payment via the payment portal. We will enable your premium features after payment.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          }
                        }
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString())),
                      );
                    }
                  },
            child: Text(_isLogin ? 'Login' : 'Sign Up'),
          ),
          TextButton(
            onPressed: () => setState(() => _isLogin = !_isLogin),
            child: Text(_isLogin
                ? "Don't have an account? Sign Up"
                : 'Already have an account? Login'),
          ),
        ],
      ),
    );
  }

  Widget _buildUserActions(AuthProvider auth) {
    return ElevatedButton.icon(
      onPressed: () async {
        await auth.signOut();
      },
      icon: const Icon(Icons.logout),
      label: const Text('Sign Out'),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}