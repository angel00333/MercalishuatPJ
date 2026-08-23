import 'package:flutter/material.dart';

import '../../services/emprendimiento_service.dart';
import '../../services/theme_service.dart';

class CrearTiendaScreen extends StatefulWidget {
  final ThemeService themeService;

  const CrearTiendaScreen({
    super.key,
    required this.themeService,
  });

  @override
  State<CrearTiendaScreen> createState() =>
      _CrearTiendaScreenState();
}

class _CrearTiendaScreenState
    extends State<CrearTiendaScreen> {
  final nombreController =
      TextEditingController();

  final descripcionController =
      TextEditingController();

  final telefonoController =
      TextEditingController();

  final correoController =
      TextEditingController();

  bool cargando = false;

  Future<void> guardar() async {
    final nombre =
        nombreController.text.trim();

    if (nombre.isEmpty) {
      mostrarMensaje(
        'Ingresa el nombre de tu tienda',
      );

      return;
    }

    setState(() {
      cargando = true;
    });

    final resultado =
        await EmprendimientoService.crear(
      nombre: nombre,
      descripcion:
          descripcionController.text.trim(),
      telefono:
          telefonoController.text.trim(),
      correoContacto:
          correoController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      cargando = false;
    });

    if (resultado['success'] == true) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Tienda creada correctamente',
          ),
        ),
      );

      Navigator.pop(
        context,
        true,
      );

      return;
    }

    mostrarMensaje(
      resultado['message'] ??
          'No se pudo crear la tienda',
    );
  }

  void mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(mensaje),
      ),
    );
  }

  @override
  void dispose() {
    nombreController.dispose();
    descripcionController.dispose();
    telefonoController.dispose();
    correoController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Crear mi tienda',
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.add_business,
              size: 80,
              color: Color(0xFFFF7E01),
            ),

            const SizedBox(height: 30),

            TextField(
              controller: nombreController,
              decoration: const InputDecoration(
                labelText:
                    'Nombre del emprendimiento',
                prefixIcon:
                    Icon(Icons.storefront),
              ),
            ),

            const SizedBox(height: 18),

            TextField(
              controller:
                  descripcionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                prefixIcon:
                    Icon(Icons.description_outlined),
              ),
            ),

            const SizedBox(height: 18),

            TextField(
              controller:
                  telefonoController,
              keyboardType:
                  TextInputType.phone,
              decoration: const InputDecoration(
                labelText:
                    'Teléfono de contacto',
                prefixIcon:
                    Icon(Icons.phone_outlined),
              ),
            ),

            const SizedBox(height: 18),

            TextField(
              controller: correoController,
              keyboardType:
                  TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText:
                    'Correo de contacto',
                prefixIcon:
                    Icon(Icons.email_outlined),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed:
                    cargando ? null : guardar,

                icon: const Icon(
                  Icons.save_outlined,
                ),

                label: cargando
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Crear tienda',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}