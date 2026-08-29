import 'package:flutter/material.dart';

import '../../models/publicacion.dart';
import '../../services/publicacion_service.dart';
import 'crear_publicacion_screen.dart';
import 'detalle_publicacion_screen.dart';
import 'editar_publicacion_screen.dart';

class MisPublicacionesScreen extends StatefulWidget {
  const MisPublicacionesScreen({
    super.key,
  });

  @override
  State<MisPublicacionesScreen> createState() =>
      _MisPublicacionesScreenState();
}

class _MisPublicacionesScreenState
    extends State<MisPublicacionesScreen> {
  List<Publicacion> publicaciones = [];

  bool cargando = true;
  String? error;

  @override
  void initState() {
    super.initState();
    cargarPublicaciones();
  }

  // ============================================
  // FORMATEAR FECHA
  // ============================================

  String formatearFecha(
    DateTime? fecha,
  ) {
    if (fecha == null) {
      return '';
    }

    final local = fecha.toLocal();

    final dia =
        local.day.toString().padLeft(
              2,
              '0',
            );

    final mes =
        local.month.toString().padLeft(
              2,
              '0',
            );

    final hora =
        local.hour.toString().padLeft(
              2,
              '0',
            );

    final minuto =
        local.minute.toString().padLeft(
              2,
              '0',
            );

    return '$dia/$mes/${local.year} · $hora:$minuto';
  }

  // ============================================
  // CARGAR PUBLICACIONES
  // ============================================

  Future<void> cargarPublicaciones() async {
    if (mounted) {
      setState(() {
        cargando = true;
        error = null;
      });
    }

    final resultado =
        await PublicacionService
            .misPublicaciones();

    if (!mounted) return;

    if (resultado['success'] == true) {
      setState(() {
        publicaciones =
            resultado['publicaciones'];

        cargando = false;
      });

      return;
    }

    setState(() {
      cargando = false;

      error =
          resultado['message'] ??
          'No se pudieron cargar las publicaciones';
    });
  }

  // ============================================
  // CREAR
  // ============================================

  Future<void> crearPublicacion() async {
    final creado =
        await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const CrearPublicacionScreen(),
      ),
    );

    if (creado == true) {
      await cargarPublicaciones();
    }
  }

  // ============================================
  // VER DETALLE
  // ============================================

  Future<void> abrirPublicacion(
    Publicacion publicacion,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            DetallePublicacionScreen(
          publicacionId:
              publicacion.id,
        ),
      ),
    );

    if (!mounted) return;

    await cargarPublicaciones();
  }

  // ============================================
  // EDITAR
  // ============================================

  Future<void> editarPublicacion(
    Publicacion publicacion,
  ) async {
    final actualizado =
        await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EditarPublicacionScreen(
          publicacion:
              publicacion,
        ),
      ),
    );

    if (!mounted) return;

    if (actualizado == true) {
      await cargarPublicaciones();
    }
  }

  // ============================================
  // ELIMINAR
  // ============================================

  Future<void> confirmarEliminar(
    Publicacion publicacion,
  ) async {
    final confirmar =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Eliminar publicación',
          ),
          content: const Text(
            '¿Estás seguro de que quieres eliminar esta publicación?',
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
            TextButton(
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

    if (confirmar != true) {
      return;
    }

    final resultado =
        await PublicacionService.eliminar(
      publicacion.id,
    );

    if (!mounted) return;

    if (resultado['success'] == true) {
      setState(() {
        publicaciones.removeWhere(
          (p) =>
              p.id ==
              publicacion.id,
        );
      });

      mostrarMensaje(
        resultado['message'] ??
            'Publicación eliminada',
      );

      return;
    }

    mostrarMensaje(
      resultado['message'] ??
          'No se pudo eliminar la publicación',
    );
  }

  // ============================================
  // MENÚ
  // ============================================

  Future<void> seleccionarOpcion(
    String opcion,
    Publicacion publicacion,
  ) async {
    switch (opcion) {
      case 'ver':
        await abrirPublicacion(
          publicacion,
        );
        break;

      case 'editar':
        await editarPublicacion(
          publicacion,
        );
        break;

      case 'eliminar':
        await confirmarEliminar(
          publicacion,
        );
        break;
    }
  }

  void mostrarMensaje(
    String mensaje,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          mensaje,
        ),
      ),
    );
  }

  // ============================================
  // BUILD
  // ============================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mis publicaciones',
        ),
      ),

      body: cargando
          ? const Center(
              child:
                  CircularProgressIndicator(
                color:
                    Color(0xFFFF7E01),
              ),
            )
          : error != null
              ? _mostrarError()
              : publicaciones.isEmpty
                  ? _sinPublicaciones()
                  : _listaPublicaciones(),

      floatingActionButton:
          FloatingActionButton(
        backgroundColor:
            const Color(0xFFFF7E01),

        onPressed:
            crearPublicacion,

        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }

  // ============================================
  // ERROR
  // ============================================

  Widget _mostrarError() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(
          24,
        ),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 60,
              color:
                  Color(0xFFFF7E01),
            ),

            const SizedBox(
              height: 15,
            ),

            Text(
              error!,
              textAlign:
                  TextAlign.center,
            ),

            const SizedBox(
              height: 20,
            ),

            ElevatedButton.icon(
              onPressed:
                  cargarPublicaciones,

              icon:
                  const Icon(
                Icons.refresh,
              ),

              label:
                  const Text(
                'Reintentar',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // SIN PUBLICACIONES
  // ============================================

  Widget _sinPublicaciones() {
    return RefreshIndicator(
      onRefresh:
          cargarPublicaciones,

      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),

        children: const [
          SizedBox(
            height: 180,
          ),

          Icon(
            Icons.post_add_outlined,
            size: 90,
            color:
                Color(0xFFFF7E01),
          ),

          SizedBox(
            height: 20,
          ),

          Center(
            child: Text(
              'Todavía no tienes publicaciones',
              style:
                  TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),

          SizedBox(
            height: 10,
          ),

          Center(
            child: Padding(
              padding:
                  EdgeInsets.symmetric(
                horizontal: 30,
              ),

              child: Text(
                'Pulsa el botón + para crear tu primera publicación.',
                textAlign:
                    TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // LISTA
  // ============================================

  Widget _listaPublicaciones() {
    return RefreshIndicator(
      onRefresh:
          cargarPublicaciones,

      child: ListView.builder(
        physics:
            const AlwaysScrollableScrollPhysics(),

        padding:
            const EdgeInsets.all(
          12,
        ),

        itemCount:
            publicaciones.length,

        itemBuilder:
            (
          context,
          index,
        ) {
          return _tarjeta(
            publicaciones[index],
          );
        },
      ),
    );
  }

  // ============================================
  // TARJETA
  // ============================================

  Widget _tarjeta(
    Publicacion publicacion,
  ) {
    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 14,
      ),

      clipBehavior:
          Clip.antiAlias,

      child: InkWell(
        onTap: () {
          abrirPublicacion(
            publicacion,
          );
        },

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment
                  .stretch,

          children: [
            // =================================
            // FECHA + MENÚ
            // =================================

            ListTile(
              leading:
                  const CircleAvatar(
                backgroundColor:
                    Color(
                  0xFFFF7E01,
                ),
                child:
                    Icon(
                  Icons.article,
                  color:
                      Colors.white,
                ),
              ),

              title:
                  const Text(
                'Publicación',

                style:
                    TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              subtitle:
                  Text(
                formatearFecha(
                  publicacion
                      .fechaCreacion,
                ),
              ),

              trailing:
                  PopupMenuButton<
                      String>(
                tooltip:
                    'Opciones',

                onSelected:
                    (opcion) {
                  seleccionarOpcion(
                    opcion,
                    publicacion,
                  );
                },

                itemBuilder:
                    (_) =>
                        const [
                  PopupMenuItem(
                    value:
                        'ver',
                    child:
                        Row(
                      children: [
                        Icon(
                          Icons
                              .visibility_outlined,
                        ),
                        SizedBox(
                          width:
                              10,
                        ),
                        Text(
                          'Ver publicación',
                        ),
                      ],
                    ),
                  ),

                  PopupMenuItem(
                    value:
                        'editar',
                    child:
                        Row(
                      children: [
                        Icon(
                          Icons
                              .edit_outlined,
                        ),
                        SizedBox(
                          width:
                              10,
                        ),
                        Text(
                          'Editar',
                        ),
                      ],
                    ),
                  ),

                  PopupMenuItem(
                    value:
                        'eliminar',
                    child:
                        Row(
                      children: [
                        Icon(
                          Icons
                              .delete_outline,
                        ),
                        SizedBox(
                          width:
                              10,
                        ),
                        Text(
                          'Eliminar',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // =================================
            // TEXTO
            // =================================

            Padding(
              padding:
                  const EdgeInsets
                      .fromLTRB(
                16,
                5,
                16,
                15,
              ),

              child: Text(
                publicacion.texto,

                maxLines: 5,

                overflow:
                    TextOverflow
                        .ellipsis,

                style:
                    const TextStyle(
                  fontSize: 16,
                ),
              ),
            ),

            // =================================
            // IMAGEN
            // =================================

            if (publicacion
                        .imagenPrincipal !=
                    null &&
                publicacion
                    .imagenPrincipal!
                    .isNotEmpty)
              Image.network(
                publicacion
                    .imagenPrincipal!,

                height: 240,

                width:
                    double.infinity,

                fit:
                    BoxFit.cover,

                errorBuilder:
                    (
                  context,
                  error,
                  stackTrace,
                ) {
                  return Container(
                    height: 200,
                    alignment:
                        Alignment.center,

                    child:
                        const Icon(
                      Icons
                          .broken_image_outlined,
                      size: 55,
                      color:
                          Color(
                        0xFFFF7E01,
                      ),
                    ),
                  );
                },
              ),

            // =================================
            // PRODUCTO
            // =================================

            if (publicacion
                    .productoNombre !=
                null)
              Container(
                margin:
                    const EdgeInsets
                        .fromLTRB(
                  12,
                  12,
                  12,
                  0,
                ),

                decoration:
                    BoxDecoration(
                  border:
                      Border.all(
                    color:
                        Theme.of(
                      context,
                    )
                            .dividerColor,
                  ),

                  borderRadius:
                      BorderRadius
                          .circular(
                    12,
                  ),
                ),

                child: ListTile(
                  leading:
                      const Icon(
                    Icons
                        .shopping_bag_outlined,
                    color:
                        Color(
                      0xFFFF7E01,
                    ),
                  ),

                  title:
                      Text(
                    publicacion
                        .productoNombre!,
                  ),

                  subtitle:
                      publicacion
                                  .productoPrecio !=
                              null
                          ? Text(
                              '\$${publicacion.productoPrecio!.toStringAsFixed(2)}',
                            )
                          : null,

                  trailing:
                      const Icon(
                    Icons
                        .chevron_right,
                  ),
                ),
              ),

            const SizedBox(
              height: 5,
            ),

            const Divider(
              height: 1,
            ),

            // =================================
            // ESTADÍSTICAS
            // =================================

            Padding(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 5,
              ),

              child: Row(
                children: [
                  const Icon(
                    Icons.favorite_border,
                    size: 21,
                  ),

                  const SizedBox(
                    width: 5,
                  ),

                  Text(
                    '${publicacion.totalMeGusta}',
                  ),

                  const SizedBox(
                    width: 20,
                  ),

                  const Icon(
                    Icons
                        .chat_bubble_outline,
                    size: 20,
                  ),

                  const SizedBox(
                    width: 5,
                  ),

                  Text(
                    '${publicacion.totalComentarios}',
                  ),

                  const Spacer(),

                  TextButton.icon(
                    onPressed: () {
                      editarPublicacion(
                        publicacion,
                      );
                    },

                    icon:
                        const Icon(
                      Icons.edit_outlined,
                    ),

                    label:
                        const Text(
                      'Editar',
                    ),
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