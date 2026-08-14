import 'package:flutter/material.dart';

import '../services/session_service.dart';

import 'login_screen.dart';
import 'home_usuario_screen.dart';
import 'home_emprendedor_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    verificarSesion();
  }

  Future<void> verificarSesion() async {
    await Future.delayed(
      const Duration(seconds: 2),
    );

    final existeSesion =
        await SessionService.existeSesion();

    if (!mounted) return;

    if (!existeSesion) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
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
              const HomeEmprendedorScreen(),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const HomeUsuarioScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF008F95),
              Color(0xFF00B8B0),
            ],
          ),
        ),
        child: const Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.storefront,
              size: 90,
              color: Colors.white,
            ),

            SizedBox(height: 20),

            Text(
              'EmprendeSV',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            SizedBox(height: 8),

            Text(
              'Descubre. Emprende. Conecta.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),

            SizedBox(height: 40),

            CircularProgressIndicator(
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}