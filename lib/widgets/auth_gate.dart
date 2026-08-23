import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/admin_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/subscription_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // ============================================================
    // AUTH INITIALIZATION
    // ============================================================

    if (!auth.isInitialized) {
      return const _AuthLoadingScreen();
    }

    // ============================================================
    // NOT AUTHENTICATED
    // ============================================================

    if (!auth.isAuthenticated) {
      return const LoginScreen();
    }

    // ============================================================
    // ADMIN
    // ============================================================

    if (auth.isAdmin) {
      return const AdminScreen();
    }

    // ============================================================
    // VALID CUSTOMER SUBSCRIPTION
    // ============================================================

    if (auth.hasValidSubscription) {
      return const HomeScreen();
    }

    // ============================================================
    // AUTHENTICATED BUT NO VALID SUBSCRIPTION
    // ============================================================

    return const SubscriptionScreen();
  }
}

// ================================================================
// LOADING SCREEN
// ================================================================

class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 42,
              height: 42,
              child: CircularProgressIndicator(),
            ),
            SizedBox(height: 20),
            Text(
              'Loading...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}