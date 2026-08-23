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

  List<ImagenProducto> imagenes =
      [];

  bool cargando = true;

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
      if (resultadoProducto[
              'success'] ==
          true) {
        producto =
            resultadoProducto[
                'producto'];
      }

      if (resultadoImagenes[
              'success'] ==
          true) {
        imagenes =
            resultadoImagenes[
                'imagenes'];
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

      body: ListView(
        children: [
          if (imagenes.isNotEmpty)
            SizedBox(
              height: 300,
              child: PageView.builder(
                itemCount:
                    imagenes.length,
                itemBuilder:
                    (_, index) {
                  return Image.network(
                    imagenes[index]
                        .url,
                    fit: BoxFit.cover,
                  );
                },
              ),
            )
          else
            Container(
              height: 250,
              alignment:
                  Alignment.center,
              child: const Icon(
                Icons.image_outlined,
                size: 100,
                color:
                    Color(0xFFFF7E01),
              ),
            ),

          Padding(
            padding:
                const EdgeInsets.all(
              20,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  p.nombre,
                  style:
                      const TextStyle(
                    fontSize: 27,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                Text(
                  '\$${p.precio.toStringAsFixed(2)}',
                  style:
                      const TextStyle(
                    fontSize: 24,
                    color:
                        Color(0xFFFF7E01),
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),

                Text(
                  p.descripcion
                              ?.isNotEmpty ==
                          true
                      ? p.descripcion!
                      : 'Sin descripción',
                ),

                const SizedBox(
                  height: 20,
                ),

                Chip(
                  label: Text(
                    p.disponible
                        ? 'Disponible'
                        : 'No disponible',
                  ),
                ),

                if (p.categoria !=
                    null) ...[
                  const SizedBox(
                    height: 10,
                  ),
                  Text(
                    'Categoría: ${p.categoria}',
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}