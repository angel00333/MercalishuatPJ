import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/publicacion_service.dart';

class CrearPublicacionScreen extends StatefulWidget {
  const CrearPublicacionScreen({
    super.key,
  });

  @override
  State<CrearPublicacionScreen> createState() =>
      _CrearPublicacionScreenState();
}

class _CrearPublicacionScreenState
    extends State<CrearPublicacionScreen> {
  final TextEditingController textoController =
      TextEditingController();

  final ImagePicker picker = ImagePicker();

  final List<XFile> imagenes = [];

  bool publicando = false;

  Future<void> seleccionarImagenes() async {
    if (imagenes.length >= 5) {
      mostrarMensaje(
        'Máximo 5 imágenes por publicación',
      );
      return;
    }

    final seleccionadas =
        await picker.pickMultiImage(
      imageQuality: 85,
    );

    if (seleccionadas.isEmpty) {
      return;
    }

    final disponibles =
        5 - imagenes.length;

    setState(() {
      imagenes.addAll(
        seleccionadas.take(disponibles),
      );
    });

    if (seleccionadas.length > disponibles) {
      mostrarMensaje(
        'Solo puedes agregar 5 imágenes',
      );
    }
  }

  Future<void> tomarFoto() async {
    if (imagenes.length >= 5) {
      mostrarMensaje(
        'Máximo 5 imágenes por publicación',
      );
      return;
    }

    final imagen =
        await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (imagen == null) {
      return;
    }

    setState(() {
      imagenes.add(imagen);
    });
  }

  void mostrarOpcionesImagen() {
    if (imagenes.length >= 5) {
      mostrarMensaje(
        'Máximo 5 imágenes por publicación',
      );
      return;
    }

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
                  'Elegir de galería',
                ),
                onTap: () {
                  Navigator.pop(context);

                  seleccionarImagenes();
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_outlined,
                ),
                title: const Text(
                  'Tomar foto',
                ),
                onTap: () {
                  Navigator.pop(context);

                  tomarFoto();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> publicar() async {
    if (publicando) {
      return;
    }

    final texto =
        textoController.text.trim();

    if (texto.isEmpty) {
      mostrarMensaje(
        'Escribe algo para publicar',
      );
      return;
    }

    setState(() {
      publicando = true;
    });

    final resultado =
        await PublicacionService.crear(
      texto: texto,
    );

    if (!mounted) {
      return;
    }

    if (resultado['success'] != true) {
      setState(() {
        publicando = false;
      });

      mostrarMensaje(
        resultado['message'] ??
            'No se pudo crear la publicación',
      );

      return;
    }

    final publicacion =
        resultado['publicacion'];

    if (publicacion == null ||
        publicacion['id'] == null) {
      setState(() {
        publicando = false;
      });

      mostrarMensaje(
        'La publicación se creó, pero no se recibió su ID',
      );

      return;
    }

    final publicacionId =
        int.tryParse(
      publicacion['id'].toString(),
    );

    if (publicacionId == null) {
      setState(() {
        publicando = false;
      });

      mostrarMensaje(
        'ID de publicación inválido',
      );

      return;
    }

    int subidas = 0;

    for (final imagen in imagenes) {
      final resultadoImagen =
          await PublicacionService
              .subirImagen(
        publicacionId:
            publicacionId,
        imagen: imagen,
      );

      if (resultadoImagen['success'] ==
          true) {
        subidas++;
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      publicando = false;
    });

    if (imagenes.isNotEmpty &&
        subidas != imagenes.length) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Publicación creada. Se subieron $subidas de ${imagenes.length} imágenes.',
          ),
        ),
      );
    }

    Navigator.pop(
      context,
      true,
    );
  }

  void eliminarImagen(
    int index,
  ) {
    if (publicando) {
      return;
    }

    setState(() {
      imagenes.removeAt(index);
    });
  }

  void mostrarMensaje(
    String mensaje,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(mensaje),
      ),
    );
  }

  @override
  void dispose() {
    textoController.dispose();

    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final limiteAlcanzado =
        imagenes.length >= 5;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Crear publicación',
        ),
        actions: [
          IconButton(
            tooltip: 'Publicar',
            onPressed:
                publicando
                    ? null
                    : publicar,
            icon:
                publicando
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color:
                              Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        color:
                            Colors.white,
                      ),
          ),
          const SizedBox(
            width: 8,
          ),
        ],
      ),
      body: ListView(
        padding:
            const EdgeInsets.all(
          20,
        ),
        children: [
          TextField(
            controller:
                textoController,
            autofocus: true,
            enabled: !publicando,
            minLines: 5,
            maxLines: null,
            maxLength: 1500,
            decoration:
                const InputDecoration(
              hintText:
                  '¿Qué quieres compartir?',
              alignLabelWithHint: true,
            ),
          ),

          const SizedBox(
            height: 20,
          ),

          OutlinedButton.icon(
            onPressed:
                publicando ||
                        limiteAlcanzado
                    ? null
                    : mostrarOpcionesImagen,
            icon: Icon(
              limiteAlcanzado
                  ? Icons.check_circle_outline
                  : Icons
                      .add_photo_alternate_outlined,
            ),
            label: Text(
              limiteAlcanzado
                  ? 'Máximo de imágenes alcanzado (5/5)'
                  : imagenes.isEmpty
                      ? 'Agregar imágenes'
                      : 'Agregar imágenes (${imagenes.length}/5)',
            ),
          ),

          if (imagenes.isNotEmpty) ...[
            const SizedBox(
              height: 20,
            ),

            SizedBox(
              height: 130,
              child:
                  ListView.separated(
                scrollDirection:
                    Axis.horizontal,
                itemCount:
                    imagenes.length,
                separatorBuilder:
                    (_, __) =>
                        const SizedBox(
                  width: 10,
                ),
                itemBuilder:
                    (
                  context,
                  index,
                ) {
                  final imagen =
                      imagenes[index];

                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(
                          12,
                        ),
                        child:
                            FutureBuilder<
                                Uint8List>(
                          future:
                              imagen.readAsBytes(),
                          builder:
                              (
                            context,
                            snapshot,
                          ) {
                            if (snapshot
                                .hasError) {
                              return Container(
                                width: 130,
                                height: 130,
                                alignment:
                                    Alignment.center,
                                child:
                                    const Icon(
                                  Icons
                                      .broken_image_outlined,
                                  size: 40,
                                ),
                              );
                            }

                            if (!snapshot
                                .hasData) {
                              return const SizedBox(
                                width: 130,
                                height: 130,
                                child:
                                    Center(
                                  child:
                                      CircularProgressIndicator(),
                                ),
                              );
                            }

                            return Image.memory(
                              snapshot.data!,
                              width: 130,
                              height: 130,
                              fit:
                                  BoxFit.cover,
                            );
                          },
                        ),
                      ),

                      Positioned(
                        top: 5,
                        right: 5,
                        child:
                            CircleAvatar(
                          radius: 16,
                          backgroundColor:
                              Colors.black54,
                          child:
                              IconButton(
                            tooltip:
                                'Eliminar imagen',
                            padding:
                                EdgeInsets.zero,
                            iconSize: 18,
                            onPressed:
                                publicando
                                    ? null
                                    : () {
                                        eliminarImagen(
                                          index,
                                        );
                                      },
                            icon:
                                const Icon(
                              Icons.close,
                              color:
                                  Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],

          if (publicando) ...[
            const SizedBox(
              height: 30,
            ),
            const Center(
              child:
                  CircularProgressIndicator(
                color:
                    Color(
                  0xFFFF7E01,
                ),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            const Center(
              child: Text(
                'Publicando...',
              ),
            ),
          ],
        ],
      ),
    );
  }
}