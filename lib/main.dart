import 'package:flutter/material.dart';

import 'config/app_theme.dart';
import 'screens/splash_screen.dart';
import 'services/theme_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/firebase_messaging_service.dart';
import 'firebase_options.dart';


@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  await Firebase.initializeApp(
    options:
        DefaultFirebaseOptions
            .currentPlatform,
  );
  await FirebaseMessagingService
    .instance
    .iniciar();

  print(
    'FCM BACKGROUND: ${message.messageId}',
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final themeService = ThemeService();

  await themeService.cargarTema();

  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options:
        DefaultFirebaseOptions
            .currentPlatform,
  );

  debugPrint(
    'FIREBASE INICIALIZADO',
  );

  await FirebaseMessagingService
      .instance
      .iniciar();

  debugPrint(
    'FCM INICIALIZADO',
  );

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