import 'package:fire_flutter/firebase_options.dart';
import 'package:fire_flutter/providers/settings_provider.dart';
import 'package:fire_flutter/screens/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase Init
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Settings Provider Init
  final settingsProvider = SettingsProvider();

  // Load SharedPreferences data
  await settingsProvider.load();

  runApp(
    ChangeNotifierProvider(
      create: (_) => settingsProvider,

      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // Dynamic Theme
      themeMode: settings.themeMode,

      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.green,

        scaffoldBackgroundColor: const Color(0xFFF9FAFC),

        cardColor: Colors.white,

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),

        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Colors.black87),
        ),
      ),

      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.green,

        scaffoldBackgroundColor: const Color(0xFF121212),

        cardColor: const Color(0xFF1E1E1E),

        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          foregroundColor: Colors.white,
          elevation: 0,
        ),

        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
        ),
      ),

      home: SplashScreen(),
    );
  }
}
