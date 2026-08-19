//import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/splash_screen.dart';
import '../screens/home_screen.dart';
import '../screens/add_pharmacy_screen.dart';
import '../screens/add_medication_screen.dart';

class AppRoutes {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/pharmacy',
        builder: (context, state) => const AddPharmacyScreen(),
      ),
      GoRoute(
        path: '/medication',
        builder: (context, state) => const AddMedicationScreen(),
      ),
    ],
  );
}
