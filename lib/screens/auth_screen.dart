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
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  final TextEditingController _nameController =
      TextEditingController();

  final TextEditingController _phoneController =
      TextEditingController();

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

    final AuthProvider auth =
        context.read<AuthProvider>();

    auth.clearError();

    // ==========================================================
    // NORMAL USER LOGIN
    // ==========================================================

    if (_isLogin) {
      final LoginResult result = await auth.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      switch (result) {
        // ------------------------------------------------------
        // ADMIN
        //
        // Admin authentication must use the dedicated
        // Admin Login screen. Do NOT open AdminScreen here.
        // ------------------------------------------------------

        case LoginResult.admin:
          await auth.signOut();

          if (!mounted) {
            return;
          }

          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text(
                  'Administrator access required.',
                ),
              ),
            );

          return;

        // ------------------------------------------------------
        // NORMAL ACTIVE USER
        // ------------------------------------------------------

        case LoginResult.activeUser:
          Navigator.of(context).pop(
            LoginResult.activeUser,
          );

          return;

        // ------------------------------------------------------
        // USER NOT FOUND / NOT ACTIVATED
        // ------------------------------------------------------

        case LoginResult.userNotFound:
        case LoginResult.notActivated:
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(
                  _getYourOwnCopyMessage(context),
                ),
              ),
            );

          return;

        // ------------------------------------------------------
        // LOGIN FAILED
        // ------------------------------------------------------

        case LoginResult.failed:
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(
                  auth.errorMessage ??
                      _localizedText(
                        context,
                        english:
                            'Unable to sign in. Please try again.',
                        arabic:
                            'تعذر تسجيل الدخول. يرجى المحاولة مرة أخرى.',
                      ),
                ),
              ),
            );

          return;
      }
    }

    // ==========================================================
    // CREATE ACCOUNT
    // ==========================================================

    final bool success = await auth.signUp(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) {
      return;
    }

    if (!success) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              auth.errorMessage ??
                  _localizedText(
                    context,
                    english:
                        'Unable to create your account.',
                    arabic:
                        'تعذر إنشاء حسابك.',
                  ),
            ),
          ),
        );

      return;
    }

    final currentUser = auth.currentUser;

    if (currentUser != null) {
      Navigator.of(context).pop(
        LoginResult.activeUser,
      );

      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            auth.errorMessage ??
                _localizedText(
                  context,
                  english:
                      'Account created. Please confirm your email before signing in.',
                  arabic:
                      'تم إنشاء الحساب. يرجى تأكيد بريدك الإلكتروني قبل تسجيل الدخول.',
                ),
          ),
        ),
      );
  }

  // ============================================================
  // TOGGLE LOGIN / SIGN UP
  // ============================================================

  void _toggleMode() {
    context.read<AuthProvider>().clearError();

    setState(() {
      _isLogin = !_isLogin;
    });
  }

  // ============================================================
  // LOCALIZATION
  // ============================================================

  String _getYourOwnCopyMessage(
    BuildContext context,
  ) {
    final String languageCode =
        Localizations.localeOf(context)
            .languageCode
            .toLowerCase();

    switch (languageCode) {
      case 'ar':
        return 'احصل على نسختك الخاصة';

      case 'fr':
        return 'Obtenez votre propre copie';

      case 'de':
        return 'Holen Sie sich Ihre eigene Kopie';

      case 'es':
        return 'Obtén tu propia copia';

      case 'it':
        return 'Ottieni la tua copia';

      case 'pt':
        return 'Obtenha sua própria cópia';

      case 'tr':
        return 'Kendi kopyanızı edinin';

      case 'ru':
        return 'Получите свою собственную копию';

      case 'zh':
        return '获取您自己的副本';

      case 'ja':
        return '自分用のコピーを入手してください';

      default:
        return 'Get your own copy';
    }
  }

  String _localizedText(
    BuildContext context, {
    required String english,
    required String arabic,
  }) {
    final String languageCode =
        Localizations.localeOf(context)
            .languageCode
            .toLowerCase();

    if (languageCode == 'ar') {
      return arabic;
    }

    return english;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth =
        context.watch<AuthProvider>();

    final LanguageProvider language =
        context.watch<LanguageProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isLogin
              ? 'LOGIN'
              : 'CREATE ACCOUNT',
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
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),

                    const SizedBox(
                      height: 32,
                    ),

                    // ==================================================
                    // NAME
                    // ==================================================

                    if (!_isLogin) ...[
                      TextFormField(
                        controller:
                            _nameController,
                        enabled:
                            !auth.isLoading,
                        textInputAction:
                            TextInputAction.next,
                        decoration:
                            const InputDecoration(
                          labelText: 'Name',
                          prefixIcon:
                              Icon(
                            Icons
                                .person_outline,
                          ),
                          border:
                              OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return _localizedText(
                              context,
                              english:
                                  'Please enter your name.',
                              arabic:
                                  'يرجى إدخال اسمك.',
                            );
                          }

                          return null;
                        },
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      // ==================================================
                      // PHONE
                      // ==================================================

                      TextFormField(
                        controller:
                            _phoneController,
                        enabled:
                            !auth.isLoading,
                        keyboardType:
                            TextInputType.phone,
                        textInputAction:
                            TextInputAction.next,
                        decoration:
                            const InputDecoration(
                          labelText: 'Phone',
                          prefixIcon:
                              Icon(
                            Icons
                                .phone_outlined,
                          ),
                          border:
                              OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return _localizedText(
                              context,
                              english:
                                  'Please enter your phone number.',
                              arabic:
                                  'يرجى إدخال رقم هاتفك.',
                            );
                          }

                          return null;
                        },
                      ),

                      const SizedBox(
                        height: 16,
                      ),
                    ],

                    // ==================================================
                    // EMAIL
                    // ==================================================

                    TextFormField(
                      controller:
                          _emailController,
                      enabled:
                          !auth.isLoading,
                      keyboardType:
                          TextInputType.emailAddress,
                      textInputAction:
                          TextInputAction.next,
                      decoration:
                          const InputDecoration(
                        labelText: 'Email',
                        prefixIcon:
                            Icon(
                          Icons
                              .email_outlined,
                        ),
                        border:
                            OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final String email =
                            value?.trim() ?? '';

                        if (email.isEmpty) {
                          return _localizedText(
                            context,
                            english:
                                'Please enter your email.',
                            arabic:
                                'يرجى إدخال بريدك الإلكتروني.',
                          );
                        }

                        if (!email.contains('@')) {
                          return _localizedText(
                            context,
                            english:
                                'Please enter a valid email.',
                            arabic:
                                'يرجى إدخال بريد إلكتروني صالح.',
                          );
                        }

                        return null;
                      },
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    // ==================================================
                    // PASSWORD
                    // ==================================================

                    TextFormField(
                      controller:
                          _passwordController,
                      enabled:
                          !auth.isLoading,
                      obscureText:
                          _obscurePassword,
                      textInputAction:
                          TextInputAction.done,
                      onFieldSubmitted: (_) {
                        if (!auth.isLoading) {
                          _submit();
                        }
                      },
                      decoration:
                          InputDecoration(
                        labelText: 'Password',
                        prefixIcon:
                            const Icon(
                          Icons.lock_outline,
                        ),
                        border:
                            const OutlineInputBorder(),
                        suffixIcon:
                            IconButton(
                          tooltip:
                              _obscurePassword
                                  ? 'Show password'
                                  : 'Hide password',
                          onPressed:
                              auth.isLoading
                                  ? null
                                  : () {
                                      setState(() {
                                        _obscurePassword =
                                            !_obscurePassword;
                                      });
                                    },
                          icon: Icon(
                            _obscurePassword
                                ? Icons
                                    .visibility_outlined
                                : Icons
                                    .visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) {
                        final String password =
                            value ?? '';

                        if (password.isEmpty) {
                          return _localizedText(
                            context,
                            english:
                                'Please enter your password.',
                            arabic:
                                'يرجى إدخال كلمة المرور.',
                          );
                        }

                        if (!_isLogin &&
                            password.length < 6) {
                          return _localizedText(
                            context,
                            english:
                                'Password must contain at least 6 characters.',
                            arabic:
                                'يجب أن تحتوي كلمة المرور على 6 أحرف على الأقل.',
                          );
                        }

                        return null;
                      },
                    ),

                    // ==================================================
                    // ERROR
                    // ==================================================

                    if (auth.errorMessage != null) ...[
                      const SizedBox(
                        height: 16,
                      ),

                      Container(
                        padding:
                            const EdgeInsets.all(12),
                        decoration:
                            BoxDecoration(
                          color:
                              Colors.red.shade50,
                          borderRadius:
                              BorderRadius.circular(8),
                          border:
                              Border.all(
                            color:
                                Colors.red.shade200,
                          ),
                        ),
                        child: Text(
                          auth.errorMessage!,
                          textAlign:
                              TextAlign.center,
                          style: TextStyle(
                            color:
                                Colors.red.shade700,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(
                      height: 24,
                    ),

                    // ==================================================
                    // SUBMIT BUTTON
                    // ==================================================

                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed:
                            auth.isLoading
                                ? null
                                : _submit,
                        child: auth.isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _isLogin
                                    ? 'LOGIN'
                                    : 'CREATE ACCOUNT',
                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    // ==================================================
                    // SWITCH LOGIN / SIGNUP
                    // ==================================================

                    TextButton(
                      onPressed:
                          auth.isLoading
                              ? null
                              : _toggleMode,
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
                      textAlign:
                          TextAlign.center,
                      style:
                          Theme.of(context)
                              .textTheme
                              .bodySmall,
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
            );
          },
        ),

        const SizedBox(
          height: 12,
        ),

        Text(
          _isLogin
              ? 'Welcome back'
              : 'Create your SANA account',
          textAlign:
              TextAlign.center,
          style:
              Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(
                fontWeight:
                    FontWeight.bold,
              ),
        ),

        const SizedBox(
          height: 8,
        ),

        Text(
          _isLogin
              ? 'Sign in to access your health information.'
              : 'Keep your health information organized in one place.',
          textAlign:
              TextAlign.center,
          style:
              Theme.of(context)
                  .textTheme
                  .bodyMedium,
        ),
      ],
    );
  }
}