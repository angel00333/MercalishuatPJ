import 'package:flutter/material.dart';

import '../../models/emprendimiento.dart';
import '../../models/producto.dart';
import '../../services/emprendimiento_service.dart';
import '../../services/producto_service.dart';
import '../producto_actions/detalle_producto_screen.dart';

class DetalleTiendaScreen
    extends StatefulWidget {
  final int emprendimientoId;

  const DetalleTiendaScreen({
    super.key,
    required this.emprendimientoId,
  });

  @override
  State<DetalleTiendaScreen>
      createState() =>
          _DetalleTiendaScreenState();
}

class _DetalleTiendaScreenState
    extends State<DetalleTiendaScreen> {
  Emprendimiento?
      emprendimiento;

  List<Producto> productos =
      [];

  bool cargando = true;

  @override
  void initState() {
    super.initState();

    cargar();
  }

  Future<void> cargar() async {
    final tienda =
        await EmprendimientoService
            .obtenerPorId(
      widget.emprendimientoId,
    );

    final catalogo =
        await ProductoService
            .listarPorEmprendimiento(
      widget.emprendimientoId,
    );

    if (!mounted) return;

    setState(() {
      if (tienda['success'] == true) {
        emprendimiento =
            tienda['emprendimiento'];
      }

      if (catalogo['success'] == true) {
        productos =
            catalogo['productos'];
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

    if (emprendimiento == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text(
            'Tienda no encontrada',
          ),
        ),
      );
    }

    final tienda =
        emprendimiento!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          tienda.nombre,
        ),
      ),

      body: ListView(
        padding:
            const EdgeInsets.all(
          20,
        ),
        children: [
          const Center(
            child:
                CircleAvatar(
              radius: 55,
              backgroundColor:
                  Color(
                0xFFFF7E01,
              ),
              child: Icon(
                Icons.storefront,
                size: 60,
                color:
                    Colors.white,
              ),
            ),
          ),

          const SizedBox(
            height: 15,
          ),

          Text(
            tienda.nombre,
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              fontSize: 26,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          if (tienda.descripcion !=
              null) ...[
            const SizedBox(
              height: 10,
            ),
            Text(
              tienda.descripcion!,
              textAlign:
                  TextAlign.center,
            ),
          ],

          const SizedBox(
            height: 30,
          ),

          const Text(
            'Productos',
            style:
                TextStyle(
              fontSize: 22,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 15,
          ),

          if (productos.isEmpty)
            const Padding(
              padding:
                  EdgeInsets.all(
                25,
              ),
              child: Center(
                child: Text(
                  'Esta tienda todavía no tiene productos.',
                ),
              ),
            ),

          ...productos.map(
            (producto) {
              return Card(
                child: ListTile(
                  leading:
                      producto.imagenPrincipal !=
                                  null &&
                              producto
                                  .imagenPrincipal!
                                  .isNotEmpty
                          ? ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(
                                8,
                              ),
                              child:
                                  Image.network(
                                producto
                                    .imagenPrincipal!,
                                width:
                                    60,
                                height:
                                    60,
                                fit:
                                    BoxFit.cover,
                              ),
                            )
                          : const SizedBox(
                              width:
                                  60,
                              child:
                                  Icon(
                                Icons
                                    .image_outlined,
                                color:
                                    Color(
                                  0xFFFF7E01,
                                ),
                              ),
                            ),

                  title: Text(
                    producto.nombre,
                  ),

                  subtitle: Text(
                    '\$${producto.precio.toStringAsFixed(2)}',
                  ),

                  trailing:
                      const Icon(
                    Icons.chevron_right,
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
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}