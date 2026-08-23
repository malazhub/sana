
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
import 'login_screen.dart';

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
      if (!mounted) return;

      try {
        Provider.of<DocumentProvider>(
          context,
          listen: false,
        ).loadDocuments();
      } catch (_) {}

      try {
        await Provider.of<InsuranceProvider>(
          context,
          listen: false,
        ).loadCards();
      } catch (_) {}

      final prefs = await SharedPreferences.getInstance();

      if (!mounted) return;

      setState(() {
        _privateRequested =
            prefs.getBool('private_requested') ?? false;
        _privatePaid =
            prefs.getBool('private_paid') ?? false;
      });
    });
  }

  Map<String, dynamic> _toMap(dynamic item) {
    if (item == null) {
      return {};
    }

    if (item is Map<String, dynamic>) {
      return item;
    }

    if (item is Map) {
      return Map<String, dynamic>.from(item);
    }

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
    final auth = context.watch<AuthProvider>();
    final language = context.watch<LanguageProvider>();
    final medProvider = context.watch<MedicationProvider>();
    final docProvider = context.watch<DoctorProvider>();
    final pharmProvider = context.watch<PharmacyProvider>();
    final docsProvider = context.watch<DocumentProvider>();
    final insuranceProvider = context.watch<InsuranceProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLanguageCard(language),

              const SizedBox(height: 16),

              _buildAccountTypeCard(),

              const SizedBox(height: 16),

              _buildAuthenticationCard(auth),

              const SizedBox(height: 16),

              _buildRecordsCard(),

              const SizedBox(height: 16),

              if (auth.isAuthenticated &&
                  _privateRequested &&
                  !_privatePaid)
                _buildPrivateAccountCard(),

              const SizedBox(height: 8),

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
                      name: auth.currentUser?.email ?? 'My Record',
                      medications: medProvider.medications
                          .map((m) => _toMap(m))
                          .toList(),
                      doctors: docProvider.doctors
                          .map((d) => _toMap(d))
                          .toList(),
                      pharmacies: pharmProvider.pharmacies
                          .map((p) => _toMap(p))
                          .toList(),
                      history: medProvider.logs
                          .map((l) => _toMap(l))
                          .toList(),
                      documents: docsProvider.documents
                          .map((d) => _toMap(d))
                          .toList(),
                      insuranceCards: insuranceProvider.cards
                          .map((c) => _toMap(c))
                          .toList(),
                    );
                  },
                  icon: const Icon(Icons.share),
                  label: const Text(
                    'Export & Share Record',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
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
      ),
    );
  }

  Widget _buildLanguageCard(LanguageProvider language) {
    final supported = language.getSupportedLanguages();

    String? selectedValue;

    if (supported.contains(language.locale.languageCode)) {
      selectedValue = language.locale.languageCode;
    } else if (supported.isNotEmpty) {
      selectedValue = supported.first;
    }

    return Card(
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
            if (selectedValue != null)
              DropdownButton<String>(
                isExpanded: true,
                value: selectedValue,
                items: supported.map((code) {
                  return DropdownMenuItem<String>(
                    value: code,
                    child: Text(
                      language.getLanguageName(code),
                    ),
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
    );
  }

  Widget _buildAccountTypeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Account Type',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _wantsPrivate,
              title: const Text('Private Account (Paid)'),
              subtitle: const Text(
                'Requires sign up with name and phone',
              ),
              onChanged: (value) {
                setState(() {
                  _wantsPrivate = value;

                  if (value) {
                    _isLogin = false;
                  }
                });
              },
            ),
            if (!_wantsPrivate)
              Padding(
                padding: const EdgeInsets.only(
                  left: 16,
                  top: 4,
                ),
                child: Text(
                  'Guest Mode (Free, no sign-in required)',
                  style: TextStyle(
                    color: Colors.grey[700],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthenticationCard(AuthProvider auth) {
    final accountText = auth.isAuthenticated
        ? 'Signed in as ${auth.currentUser?.email ?? 'User'}'
        : 'Guest Mode';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              accountText,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 12),

            if (!auth.isAuthenticated)
              _buildGuestLoginButton(),

            if (auth.isAuthenticated)
              _buildUserActions(auth),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const LoginScreen(),
            ),
          );
        },
        icon: const Icon(Icons.login),
        label: const Text(
          'Login',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildRecordsCard() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(
              Icons.folder_shared,
              color: Colors.teal,
            ),
            title: const Text('Medical Documents'),
            subtitle: const Text(
              'Scans, PDFs, and videos',
            ),
            trailing: const Icon(
              Icons.chevron_right,
            ),
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
            leading: const Icon(
              Icons.credit_card,
              color: Colors.teal,
            ),
            title: const Text('Insurance Cards'),
            subtitle: const Text(
              'Front and back photos',
            ),
            trailing: const Icon(
              Icons.chevron_right,
            ),
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
    );
  }

  Widget _buildPrivateAccountCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Private Account Pending',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'To activate private features please pay USD 50.',
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _payForPrivateAccount,
                    child: const Text('Pay USD 50'),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: ElevatedButton(
                    onPressed: _cancelPrivateRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _payForPrivateAccount() async {
    const payUrl =
        'https://link.payoneer.com/Token?t=CA1D522054524AC081ACCB17B5D8571B&src=pl';

    final opened =
        await PaymentService.openPaymentUrl(payUrl);

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not open payment link.',
          ),
        ),
      );
      return;
    }

    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Confirm Payment'),
          content: const Text(
            'Did you complete the USD 50 payment in the opened Payoneer tab?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setBool('private_paid', true);

    if (!mounted) return;

    setState(() {
      _privatePaid = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Payment recorded. Private features enabled.',
        ),
      ),
    );
  }

  Future<void> _cancelPrivateRequest() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setBool(
      'private_requested',
      false,
    );

    if (!mounted) return;

    setState(() {
      _privateRequested = false;
    });
  }

  Widget _buildStatCard(
    String title,
    String count,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 8,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: color,
                size: 28,
              ),
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
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserActions(AuthProvider auth) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: auth.isLoading
            ? null
            : () async {
                await auth.signOut();

                if (!mounted) return;

                setState(() {
                  _privateRequested = false;
                  _privatePaid = false;
                });
              },
        icon: const Icon(Icons.logout),
        label: const Text('Sign Out'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
      ),
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

