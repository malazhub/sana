import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLogin = true;
  bool _obscurePassword = true;

  static const Color _teal = Color(0xFF00897B);
  static const Color _darkTeal = Color(0xFF00695C);
  static const Color _background = Color(0xFFF4FAF9);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final auth = context.read<AuthProvider>();

    auth.clearError();

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    final bool success;

    if (_isLogin) {
      success = await auth.signIn(
        email: email,
        password: password,
      );
    } else {
      success = await auth.signUp(
        email: email,
        password: password,
        name: name,
        phone: phone,
      );
    }

    if (!mounted) return;

    if (!success) {
      _showError(
        auth.errorMessage ??
            (_isLogin
                ? 'Unable to sign in. Please check your details.'
                : 'Unable to create your account.'),
      );
      return;
    }

    // AuthGate is responsible for navigation.
    if (!_isLogin && auth.currentUser == null) {
      _showInfoDialog(
        title: 'Account Created',
        message:
            'Your account has been created successfully.\n\n'
            'Please check your email and confirm your email address '
            'before signing in.',
        icon: Icons.mark_email_read_outlined,
      );
    }
  }

  void _toggleMode() {
    final auth = context.read<AuthProvider>();

    auth.clearError();
    _formKey.currentState?.reset();

    setState(() {
      _isLogin = !_isLogin;
      _obscurePassword = true;
    });
  }

  Future<void> _resetPassword() async {
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showError('Enter your email address first.');
      return;
    }

    final emailIsValid =
        RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);

    if (!emailIsValid) {
      _showError('Enter a valid email address first.');
      return;
    }

    final auth = context.read<AuthProvider>();

    auth.clearError();

    final success = await auth.resetPassword(email);

    if (!mounted) return;

    if (success) {
      _showInfoDialog(
        title: 'Password Reset',
        message:
            'If an account exists for this email address, '
            'a password reset email has been sent.',
        icon: Icons.lock_reset_outlined,
      );
    } else {
      _showError(
        auth.errorMessage ??
            'Unable to send the password reset email.',
      );
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade700,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Row(
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(message),
              ),
            ],
          ),
        ),
      );
  }

  void _showInfoDialog({
    required String title,
    required String message,
    required IconData icon,
  }) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          icon: Icon(
            icon,
            size: 48,
            color: _teal,
          ),
          title: Text(
            title,
            textAlign: TextAlign.center,
          ),
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade700,
              height: 1.45,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _teal,
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('OK'),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _darkTeal,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'SANA',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(
              20,
              28,
              20,
              32,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 460,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),

                    const SizedBox(height: 30),

                    if (!_isLogin) ...[
                      _buildTextField(
                        controller: _nameController,
                        label: 'Full Name',
                        hint: 'Enter your name',
                        icon: Icons.person_outline,
                        enabled: !auth.isLoading,
                        textInputAction:
                            TextInputAction.next,
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Please enter your name.';
                          }

                          if (value.trim().length < 2) {
                            return 'Please enter a valid name.';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 15),

                      _buildTextField(
                        controller: _phoneController,
                        label: 'Phone',
                        hint: 'Enter your phone number',
                        icon: Icons.phone_outlined,
                        enabled: !auth.isLoading,
                        keyboardType: TextInputType.phone,
                        textInputAction:
                            TextInputAction.next,
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Please enter your phone number.';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 15),
                    ],

                    _buildTextField(
                      controller: _emailController,
                      label: 'Email',
                      hint: 'Enter your email address',
                      icon: Icons.email_outlined,
                      enabled: !auth.isLoading,
                      keyboardType:
                          TextInputType.emailAddress,
                      textInputAction:
                          TextInputAction.next,
                      validator: (value) {
                        final email =
                            value?.trim() ?? '';

                        if (email.isEmpty) {
                          return 'Please enter your email.';
                        }

                        final valid = RegExp(
                          r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                        ).hasMatch(email);

                        if (!valid) {
                          return 'Please enter a valid email.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 15),

                    _buildPasswordField(auth),

                    if (auth.errorMessage != null) ...[
                      const SizedBox(height: 15),
                      _buildError(auth.errorMessage!),
                    ],

                    const SizedBox(height: 22),

                    SizedBox(
                      height: 54,
                      child: FilledButton(
                        onPressed:
                            auth.isLoading ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: _teal,
                          disabledBackgroundColor:
                              Colors.teal.shade200,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                        ),
                        child: auth.isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _isLogin
                                    ? 'SIGN IN'
                                    : 'CREATE ACCOUNT',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight:
                                      FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    OutlinedButton(
                      onPressed:
                          auth.isLoading ? null : _toggleMode,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _teal,
                        side: BorderSide(
                          color: _teal.withValues(alpha: 0.5),
                        ),
                        minimumSize:
                            const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        _isLogin
                            ? 'Create a new account'
                            : 'I already have an account',
                      ),
                    ),

                    if (_isLogin) ...[
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: auth.isLoading
                            ? null
                            : _resetPassword,
                        child: const Text(
                          'Forgot your password?',
                        ),
                      ),
                    ],

                    const SizedBox(height: 18),

                    Text(
                      'SANA • Smart Health Tracker',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _teal.withValues(alpha: 0.15),
                _teal.withValues(alpha: 0.05),
              ],
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: _teal.withValues(alpha: 0.18),
            ),
          ),
          child: const Icon(
            Icons.health_and_safety,
            size: 52,
            color: _teal,
          ),
        ),

        const SizedBox(height: 18),

        Text(
          _isLogin
              ? 'Welcome to SANA'
              : 'Create your SANA account',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          _isLogin
              ? 'Sign in to manage your health records'
              : 'Keep your health information organized in one place',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool enabled,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization:
          keyboardType == TextInputType.emailAddress
              ? TextCapitalization.none
              : TextCapitalization.sentences,
      autocorrect: false,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: _teal,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.red.shade400,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.red.shade600,
            width: 2,
          ),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildPasswordField(AuthProvider auth) {
    return TextFormField(
      controller: _passwordController,
      enabled: !auth.isLoading,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) {
        if (!auth.isLoading) {
          _submit();
        }
      },
      decoration: InputDecoration(
        labelText: 'Password',
        hintText:
            _isLogin
                ? 'Enter your password'
                : 'At least 6 characters',
        prefixIcon: const Icon(
          Icons.lock_outline,
        ),
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
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(14),
          ),
          borderSide: BorderSide(
            color: _teal,
            width: 2,
          ),
        ),
      ),
      validator: (value) {
        final password = value ?? '';

        if (password.isEmpty) {
          return 'Please enter your password.';
        }

        if (!_isLogin && password.length < 6) {
          return 'Password must contain at least 6 characters.';
        }

        return null;
      },
    );
  }

  Widget _buildError(String message) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
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
            color: Colors.red.shade700,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.red.shade800,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}