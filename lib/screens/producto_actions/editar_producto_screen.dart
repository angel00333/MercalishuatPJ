import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/categoria.dart';
import '../../models/imagen_producto.dart';
import '../../models/producto.dart';
import '../../services/categoria_service.dart';
import '../../services/imagen_service.dart';
import '../../services/producto_service.dart';

class EditarProductoScreen
    extends StatefulWidget {
  final Producto producto;

  const EditarProductoScreen({
    super.key,
    required this.producto,
  });

  @override
  State<EditarProductoScreen>
      createState() =>
          _EditarProductoScreenState();
}

class _EditarProductoScreenState
    extends State<
        EditarProductoScreen> {
  late TextEditingController
      nombreController;

  late TextEditingController
      descripcionController;

  late TextEditingController
      precioController;

  final ImagePicker picker =
      ImagePicker();

  List<Categoria> categorias =
      [];

  List<ImagenProducto>
      imagenesExistentes = [];

  List<XFile> imagenesNuevas =
      [];

  late int categoriaId;
  late bool disponible;

  bool cargando = false;
  bool cargandoImagenes = true;

  @override
  void initState() {
    super.initState();

    nombreController =
        TextEditingController(
      text: widget.producto.nombre,
    );

    descripcionController =
        TextEditingController(
      text:
          widget.producto.descripcion ??
              '',
    );

    precioController =
        TextEditingController(
      text: widget.producto.precio
          .toStringAsFixed(2),
    );

    categoriaId =
        widget.producto.categoriaId;

    disponible =
        widget.producto.disponible;

    cargarCategorias();
    cargarImagenes();
  }

  Future<void> cargarCategorias()
      async {
    final resultado =
        await CategoriaService.listar();

    if (!mounted) return;

    if (resultado['success'] ==
        true) {
      setState(() {
        categorias =
            resultado['categorias']
                as List<Categoria>;
      });
    }
  }

  Future<void> cargarImagenes()
      async {
    final resultado =
        await ImagenService.listar(
      widget.producto.id,
    );

    if (!mounted) return;

    setState(() {
      if (resultado['success'] ==
          true) {
        imagenesExistentes =
            resultado['imagenes']
                as List<ImagenProducto>;
      }

      cargandoImagenes =
          false;
    });
  }

  int get cantidadTotalImagenes =>
      imagenesExistentes.length +
      imagenesNuevas.length;

  Future<void>
      seleccionarImagenes() async {
    if (cantidadTotalImagenes >=
        5) {
      mostrarMensaje(
        'El producto ya tiene 5 imágenes',
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
        5 - cantidadTotalImagenes;

    setState(() {
      imagenesNuevas.addAll(
        seleccionadas.take(
          disponibles,
        ),
      );
    });

    if (seleccionadas.length >
        disponibles) {
      mostrarMensaje(
        'Solo puedes tener hasta 5 imágenes por producto',
      );
    }
  }

  Future<void> tomarFoto() async {
    if (cantidadTotalImagenes >=
        5) {
      mostrarMensaje(
        'El producto ya tiene 5 imágenes',
      );

      return;
    }

    final imagen =
        await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (imagen != null) {
      setState(() {
        imagenesNuevas.add(
          imagen,
        );
      });
    }
  }

  Future<void>
      eliminarImagenExistente(
    ImagenProducto imagen,
  ) async {
    final resultado =
        await ImagenService.eliminar(
      productoId:
          widget.producto.id,
      imagenId:
          imagen.id,
    );

    if (!mounted) return;

    mostrarMensaje(
      resultado['message'] ??
          'Operación terminada',
    );

    if (resultado['success'] ==
        true) {
      await cargarImagenes();
    }
  }

  Future<void> marcarPrincipal(
    ImagenProducto imagen,
  ) async {
    final resultado =
        await ImagenService
            .marcarPrincipal(
      productoId:
          widget.producto.id,
      imagenId:
          imagen.id,
    );

    if (!mounted) return;

    mostrarMensaje(
      resultado['message'] ??
          'Operación terminada',
    );

    if (resultado['success'] ==
        true) {
      await cargarImagenes();
    }
  }

  Future<void> guardar() async {
    final nombre =
        nombreController.text.trim();

    final precio =
        double.tryParse(
      precioController.text
          .trim()
          .replaceAll(',', '.'),
    );

    if (nombre.isEmpty) {
      mostrarMensaje(
        'Ingresa el nombre del producto',
      );

      return;
    }

    if (precio == null ||
        precio < 0) {
      mostrarMensaje(
        'Ingresa un precio válido',
      );

      return;
    }

    setState(() {
      cargando = true;
    });

    final resultado =
        await ProductoService.editar(
      id: widget.producto.id,
      categoriaId:
          categoriaId,
      nombre: nombre,
      descripcion:
          descripcionController.text
              .trim(),
      precio: precio,
      disponible:
          disponible,
    );

    if (!mounted) return;

    if (resultado['success'] !=
        true) {
      setState(() {
        cargando = false;
      });

      mostrarMensaje(
        resultado['message'] ??
            'No se pudo actualizar el producto',
      );

      return;
    }

    for (final imagen
        in imagenesNuevas) {
      final resultadoImagen =
          await ImagenService
              .subirImagen(
        productoId:
            widget.producto.id,
        imagen: imagen,
      );

      if (resultadoImagen[
              'success'] !=
          true) {
        if (!mounted) return;

        mostrarMensaje(
          resultadoImagen[
                  'message'] ??
              'Una imagen no pudo subirse',
        );
      }
    }

    if (!mounted) return;

    setState(() {
      cargando = false;
      imagenesNuevas.clear();
    });

    mostrarMensaje(
      'Producto actualizado correctamente',
    );

    Navigator.pop(
      context,
      true,
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
    precioController.dispose();

    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Editar producto',
        ),
      ),

      body: ListView(
        padding:
            const EdgeInsets.all(
          20,
        ),
        children: [
          TextField(
            controller:
                nombreController,
            decoration:
                const InputDecoration(
              labelText:
                  'Nombre',
              prefixIcon:
                  Icon(
                Icons
                    .inventory_2_outlined,
              ),
            ),
          ),

          const SizedBox(
            height: 15,
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
                Icons
                    .description_outlined,
              ),
            ),
          ),

          const SizedBox(
            height: 15,
          ),

          TextField(
            controller:
                precioController,
            keyboardType:
                const TextInputType
                    .numberWithOptions(
              decimal: true,
            ),
            decoration:
                const InputDecoration(
              labelText:
                  'Precio',
              prefixText:
                  '\$ ',
            ),
          ),

          const SizedBox(
            height: 15,
          ),

          if (categorias.isNotEmpty)
            DropdownButtonFormField<
                int>(
              initialValue:
                  categoriaId,
              decoration:
                  const InputDecoration(
                labelText:
                    'Categoría',
              ),
              items:
                  categorias.map(
                (categoria) {
                  return DropdownMenuItem<
                      int>(
                    value:
                        categoria.id,
                    child:
                        Text(
                      categoria.nombre,
                    ),
                  );
                },
              ).toList(),
              onChanged:
                  (valor) {
                if (valor !=
                    null) {
                  setState(() {
                    categoriaId =
                        valor;
                  });
                }
              },
            ),

          const SizedBox(
            height: 10,
          ),

          SwitchListTile(
            contentPadding:
                EdgeInsets.zero,
            title:
                const Text(
              'Disponible',
            ),
            value:
                disponible,
            onChanged:
                (valor) {
              setState(() {
                disponible =
                    valor;
              });
            },
          ),

          const Divider(
            height: 40,
          ),

          const Text(
            'Imágenes',
            style: TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 5,
          ),

          Text(
            '$cantidadTotalImagenes / 5 imágenes',
          ),

          const SizedBox(
            height: 15,
          ),

          Row(
            children: [
              Expanded(
                child:
                    OutlinedButton.icon(
                  onPressed:
                      seleccionarImagenes,
                  icon:
                      const Icon(
                    Icons
                        .photo_library_outlined,
                  ),
                  label:
                      const Text(
                    'Galería',
                  ),
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child:
                    OutlinedButton.icon(
                  onPressed:
                      tomarFoto,
                  icon:
                      const Icon(
                    Icons
                        .camera_alt_outlined,
                  ),
                  label:
                      const Text(
                    'Cámara',
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 20,
          ),

          if (cargandoImagenes)
            const Center(
              child:
                  CircularProgressIndicator(
                color:
                    Color(0xFFFF7E01),
              ),
            ),

          if (!cargandoImagenes &&
              imagenesExistentes
                  .isNotEmpty)
            ...imagenesExistentes.map(
              (imagen) {
                return Card(
                  child: ListTile(
                    leading:
                        ClipRRect(
                      borderRadius:
                          BorderRadius.circular(
                        8,
                      ),
                      child:
                          Image.network(
                        imagen.url,
                        width: 65,
                        height: 65,
                        fit:
                            BoxFit.cover,
                      ),
                    ),
                    title: Text(
                      imagen.principal
                          ? 'Imagen principal'
                          : 'Imagen del producto',
                    ),
                    subtitle:
                        imagen.principal
                            ? const Text(
                                'Se muestra primero',
                              )
                            : null,
                    trailing:
                        PopupMenuButton<
                            String>(
                      onSelected:
                          (valor) {
                        if (valor ==
                            'principal') {
                          marcarPrincipal(
                            imagen,
                          );
                        }

                        if (valor ==
                            'eliminar') {
                          eliminarImagenExistente(
                            imagen,
                          );
                        }
                      },
                      itemBuilder:
                          (_) => [
                        if (!imagen
                            .principal)
                          const PopupMenuItem(
                            value:
                                'principal',
                            child:
                                Text(
                              'Usar como principal',
                            ),
                          ),
                        const PopupMenuItem(
                          value:
                              'eliminar',
                          child:
                              Text(
                            'Eliminar',
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

          if (imagenesNuevas
              .isNotEmpty) ...[
            const SizedBox(
              height: 15,
            ),

            const Text(
              'Nuevas imágenes',
              style: TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            SizedBox(
              height: 105,
              child:
                  ListView.builder(
                scrollDirection:
                    Axis.horizontal,
                itemCount:
                    imagenesNuevas
                        .length,
                itemBuilder:
                    (context,
                        index) {
                  return FutureBuilder<
                      Uint8List>(
                    future:
                        imagenesNuevas[
                                index]
                            .readAsBytes(),
                    builder:
                        (context,
                            snapshot) {
                      if (!snapshot
                          .hasData) {
                        return const SizedBox(
                          width:
                              95,
                          child:
                              Center(
                            child:
                                CircularProgressIndicator(),
                          ),
                        );
                      }

                      return Stack(
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.only(
                              right:
                                  10,
                            ),
                            child:
                                ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(
                                10,
                              ),
                              child:
                                  Image.memory(
                                snapshot.data!,
                                width:
                                    95,
                                height:
                                    95,
                                fit:
                                    BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 5,
                            top: -5,
                            child:
                                IconButton(
                              onPressed:
                                  () {
                                setState(
                                  () {
                                    imagenesNuevas.removeAt(
                                      index,
                                    );
                                  },
                                );
                              },
                              icon:
                                  const Icon(
                                Icons.cancel,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],

          const SizedBox(
            height: 30,
          ),

          SizedBox(
            height: 50,
            child:
                ElevatedButton(
              onPressed:
                  cargando
                      ? null
                      : guardar,
              child:
                  cargando
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