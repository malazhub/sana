import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/routes/app_routes.dart';
import 'providers/language_provider.dart';
import 'providers/settings_provider.dart';

class SanaApp extends StatelessWidget {
  const SanaApp({super.key});

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('ar'),
    Locale('fr'),
    Locale('es'),
    Locale('de'),
    Locale('tr'),
    Locale('hi'),
    Locale('zh'),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer2<SettingsProvider, LanguageProvider>(
      builder: (
        context,
        settings,
        language,
        child,
      ) {
        return MaterialApp(
          title: 'SANA',
          debugShowCheckedModeBanner: false,

          theme: _lightTheme,
          darkTheme: _darkTheme,
          themeMode: settings.isDarkMode
              ? ThemeMode.dark
              : ThemeMode.light,

          locale: language.locale,
          supportedLocales: supportedLocales,

          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          localeResolutionCallback: (
            deviceLocale,
            supportedLocales,
          ) {
            if (deviceLocale == null) {
              return supportedLocales.first;
            }

            for (final locale in supportedLocales) {
              if (locale.languageCode ==
                  deviceLocale.languageCode) {
                return locale;
              }
            }

            return supportedLocales.first;
          },

          initialRoute: AppRoutes.splash,
          routes: AppRoutes.routes,
          onGenerateRoute: AppRoutes.onGenerateRoute,
        );
      },
    );
  }

  static final ThemeData _lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.teal,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: Colors.white,
  );

  static final ThemeData _darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.teal,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF101414),
  );
}