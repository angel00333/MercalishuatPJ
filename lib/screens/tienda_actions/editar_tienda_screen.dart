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
    extends State<EditarTiendaScreen> {
  late TextEditingController
      nombreController;

  late TextEditingController
      descripcionController;

  late TextEditingController
      telefonoController;

  late TextEditingController
      correoController;

  final ImagePicker picker =
      ImagePicker();

  String? imagenUrl;

  double? latitud;
  double? longitud;

  bool guardando =
      false;

  bool subiendoImagen =
      false;

  bool obteniendoUbicacion =
      false;

  // ============================================================
  // INIT
  // ============================================================

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

    // ==========================================================
    // UBICACIÓN ACTUAL GUARDADA
    // ==========================================================

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
      source:
          source,
      imageQuality:
          85,
    );

    if (imagen == null) {
      return;
    }

    setState(() {
      subiendoImagen =
          true;
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
      subiendoImagen =
          false;
    });

    if (resultado['success'] ==
        true) {
      setState(() {
        imagenUrl =
            resultado[
                'imagen_url'];
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
      context:
          context,
      builder:
          (modalContext) {
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
                onTap:
                    () {
                  Navigator.pop(
                    modalContext,
                  );

                  elegirImagen(
                    ImageSource
                        .gallery,
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
                onTap:
                    () {
                  Navigator.pop(
                    modalContext,
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
  // USAR MI UBICACIÓN ACTUAL
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
      final bool servicio =
          await Geolocator
              .isLocationServiceEnabled();

      if (!servicio) {
        if (!mounted) {
          return;
        }

        mostrarMensaje(
          'Activa la ubicación del dispositivo',
        );

        await Geolocator
            .openLocationSettings();

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
        if (mounted) {
          mostrarMensaje(
            'Permiso de ubicación denegado',
          );
        }

        return;
      }

      if (permiso ==
          LocationPermission
              .deniedForever) {
        if (mounted) {
          mostrarMensaje(
            'Activa el permiso de ubicación desde los ajustes',
          );
        }

        await Geolocator
            .openAppSettings();

        return;
      }

      const settings =
          LocationSettings(
        accuracy:
            LocationAccuracy.high,
      );

      final Position posicion =
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
        'Ubicación actual seleccionada',
      );
    } catch (e) {
      debugPrint(
        'Error ubicación: $e',
      );

      if (mounted) {
        mostrarMensaje(
          'No se pudo obtener la ubicación',
        );
      }
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
  // UBICAR EN EL MAPA
  // ============================================================

  Future<void> ubicarEnMapa() async {
    LatLng? inicial;

    if (latitud != null &&
        longitud != null) {
      inicial =
          LatLng(
        latitud!,
        longitud!,
      );
    }

    final LatLng? resultado =
        await Navigator.push<
            LatLng>(
      context,
      MaterialPageRoute(
        builder:
            (_) =>
                SeleccionarUbicacionScreen(
          ubicacionInicial:
              inicial,
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
      'Nueva ubicación seleccionada',
    );
  }

  // ============================================================
  // ELIMINAR UBICACIÓN
  // ============================================================

  void eliminarUbicacion() {
    setState(() {
      latitud =
          null;

      longitud =
          null;
    });

    mostrarMensaje(
      'Ubicación eliminada. Selecciona una nueva antes de guardar.',
    );
  }

  // ============================================================
  // GUARDAR
  // ============================================================

  Future<void> guardar() async {
    final nombre =
        nombreController.text
            .trim();

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
      guardando =
          true;
    });

    // ==========================================================
    // AQUÍ ESTABA EL ERROR
    //
    // AHORA SÍ ENVIAMOS LATITUD Y LONGITUD.
    // ==========================================================

    final resultado =
        await EmprendimientoService
            .editar(
      nombre:
          nombre,

      descripcion:
          descripcionController
              .text
              .trim(),

      telefono:
          telefonoController
              .text
              .trim(),

      correoContacto:
          correoController
              .text
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
      guardando =
          false;
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
  // MENSAJE
  // ============================================================

  void mostrarMensaje(
    String mensaje,
  ) {
    ScaffoldMessenger.of(
      context,
    )
      ..hideCurrentSnackBar()
      ..showSnackBar(
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
    final bool oscuro =
        Theme.of(context)
                .brightness ==
            Brightness.dark;

    final bool tieneUbicacion =
        latitud != null &&
            longitud != null;

    return Scaffold(
      appBar:
          AppBar(
        title:
            const Text(
          'Editar tienda',
        ),
      ),

      body:
          ListView(
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

          const Row(
            children: [
              Icon(
                Icons
                    .location_on_outlined,
                color:
                    Color(
                  0xFFFF7E01,
                ),
              ),
              SizedBox(
                width:
                    8,
              ),
              Text(
                'Ubicación del emprendimiento',
                style:
                    TextStyle(
                  fontSize:
                      17,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(
            height:
                16,
          ),

          OutlinedButton.icon(
            onPressed:
                obteniendoUbicacion
                    ? null
                    : usarMiUbicacionActual,
            icon:
                obteniendoUbicacion
                    ? const SizedBox(
                        width:
                            18,
                        height:
                            18,
                        child:
                            CircularProgressIndicator(
                          strokeWidth:
                              2,
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

          const SizedBox(
            height:
                10,
          ),

          OutlinedButton.icon(
            onPressed:
                ubicarEnMapa,
            icon:
                const Icon(
              Icons.map_outlined,
            ),
            label:
                Text(
              tieneUbicacion
                  ? 'Cambiar ubicación en el mapa'
                  : 'Ubicar en el mapa',
            ),
          ),

          const SizedBox(
            height:
                16,
          ),

          Container(
            padding:
                const EdgeInsets.all(
              15,
            ),
            decoration:
                BoxDecoration(
              color:
                  tieneUbicacion
                      ? const Color(
                              0xFFFF7E01,
                            )
                          .withValues(
                          alpha:
                              oscuro
                                  ? 0.16
                                  : 0.08,
                        )
                      : Theme.of(
                          context,
                        )
                          .colorScheme
                          .surfaceContainerHighest,
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
              border:
                  Border.all(
                color:
                    tieneUbicacion
                        ? const Color(
                            0xFFFF7E01,
                          )
                        : Theme.of(
                            context,
                          ).dividerColor,
              ),
            ),
            child:
                tieneUbicacion
                    ? Row(
                        children: [
                          const Icon(
                            Icons
                                .location_on,
                            color:
                                Color(
                              0xFFFF7E01,
                            ),
                          ),
                          const SizedBox(
                            width:
                                10,
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
                                  height:
                                      3,
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
                                10,
                          ),
                          Expanded(
                            child:
                                Text(
                              'No hay ubicación seleccionada.',
                            ),
                          ),
                        ],
                      ),
          ),

          const SizedBox(
            height:
                30,
          ),

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
                              22,
                          height:
                              22,
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