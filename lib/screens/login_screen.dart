import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
  });

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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final auth = context.read<AuthProvider>();

    auth.clearError();

    final bool success;

    if (_isLogin) {
      success = await auth.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } else {
      success = await auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
      );
    }

    if (!mounted) return;

    if (!success) {
      _showError(
        auth.errorMessage ??
            (_isLogin
                ? 'Unable to sign in.'
                : 'Unable to create account.'),
      );
      return;
    }

    // AuthGate handles navigation automatically.
    //
    // We intentionally do not push HomeScreen, AdminScreen,
    // or SubscriptionScreen from here.
    if (!_isLogin && auth.currentUser == null) {
      _showMessage(
        title: 'Account Created',
        message:
            'Your account was created. Please confirm your email before signing in.',
        icon: Icons.mark_email_outlined,
      );
    }
  }

  void _toggleMode() {
    context.read<AuthProvider>().clearError();

    _formKey.currentState?.reset();

    setState(() {
      _isLogin = !_isLogin;
    });
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      _showError('Enter your email address first.');
      return;
    }

    final auth = context.read<AuthProvider>();

    final success = await auth.resetPassword(email);

    if (!mounted) return;

    if (success) {
      _showMessage(
        title: 'Password Reset',
        message:
            'If the email exists, a password reset message has been sent.',
        icon: Icons.mark_email_read_outlined,
      );
    } else {
      _showError(
        auth.errorMessage ??
            'Unable to send password reset email.',
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text(message),
        ),
      );
  }

  void _showMessage({
    required String title,
    required String message,
    required IconData icon,
  }) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              24,
              8,
              24,
              32,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 52,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                    },
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF009688),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          _isLogin ? 'Login' : 'Create Account',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
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

                    const SizedBox(height: 32),

                    if (!_isLogin) ...[
                      TextFormField(
                        controller: _nameController,
                        enabled: !auth.isLoading,
                        textInputAction:
                            TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          prefixIcon:
                              Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Please enter your name.';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _phoneController,
                        enabled: !auth.isLoading,
                        keyboardType:
                            TextInputType.phone,
                        textInputAction:
                            TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Phone',
                          prefixIcon:
                              Icon(Icons.phone_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Please enter your phone number.';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 16),
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
                          return 'Please enter your email.';
                        }

                        if (!email.contains('@') ||
                            !email.contains('.')) {
                          return 'Please enter a valid email.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _passwordController,
                      enabled: !auth.isLoading,
                      obscureText: _obscurePassword,
                      textInputAction:
                          TextInputAction.done,
                      onFieldSubmitted: (_) {
                        if (!auth.isLoading) {
                          _submit();
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
                          return 'Please enter your password.';
                        }

                        if (!_isLogin &&
                            password.length < 6) {
                          return 'Password must contain at least 6 characters.';
                        }

                        return null;
                      },
                    ),

                    if (auth.errorMessage != null) ...[
                      const SizedBox(height: 16),
                      _buildError(auth.errorMessage!),
                    ],

                    const SizedBox(height: 24),

                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed:
                            auth.isLoading ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF009688),
                        ),
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
                                    ? 'LOGIN'
                                    : 'CREATE ACCOUNT',
                                style: const TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextButton(
                      onPressed:
                          auth.isLoading ? null : _toggleMode,
                      child: Text(
                        _isLogin
                            ? 'Create a new account'
                            : 'Already have an account? Sign in',
                      ),
                    ),

                    if (_isLogin)
                      TextButton(
                        onPressed:
                            auth.isLoading
                                ? null
                                : _resetPassword,
                        child:
                            const Text('Forgot password?'),
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
          width: 82,
          height: 82,
          decoration: BoxDecoration(
            color: const Color(0xFF009688)
                .withValues(alpha: 0.10),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.health_and_safety,
            size: 48,
            color: Color(0xFF009688),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _isLogin
              ? 'Welcome to SANA'
              : 'Join SANA',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isLogin
              ? 'Sign in to continue'
              : 'Create your account to get started',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _buildError(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
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
                color: Colors.red.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}