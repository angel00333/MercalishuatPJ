import 'package:flutter/material.dart';

import 'config/app_theme.dart';
import 'screens/splash_screen.dart';
import 'services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final themeService = ThemeService();

  await themeService.cargarTema();

  runApp(
    MercalishuatApp(
      themeService: themeService,
    ),
  );
}

class MercalishuatApp extends StatefulWidget {
  final ThemeService themeService;

  const MercalishuatApp({
    super.key,
    required this.themeService,
  });

  @override
  State<MercalishuatApp> createState() =>
      _MercalishuatAppState();
}

class _MercalishuatAppState extends State<MercalishuatApp> {
  @override
  void initState() {
    super.initState();

    widget.themeService.addListener(
      _actualizarTema,
    );
  }

  void _actualizarTema() {
    setState(() {});
  }

  @override
  void dispose() {
    widget.themeService.removeListener(
      _actualizarTema,
    );

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mercalishuat',

      debugShowCheckedModeBanner: false,

      theme: AppTheme.lightTheme.copyWith(
        textTheme: AppTheme.lightTheme.textTheme.apply(
          fontFamily: 'Outfit',
        ),
        primaryTextTheme: AppTheme.lightTheme.primaryTextTheme.apply(
          fontFamily: 'Outfit',
        ),
      ),

      darkTheme: AppTheme.darkTheme.copyWith(
        textTheme: AppTheme.darkTheme.textTheme.apply(
          fontFamily: 'Outfit',
        ),
        primaryTextTheme: AppTheme.darkTheme.primaryTextTheme.apply(
          fontFamily: 'Outfit',
        ),
      ),

      themeMode: widget.themeService.themeMode,

      home: SplashScreen(
        themeService: widget.themeService,
      ),
    );
  }
}