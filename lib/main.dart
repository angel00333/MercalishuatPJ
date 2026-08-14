import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MercalishuatApp());
}

class MercalishuatApp extends StatelessWidget {
  const MercalishuatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mercalishuat',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00A6A6),
        ),

        scaffoldBackgroundColor: const Color(0xFFF5F8F8),
      ),

      home: const SplashScreen(),
    );
  }
}