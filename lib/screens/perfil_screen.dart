import 'package:flutter/material.dart';

import '../services/session_service.dart';
import 'login_screen.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({
    super.key,
  });

  @override
  State<PerfilScreen> createState() =>
      _PerfilScreenState();
}

class _PerfilScreenState
    extends State<PerfilScreen> {
  String nombre = '';
  String correo = '';
  String rol = '';

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  Future<void> cargarDatos() async {
    final nombreGuardado =
        await SessionService.obtenerNombre();

    final correoGuardado =
        await SessionService.obtenerCorreo();

    final rolGuardado =
        await SessionService.obtenerRol();

    if (!mounted) return;

    setState(() {
      nombre = nombreGuardado ?? '';
      correo = correoGuardado ?? '';
      rol = rolGuardado ?? '';
    });
  }

  Future<void> cerrarSesion() async {
    await SessionService.cerrarSesion();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const LoginScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mi perfil',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              child: Icon(
                Icons.person,
                size: 60,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              nombre,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            ListTile(
              leading:
                  const Icon(Icons.email),
              title:
                  const Text('Correo'),
              subtitle: Text(correo),
            ),

            ListTile(
              leading:
                  const Icon(Icons.badge),
              title:
                  const Text('Tipo de cuenta'),
              subtitle: Text(
                rol.toUpperCase(),
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: cerrarSesion,
                icon: const Icon(
                  Icons.logout,
                ),
                label: const Text(
                  'Cerrar sesión',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}