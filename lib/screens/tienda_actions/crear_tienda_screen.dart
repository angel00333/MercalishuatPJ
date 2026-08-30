import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../services/emprendimiento_service.dart';
import '../../services/theme_service.dart';

import 'seleccionar_ubicacion_screen.dart';

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
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final nombreController =
      TextEditingController();

  final descripcionController =
      TextEditingController();

  final telefonoController =
      TextEditingController();

  final correoController =
      TextEditingController();

  // ============================================================
  // ESTADO
  // ============================================================

  bool cargando = false;

  bool obteniendoUbicacion = false;

  // ============================================================
  // UBICACIÓN DEL EMPRENDIMIENTO
  // ============================================================

  double? latitud;

  double? longitud;

  // ============================================================
  // GUARDAR
  // ============================================================

  Future<void> guardar() async {
    final nombre =
        nombreController.text.trim();

    if (nombre.isEmpty) {
      mostrarMensaje(
        'Ingresa el nombre de tu tienda',
      );

      return;
    }

    // ==========================================================
    // UBICACIÓN OBLIGATORIA
    // ==========================================================

    if (latitud == null ||
        longitud == null) {
      mostrarMensaje(
        'Selecciona la ubicación de tu emprendimiento',
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

      // ========================================================
      // BETA 4.3
      // ========================================================

      latitud: latitud,
      longitud: longitud,
    );

    if (!mounted) {
      return;
    }

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

  // ============================================================
  // USAR MI UBICACIÓN ACTUAL
  // ============================================================

  Future<void>
      usarMiUbicacionActual() async {
    if (obteniendoUbicacion) {
      return;
    }

    setState(() {
      obteniendoUbicacion = true;
    });

    try {
      // ========================================================
      // COMPROBAR GPS
      // ========================================================

      final servicioActivo =
          await Geolocator
              .isLocationServiceEnabled();

      if (!servicioActivo) {
        if (!mounted) {
          return;
        }

        await _mostrarGpsDesactivado();

        return;
      }

      // ========================================================
      // COMPROBAR PERMISO
      // ========================================================

      LocationPermission permiso =
          await Geolocator
              .checkPermission();

      if (permiso ==
          LocationPermission.denied) {
        permiso =
            await Geolocator
                .requestPermission();
      }

      if (permiso ==
          LocationPermission.denied) {
        if (!mounted) {
          return;
        }

        mostrarMensaje(
          'El permiso de ubicación fue denegado',
        );

        return;
      }

      if (permiso ==
          LocationPermission.deniedForever) {
        if (!mounted) {
          return;
        }

        await _mostrarPermisoBloqueado();

        return;
      }

      // ========================================================
      // OBTENER COORDENADAS
      // ========================================================

      const settings =
          LocationSettings(
        accuracy:
            LocationAccuracy.high,
      );

      final posicion =
          await Geolocator
              .getCurrentPosition(
        locationSettings:
            settings,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        latitud =
            posicion.latitude;

        longitud =
            posicion.longitude;
      });

      mostrarMensaje(
        'Ubicación obtenida correctamente',
      );
    } catch (e) {
      debugPrint(
        'Error obteniendo ubicación: $e',
      );

      if (!mounted) {
        return;
      }

      mostrarMensaje(
        'No se pudo obtener tu ubicación',
      );
    } finally {
      if (mounted) {
        setState(() {
          obteniendoUbicacion =
              false;
        });
      }
    }
  }

  // ============================================================
  // UBICAR MANUALMENTE EN EL MAPA
  // ============================================================

  Future<void> ubicarEnMapa() async {
    LatLng? ubicacionInicial;

    if (latitud != null &&
        longitud != null) {
      ubicacionInicial =
          LatLng(
        latitud!,
        longitud!,
      );
    }

    final resultado =
        await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            SeleccionarUbicacionScreen(
          ubicacionInicial:
              ubicacionInicial,
        ),
      ),
    );

    if (!mounted ||
        resultado == null) {
      return;
    }

    setState(() {
      latitud =
          resultado.latitude;

      longitud =
          resultado.longitude;
    });

    mostrarMensaje(
      'Ubicación seleccionada',
    );
  }

  // ============================================================
  // ELIMINAR UBICACIÓN
  // ============================================================

  void eliminarUbicacion() {
    setState(() {
      latitud = null;
      longitud = null;
    });
  }

  // ============================================================
  // GPS DESACTIVADO
  // ============================================================

  Future<void>
      _mostrarGpsDesactivado() async {
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.location_off_outlined,
            color:
                Color(0xFFFF7E01),
            size: 42,
          ),

          title: const Text(
            'Ubicación desactivada',
          ),

          content: const Text(
            'Activa la ubicación del dispositivo para utilizar tu posición actual.',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child: const Text(
                'Cancelar',
              ),
            ),

            FilledButton(
              style:
                  FilledButton.styleFrom(
                backgroundColor:
                    const Color(
                  0xFFFF7E01,
                ),
                foregroundColor:
                    Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(
                  dialogContext,
                );

                await Geolocator
                    .openLocationSettings();
              },
              child: const Text(
                'Abrir ajustes',
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // PERMISO BLOQUEADO
  // ============================================================

  Future<void>
      _mostrarPermisoBloqueado() async {
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.gps_off_outlined,
            color:
                Color(0xFFFF7E01),
            size: 42,
          ),

          title: const Text(
            'Permiso requerido',
          ),

          content: const Text(
            'El permiso de ubicación está bloqueado. Puedes activarlo desde los ajustes de la aplicación.',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child: const Text(
                'Cancelar',
              ),
            ),

            FilledButton(
              style:
                  FilledButton.styleFrom(
                backgroundColor:
                    const Color(
                  0xFFFF7E01,
                ),
                foregroundColor:
                    Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(
                  dialogContext,
                );

                await Geolocator
                    .openAppSettings();
              },
              child: const Text(
                'Abrir ajustes',
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // MENSAJE
  // ============================================================

  void mostrarMensaje(
    String mensaje,
  ) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          mensaje,
        ),
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    nombreController.dispose();

    descripcionController.dispose();

    telefonoController.dispose();

    correoController.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final oscuro =
        Theme.of(context).brightness ==
            Brightness.dark;

    final ubicacionSeleccionada =
        latitud != null &&
            longitud != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Crear mi tienda',
        ),
      ),

      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(
          24,
        ),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,

          children: [
            // ==================================================
            // ICONO
            // ==================================================

            const Icon(
              Icons.add_business,
              size: 80,
              color:
                  Color(0xFFFF7E01),
            ),

            const SizedBox(
              height: 30,
            ),

            // ==================================================
            // NOMBRE
            // ==================================================

            TextField(
              controller:
                  nombreController,

              decoration:
                  const InputDecoration(
                labelText:
                    'Nombre del emprendimiento',

                prefixIcon:
                    Icon(
                  Icons.storefront,
                ),
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            // ==================================================
            // DESCRIPCIÓN
            // ==================================================

            TextField(
              controller:
                  descripcionController,

              maxLines: 4,

              decoration:
                  const InputDecoration(
                labelText:
                    'Descripción',

                prefixIcon:
                    Icon(
                  Icons
                      .description_outlined,
                ),
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            // ==================================================
            // TELÉFONO
            // ==================================================

            TextField(
              controller:
                  telefonoController,

              keyboardType:
                  TextInputType.phone,

              decoration:
                  const InputDecoration(
                labelText:
                    'Teléfono de contacto',

                prefixIcon:
                    Icon(
                  Icons.phone_outlined,
                ),
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            // ==================================================
            // CORREO
            // ==================================================

            TextField(
              controller:
                  correoController,

              keyboardType:
                  TextInputType
                      .emailAddress,

              decoration:
                  const InputDecoration(
                labelText:
                    'Correo de contacto',

                prefixIcon:
                    Icon(
                  Icons.email_outlined,
                ),
              ),
            ),

            const SizedBox(
              height: 30,
            ),

            // ==================================================
            // UBICACIÓN
            // ==================================================

            Row(
              children: [
                const Icon(
                  Icons
                      .location_on_outlined,
                  color:
                      Color(
                    0xFFFF7E01,
                  ),
                ),

                const SizedBox(
                  width: 8,
                ),

                Text(
                  'Ubicación del emprendimiento',
                  style:
                      Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              'Selecciona el lugar donde está ubicado tu emprendimiento.',
              style:
                  Theme.of(context)
                      .textTheme
                      .bodySmall,
            ),

            const SizedBox(
              height: 18,
            ),

            // ==================================================
            // USAR GPS
            // ==================================================

            SizedBox(
              height: 52,

              child:
                  OutlinedButton.icon(
                onPressed:
                    obteniendoUbicacion
                        ? null
                        : usarMiUbicacionActual,

                icon:
                    obteniendoUbicacion
                        ? const SizedBox(
                            width: 19,
                            height: 19,
                            child:
                                CircularProgressIndicator(
                              strokeWidth:
                                  2,
                              color:
                                  Color(
                                0xFFFF7E01,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons
                                .my_location,
                          ),

                label: Text(
                  obteniendoUbicacion
                      ? 'Obteniendo ubicación...'
                      : 'Usar mi ubicación actual',
                ),
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            // ==================================================
            // UBICAR EN MAPA
            // ==================================================

            SizedBox(
              height: 52,

              child:
                  OutlinedButton.icon(
                onPressed:
                    ubicarEnMapa,

                icon:
                    const Icon(
                  Icons.map_outlined,
                ),

                label:
                    const Text(
                  'Ubicar en el mapa',
                ),
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            // ==================================================
            // UBICACIÓN SELECCIONADA
            // ==================================================

            AnimatedContainer(
              duration:
                  const Duration(
                milliseconds: 250,
              ),

              padding:
                  const EdgeInsets.all(
                16,
              ),

              decoration:
                  BoxDecoration(
                color:
                    ubicacionSeleccionada
                        ? const Color(
                                0xFFFF7E01,
                              )
                            .withValues(
                            alpha:
                                oscuro
                                    ? 0.16
                                    : 0.10,
                          )
                        : Theme.of(
                            context,
                          )
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(
                              alpha:
                                  0.45,
                            ),

                borderRadius:
                    BorderRadius.circular(
                  16,
                ),

                border:
                    Border.all(
                  color:
                      ubicacionSeleccionada
                          ? const Color(
                              0xFFFF7E01,
                            )
                          : Theme.of(
                              context,
                            )
                              .dividerColor,
                ),
              ),

              child:
                  ubicacionSeleccionada
                      ? Row(
                          children: [
                            const ContainerUbicacionIcon(),

                            const SizedBox(
                              width: 12,
                            ),

                            Expanded(
                              child:
                                  Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,

                                children: [
                                  const Text(
                                    'Ubicación seleccionada',
                                    style:
                                        TextStyle(
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 4,
                                  ),

                                  Text(
                                    '${latitud!.toStringAsFixed(6)}, '
                                    '${longitud!.toStringAsFixed(6)}',
                                    style:
                                        const TextStyle(
                                      fontSize:
                                          12,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            IconButton(
                              tooltip:
                                  'Eliminar ubicación',

                              onPressed:
                                  eliminarUbicacion,

                              icon:
                                  const Icon(
                                Icons.close,
                              ),
                            ),
                          ],
                        )
                      : const Row(
                          children: [
                            Icon(
                              Icons
                                  .location_off_outlined,
                            ),

                            SizedBox(
                              width: 12,
                            ),

                            Expanded(
                              child:
                                  Text(
                                'Aún no has seleccionado la ubicación de tu tienda.',
                              ),
                            ),
                          ],
                        ),
            ),

            const SizedBox(
              height: 30,
            ),

            // ==================================================
            // GUARDAR
            // ==================================================

            SizedBox(
              width:
                  double.infinity,

              height: 50,

              child:
                  ElevatedButton.icon(
                onPressed:
                    cargando
                        ? null
                        : guardar,

                icon:
                    const Icon(
                  Icons.save_outlined,
                ),

                label:
                    cargando
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child:
                                CircularProgressIndicator(
                              strokeWidth:
                                  2,
                              color:
                                  Colors.white,
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

// ============================================================
// ICONO UBICACIÓN
// ============================================================

class ContainerUbicacionIcon
    extends StatelessWidget {
  const ContainerUbicacionIcon({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: 42,
      height: 42,

      decoration:
          BoxDecoration(
        color:
            const Color(
          0xFFFF7E01,
        ),

        borderRadius:
            BorderRadius.circular(
          12,
        ),
      ),

      child:
          const Icon(
        Icons.location_on,
        color:
            Colors.white,
      ),
    );
  }
}