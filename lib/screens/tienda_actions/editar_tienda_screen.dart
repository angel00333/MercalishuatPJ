import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/emprendimiento.dart';
import '../../services/emprendimiento_service.dart';
import '../../services/perfil_imagen_service.dart';

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
  }

  Future<void> elegirImagen(
    ImageSource source,
  ) async {
    final imagen =
        await picker.pickImage(
      source: source,
      imageQuality: 85,
    );

    if (imagen == null) return;

    setState(() {
      subiendoImagen = true;
    });

    final resultado =
        await PerfilImagenService
            .subirImagenEmprendimiento(
      imagen,
    );

    if (!mounted) return;

    setState(() {
      subiendoImagen = false;
    });

    if (resultado['success'] == true) {
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
                leading: const Icon(
                  Icons.photo_library_outlined,
                ),
                title: const Text(
                  'Galería',
                ),
                onTap: () {
                  Navigator.pop(context);

                  elegirImagen(
                    ImageSource.gallery,
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_outlined,
                ),
                title: const Text(
                  'Cámara',
                ),
                onTap: () {
                  Navigator.pop(context);

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

  Future<void> guardar() async {
    final nombre =
        nombreController.text.trim();

    if (nombre.isEmpty) {
      mostrarMensaje(
        'Ingresa el nombre del emprendimiento',
      );
      return;
    }

    setState(() {
      guardando = true;
    });

    final resultado =
        await EmprendimientoService.editar(
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
    );

    if (!mounted) return;

    setState(() {
      guardando = false;
    });

    if (resultado['success'] == true) {
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

  void mostrarMensaje(
    String mensaje,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content:
            Text(mensaje),
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
  Widget build(
    BuildContext context,
  ) {
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
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 65,
                  backgroundColor:
                      const Color(
                    0xFFFF7E01,
                  ),
                  backgroundImage:
                      imagenUrl != null &&
                              imagenUrl!
                                  .isNotEmpty
                          ? NetworkImage(
                              imagenUrl!,
                            )
                          : null,
                  child:
                      imagenUrl == null ||
                              imagenUrl!
                                  .isEmpty
                          ? const Icon(
                              Icons.storefront,
                              size: 70,
                              color:
                                  Colors.white,
                            )
                          : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
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
                                  Icons.camera_alt,
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
            height: 30,
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
            height: 18,
          ),

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
                Icons.description_outlined,
              ),
            ),
          ),

          const SizedBox(
            height: 18,
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
            height: 18,
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
            height: 30,
          ),

          SizedBox(
            height: 50,
            child:
                ElevatedButton.icon(
              onPressed:
                  guardando
                      ? null
                      : guardar,
              icon:
                  const Icon(
                Icons.save_outlined,
              ),
              label:
                  guardando
                      ? const CircularProgressIndicator(
                          color:
                              Colors.white,
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