import 'package:flutter/material.dart';
import 'home_page.dart';

class GuardianApp extends StatelessWidget {
  const GuardianApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Guardian Vision Kids',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5EC7FF),
          primary: const Color(0xFF5EC7FF),
          secondary: const Color(0xFFFFD166),
          surface: const Color(0xFFF7FBFF),
        ),
        scaffoldBackgroundColor: const Color(0xFFEAF9FF),
        useMaterial3: true,
        textTheme: ThemeData.light().textTheme.apply(
          fontFamily: 'Roboto',
        ),
      ),
      home: const HomePage(),
    );
  }
}
