import 'package:flutter/material.dart';

import '../../models/emprendimiento.dart';
import '../../services/emprendimiento_service.dart';
import '../../services/theme_service.dart';
import 'crear_tienda_screen.dart';

class MiTiendaScreen extends StatefulWidget {
  final ThemeService themeService;

  const MiTiendaScreen({
    super.key,
    required this.themeService,
  });

  @override
  State<MiTiendaScreen> createState() => _MiTiendaScreenState();
}

class _MiTiendaScreenState extends State<MiTiendaScreen> {
  bool cargando = true;

  Emprendimiento? emprendimiento;

  String? error;

  @override
  void initState() {
    super.initState();
    cargarTienda();
  }

  Future<void> cargarTienda() async {
    setState(() {
      cargando = true;
      error = null;
    });

    final resultado =
        await EmprendimientoService.obtenerMiTienda();

    if (!mounted) return;

    if (resultado['success'] == true) {
      setState(() {
        emprendimiento =
            resultado['emprendimiento'];

        cargando = false;
      });

      return;
    }

    // 404 significa que todavía no tiene tienda.
    if (resultado['statusCode'] == 404) {
      setState(() {
        emprendimiento = null;
        cargando = false;
      });

      return;
    }

    setState(() {
      cargando = false;
      error = resultado['message'] ??
          'No se pudo cargar la tienda';
    });
  }

  Future<void> crearTienda() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CrearTiendaScreen(
          themeService: widget.themeService,
        ),
      ),
    );

    if (resultado == true) {
      cargarTienda();
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
        title: const Text('Mi tienda'),
      ),

      body: error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 60,
                      color: Color(0xFFFF7E01),
                    ),

                    const SizedBox(height: 15),

                    Text(
                      error!,
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: cargarTienda,
                      child: const Text(
                        'Reintentar',
                      ),
                    ),
                  ],
                ),
              ),
            )
          : emprendimiento == null
              ? _sinTienda()
              : _mostrarTienda(),
    );
  }

  Widget _sinTienda() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.storefront_outlined,
              size: 90,
              color: Color(0xFFFF7E01),
            ),

            const SizedBox(height: 20),

            const Text(
              'Todavía no tienes una tienda',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Crea tu emprendimiento para comenzar a publicar productos.',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: 220,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: crearTienda,
                icon: const Icon(
                  Icons.add_business,
                ),
                label: const Text(
                  'Crear mi tienda',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mostrarTienda() {
    final tienda = emprendimiento!;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Center(
          child: CircleAvatar(
            radius: 55,
            backgroundColor: Color(0xFFFF7E01),
            child: Icon(
              Icons.storefront,
              size: 65,
              color: Colors.white,
            ),
          ),
        ),

        const SizedBox(height: 20),

        Text(
          tienda.nombre,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 25),

        Card(
          child: ListTile(
            leading: const Icon(
              Icons.description_outlined,
              color: Color(0xFFFF7E01),
            ),
            title: const Text('Descripción'),
            subtitle: Text(
              tienda.descripcion?.isNotEmpty == true
                  ? tienda.descripcion!
                  : 'Sin descripción',
            ),
          ),
        ),

        Card(
          child: ListTile(
            leading: const Icon(
              Icons.phone_outlined,
              color: Color(0xFFFF7E01),
            ),
            title: const Text('Teléfono'),
            subtitle: Text(
              tienda.telefono?.isNotEmpty == true
                  ? tienda.telefono!
                  : 'No especificado',
            ),
          ),
        ),

        Card(
          child: ListTile(
            leading: const Icon(
              Icons.email_outlined,
              color: Color(0xFFFF7E01),
            ),
            title: const Text(
              'Correo de contacto',
            ),
            subtitle: Text(
              tienda.correoContacto?.isNotEmpty == true
                  ? tienda.correoContacto!
                  : 'No especificado',
            ),
          ),
        ),
      ],
    );
  }
}