import 'package:flutter/material.dart';
import 'home_page.dart';

class GuardianApp extends StatelessWidget {
  const GuardianApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Guardian Vision Pais',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1F4E79),
          primary: const Color(0xFF1F4E79),
          secondary: const Color(0xFF4CB2FF),
          surface: const Color(0xFFF3F7FB),
        ),
        scaffoldBackgroundColor: const Color(0xFFEAF3FA),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1F4E79),
          foregroundColor: Colors.white,
        ),
      ),
      home: const HomePage(),
    );
  }
}
