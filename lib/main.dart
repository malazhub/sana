import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'providers/admin_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/doctor_provider.dart';
import 'providers/document_provider.dart';
import 'providers/insurance_provider.dart';
import 'providers/language_provider.dart';
import 'providers/medication_provider.dart';
import 'providers/pharmacy_provider.dart';

import 'widgets/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    // KEEP THE EXISTING AUTHORITATIVE VALUES
    // FROM YOUR CURRENT CONVERSATION VERSION HERE.
    //
    // Do not replace them with values from GitHub.
    url: 'YOUR_EXISTING_SUPABASE_URL',
    publishableKey: 'YOUR_EXISTING_SUPABASE_PUBLISHABLE_KEY',
  );

  runApp(
    const SanaApp(),
  );
}

class SanaApp extends StatelessWidget {
  const SanaApp({
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
          create: (_) => AdminProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),
      ],
      child: const _SanaRoot(),
    );
  }
}

class _SanaRoot extends StatefulWidget {
  const _SanaRoot();

  @override
  State<_SanaRoot> createState() =>
      _SanaRootState();
}

class _SanaRootState extends State<_SanaRoot> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      context
          .read<AuthProvider>()
          .initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SANA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
        ),
      ),
      home: const AuthGate(),
    );
  }
}