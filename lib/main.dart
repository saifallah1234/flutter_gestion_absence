import 'package:flutter/material.dart';
import 'screens/LoginScreen.dart';

void main() {
  runApp(const GestAbsenceApp());
}

class GestAbsenceApp extends StatelessWidget {
  const GestAbsenceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FSB Sanctuary - Gest Absence',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFBF8FF), // Background color
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A237E), 
          primary: const Color(0xFF1A237E),
          secondary: const Color(0xFF000666),
          background: const Color(0xFFFBF8FF), 
        ),
        fontFamily: 'Manrope', // Ensure Manrope is declared in pubspec.yaml
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFE8E7F2), // Light gray-blue for inputs
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A237E),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}