import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/notification_service.dart';
import 'providers/admin_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/doctor_provider.dart';
import 'providers/document_provider.dart';
import 'providers/insurance_provider.dart';
import 'providers/language_provider.dart';
import 'providers/medication_provider.dart';
import 'providers/pharmacy_provider.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ============================================================
  // NOTIFICATIONS
  // ============================================================

  try {
    await NotificationService.initialize();
  } catch (error, stackTrace) {
    debugPrint(
      'Notification initialization failed: '
      '$error\n$stackTrace',
    );
  }

  // ============================================================
  // SUPABASE
  // ============================================================

  try {
    await Supabase.initialize(
      url: 'https://emvadnooxyspfsfnzlmb.supabase.co',
      publishableKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVtdmFkbm9veHlzcGZzZm56bG1iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc0ODY2NTYsImV4cCI6MjA3MzA2MjY1Nn0.w0ZrF4vAcTrv4fAcJKzMhv1FqXScCD7f1HMrTlEU340',
    );
  } catch (error, stackTrace) {
    debugPrint(
      'Supabase initialization failed: '
      '$error\n$stackTrace',
    );
  }

  runApp(
    const MyApp(),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LanguageProvider>(
          create: (_) => LanguageProvider(),
        ),
        ChangeNotifierProvider<MedicationProvider>(
          create: (_) => MedicationProvider(),
        ),
        ChangeNotifierProvider<DoctorProvider>(
          create: (_) => DoctorProvider(),
        ),
        ChangeNotifierProvider<PharmacyProvider>(
          create: (_) => PharmacyProvider(),
        ),
        ChangeNotifierProvider<DocumentProvider>(
          create: (_) => DocumentProvider(),
        ),
        ChangeNotifierProvider<InsuranceProvider>(
          create: (_) => InsuranceProvider(),
        ),
        ChangeNotifierProvider<AdminProvider>(
          create: (_) => AdminProvider(),
        ),
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(),
        ),
      ],
      child: const _SanaApp(),
    );
  }
}

class _SanaApp extends StatefulWidget {
  const _SanaApp();

  @override
  State<_SanaApp> createState() => _SanaAppState();
}

class _SanaAppState extends State<_SanaApp> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      context.read<AuthProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<LanguageProvider, AuthProvider>(
      builder: (
        context,
        language,
        auth,
        child,
      ) {
        return MaterialApp(
          title: 'SANA',
          debugShowCheckedModeBanner: false,
          locale: language.locale,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.teal,
            ),
            useMaterial3: true,
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: const AppBarTheme(
              centerTitle: true,
            ),
          ),
          home: _buildHome(auth),
        );
      },
    );
  }

  Widget _buildHome(AuthProvider auth) {
    if (!auth.isInitialized) {
      return const _AuthLoadingScreen();
    }

    return const HomeScreen();
  }
}

class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.health_and_safety,
              color: Colors.teal,
              size: 56,
            ),
            SizedBox(height: 16),
            Text(
              'SANA',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: Colors.teal,
              ),
            ),
            SizedBox(height: 20),
            SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Colors.teal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}