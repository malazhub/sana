import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/notification_service.dart';

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

  // Initialize notifications.
  try {
    await NotificationService.initialize();
  } catch (error, stackTrace) {
    debugPrint(
      'Notification initialization failed: '
      '$error\n$stackTrace',
    );
  }

  // Initialize Supabase.
  try {
    await Supabase.initialize(
      url: 'https://emvadnooxyspfsfnzlmb.supabase.co',
      publishableKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVtdmFkbm9veHlzcGZzZm56bG1iIiwicm9sZSI6ImFub25',
    );
  } catch (error, stackTrace) {
    debugPrint(
      'Supabase initialization failed: '
      '$error\n$stackTrace',
    );
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => LanguageProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => MedicationProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => DoctorProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => PharmacyProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => DocumentProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => InsuranceProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),
      ],
      child: Consumer<LanguageProvider>(
        builder: (
          context,
          language,
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
            ),
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}