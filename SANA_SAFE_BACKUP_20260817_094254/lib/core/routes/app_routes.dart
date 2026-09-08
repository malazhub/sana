import 'package:flutter/material.dart';

import '../../screens/splash_screen.dart';
import '../../screens/home_screen.dart';
import '../../screens/add_medication_screen.dart';
import '../../screens/medication_history_screen.dart';
import '../../screens/profile_screen.dart';
import '../../screens/add_doctor_screen.dart';
import '../../screens/add_pharmacy_screen.dart';
import '../../screens/documents_screen.dart';
import '../../screens/insurance_screen.dart';
import '../../screens/share_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String splash = '/splash';
  static const String home = '/home';
  static const String addMedication = '/add-medication';
  static const String medicationDetail = '/medication-detail';
  static const String history = '/history';
  static const String profile = '/profile';
  static const String addDoctor = '/add-doctor';
  static const String addPharmacy = '/add-pharmacy';
  static const String documents = '/documents';
  static const String insurance = '/insurance';

  static final Map<String, WidgetBuilder> routes = {
    splash: (context) => const SplashScreen(),
    home: (context) => const HomeScreen(),
    addMedication: (context) => const AddMedicationScreen(),
    history: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Medication History'),
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
          ),
          body: const MedicationHistoryScreen(),
        ),
    profile: (context) => const ProfileScreen(),
    addDoctor: (context) => const AddDoctorScreen(),
    addPharmacy: (context) => const AddPharmacyScreen(),
    documents: (context) => const DocumentsScreen(),
    insurance: (context) => const InsuranceScreen(),
  };

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final uri = Uri.parse(settings.name ?? '');

    final path = uri.fragment.isNotEmpty ? uri.fragment : uri.path;

    final parts = path.split('/');

    // Share links: /share/TOKEN
    if (parts.length == 3 && parts[1] == 'share' && parts[2].isNotEmpty) {
      final token = parts[2];

      return MaterialPageRoute(
        builder: (_) => ShareScreen(token: token),
        settings: settings,
      );
    }

    // Normal registered routes.
    final builder = routes[path];

    if (builder != null) {
      return MaterialPageRoute(
        builder: builder,
        settings: settings,
      );
    }

    // Unknown route.
    return MaterialPageRoute(
      builder: (_) => const HomeScreen(),
      settings: settings,
    );
  }
}
