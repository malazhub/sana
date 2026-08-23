import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  Future<void> _initialize() async {
    final auth = context.read<AuthProvider>();
    final language = context.read<LanguageProvider>();

    try {
      await Future.wait([
        _initializeAuth(auth),
        _initializeLanguage(language),
        Future<void>.delayed(
          const Duration(milliseconds: 800),
        ),
      ]);
    } catch (error, stackTrace) {
      debugPrint(
        'Splash initialization failed: '
        '$error\n$stackTrace',
      );
    }
  }

  Future<void> _initializeAuth(
    AuthProvider auth,
  ) async {
    if (auth.isInitialized) {
      return;
    }

    await auth.initialize();
  }

  Future<void> _initializeLanguage(
    LanguageProvider language,
  ) async {
    if (language.isInitialized) {
      return;
    }

    await language.init();
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