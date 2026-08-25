
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/auth_provider.dart';
import '../providers/doctor_provider.dart';
import '../providers/document_provider.dart';
import '../providers/insurance_provider.dart';
import '../providers/language_provider.dart';
import '../providers/medication_provider.dart';
import '../providers/pharmacy_provider.dart';
import '../services/payment_service.dart';
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
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadProfileState();
  }

  Future<void> _loadProfileState() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      try {
        await context.read<DocumentProvider>().loadDocuments();
      } catch (_) {}

      try {
        await context.read<InsuranceProvider>().loadCards();
      } catch (_) {}

      final prefs = await SharedPreferences.getInstance();

      if (!mounted) return;

      setState(() {
        _privateRequested =
            prefs.getBool('private_requested') ?? false;
        _privatePaid = prefs.getBool('private_paid') ?? false;
      });
    });
  }

  Map<String, dynamic> _toMap(dynamic item) {
    if (item == null) return {};

    if (item is Map<String, dynamic>) {
      return item;
    }

    if (item is Map) {
      return Map<String, dynamic>.from(item);
    }

    try {
      final value = (item as dynamic).toMap();

      if (value is Map<String, dynamic>) {
        return value;
      }

      if (value is Map) {
        return Map<String, dynamic>.from(value);
      }
    } catch (_) {}

    try {
      final value = (item as dynamic).toJson();

      if (value is Map<String, dynamic>) {
        return value;
      }

      if (value is Map) {
        return Map<String, dynamic>.from(value);
      }
    } catch (_) {}

    return {};
  }

  String _accountTitle(AuthProvider auth) {
    if (auth.isAuthenticated) {
      final email = auth.currentUser?.email;

      if (email != null && email.trim().isNotEmpty) {
        return 'Signed in as $email';
      }

      return 'Signed in';
    }

    return 'Not signed in';
  }

  Future<void> _submitAuth(AuthProvider auth) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    auth.clearError();

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final bool success;

    if (_isLogin) {
      success = await auth.signIn(
        email: email,
        password: password,
      );
    } else {
      success = await auth.signUp(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: email,
        password: password,
      );
    }

    if (!mounted) return;

    if (!success) {
      _showSnack(
        auth.errorMessage ??
            (_isLogin
                ? 'Unable to sign in.'
                : 'Unable to create account.'),
        error: true,
      );
      return;
    }

    if (!_isLogin && _wantsPrivate) {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool('private_requested', true);

      if (!mounted) return;

      setState(() {
        _privateRequested = true;
      });

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Private Account Requested'),
            content: const Text(
              'Your private account request has been recorded. '
              'Complete the payment to activate private features.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  void _showSnack(
    String message, {
    bool error = false,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor:
              error ? Colors.red.shade700 : Colors.teal,
          content: Text(message),
        ),
      );
  }

  Future<void> _payForPrivateAccount() async {
    const paymentUrl =
        'https://link.payoneer.com/Token?t=CA1D522054524AC081ACCB17B5D8571B&src=pl';

    final opened =
        await PaymentService.openPaymentUrl(paymentUrl);

    if (!mounted) return;

    if (!opened) {
      _showSnack(
        'Could not open payment link.',
        error: true,
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Payment'),
          content: const Text(
            'Did you complete the USD 50 payment in the opened payment page?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('No'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('private_paid', true);

    if (!mounted) return;

    setState(() {
      _privatePaid = true;
    });

    _showSnack(
      'Payment recorded. Private features enabled.',
    );
  }

  Future<void> _cancelPrivateRequest() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('private_requested', false);

    if (!mounted) return;

    setState(() {
      _privateRequested = false;
    });

    _showSnack('Private account request cancelled.');
  }

  Future<void> _shareRecord({
    required AuthProvider auth,
    required MedicationProvider medications,
    required DoctorProvider doctors,
    required PharmacyProvider pharmacies,
    required DocumentProvider documents,
    required InsuranceProvider insurance,
  }) async {
    final email = auth.currentUser?.email;

    await SharingService.shareMedications(
      name: email?.trim().isNotEmpty == true
          ? email!
          : 'My Record',
      medications:
          medications.medications.map(_toMap).toList(),
      doctors:
          doctors.doctors.map(_toMap).toList(),
      pharmacies:
          pharmacies.pharmacies.map(_toMap).toList(),
      history:
          medications.logs.map(_toMap).toList(),
      documents:
          documents.documents.map(_toMap).toList(),
      insuranceCards:
          insurance.cards.map(_toMap).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final language = context.watch<LanguageProvider>();
    final medications = context.watch<MedicationProvider>();
    final doctors = context.watch<DoctorProvider>();
    final pharmacies = context.watch<PharmacyProvider>();
    final documents = context.watch<DocumentProvider>();
    final insurance = context.watch<InsuranceProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
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
              _buildPrivatePendingCard(),
            if (auth.isAuthenticated &&
                _privateRequested &&
                !_privatePaid)
              const SizedBox(height: 16),
            _buildStatistics(
              medications,
              doctors,
              pharmacies,
            ),
            const SizedBox(height: 24),
            _buildShareButton(
              auth: auth,
              medications: medications,
              doctors: doctors,
              pharmacies: pharmacies,
              documents: documents,
              insurance: insurance,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageCard(
    LanguageProvider language,
  ) {
    final supported =
        language.getSupportedLanguages();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Language',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: supported.contains(
                language.locale.languageCode,
              )
                  ? language.locale.languageCode
                  : null,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon:
                    Icon(Icons.language),
              ),
              items: supported.map(
                (code) {
                  return DropdownMenuItem<String>(
                    value: code,
                    child: Text(
                      language.getLanguageName(code),
                    ),
                  );
                },
              ).toList(),
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
      child: Column(
        children: [
          const Padding(
            padding:
                EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Account Type',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          SwitchListTile(
            value: _wantsPrivate,
            title: const Text('Private Account'),
            subtitle: const Text(
              'Paid account with private features',
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
            const Padding(
              padding:
                  EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Guest / Free mode',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAuthenticationCard(
    AuthProvider auth,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              _accountTitle(auth),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            if (!auth.isAuthenticated)
              _buildAuthForm(auth),
            if (auth.isAuthenticated)
              _buildUserActions(auth),
          ],
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
            title: const Text(
              'Medical Documents',
            ),
            subtitle: const Text(
              'Scans, PDFs, and videos',
            ),
            trailing:
                const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const DocumentsScreen(),
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
            title: const Text(
              'Insurance Cards',
            ),
            subtitle: const Text(
              'Front and back photos',
            ),
            trailing:
                const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const InsuranceScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPrivatePendingCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Private Account Pending',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Complete the USD 50 payment to activate '
              'private features.',
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton(
                  onPressed:
                      _payForPrivateAccount,
                  child:
                      const Text('Pay USD 50'),
                ),
                OutlinedButton(
                  onPressed:
                      _cancelPrivateRequest,
                  child: const Text(
                    'Cancel Request',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistics(
    MedicationProvider medications,
    DoctorProvider doctors,
    PharmacyProvider pharmacies,
  ) {
    return Row(
      children: [
        _buildStatCard(
          'Medications',
          medications.medications.length
              .toString(),
          Icons.medication,
          Colors.blue,
        ),
        const SizedBox(width: 8),
        _buildStatCard(
          'Doctors',
          doctors.doctors.length.toString(),
          Icons.medical_services,
          Colors.green,
        ),
        const SizedBox(width: 8),
        _buildStatCard(
          'Pharmacies',
          pharmacies.pharmacies.length.toString(),
          Icons.local_pharmacy,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildShareButton({
    required AuthProvider auth,
    required MedicationProvider medications,
    required DoctorProvider doctors,
    required PharmacyProvider pharmacies,
    required DocumentProvider documents,
    required InsuranceProvider insurance,
  }) {
    return SizedBox(
      height: 52,
      child: FilledButton.icon(
        onPressed: () => _shareRecord(
          auth: auth,
          medications: medications,
          doctors: doctors,
          pharmacies: pharmacies,
          documents: documents,
          insurance: insurance,
        ),
        icon: const Icon(Icons.share),
        label: const Text(
          'Export & Share Record',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(12),
          ),
        ),
      ),
    );
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
                textAlign: TextAlign.center,
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

  Widget _buildAuthForm(AuthProvider auth) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          if (!_isLogin) ...[
            TextFormField(
              controller: _nameController,
              enabled: !auth.isLoading,
              textInputAction:
                  TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon:
                    Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Enter your name.';
                }

                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              enabled: !auth.isLoading,
              keyboardType:
                  TextInputType.phone,
              textInputAction:
                  TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon:
                    Icon(Icons.phone_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Enter your phone number.';
                }

                return null;
              },
            ),
            const SizedBox(height: 12),
          ],
          TextFormField(
            controller: _emailController,
            enabled: !auth.isLoading,
            keyboardType:
                TextInputType.emailAddress,
            textInputAction:
                TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon:
                  Icon(Icons.email_outlined),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              final email =
                  value?.trim() ?? '';

              if (email.isEmpty) {
                return 'Enter your email.';
              }

              if (!email.contains('@') ||
                  !email.contains('.')) {
                return 'Enter a valid email.';
              }

              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _passwordController,
            enabled: !auth.isLoading,
            obscureText: _obscurePassword,
            textInputAction:
                TextInputAction.done,
            onFieldSubmitted: (_) {
              if (!auth.isLoading) {
                _submitAuth(auth);
              }
            },
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon:
                  const Icon(Icons.lock_outline),
              border:
                  const OutlineInputBorder(),
              suffixIcon: IconButton(
                tooltip: _obscurePassword
                    ? 'Show password'
                    : 'Hide password',
                onPressed: auth.isLoading
                    ? null
                    : () {
                        setState(() {
                          _obscurePassword =
                              !_obscurePassword;
                        });
                      },
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: (value) {
              final password = value ?? '';

              if (password.isEmpty) {
                return 'Enter your password.';
              }

              if (!_isLogin &&
                  password.length < 6) {
                return 'Password must contain at least 6 characters.';
              }

              return null;
            },
          ),
          if (auth.errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius:
                    BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.red.shade200,
                ),
              ),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.error_outline,
                    color:
                        Colors.red.shade700,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      auth.errorMessage!,
                      style: TextStyle(
                        color:
                            Colors.red.shade700,
                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: FilledButton(
              onPressed: auth.isLoading
                  ? null
                  : () => _submitAuth(auth),
              child: auth.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _isLogin
                          ? 'Login'
                          : 'Sign Up',
                    ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: auth.isLoading
                ? null
                : () {
                    auth.clearError();

                    _formKey.currentState
                        ?.reset();

                    setState(() {
                      _isLogin = !_isLogin;
                    });
                  },
            child: Text(
              _isLogin
                  ? "Don't have an account? Sign Up"
                  : 'Already have an account? Login',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserActions(
    AuthProvider auth,
  ) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: auth.isLoading
            ? null
            : () async {
                await auth.signOut();

                if (!mounted) return;

                _showSnack(
                  'Signed out successfully.',
                );
              },
        icon: const Icon(Icons.logout),
        label: const Text('Sign Out'),
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

