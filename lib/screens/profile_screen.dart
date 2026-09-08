import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../services/payment_service.dart';

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
  bool _busy = false;

  static const String _payoneerUrl =
      'https://link.payoneer.com/Token?t=CA1D522054524AC081ACCB17B5D8571B&src=pl';

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthProvider auth) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _busy = true);
    auth.clearError();

    final success = _isLogin
        ? await auth.signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          )
        : await auth.signUp(
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

    if (!mounted) return;

    setState(() => _busy = false);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            auth.errorMessage ??
                (_isLogin ? 'Unable to sign in.' : 'Unable to create account.'),
          ),
        ),
      );
      return;
    }

    if (_isLogin) {
      if (auth.isAdmin) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Administrator account signed in.')),
        );
      } else if (!auth.isActive) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inactive account: Guest Mode is active.'),
          ),
        );
      }
    }

    if (!_isLogin && _wantsPrivate) {
      setState(() => _privateRequested = true);
    }
  }

  Future<void> _openPayoneer() async {
    final opened = await PaymentService.openPaymentUrl(_payoneerUrl);

    if (!mounted) return;

    if (opened) {
      setState(() => _privatePaid = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment page opened.'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open payment page.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final language = context.watch<LanguageProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _languageBox(language),
            const SizedBox(height: 16),
            _accountBox(auth),
            const SizedBox(height: 16),
            _authBox(auth),
            if (auth.isAuthenticated && _privateRequested && !_privatePaid) ...[
              const SizedBox(height: 16),
              _privatePaymentBox(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _languageBox(LanguageProvider language) {
    final languages = language.getSupportedLanguages();
    final selected = languages.contains(language.locale.languageCode)
        ? language.locale.languageCode
        : languages.first;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DropdownButtonFormField<String>(
          initialValue: selected,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Language',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.language),
          ),
          items: languages
              .map(
                (code) => DropdownMenuItem<String>(
                  value: code,
                  child: Text(language.getLanguageName(code)),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              language.setLanguage(value);
            }
          },
        ),
      ),
    );
  }

  Widget _accountBox(AuthProvider auth) {
    final title = auth.isAdmin
        ? 'Administrator'
        : auth.isActive
            ? 'Active User'
            : 'Guest Mode';

    return Card(
      child: ListTile(
        leading: Icon(
          auth.isAdmin
              ? Icons.admin_panel_settings
              : auth.isActive
                  ? Icons.verified_user
                  : Icons.person_outline,
          color: Colors.teal,
        ),
        title: Text(title),
        subtitle: Text(
          auth.currentUser?.email ?? 'No signed-in account',
        ),
      ),
    );
  }

  Widget _authBox(AuthProvider auth) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (!_isLogin)
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
              if (!_isLogin) const SizedBox(height: 10),
              if (!_isLogin)
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    border: OutlineInputBorder(),
                  ),
                ),
              if (!_isLogin) const SizedBox(height: 10),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email is required.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'Password must contain at least 6 characters.';
                  }
                  return null;
                },
              ),
              if (!_isLogin) ...[
                const SizedBox(height: 10),
                SwitchListTile(
                  value: _wantsPrivate,
                  title: const Text('Private Account'),
                  onChanged: (value) {
                    setState(() => _wantsPrivate = value);
                  },
                ),
              ],
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _busy ? null : () => _submit(auth),
                  child: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(),
                        )
                      : Text(
                          _isLogin ? 'LOGIN' : 'CREATE ACCOUNT',
                        ),
                ),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: _busy
                    ? null
                    : () {
                        setState(() => _isLogin = !_isLogin);
                      },
                child: Text(
                  _isLogin ? 'Create account' : 'Return to login',
                ),
              ),
              if (auth.isAuthenticated)
                TextButton(
                  onPressed: () => auth.signOut(),
                  child: const Text('LOGOUT'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _privatePaymentBox() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Get Your Own Copy',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Private copy payment is linked to the existing Payoneer function.',
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _openPayoneer,
              icon: const Icon(Icons.payment),
              label: const Text('Pay with Payoneer'),
            ),
          ],
        ),
      ),
    );
  }
}
