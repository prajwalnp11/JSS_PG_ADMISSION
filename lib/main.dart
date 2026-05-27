import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';

void main() {
  runApp(const JssAdmissionApp());
}

class JssAdmissionApp extends StatelessWidget {
  const JssAdmissionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JSS PG Admissions',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D47A1), // JSS Navy Blue
          primary: const Color(0xFF0D47A1),
          secondary: const Color(0xFFFFB300), // Gold/Amber accent
          surface: Colors.white,
          background: const Color(0xFFF5F7FA), // Soft background color
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        
        // Define elegant Card styling
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 2,
          margin: EdgeInsets.zero,
        ),
        
        // Customise form inputs globally for clean outline style
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF0D47A1), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
          ),
          labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        ),
        
        // Typography customization
        fontFamily: 'Roboto', // Default standard font
      ),
      home: const DashboardScreen(),
    );
  }
}
