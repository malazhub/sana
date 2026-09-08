import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  final TextEditingController _nameController = TextEditingController();

  final TextEditingController _phoneController = TextEditingController();

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

  // ============================================================
  // SUBMIT
  // ============================================================

  Future<void> _submit() async {
    final form = _formKey.currentState;

    if (form == null || !form.validate()) {
      return;
    }

    final auth = context.read<AuthProvider>();

    auth.clearError();

    if (_isLogin) {
      final success = await auth.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      if (!success) {
        _showError(
          auth.errorMessage ??
              _localizedText(
                context,
                english: 'Unable to sign in. Please try again.',
                arabic:
                    'ØªØ¹Ø°Ø± ØªØ³Ø¬ÙŠÙ„ Ø§Ù„Ø¯Ø®ÙˆÙ„. ÙŠØ±Ø¬Ù‰ Ø§Ù„Ù…Ø­Ø§ÙˆÙ„Ø© Ù…Ø±Ø© Ø£Ø®Ø±Ù‰.',
              ),
        );
        return;
      }

      /*
       * AuthGate owns navigation.
       *
       * Do not push AdminScreen, HomeScreen or
       * SubscriptionScreen from this widget.
       *
       * AuthProvider notifies listeners after login,
       * causing AuthGate to rebuild automatically.
       */
      return;
    }

    final success = await auth.signUp(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) {
      return;
    }

    if (!success) {
      _showError(
        auth.errorMessage ??
            _localizedText(
              context,
              english: 'Unable to create your account.',
              arabic: 'ØªØ¹Ø°Ø± Ø¥Ù†Ø´Ø§Ø¡ Ø­Ø³Ø§Ø¨Ùƒ.',
            ),
      );
      return;
    }

    /*
     * If Supabase email confirmation is enabled,
     * signUp may create the account without creating
     * an authenticated session.
     */
    if (auth.isAuthenticated) {
      return;
    }

    _showMessage(
      title: _localizedText(
        context,
        english: 'Account created',
        arabic: 'ØªÙ… Ø¥Ù†Ø´Ø§Ø¡ Ø§Ù„Ø­Ø³Ø§Ø¨',
      ),
      message: _localizedText(
        context,
        english:
            'Your account was created successfully. Please confirm your email before signing in.',
        arabic:
            'ØªÙ… Ø¥Ù†Ø´Ø§Ø¡ Ø­Ø³Ø§Ø¨Ùƒ Ø¨Ù†Ø¬Ø§Ø­. ÙŠØ±Ø¬Ù‰ ØªØ£ÙƒÙŠØ¯ Ø¨Ø±ÙŠØ¯Ùƒ Ø§Ù„Ø¥Ù„ÙƒØªØ±ÙˆÙ†ÙŠ Ù‚Ø¨Ù„ ØªØ³Ø¬ÙŠÙ„ Ø§Ù„Ø¯Ø®ÙˆÙ„.',
      ),
      icon: Icons.mark_email_read_outlined,
    );
  }

  // ============================================================
  // LOGIN / SIGNUP TOGGLE
  // ============================================================

  void _toggleMode() {
    context.read<AuthProvider>().clearError();

    setState(() {
      _isLogin = !_isLogin;
    });
  }

  // ============================================================
  // ERROR MESSAGE
  // ============================================================

  void _showError(
    String message,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // INFORMATION MESSAGE
  // ============================================================

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
                const SizedBox(
                  height: 16,
                ),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                const SizedBox(
                  height: 24,
                ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(
                        sheetContext,
                      ).pop();
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

  // ============================================================
  // LOCALIZATION
  // ============================================================

  String _localizedText(
    BuildContext context, {
    required String english,
    required String arabic,
  }) {
    final languageCode = Localizations.localeOf(
      context,
    ).languageCode.toLowerCase();

    if (languageCode == 'ar') {
      return arabic;
    }

    return english;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final auth = context.watch<AuthProvider>();

    final language = context.watch<LanguageProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isLogin ? 'LOGIN' : 'CREATE ACCOUNT',
        ),
        centerTitle: true,
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),

                    const SizedBox(
                      height: 32,
                    ),

                    // ------------------------------------------------
                    // NAME
                    // ------------------------------------------------

                    if (!_isLogin) ...[
                      TextFormField(
                        controller: _nameController,
                        enabled: !auth.isLoading,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          prefixIcon: Icon(
                            Icons.person_outline,
                          ),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return _localizedText(
                              context,
                              english: 'Please enter your name.',
                              arabic: 'ÙŠØ±Ø¬Ù‰ Ø¥Ø¯Ø®Ø§Ù„ Ø§Ø³Ù…Ùƒ.',
                            );
                          }

                          return null;
                        },
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      // ------------------------------------------------
                      // PHONE
                      // ------------------------------------------------

                      TextFormField(
                        controller: _phoneController,
                        enabled: !auth.isLoading,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Phone',
                          prefixIcon: Icon(
                            Icons.phone_outlined,
                          ),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return _localizedText(
                              context,
                              english: 'Please enter your phone number.',
                              arabic: 'ÙŠØ±Ø¬Ù‰ Ø¥Ø¯Ø®Ø§Ù„ Ø±Ù‚Ù… Ù‡Ø§ØªÙÙƒ.',
                            );
                          }

                          return null;
                        },
                      ),

                      const SizedBox(
                        height: 16,
                      ),
                    ],

                    // ------------------------------------------------
                    // EMAIL
                    // ------------------------------------------------

                    TextFormField(
                      controller: _emailController,
                      enabled: !auth.isLoading,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(
                          Icons.email_outlined,
                        ),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final email = value?.trim() ?? '';

                        if (email.isEmpty) {
                          return _localizedText(
                            context,
                            english: 'Please enter your email.',
                            arabic:
                                'ÙŠØ±Ø¬Ù‰ Ø¥Ø¯Ø®Ø§Ù„ Ø¨Ø±ÙŠØ¯Ùƒ Ø§Ù„Ø¥Ù„ÙƒØªØ±ÙˆÙ†ÙŠ.',
                          );
                        }

                        if (!email.contains(
                              '@',
                            ) ||
                            !email.contains(
                              '.',
                            )) {
                          return _localizedText(
                            context,
                            english: 'Please enter a valid email.',
                            arabic:
                                'ÙŠØ±Ø¬Ù‰ Ø¥Ø¯Ø®Ø§Ù„ Ø¨Ø±ÙŠØ¯ Ø¥Ù„ÙƒØªØ±ÙˆÙ†ÙŠ ØµØ§Ù„Ø­.',
                          );
                        }

                        return null;
                      },
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    // ------------------------------------------------
                    // PASSWORD
                    // ------------------------------------------------

                    TextFormField(
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
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                        ),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword
                              ? 'Show password'
                              : 'Hide password',
                          onPressed: auth.isLoading
                              ? null
                              : () {
                                  setState(
                                    () {
                                      _obscurePassword = !_obscurePassword;
                                    },
                                  );
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
                          return _localizedText(
                            context,
                            english: 'Please enter your password.',
                            arabic:
                                'ÙŠØ±Ø¬Ù‰ Ø¥Ø¯Ø®Ø§Ù„ ÙƒÙ„Ù…Ø© Ø§Ù„Ù…Ø±ÙˆØ±.',
                          );
                        }

                        if (!_isLogin && password.length < 6) {
                          return _localizedText(
                            context,
                            english:
                                'Password must contain at least 6 characters.',
                            arabic:
                                'ÙŠØ¬Ø¨ Ø£Ù† ØªØ­ØªÙˆÙŠ ÙƒÙ„Ù…Ø© Ø§Ù„Ù…Ø±ÙˆØ± Ø¹Ù„Ù‰ 6 Ø£Ø­Ø±Ù Ø¹Ù„Ù‰ Ø§Ù„Ø£Ù‚Ù„.',
                          );
                        }

                        return null;
                      },
                    ),

                    // ------------------------------------------------
                    // ERROR
                    // ------------------------------------------------

                    if (auth.errorMessage != null) ...[
                      const SizedBox(
                        height: 16,
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(
                            8,
                          ),
                          border: Border.all(
                            color: Colors.red.shade200,
                          ),
                        ),
                        child: Text(
                          auth.errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(
                      height: 24,
                    ),

                    // ------------------------------------------------
                    // SUBMIT
                    // ------------------------------------------------

                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: auth.isLoading ? null : _submit,
                        child: auth.isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _isLogin ? 'LOGIN' : 'CREATE ACCOUNT',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    // ------------------------------------------------
                    // SWITCH MODE
                    // ------------------------------------------------

                    TextButton(
                      onPressed: auth.isLoading ? null : _toggleMode,
                      child: Text(
                        _isLogin
                            ? 'Create a new account'
                            : 'Already have an account? Sign in',
                      ),
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    Text(
                      'Language: '
                      '${language.locale.languageCode.toUpperCase()}',
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall,
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

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Column(
      children: [
        Image.asset(
          'assets/health_logo.png',
          height: 72,
          errorBuilder: (_, __, ___) {
            return const Icon(
              Icons.health_and_safety,
              size: 72,
              color: Colors.teal,
            );
          },
        ),
        const SizedBox(
          height: 12,
        ),
        Text(
          _isLogin ? 'Welcome back' : 'Create your SANA account',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(
          height: 8,
        ),
        Text(
          _isLogin
              ? 'Sign in to continue to SANA.'
              : 'Create your account to get started.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
      ],
    );
  }
}
