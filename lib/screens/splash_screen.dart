import 'package:flutter/material.dart';

import '../services/session_service.dart';
import '../services/theme_service.dart';
import 'home_emprendedor_screen.dart';
import 'home_usuario_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  final ThemeService themeService;

  const SplashScreen({
    super.key,
    required this.themeService,
  });

  @override
  State<SplashScreen> createState() =>
      _SplashScreenState();
}

class _SplashScreenState
    extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    verificarSesion();
  }

  Future<void> verificarSesion() async {
    await Future.delayed(
      const Duration(seconds: 2),
    );

    final haySesion =
        await SessionService.haySesion();

    if (!mounted) return;

    if (!haySesion) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LoginScreen(
            themeService:
                widget.themeService,
          ),
        ),
      );

      return;
    }

    final rol =
        await SessionService.obtenerRol();

    if (!mounted) return;

    if (rol == 'emprendedor') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              HomeEmprendedorScreen(
            themeService:
                widget.themeService,
          ),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              HomeUsuarioScreen(
            themeService:
                widget.themeService,
          ),
        ),
      );
    }
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/logo.png',
            width: 150,
            height: 150,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 20),
          const Text(
            'Mercalishuat',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF7E01),
            ),
          ),
          const SizedBox(height: 25),
          const CircularProgressIndicator(
            color: Color(0xFFFF7E01),
          ),
        ],
      ),
    ),
  );
}
}