import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/routes/app_routes.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final auth = context.read<AuthProvider>();
    final language = context.read<LanguageProvider>();

    await Future.wait([
      _waitForAuth(auth),
      _initializeLanguage(language),
      Future<void>.delayed(const Duration(milliseconds: 800)),
    ]);

    if (!mounted) {
      return;
    }

    if (auth.isAuthenticated) {
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.home,
      );
    } else {
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.home,
      );
    }
  }

  Future<void> _waitForAuth(AuthProvider auth) async {
    while (auth.isLoading) {
      await Future<void>.delayed(
        const Duration(milliseconds: 50),
      );
    }
  }

  Future<void> _initializeLanguage(
    LanguageProvider language,
  ) async {
    if (!language.isInitialized) {
      await language.init();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
            const SizedBox(height: 16),
            const Text(
              'SANA',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Loading...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(),
            ),
          ],
        ),
      ),
    );
  }
}