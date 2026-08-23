import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'admin_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({
    super.key,
  });

  @override
  State<AdminLoginScreen> createState() =>
      _AdminLoginScreenState();
}

class _AdminLoginScreenState
    extends State<AdminLoginScreen> {
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  final TextEditingController
      _emailController =
      TextEditingController();

  final TextEditingController
      _passwordController =
      TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    final AuthProvider auth =
        context.read<AuthProvider>();

    auth.clearError();

    final LoginResult result =
        await auth.signIn(
      email:
          _emailController.text.trim(),
      password:
          _passwordController.text,
    );

    if (!mounted) {
      return;
    }

    switch (result) {
      case LoginResult.admin:
        /*
         * signIn() has already loaded the users-table
         * profile. Verify the role once more immediately
         * before opening the protected administrator screen.
         */
        if (!auth.isAuthenticated ||
            !auth.isAdmin) {
          await auth.signOut();

          if (!mounted) {
            return;
          }

          _showError(
            'Administrator access required.',
          );

          return;
        }

        await Navigator.of(context)
            .pushReplacement(
          MaterialPageRoute(
            builder: (_) =>
                const AdminScreen(),
          ),
        );

        return;

      case LoginResult.activeUser:
      case LoginResult.notActivated:
      case LoginResult.userNotFound:
        await auth.signOut();

        if (!mounted) {
          return;
        }

        _showError(
          'Administrator access required.',
        );

        return;

      case LoginResult.failed:
        _showError(
          auth.errorMessage ??
              'Unable to sign in. Please check your email and password.',
        );

        return;
    }
  }

  void _showError(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content:
              Text(message),
          backgroundColor:
              Colors.red.shade700,
        ),
      );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final AuthProvider auth =
        context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Administrator Login',
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child:
              SingleChildScrollView(
            padding:
                const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxWidth: 460,
              ),
              child: Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .stretch,
                      children: [
                        const Icon(
                          Icons
                              .admin_panel_settings,
                          size: 80,
                        ),

                        const SizedBox(
                          height: 20,
                        ),

                        const Text(
                          'Administrator Access',
                          textAlign:
                              TextAlign.center,
                          style:
                              TextStyle(
                            fontSize: 26,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        Text(
                          'Sign in with your administrator account.',
                          textAlign:
                              TextAlign.center,
                          style: TextStyle(
                            color: Colors
                                .grey
                                .shade700,
                          ),
                        ),

                        const SizedBox(
                          height: 28,
                        ),

                        TextFormField(
                          controller:
                              _emailController,
                          enabled:
                              !auth.isLoading,
                          keyboardType:
                              TextInputType
                                  .emailAddress,
                          textInputAction:
                              TextInputAction
                                  .next,
                          decoration:
                              const InputDecoration(
                            labelText:
                                'Email',
                            hintText:
                                'Administrator email',
                            prefixIcon:
                                Icon(
                              Icons
                                  .email_outlined,
                            ),
                            border:
                                OutlineInputBorder(),
                          ),
                          validator:
                              (value) {
                            final email =
                                value
                                        ?.trim() ??
                                    '';

                            if (email
                                .isEmpty) {
                              return 'Please enter your email.';
                            }

                            if (!email
                                .contains(
                              '@',
                            )) {
                              return 'Please enter a valid email.';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(
                          height: 16,
                        ),

                        TextFormField(
                          controller:
                              _passwordController,
                          enabled:
                              !auth.isLoading,
                          obscureText:
                              _obscurePassword,
                          textInputAction:
                              TextInputAction
                                  .done,
                          onFieldSubmitted:
                              (_) {
                            if (!auth
                                .isLoading) {
                              _login();
                            }
                          },
                          decoration:
                              InputDecoration(
                            labelText:
                                'Password',
                            prefixIcon:
                                const Icon(
                              Icons
                                  .lock_outline,
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
                                          setState(
                                            () {
                                              _obscurePassword =
                                                  !_obscurePassword;
                                            },
                                          );
                                        },
                              icon:
                                  Icon(
                                _obscurePassword
                                    ? Icons
                                        .visibility_outlined
                                    : Icons
                                        .visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator:
                              (value) {
                            if ((value ??
                                    '')
                                .isEmpty) {
                              return 'Please enter your password.';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(
                          height: 24,
                        ),

                        SizedBox(
                          height: 52,
                          child:
                              FilledButton
                                  .icon(
                            onPressed:
                                auth.isLoading
                                    ? null
                                    : _login,
                            icon:
                                auth.isLoading
                                    ? const SizedBox(
                                        width:
                                            20,
                                        height:
                                            20,
                                        child:
                                            CircularProgressIndicator(
                                          strokeWidth:
                                              2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons
                                            .login,
                                      ),
                            label:
                                Text(
                              auth.isLoading
                                  ? 'Signing in...'
                                  : 'SIGN IN AS ADMINISTRATOR',
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        TextButton(
                          onPressed:
                              auth.isLoading
                                  ? null
                                  : () {
                                      Navigator.of(
                                        context,
                                      ).maybePop();
                                    },
                          child:
                              const Text(
                            'Cancel',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}