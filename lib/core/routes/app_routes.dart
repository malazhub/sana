import 'package:flutter/material.dart';
import '../../screens/auth_screen.dart';
import '../../screens/add_doctor_screen.dart';
import '../../screens/add_medication_screen.dart';
import '../../screens/add_pharmacy_screen.dart';
import '../../screens/documents_screen.dart';
import '../../screens/home_screen.dart';
import '../../screens/insurance_screen.dart';
import '../../screens/medication_history_screen.dart';
import '../../screens/profile_screen.dart';
import '../../screens/share_screen.dart';
import '../../screens/splash_screen.dart';

class AppRoutes {
  AppRoutes._();
  static const String auth = '/auth';
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
    splash: (_) => const SplashScreen(),
    auth: (_) => const AuthScreen(),
    home: (_) => const HomeScreen(),
    addMedication: (_) => const AddMedicationScreen(),
    history: (_) => const MedicationHistoryScreen(),
    profile: (_) => const ProfileScreen(),
    addDoctor: (_) => const AddDoctorScreen(),
    addPharmacy: (_) => const AddPharmacyScreen(),
    documents: (_) => const DocumentsScreen(),
    insurance: (_) => const InsuranceScreen(),
  };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final name = settings.name ?? '';

    // Dynamic share route:
    // /share/TOKEN
    final uri = Uri.tryParse(name);

    if (uri != null) {
      final path = uri.fragment.isNotEmpty
          ? uri.fragment
          : uri.path;

      final parts = path
          .split('/')
          .where((part) => part.isNotEmpty)
          .toList();

      if (parts.length == 2 &&
          parts[0] == 'share' &&
          parts[1].isNotEmpty) {
        return MaterialPageRoute(
          builder: (_) => ShareScreen(
            token: parts[1],
          ),
          settings: settings,
        );
      }
    }

    final builder = routes[name];

    if (builder != null) {
      return MaterialPageRoute(
        builder: builder,
        settings: settings,
      );
    }

    return MaterialPageRoute(
      builder: (_) => const _UnknownRouteScreen(),
      settings: settings,
    );
  }
}

class _UnknownRouteScreen extends StatelessWidget {
  const _UnknownRouteScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Page not found'),
      ),
      body: Center(
        child: FilledButton(
          onPressed: () {
            Navigator.of(context).pushNamedAndRemoveUntil(
              AppRoutes.home,
              (route) => false,
            );
          },
          child: const Text('Go to Home'),
        ),
      ),
    );
  }
}