import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/admin_screen.dart';
import '../screens/home_screen.dart';

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
    // GUEST MODE
    // ============================================================
    //
    // No authenticated user = Guest Mode.
    //
    // Guest can open and use the normal SANA application.
    // Login is available from the application wherever you
    // provide the login entry point.
    //

    if (!auth.isAuthenticated) {
      return const HomeScreen();
    }

    // ============================================================
    // ADMIN
    // ============================================================
    //
    // Authenticated administrator goes directly to AdminScreen.
    //

    if (auth.isAdmin) {
      return const AdminScreen();
    }

    // ============================================================
    // ACTIVE AUTHENTICATED USER
    // ============================================================
    //
    // A valid active user gets the normal application.
    //

    if (auth.hasValidSubscription) {
      return const HomeScreen();
    }

    // ============================================================
    // NON-ACTIVE AUTHENTICATED USER
    // ============================================================
    //
    // According to the required SANA behavior:
    //
    // non-active user -> Guest Mode
    //
    // We therefore do NOT send this user to SubscriptionScreen.
    //

    return const HomeScreen();
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