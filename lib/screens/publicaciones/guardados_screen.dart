import 'package:flutter/material.dart';

import '../../models/publicacion.dart';
import '../../services/publicacion_service.dart';
import 'detalle_publicacion_screen.dart';

class GuardadosScreen extends StatefulWidget {
  const GuardadosScreen({
    super.key,
  });

  @override
  State<GuardadosScreen> createState() =>
      _GuardadosScreenState();
}

class _GuardadosScreenState
    extends State<GuardadosScreen> {
  List<Publicacion> publicaciones = [];

  bool cargando = true;
  String? error;

  @override
  void initState() {
    super.initState();

    cargarGuardados();
  }

  // ============================================
  // FECHA
  // ============================================

  String formatearFecha(
    DateTime? fecha,
  ) {
    if (fecha == null) {
      return '';
    }

    final local = fecha.toLocal();

    final dia =
        local.day
            .toString()
            .padLeft(
              2,
              '0',
            );

    final mes =
        local.month
            .toString()
            .padLeft(
              2,
              '0',
            );

    final hora =
        local.hour
            .toString()
            .padLeft(
              2,
              '0',
            );

    final minuto =
        local.minute
            .toString()
            .padLeft(
              2,
              '0',
            );

    return '$dia/$mes/${local.year} · $hora:$minuto';
  }

  // ============================================
  // CARGAR GUARDADOS
  // ============================================

  Future<void> cargarGuardados() async {
    if (mounted) {
      setState(() {
        cargando = true;
        error = null;
      });
    }

    final resultado =
        await PublicacionService
            .listarGuardados();

    if (!mounted) {
      return;
    }

    if (resultado['success'] == true) {
      setState(() {
        publicaciones =
            resultado[
                'publicaciones'];

        cargando = false;
      });

      return;
    }

    setState(() {
      cargando = false;

      error =
          resultado['message'] ??
          'No se pudieron cargar los guardados';
    });
  }

  // ============================================
  // ABRIR PUBLICACIÓN
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

    if (!mounted) {
      return;
    }

    await cargarGuardados();
  }

  // ============================================
  // QUITAR GUARDADO
  // ============================================

  Future<void> quitarGuardado(
    Publicacion publicacion,
  ) async {
    final resultado =
        await PublicacionService
            .quitarGuardado(
      publicacion.id,
    );

    if (!mounted) {
      return;
    }

    if (resultado['success'] == true) {
      setState(() {
        publicaciones.removeWhere(
          (p) =>
              p.id ==
              publicacion.id,
        );
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Eliminado de guardados',
          ),
        ),
      );

      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          resultado['message'] ??
              'No se pudo quitar de guardados',
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
          'Guardados',
        ),
      ),

      body: cargando
          ? const Center(
              child:
                  CircularProgressIndicator(
                color:
                    Color(
                  0xFFFF7E01,
                ),
              ),
            )
          : error != null
              ? _mostrarError()
              : publicaciones.isEmpty
                  ? _sinGuardados()
                  : _listaGuardados(),
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
                  Color(
                0xFFFF7E01,
              ),
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
                  cargarGuardados,

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
  // VACÍO
  // ============================================

  Widget _sinGuardados() {
    return RefreshIndicator(
      onRefresh:
          cargarGuardados,

      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),

        children: const [
          SizedBox(
            height: 180,
          ),

          Icon(
            Icons.bookmark_border,
            size: 90,
            color:
                Color(
              0xFFFF7E01,
            ),
          ),

          SizedBox(
            height: 20,
          ),

          Center(
            child: Text(
              'No tienes publicaciones guardadas',
              textAlign:
                  TextAlign.center,
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
                'Las publicaciones que guardes aparecerán aquí.',
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

  Widget _listaGuardados() {
    return RefreshIndicator(
      onRefresh:
          cargarGuardados,

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
              CrossAxisAlignment.stretch,

          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    const Color(
                  0xFFFF7E01,
                ),

                backgroundImage:
                    publicacion
                                    .emprendimientoImagen !=
                                null &&
                            publicacion
                                .emprendimientoImagen!
                                .isNotEmpty
                        ? NetworkImage(
                            publicacion
                                .emprendimientoImagen!,
                          )
                        : null,

                child:
                    publicacion
                                    .emprendimientoImagen ==
                                null ||
                            publicacion
                                .emprendimientoImagen!
                                .isEmpty
                        ? const Icon(
                            Icons.store,
                            color:
                                Colors.white,
                          )
                        : null,
              ),

              title: Text(
                publicacion
                        .emprendimientoNombre ??
                    'Emprendimiento',

                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              subtitle: Text(
                formatearFecha(
                  publicacion
                      .fechaCreacion,
                ),
              ),

              trailing: IconButton(
                tooltip:
                    'Quitar de guardados',

                onPressed: () {
                  quitarGuardado(
                    publicacion,
                  );
                },

                icon:
                    const Icon(
                  Icons.bookmark,
                  color:
                      Color(
                    0xFFFF7E01,
                  ),
                ),
              ),
            ),

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
                    TextOverflow.ellipsis,

                style:
                    const TextStyle(
                  fontSize: 16,
                ),
              ),
            ),

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
                  borderRadius:
                      BorderRadius
                          .circular(
                    12,
                  ),

                  border:
                      Border.all(
                    color:
                        Theme.of(
                      context,
                    )
                            .dividerColor,
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

                  title: Text(
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

            const Divider(),

            Padding(
              padding:
                  const EdgeInsets
                      .fromLTRB(
                12,
                0,
                12,
                8,
              ),

              child: Row(
                children: [
                  const Icon(
                    Icons.favorite_border,
                    size: 20,
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

                  const Icon(
                    Icons.chevron_right,
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