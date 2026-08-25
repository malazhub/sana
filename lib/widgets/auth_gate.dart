import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sana/providers/auth_provider.dart';
import 'package:sana/screens/admin_screen.dart' as admin_screen;
import 'package:sana/screens/home_screen.dart' as home_screen;

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // ------------------------------------------------------------
    // 1. AUTH PROVIDER IS STILL INITIALIZING
    // ------------------------------------------------------------
    if (!auth.isInitialized) {
      return const _AuthLoadingScreen();
    }

    // ------------------------------------------------------------
    // 2. NO LOGIN -> GUEST HOME
    // ------------------------------------------------------------
    if (!auth.isAuthenticated) {
      return const home_screen.HomeScreen();
    }

    // ------------------------------------------------------------
    // 3. LOGGED-IN ADMIN -> ADMIN PANEL
    // ------------------------------------------------------------
    if (auth.isAdmin) {
      return const admin_screen.AdminScreen();
    }

    // ------------------------------------------------------------
    // 4. LOGGED-IN NORMAL USER -> HOME
    // ------------------------------------------------------------
    return const home_screen.HomeScreen();
  }
}

class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}