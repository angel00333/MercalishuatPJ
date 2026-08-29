import 'package:flutter/material.dart';

import '../../models/imagen_producto.dart';
import '../../models/producto.dart';
import '../../services/imagen_service.dart';
import '../../services/producto_service.dart';

class DetalleProductoScreen
    extends StatefulWidget {
  final int productoId;

  const DetalleProductoScreen({
    super.key,
    required this.productoId,
  });

  @override
  State<DetalleProductoScreen>
      createState() =>
          _DetalleProductoScreenState();
}

class _DetalleProductoScreenState
    extends State<DetalleProductoScreen> {
  Producto? producto;

  List<ImagenProducto> imagenes = [];

  bool cargando = true;

  int imagenActual = 0;

  @override
  void initState() {
    super.initState();

    cargar();
  }

  Future<void> cargar() async {
    final resultadoProducto =
        await ProductoService.obtenerPorId(
      widget.productoId,
    );

    final resultadoImagenes =
        await ImagenService.listar(
      widget.productoId,
    );

    if (!mounted) return;

    setState(() {
      if (resultadoProducto['success'] ==
          true) {
        producto =
            resultadoProducto['producto'];
      }

      if (resultadoImagenes['success'] ==
          true) {
        imagenes =
            resultadoImagenes['imagenes'];
      }

      cargando = false;
    });
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    if (cargando) {
      return const Scaffold(
        body: Center(
          child:
              CircularProgressIndicator(
            color:
                Color(0xFFFF7E01),
          ),
        ),
      );
    }

    if (producto == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text(
            'Producto no encontrado',
          ),
        ),
      );
    }

    final p = producto!;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Producto',
        ),
      ),

      body: RefreshIndicator(
        onRefresh: cargar,

        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),

          children: [
            // ============================================
            // IMÁGENES RESPONSIVE
            // ============================================

            if (imagenes.isNotEmpty)
              LayoutBuilder(
                builder: (
                  context,
                  constraints,
                ) {
                  final ancho =
                      constraints.maxWidth;

                  final alto =
                      ancho
                          .clamp(
                            300.0,
                            520.0,
                          )
                          .toDouble();

                  return Column(
                    children: [
                      Container(
                        width:
                            double.infinity,

                        height:
                            alto,

                        color:
                            Colors.white,

                        child:
                            PageView.builder(
                          itemCount:
                              imagenes.length,

                          onPageChanged:
                              (index) {
                            setState(() {
                              imagenActual =
                                  index;
                            });
                          },

                          itemBuilder:
                              (
                            context,
                            index,
                          ) {
                            final imagen =
                                imagenes[index];

                            return InteractiveViewer(
                              minScale:
                                  1.0,

                              maxScale:
                                  4.0,

                              child:
                                  Center(
                                child:
                                    Image.network(
                                  imagen.url,

                                  width:
                                      double.infinity,

                                  height:
                                      alto,

                                  fit:
                                      BoxFit
                                          .contain,

                                  alignment:
                                      Alignment
                                          .center,

                                  loadingBuilder:
                                      (
                                    context,
                                    child,
                                    loadingProgress,
                                  ) {
                                    if (loadingProgress ==
                                        null) {
                                      return child;
                                    }

                                    return const Center(
                                      child:
                                          CircularProgressIndicator(
                                        color:
                                            Color(
                                          0xFFFF7E01,
                                        ),
                                      ),
                                    );
                                  },

                                  errorBuilder:
                                      (
                                    context,
                                    error,
                                    stackTrace,
                                  ) {
                                    return const Center(
                                      child:
                                          Icon(
                                        Icons
                                            .broken_image_outlined,
                                        size:
                                            80,
                                        color:
                                            Colors.grey,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // ==================================
                      // INDICADORES
                      // ==================================

                      if (imagenes.length > 1)
                        Padding(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            vertical:
                                10,
                          ),

                          child:
                              Row(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .center,

                            children:
                                List.generate(
                              imagenes.length,
                              (index) {
                                final seleccionada =
                                    index ==
                                        imagenActual;

                                return AnimatedContainer(
                                  duration:
                                      const Duration(
                                    milliseconds:
                                        200,
                                  ),

                                  margin:
                                      const EdgeInsets
                                          .symmetric(
                                    horizontal:
                                        4,
                                  ),

                                  width:
                                      seleccionada
                                          ? 20
                                          : 8,

                                  height:
                                      8,

                                  decoration:
                                      BoxDecoration(
                                    color:
                                        seleccionada
                                            ? const Color(
                                                0xFFFF7E01,
                                              )
                                            : Colors
                                                .grey
                                                .shade400,

                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                      20,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                    ],
                  );
                },
              )
            else
              Container(
                width:
                    double.infinity,

                height:
                    300,

                color:
                    Colors.white,

                alignment:
                    Alignment.center,

                child:
                    const Icon(
                  Icons
                      .image_outlined,

                  size:
                      100,

                  color:
                      Color(
                    0xFFFF7E01,
                  ),
                ),
              ),

            // ============================================
            // INFORMACIÓN PRODUCTO
            // ============================================

            Padding(
              padding:
                  const EdgeInsets.all(
                20,
              ),

              child:
                  Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                children: [
                  Text(
                    p.nombre,

                    style:
                        const TextStyle(
                      fontSize:
                          27,

                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height:
                        8,
                  ),

                  Text(
                    '\$${p.precio.toStringAsFixed(2)}',

                    style:
                        const TextStyle(
                      fontSize:
                          24,

                      color:
                          Color(
                        0xFFFF7E01,
                      ),

                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height:
                        20,
                  ),

                  Text(
                    p.descripcion
                                ?.trim()
                                .isNotEmpty ==
                            true
                        ? p.descripcion!
                        : 'Sin descripción',

                    style:
                        const TextStyle(
                      fontSize:
                          16,
                    ),
                  ),

                  const SizedBox(
                    height:
                        20,
                  ),

                  Container(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal:
                          14,

                      vertical:
                          8,
                    ),

                    decoration:
                        BoxDecoration(
                      border:
                          Border.all(
                        color:
                            p.disponible
                                ? const Color(
                                    0xFFFF7E01,
                                  )
                                : Colors.red,
                      ),

                      borderRadius:
                          BorderRadius
                              .circular(
                        10,
                      ),
                    ),

                    child:
                        Row(
                      mainAxisSize:
                          MainAxisSize
                              .min,

                      children: [
                        Icon(
                          p.disponible
                              ? Icons
                                  .check_circle_outline
                              : Icons
                                  .cancel_outlined,

                          size:
                              18,

                          color:
                              p.disponible
                                  ? const Color(
                                      0xFFFF7E01,
                                    )
                                  : Colors
                                      .red,
                        ),

                        const SizedBox(
                          width:
                              6,
                        ),

                        Text(
                          p.disponible
                              ? 'Disponible'
                              : 'No disponible',

                          style:
                              TextStyle(
                            fontWeight:
                                FontWeight
                                    .w600,

                            color:
                                p.disponible
                                    ? const Color(
                                        0xFFFF7E01,
                                      )
                                    : Colors
                                        .red,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (p.categoria !=
                      null) ...[
                    const SizedBox(
                      height:
                          16,
                    ),

                    Row(
                      children: [
                        const Icon(
                          Icons
                              .category_outlined,

                          size:
                              20,

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
                            'Categoría: ${p.categoria}',
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(
                    height:
                        30,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}