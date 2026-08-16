import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/theme_service.dart';
import 'home_emprendedor_screen.dart';
import 'home_usuario_screen.dart';
import 'registro_screen.dart';

class LoginScreen extends StatefulWidget {
  final ThemeService themeService;

  const LoginScreen({
    super.key,
    required this.themeService,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final correoController = TextEditingController();
  final passwordController = TextEditingController();

  bool cargando = false;
  bool ocultarPassword = true;

  Future<void> iniciarSesion() async {
    final correo = correoController.text.trim();
    final password = passwordController.text.trim();

    if (correo.isEmpty || password.isEmpty) {
      mostrarMensaje('Completa todos los campos');
      return;
    }

    setState(() {
      cargando = true;
    });

    final resultado = await AuthService.login(
      correo: correo,
      password: password,
    );

    if (!mounted) return;

    setState(() {
      cargando = false;
    });

    if (resultado['success'] == true) {
      final rol = resultado['rol'];

      if (rol == 'emprendedor') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => HomeEmprendedorScreen(
              themeService: widget.themeService,
            ),
          ),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => HomeUsuarioScreen(
              themeService: widget.themeService,
            ),
          ),
          (route) => false,
        );
      }
    } else {
      mostrarMensaje(
        resultado['message'] ?? 'No se pudo iniciar sesión',
      );
    }
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
    correoController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(
                  Icons.storefront,
                  size: 90,
                  color: Color(0xFFFF7E01),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Mercalishuat',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Descubre emprendimientos salvadoreños',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
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
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: cargando ? null : iniciarSesion,
                    child: cargando
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Iniciar sesión'),
                  ),
                ),
                const SizedBox(height: 15),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RegistroScreen(
                          themeService: widget.themeService,
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    '¿No tienes cuenta? Regístrate',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}