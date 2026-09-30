import 'package:flutter/material.dart';

import '../../helpers/chat_helper.dart';
import '../../models/emprendimiento.dart';
import '../../models/producto.dart';
import '../../services/emprendimiento_service.dart';
import '../../services/producto_service.dart';
import '../producto_actions/detalle_producto_screen.dart';

class DetalleTiendaScreen extends StatefulWidget {
  final int emprendimientoId;

  const DetalleTiendaScreen({
    super.key,
    required this.emprendimientoId,
  });

  @override
  State<DetalleTiendaScreen> createState() =>
      _DetalleTiendaScreenState();
}

class _DetalleTiendaScreenState
    extends State<DetalleTiendaScreen> {
  Emprendimiento? emprendimiento;

  List<Producto> productos = [];

  bool cargando = true;

  @override
  void initState() {
    super.initState();

    cargar();
  }

  // ============================================================
  // CARGAR TIENDA Y PRODUCTOS
  // ============================================================

  Future<void> cargar() async {
    final tienda =
        await EmprendimientoService.obtenerPorId(
      widget.emprendimientoId,
    );

    final catalogo =
        await ProductoService.listarPorEmprendimiento(
      widget.emprendimientoId,
    );

    if (!mounted) {
      return;
    }

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

  // ============================================================
  // ABRIR CHAT
  // ============================================================

  Future<void> _enviarMensaje(
    Emprendimiento tienda,
  ) async {
    if (tienda.usuarioId == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'No se encontró el usuario propietario de esta tienda.',
            ),
          ),
        );

      return;
    }

    await ChatHelper.abrirChat(
      context: context,
      usuarioDestinoId:
          tienda.usuarioId!,
      nombreDestino:
          tienda.nombre,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    if (cargando) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Color(
              0xFFFF7E01,
            ),
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

    final Emprendimiento tienda =
        emprendimiento!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          tienda.nombre,
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(
          20,
        ),
        children: [
          // ====================================================
          // IMAGEN
          // ====================================================

          Center(
            child: CircleAvatar(
              radius: 55,

              backgroundColor:
                  const Color(
                0xFFFF7E01,
              ),

              backgroundImage:
                  tienda.imagenUrl !=
                              null &&
                          tienda.imagenUrl!
                              .isNotEmpty
                      ? NetworkImage(
                          tienda.imagenUrl!,
                        )
                      : null,

              child:
                  tienda.imagenUrl ==
                              null ||
                          tienda.imagenUrl!
                              .isEmpty
                      ? const Icon(
                          Icons.storefront,
                          size: 60,
                          color:
                              Colors.white,
                        )
                      : null,
            ),
          ),

          const SizedBox(
            height: 15,
          ),

          // ====================================================
          // NOMBRE
          // ====================================================

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

          // ====================================================
          // DESCRIPCIÓN
          // ====================================================

          if (tienda.descripcion !=
                  null &&
              tienda.descripcion!
                  .isNotEmpty) ...[
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
            height: 20,
          ),

          // ====================================================
          // ENVIAR MENSAJE
          // ====================================================

          SizedBox(
            width:
                double.infinity,
            height:
                50,
            child:
                FilledButton.icon(
              style:
                  FilledButton.styleFrom(
                backgroundColor:
                    const Color(
                  0xFFFF7E01,
                ),
                foregroundColor:
                    Colors.white,
              ),

              onPressed:
                  tienda.usuarioId ==
                          null
                      ? null
                      : () {
                          _enviarMensaje(
                            tienda,
                          );
                        },

              icon:
                  const Icon(
                Icons
                    .chat_bubble_outline,
              ),

              label:
                  const Text(
                'Enviar mensaje',
              ),
            ),
          ),

          const SizedBox(
            height: 30,
          ),

          // ====================================================
          // PRODUCTOS
          // ====================================================

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
            (
              producto,
            ) {
              return Card(
                child: ListTile(
                  // ============================================
                  // IMAGEN PRODUCTO
                  // ============================================

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

                  // ============================================
                  // NOMBRE
                  // ============================================

                  title:
                      Text(
                    producto.nombre,
                  ),

                  // ============================================
                  // PRECIO
                  // ============================================

                  subtitle:
                      Text(
                    '\$${producto.precio.toStringAsFixed(2)}',
                  ),

                  trailing:
                      const Icon(
                    Icons.chevron_right,
                  ),

                  // ============================================
                  // DETALLE PRODUCTO
                  // ============================================

                  onTap:
                      () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) =>
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