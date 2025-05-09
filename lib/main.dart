// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:intl/date_symbol_data_local.dart';

import 'screens/main_screen.dart';
import 'providers/theme_provider.dart';
import 'providers/time_settings_provider.dart';
import 'providers/world_clock_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Intl Date Formatting
  try {
     await initializeDateFormatting(null, null);
     print("Intl Date Formatting Initialized Successfully.");
  } catch (e) {
      print("Error initializing intl formatting: $e");
  }

  // Initialize the timezone database
  tz.initializeTimeZones();
  print("Timezone Database Initialized.");

  runApp(
    MultiProvider( // Use MultiProvider for multiple providers
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => TimeSettingsProvider()),
        ChangeNotifierProvider(create: (_) => WorldClockProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

// The root widget
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Access the ThemeProvider to set the theme mode and get dynamic themes
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Zulu Time Converter',

      // --- Use dynamic themes generated by the provider ---
      theme: themeProvider.lightThemeData,
      darkTheme: themeProvider.darkThemeData,
      themeMode: themeProvider.themeMode, // Controls which theme is active
      // --- End dynamic theme usage ---

      debugShowCheckedModeBanner: false,

      // Set the initial screen structure
      home: const MainScreen(),
    );
  }
}