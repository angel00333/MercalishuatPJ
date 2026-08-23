// lib/screens/producto_actions/productos_screen.dart

import 'package:flutter/material.dart';

import '../../models/producto.dart';
import '../../services/producto_service.dart';
import 'crear_producto_screen.dart';
import 'detalle_producto_screen.dart';
import 'editar_producto_screen.dart';

class ProductosScreen extends StatefulWidget {
  const ProductosScreen({
    super.key,
  });

  @override
  State<ProductosScreen> createState() =>
      _ProductosScreenState();
}

class _ProductosScreenState
    extends State<ProductosScreen> {
  bool cargando = true;

  String? error;

  List<Producto> productos = [];

  @override
  void initState() {
    super.initState();

    cargarProductos();
  }

  Future<void> cargarProductos() async {
    setState(() {
      cargando = true;
      error = null;
    });

    final resultado =
        await ProductoService.listarMisProductos();

    if (!mounted) return;

    if (resultado['success'] == true) {
      setState(() {
        productos =
            resultado['productos'] as List<Producto>;

        cargando = false;
      });
    } else {
      setState(() {
        cargando = false;

        error =
            resultado['message'] ??
            'No se pudieron cargar los productos';
      });
    }
  }

  Future<void> crearProducto() async {
    final creado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const CrearProductoScreen(),
      ),
    );

    if (creado == true) {
      cargarProductos();
    }
  }

  Future<void> editarProducto(
    Producto producto,
  ) async {
    final editado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditarProductoScreen(
          producto: producto,
        ),
      ),
    );

    if (editado == true) {
      cargarProductos();
    }
  }

  Future<void> eliminarProducto(
    Producto producto,
  ) async {
    final confirmar =
        await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text(
            'Eliminar producto',
          ),
          content: Text(
            '¿Deseas eliminar "${producto.nombre}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                'Cancelar',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text(
                'Eliminar',
              ),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    final resultado =
        await ProductoService.eliminar(
      producto.id,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          resultado['message'] ??
              'Operación terminada',
        ),
      ),
    );

    if (resultado['success'] == true) {
      cargarProductos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mis productos',
        ),
      ),
      floatingActionButton:
          FloatingActionButton(
        backgroundColor:
            const Color(0xFFFF7E01),
        foregroundColor:
            Colors.white,
        onPressed: crearProducto,
        child: const Icon(
          Icons.add,
        ),
      ),
      body: _contenido(),
    );
  }

  Widget _contenido() {
    if (cargando) {
      return const Center(
        child:
            CircularProgressIndicator(
          color:
              Color(0xFFFF7E01),
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Text(
              error!,
              textAlign:
                  TextAlign.center,
            ),
            const SizedBox(
              height: 15,
            ),
            ElevatedButton(
              onPressed:
                  cargarProductos,
              child: const Text(
                'Reintentar',
              ),
            ),
          ],
        ),
      );
    }

    if (productos.isEmpty) {
      return Center(
        child: Padding(
          padding:
              const EdgeInsets.all(
            30,
          ),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                color:
                    Color(0xFFFF7E01),
                size: 90,
              ),
              const SizedBox(
                height: 20,
              ),
              const Text(
                'Todavía no tienes productos',
                textAlign:
                    TextAlign.center,
                style: TextStyle(
                  fontSize: 23,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              const Text(
                'Agrega el primer producto de tu emprendimiento.',
                textAlign:
                    TextAlign.center,
              ),
              const SizedBox(
                height: 25,
              ),
              ElevatedButton.icon(
                onPressed:
                    crearProducto,
                icon: const Icon(
                  Icons.add,
                ),
                label: const Text(
                  'Crear producto',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: cargarProductos,
      child: ListView.builder(
        padding:
            const EdgeInsets.all(
          16,
        ),
        itemCount:
            productos.length,
        itemBuilder:
            (context, index) {
          final producto =
              productos[index];

          return Card(
            margin:
                const EdgeInsets.only(
              bottom: 12,
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.all(
                12,
              ),
              leading:
                  _imagenProducto(
                producto,
              ),
              title: Text(
                producto.nombre,
                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              subtitle: Column(
                mainAxisSize:
                    MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  const SizedBox(
                    height: 5,
                  ),
                  Text(
                    '\$${producto.precio.toStringAsFixed(2)}',
                  ),
                  const SizedBox(
                    height: 3,
                  ),
                  Text(
                    producto.disponible
                        ? 'Disponible'
                        : 'No disponible',
                  ),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        DetalleProductoScreen(
                      productoId:
                          producto.id,
                    ),
                  ),
                );
              },
              trailing:
                  PopupMenuButton<String>(
                onSelected:
                    (valor) {
                  if (valor ==
                      'editar') {
                    editarProducto(
                      producto,
                    );
                  }

                  if (valor ==
                      'eliminar') {
                    eliminarProducto(
                      producto,
                    );
                  }
                },
                itemBuilder:
                    (_) => const [
                  PopupMenuItem<String>(
                    value:
                        'editar',
                    child: Text(
                      'Editar',
                    ),
                  ),
                  PopupMenuItem<String>(
                    value:
                        'eliminar',
                    child: Text(
                      'Eliminar',
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _imagenProducto(
    Producto producto,
  ) {
    if (producto.imagenPrincipal ==
            null ||
        producto.imagenPrincipal!
            .isEmpty) {
      return Container(
        width: 65,
        height: 65,
        decoration: BoxDecoration(
          color:
              const Color(
            0xFFFF7E01,
          ).withValues(
            alpha: 0.12,
          ),
          borderRadius:
              BorderRadius.circular(
            10,
          ),
        ),
        child: const Icon(
          Icons.image_outlined,
          color:
              Color(0xFFFF7E01),
        ),
      );
    }

    return ClipRRect(
      borderRadius:
          BorderRadius.circular(
        10,
      ),
      child: Image.network(
        producto.imagenPrincipal!,
        width: 65,
        height: 65,
        fit: BoxFit.cover,
        errorBuilder:
            (_, __, ___) {
          return Container(
            width: 65,
            height: 65,
            alignment:
                Alignment.center,
            child: const Icon(
              Icons.broken_image_outlined,
              color:
                  Color(0xFFFF7E01),
            ),
          );
        },
      ),
    );
  }
}