import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/categoria.dart';
import '../../models/producto.dart';
import '../../services/categoria_service.dart';
import '../../services/imagen_service.dart';
import '../../services/producto_service.dart';

class CrearProductoScreen
    extends StatefulWidget {
  const CrearProductoScreen({
    super.key,
  });

  @override
  State<CrearProductoScreen>
      createState() =>
          _CrearProductoScreenState();
}

class _CrearProductoScreenState
    extends State<CrearProductoScreen> {
  final nombreController =
      TextEditingController();

  final descripcionController =
      TextEditingController();

  final precioController =
      TextEditingController();

  final ImagePicker picker =
      ImagePicker();

  List<Categoria> categorias =
      [];

  int? categoriaId;

  bool disponible = true;

  bool cargando = false;
  bool cargandoCategorias = true;

  List<XFile> imagenes = [];

  @override
  void initState() {
    super.initState();

    cargarCategorias();
  }

  Future<void> cargarCategorias() async {
    final resultado =
        await CategoriaService.listar();

    if (!mounted) return;

    if (resultado['success'] == true) {
      setState(() {
        categorias =
            resultado['categorias']
                as List<Categoria>;

        cargandoCategorias =
            false;
      });
    } else {
      setState(() {
        cargandoCategorias =
            false;
      });

      mostrarMensaje(
        resultado['message'] ??
            'No se pudieron cargar las categorías',
      );
    }
  }

  Future<void> seleccionarImagenes() async {
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
        seleccionadas.take(
          disponibles,
        ),
      );
    });

    if (seleccionadas.length >
        disponibles) {
      mostrarMensaje(
        'Solo puedes agregar hasta 5 imágenes',
      );
    }
  }

  Future<void> tomarFoto() async {
    if (imagenes.length >= 5) {
      mostrarMensaje(
        'Solo puedes agregar hasta 5 imágenes',
      );
      return;
    }

    final imagen =
        await picker.pickImage(
      source:
          ImageSource.camera,
      imageQuality: 85,
    );

    if (imagen != null) {
      setState(() {
        imagenes.add(
          imagen,
        );
      });
    }
  }

  Future<void> guardar() async {
    final nombre =
        nombreController.text.trim();

    final descripcion =
        descripcionController.text
            .trim();

    final precio =
        double.tryParse(
      precioController.text
          .trim()
          .replaceAll(
            ',',
            '.',
          ),
    );

    if (nombre.isEmpty) {
      mostrarMensaje(
        'Ingresa el nombre del producto',
      );

      return;
    }

    if (categoriaId == null) {
      mostrarMensaje(
        'Selecciona una categoría',
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
        await ProductoService.crear(
      categoriaId:
          categoriaId!,
      nombre: nombre,
      descripcion:
          descripcion,
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
            'No se pudo crear el producto',
      );

      return;
    }

    final Producto producto =
        resultado['producto'];

    for (final imagen
        in imagenes) {
      final resultadoImagen =
          await ImagenService
              .subirImagen(
        productoId:
            producto.id,
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
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Producto creado correctamente',
        ),
      ),
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
          'Crear producto',
        ),
      ),

      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(
          20,
        ),
        child: Column(
          children: [
            TextField(
              controller:
                  nombreController,
              decoration:
                  const InputDecoration(
                labelText:
                    'Nombre del producto',
                prefixIcon:
                    Icon(
                  Icons.inventory_2_outlined,
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
                  Icons.description_outlined,
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
                prefixIcon:
                    Icon(
                  Icons.attach_money,
                ),
              ),
            ),

            const SizedBox(
              height: 15,
            ),

            if (cargandoCategorias)
              const CircularProgressIndicator(
                color:
                    Color(0xFFFF7E01),
              )
            else
              DropdownButtonFormField<
                  int>(
                initialValue:
                    categoriaId,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Categoría',
                  prefixIcon:
                      Icon(
                    Icons.category_outlined,
                  ),
                ),
                items:
                    categorias
                        .map(
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
                  setState(() {
                    categoriaId =
                        valor;
                  });
                },
              ),

            const SizedBox(
              height: 15,
            ),

            SwitchListTile(
              contentPadding:
                  EdgeInsets.zero,
              title: const Text(
                'Producto disponible',
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

            const SizedBox(
              height: 20,
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
                      Icons.photo_library_outlined,
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
                      Icons.camera_alt_outlined,
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
              height: 15,
            ),

            if (imagenes.isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection:
                      Axis.horizontal,
                  itemCount:
                      imagenes.length,
                  itemBuilder:
                      (context, index) {
                    return FutureBuilder<
                        List<int>>(
                      future:
                          imagenes[index]
                              .readAsBytes(),
                      builder:
                          (context,
                              snapshot) {
                        if (!snapshot
                            .hasData) {
                          return const SizedBox(
                            width: 100,
                            child:
                                Center(
                              child:
                                  CircularProgressIndicator(),
                            ),
                          );
                        }

                        return Stack(
                          children: [
                            Container(
                              margin:
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
                                  Uint8List.fromList(
                                    snapshot.data!,
                                  ),
                                  width:
                                      90,
                                  height:
                                      90,
                                  fit:
                                      BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              right: 5,
                              top: 0,
                              child:
                                  IconButton(
                                icon:
                                    const Icon(
                                  Icons.cancel,
                                ),
                                onPressed:
                                    () {
                                  setState(
                                    () {
                                      imagenes.removeAt(
                                        index,
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),

            const SizedBox(
              height: 30,
            ),

            SizedBox(
              width:
                  double.infinity,
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
                            'Guardar producto',
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}