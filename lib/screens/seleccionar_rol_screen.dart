import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/theme_service.dart';
import 'login_screen.dart';

class SeleccionarRolScreen extends StatefulWidget {
  final String nombre;
  final String correo;
  final String password;
  final ThemeService themeService;

  const SeleccionarRolScreen({
    super.key,
    required this.nombre,
    required this.correo,
    required this.password,
    required this.themeService,
  });

  @override
  State<SeleccionarRolScreen> createState() =>
      _SeleccionarRolScreenState();
}

class _SeleccionarRolScreenState extends State<SeleccionarRolScreen> {
  String? rolSeleccionado;
  bool cargando = false;

  Future<void> registrar() async {
    if (rolSeleccionado == null) {
      mostrarMensaje('Selecciona un tipo de cuenta');
      return;
    }

    setState(() {
      cargando = true;
    });

    final resultado = await AuthService.registro(
      nombre: widget.nombre,
      correo: widget.correo,
      password: widget.password,
      rol: rolSeleccionado!,
    );

    if (!mounted) return;

    setState(() {
      cargando = false;
    });

    if (resultado['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cuenta creada correctamente'),
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => LoginScreen(
            themeService: widget.themeService,
          ),
        ),
        (route) => false,
      );
    } else {
      mostrarMensaje(
        resultado['message'] ?? 'No se pudo crear la cuenta',
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

  Widget tarjetaRol({
    required String titulo,
    required String descripcion,
    required String valor,
    required IconData icono,
  }) {
    final seleccionado = rolSeleccionado == valor;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          setState(() {
            rolSeleccionado = valor;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: seleccionado
                  ? const Color(0xFFFF7E01)
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icono,
                size: 45,
                color: const Color(0xFFFF7E01),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(descripcion),
                  ],
                ),
              ),
              Radio<String>(
                value: valor,
                groupValue: rolSeleccionado,
                activeColor: const Color(0xFFFF7E01),
                onChanged: (value) {
                  setState(() {
                    rolSeleccionado = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar rol'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              '¿Cómo utilizarás Mercalishuat?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            tarjetaRol(
              titulo: 'Usuario',
              descripcion:
                  'Descubre productos, tiendas y emprendimientos.',
              valor: 'usuario',
              icono: Icons.person_outline,
            ),
            const SizedBox(height: 15),
            tarjetaRol(
              titulo: 'Emprendedor',
              descripcion:
                  'Crea tu tienda y promociona tus productos.',
              valor: 'emprendedor',
              icono: Icons.storefront_outlined,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: cargando ? null : registrar,
                child: cargando
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Crear cuenta'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}