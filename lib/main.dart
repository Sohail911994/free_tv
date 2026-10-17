import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0F0F1E),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const FreeTvApp());
}

class FreeTvApp extends StatelessWidget {
  const FreeTvApp({super.key});

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF0F0F1E);
    const card = Color(0xFF1C1C2E);

    return MaterialApp(
      title: 'Free TV',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          primary: Colors.tealAccent,
          secondary: Colors.tealAccent,
          surface: card,
          onPrimary: Color(0xFF0F0F1E),
          onSurface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: background,
          foregroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: Colors.tealAccent),
          actionsIconTheme: IconThemeData(color: Colors.tealAccent),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: card,
          hintStyle: const TextStyle(color: Colors.white54),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: Colors.tealAccent,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
