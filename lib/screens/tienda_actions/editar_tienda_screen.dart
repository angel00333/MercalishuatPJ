import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../models/emprendimiento.dart';
import '../../services/emprendimiento_service.dart';
import '../../services/perfil_imagen_service.dart';

import 'seleccionar_ubicacion_screen.dart';

class EditarTiendaScreen
    extends StatefulWidget {
  final Emprendimiento tienda;

  const EditarTiendaScreen({
    super.key,
    required this.tienda,
  });

  @override
  State<EditarTiendaScreen>
      createState() =>
          _EditarTiendaScreenState();
}

class _EditarTiendaScreenState
    extends State<
        EditarTiendaScreen> {
  late TextEditingController
      nombreController;

  late TextEditingController
      descripcionController;

  late TextEditingController
      telefonoController;

  late TextEditingController
      correoController;

  final picker =
      ImagePicker();

  String? imagenUrl;

  bool guardando = false;
  bool subiendoImagen = false;
  bool obteniendoUbicacion =
      false;

  double? latitud;
  double? longitud;

  @override
  void initState() {
    super.initState();

    nombreController =
        TextEditingController(
      text:
          widget.tienda.nombre,
    );

    descripcionController =
        TextEditingController(
      text:
          widget.tienda.descripcion ??
              '',
    );

    telefonoController =
        TextEditingController(
      text:
          widget.tienda.telefono ??
              '',
    );

    correoController =
        TextEditingController(
      text:
          widget.tienda
                  .correoContacto ??
              '',
    );

    imagenUrl =
        widget.tienda.imagenUrl;

    latitud =
        widget.tienda.latitud;

    longitud =
        widget.tienda.longitud;
  }

  // ============================================================
  // IMAGEN
  // ============================================================

  Future<void> elegirImagen(
    ImageSource source,
  ) async {
    final imagen =
        await picker.pickImage(
      source: source,
      imageQuality: 85,
    );

    if (imagen == null) {
      return;
    }

    setState(() {
      subiendoImagen = true;
    });

    final resultado =
        await PerfilImagenService
            .subirImagenEmprendimiento(
      imagen,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      subiendoImagen = false;
    });

    if (resultado['success'] ==
        true) {
      setState(() {
        imagenUrl =
            resultado['imagen_url'];
      });

      mostrarMensaje(
        'Imagen de la tienda actualizada',
      );

      return;
    }

    mostrarMensaje(
      resultado['message'] ??
          'No se pudo subir la imagen',
    );
  }

  void opcionesImagen() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading:
                    const Icon(
                  Icons
                      .photo_library_outlined,
                ),
                title:
                    const Text(
                  'Galería',
                ),
                onTap: () {
                  Navigator.pop(
                    context,
                  );

                  elegirImagen(
                    ImageSource.gallery,
                  );
                },
              ),

              ListTile(
                leading:
                    const Icon(
                  Icons
                      .camera_alt_outlined,
                ),
                title:
                    const Text(
                  'Cámara',
                ),
                onTap: () {
                  Navigator.pop(
                    context,
                  );

                  elegirImagen(
                    ImageSource.camera,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // USAR UBICACIÓN ACTUAL
  // ============================================================

  Future<void>
      usarMiUbicacionActual() async {
    if (obteniendoUbicacion) {
      return;
    }

    setState(() {
      obteniendoUbicacion =
          true;
    });

    try {
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
          'Permiso de ubicación denegado',
        );

        return;
      }

      if (permiso ==
          LocationPermission
              .deniedForever) {
        if (!mounted) {
          return;
        }

        await _mostrarPermisoBloqueado();

        return;
      }

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
        'Ubicación actualizada',
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
  // UBICAR EN MAPA
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
        await Navigator
            .push<LatLng>(
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
  // GUARDAR
  // ============================================================

  Future<void> guardar() async {
    final nombre =
        nombreController.text.trim();

    if (nombre.isEmpty) {
      mostrarMensaje(
        'Ingresa el nombre del emprendimiento',
      );

      return;
    }

    if (latitud == null ||
        longitud == null) {
      mostrarMensaje(
        'Selecciona la ubicación del emprendimiento',
      );

      return;
    }

    setState(() {
      guardando = true;
    });

    final resultado =
        await EmprendimientoService
            .editar(
      nombre: nombre,

      descripcion:
          descripcionController.text
              .trim(),

      telefono:
          telefonoController.text
              .trim(),

      correoContacto:
          correoController.text
              .trim(),

      latitud:
          latitud,

      longitud:
          longitud,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      guardando = false;
    });

    if (resultado['success'] ==
        true) {
      mostrarMensaje(
        'Emprendimiento actualizado',
      );

      Navigator.pop(
        context,
        true,
      );

      return;
    }

    mostrarMensaje(
      resultado['message'] ??
          'No se pudo actualizar',
    );
  }

  // ============================================================
  // GPS DESACTIVADO
  // ============================================================

  Future<void>
      _mostrarGpsDesactivado() async {
    await showDialog(
      context: context,
      builder: (
        dialogContext,
      ) {
        return AlertDialog(
          icon: const Icon(
            Icons
                .location_off_outlined,
            color:
                Color(0xFFFF7E01),
            size: 42,
          ),

          title:
              const Text(
            'Ubicación desactivada',
          ),

          content:
              const Text(
            'Activa la ubicación del dispositivo para utilizar tu posición actual.',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child:
                  const Text(
                'Cancelar',
              ),
            ),

            FilledButton(
              style:
                  FilledButton
                      .styleFrom(
                backgroundColor:
                    const Color(
                  0xFFFF7E01,
                ),
                foregroundColor:
                    Colors.white,
              ),
              onPressed:
                  () async {
                Navigator.pop(
                  dialogContext,
                );

                await Geolocator
                    .openLocationSettings();
              },
              child:
                  const Text(
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
      builder: (
        dialogContext,
      ) {
        return AlertDialog(
          icon: const Icon(
            Icons
                .gps_off_outlined,
            color:
                Color(0xFFFF7E01),
            size: 42,
          ),

          title:
              const Text(
            'Permiso requerido',
          ),

          content:
              const Text(
            'El permiso de ubicación está bloqueado. Puedes habilitarlo desde los ajustes de la aplicación.',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child:
                  const Text(
                'Cancelar',
              ),
            ),

            FilledButton(
              style:
                  FilledButton
                      .styleFrom(
                backgroundColor:
                    const Color(
                  0xFFFF7E01,
                ),
                foregroundColor:
                    Colors.white,
              ),
              onPressed:
                  () async {
                Navigator.pop(
                  dialogContext,
                );

                await Geolocator
                    .openAppSettings();
              },
              child:
                  const Text(
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
        content:
            Text(
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
        title:
            const Text(
          'Editar tienda',
        ),
      ),

      body: ListView(
        padding:
            const EdgeInsets.all(
          24,
        ),

        children: [
          // ====================================================
          // FOTO
          // ====================================================

          Center(
            child:
                Stack(
              children: [
                CircleAvatar(
                  radius:
                      65,

                  backgroundColor:
                      const Color(
                    0xFFFF7E01,
                  ),

                  backgroundImage:
                      imagenUrl !=
                                  null &&
                              imagenUrl!
                                  .isNotEmpty
                          ? NetworkImage(
                              imagenUrl!,
                            )
                          : null,

                  child:
                      imagenUrl ==
                                  null ||
                              imagenUrl!
                                  .isEmpty
                          ? const Icon(
                              Icons
                                  .storefront,
                              size:
                                  70,
                              color:
                                  Colors.white,
                            )
                          : null,
                ),

                Positioned(
                  right:
                      0,
                  bottom:
                      0,

                  child:
                      Material(
                    color:
                        const Color(
                      0xFFFF7E01,
                    ),

                    shape:
                        const CircleBorder(),

                    child:
                        IconButton(
                      onPressed:
                          subiendoImagen
                              ? null
                              : opcionesImagen,

                      icon:
                          subiendoImagen
                              ? const SizedBox(
                                  width:
                                      20,
                                  height:
                                      20,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth:
                                        2,
                                    color:
                                        Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons
                                      .camera_alt,
                                  color:
                                      Colors.white,
                                ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height:
                30,
          ),

          // ====================================================
          // NOMBRE
          // ====================================================

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
            height:
                18,
          ),

          // ====================================================
          // DESCRIPCIÓN
          // ====================================================

          TextField(
            controller:
                descripcionController,

            maxLines:
                4,

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
            height:
                18,
          ),

          // ====================================================
          // TELÉFONO
          // ====================================================

          TextField(
            controller:
                telefonoController,

            keyboardType:
                TextInputType.phone,

            decoration:
                const InputDecoration(
              labelText:
                  'Teléfono',

              prefixIcon:
                  Icon(
                Icons.phone_outlined,
              ),
            ),
          ),

          const SizedBox(
            height:
                18,
          ),

          // ====================================================
          // CORREO
          // ====================================================

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
            height:
                30,
          ),

          // ====================================================
          // UBICACIÓN
          // ====================================================

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
                width:
                    8,
              ),

              Expanded(
                child:
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
              ),
            ],
          ),

          const SizedBox(
            height:
                8,
          ),

          Text(
            'Puedes mantener la ubicación actual o cambiarla.',

            style:
                Theme.of(context)
                    .textTheme
                    .bodySmall,
          ),

          const SizedBox(
            height:
                18,
          ),

          // ====================================================
          // UBICACIÓN ACTUAL
          // ====================================================

          SizedBox(
            height:
                52,

            child:
                OutlinedButton.icon(
              onPressed:
                  obteniendoUbicacion
                      ? null
                      : usarMiUbicacionActual,

              icon:
                  obteniendoUbicacion
                      ? const SizedBox(
                          width:
                              19,
                          height:
                              19,
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

              label:
                  Text(
                obteniendoUbicacion
                    ? 'Obteniendo ubicación...'
                    : 'Usar mi ubicación actual',
              ),
            ),
          ),

          const SizedBox(
            height:
                12,
          ),

          // ====================================================
          // MAPA
          // ====================================================

          SizedBox(
            height:
                52,

            child:
                OutlinedButton.icon(
              onPressed:
                  ubicarEnMapa,

              icon:
                  const Icon(
                Icons
                    .map_outlined,
              ),

              label:
                  Text(
                ubicacionSeleccionada
                    ? 'Cambiar ubicación en el mapa'
                    : 'Ubicar en el mapa',
              ),
            ),
          ),

          const SizedBox(
            height:
                18,
          ),

          // ====================================================
          // UBICACIÓN SELECCIONADA
          // ====================================================

          AnimatedContainer(
            duration:
                const Duration(
              milliseconds:
                  250,
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
                  BorderRadius
                      .circular(
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
                          ).dividerColor,
              ),
            ),

            child:
                ubicacionSeleccionada
                    ? Row(
                        children: [
                          Container(
                            width:
                                42,
                            height:
                                42,

                            decoration:
                                BoxDecoration(
                              color:
                                  const Color(
                                0xFFFF7E01,
                              ),
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                12,
                              ),
                            ),

                            child:
                                const Icon(
                              Icons
                                  .location_on,
                              color:
                                  Colors.white,
                            ),
                          ),

                          const SizedBox(
                            width:
                                12,
                          ),

                          Expanded(
                            child:
                                Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,

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
                                  height:
                                      4,
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
                            width:
                                12,
                          ),

                          Expanded(
                            child:
                                Text(
                              'Este emprendimiento todavía no tiene ubicación.',
                            ),
                          ),
                        ],
                      ),
          ),

          const SizedBox(
            height:
                30,
          ),

          // ====================================================
          // GUARDAR
          // ====================================================

          SizedBox(
            height:
                50,

            child:
                ElevatedButton.icon(
              onPressed:
                  guardando
                      ? null
                      : guardar,

              icon:
                  const Icon(
                Icons
                    .save_outlined,
              ),

              label:
                  guardando
                      ? const SizedBox(
                          width:
                              24,
                          height:
                              24,
                          child:
                              CircularProgressIndicator(
                            strokeWidth:
                                2,
                            color:
                                Colors.white,
                          ),
                        )
                      : const Text(
                          'Guardar cambios',
                        ),
            ),
          ),
        ],
      ),
    );
  }
}