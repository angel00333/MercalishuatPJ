import 'package:flutter/material.dart';

import '../services/session_service.dart';
import '../services/theme_service.dart';
import 'login_screen.dart';

class PerfilScreen extends StatefulWidget {
  final ThemeService themeService;

  const PerfilScreen({
    super.key,
    required this.themeService,
  });

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  String nombre = '';
  String correo = '';
  String rol = '';

  bool cargando = true;

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
      cargando = false;
    });
  }

  Future<void> cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cerrar sesión'),
          content: const Text(
            '¿Deseas cerrar tu sesión de Mercalishuat?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Cerrar sesión'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    await SessionService.cerrarSesion();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => LoginScreen(
          themeService: widget.themeService,
        ),
      ),
      (route) => false,
    );
  }

  String obtenerNombreRol() {
    switch (rol) {
      case 'emprendedor':
        return 'Emprendedor';

      case 'administrador':
        return 'Administrador';

      default:
        return 'Usuario';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFFF7E01),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Center(
            child: CircleAvatar(
              radius: 55,
              backgroundColor: Color(0xFFFF7E01),
              child: Icon(
                Icons.person,
                size: 65,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              nombre.isEmpty ? 'Usuario' : nombre,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 35),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.email_outlined,
                color: Color(0xFFFF7E01),
              ),
              title: const Text('Correo'),
              subtitle: Text(correo),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.badge_outlined,
                color: Color(0xFFFF7E01),
              ),
              title: const Text('Tipo de cuenta'),
              subtitle: Text(obtenerNombreRol()),
            ),
          ),
          const SizedBox(height: 35),
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: cerrarSesion,
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar sesión'),
            ),
          ),
        ],
      ),
    );
  }
}