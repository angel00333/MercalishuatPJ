import 'package:flutter/material.dart';

import '../services/theme_service.dart';
import 'seleccionar_rol_screen.dart';

class RegistroScreen extends StatefulWidget {
  final ThemeService themeService;

  const RegistroScreen({
    super.key,
    required this.themeService,
  });

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final nombreController = TextEditingController();
  final correoController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmarPasswordController = TextEditingController();

  bool ocultarPassword = true;
  bool ocultarConfirmacion = true;

  void continuar() {
    final nombre = nombreController.text.trim();
    final correo = correoController.text.trim();
    final password = passwordController.text.trim();
    final confirmar = confirmarPasswordController.text.trim();

    if (nombre.isEmpty ||
        correo.isEmpty ||
        password.isEmpty ||
        confirmar.isEmpty) {
      mostrarMensaje('Completa todos los campos');
      return;
    }

    if (!correo.contains('@') || !correo.contains('.')) {
      mostrarMensaje('Ingresa un correo válido');
      return;
    }

    if (password.length < 6) {
      mostrarMensaje(
        'La contraseña debe tener al menos 6 caracteres',
      );
      return;
    }

    if (password != confirmar) {
      mostrarMensaje('Las contraseñas no coinciden');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SeleccionarRolScreen(
          nombre: nombre,
          correo: correo,
          password: password,
          themeService: widget.themeService,
        ),
      ),
    );
  }

  void mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
      ),
    );
  }

  @override
  void dispose() {
    nombreController.dispose();
    correoController.dispose();
    passwordController.dispose();
    confirmarPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear cuenta'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.person_add_alt_1,
              size: 75,
              color: Color(0xFFFF7E01),
            ),
            const SizedBox(height: 25),
            TextField(
              controller: nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre completo',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: correoController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: passwordController,
              obscureText: ocultarPassword,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      ocultarPassword = !ocultarPassword;
                    });
                  },
                  icon: Icon(
                    ocultarPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: confirmarPasswordController,
              obscureText: ocultarConfirmacion,
              decoration: InputDecoration(
                labelText: 'Confirmar contraseña',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      ocultarConfirmacion = !ocultarConfirmacion;
                    });
                  },
                  icon: Icon(
                    ocultarConfirmacion
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: continuar,
                child: const Text('Continuar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}