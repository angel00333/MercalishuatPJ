import 'package:flutter/material.dart';

import '../../models/publicacion.dart';
import '../../services/publicacion_service.dart';
import 'detalle_publicacion_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({
    super.key,
  });

  @override
  State<FeedScreen> createState() =>
      _FeedScreenState();
}

class _FeedScreenState
    extends State<FeedScreen> {
  final ScrollController scrollController =
      ScrollController();

  List<Publicacion> publicaciones = [];

  int pagina = 1;

  bool cargando = true;
  bool cargandoMas = false;
  bool hayMas = true;

  String? error;

  @override
  void initState() {
    super.initState();

    cargarFeed();

    scrollController.addListener(
      detectarFinal,
    );
  }

  // ============================================
  // FECHA Y HORA
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
  // DETECTAR FINAL DEL SCROLL
  // ============================================

  void detectarFinal() {
    if (!scrollController.hasClients) {
      return;
    }

    if (scrollController.position.pixels >=
        scrollController
                .position.maxScrollExtent -
            300) {
      cargarMas();
    }
  }

  // ============================================
  // CARGAR FEED
  // ============================================

  Future<void> cargarFeed() async {
    if (mounted) {
      setState(() {
        cargando = true;
        error = null;
      });
    }

    pagina = 1;

    final resultado =
        await PublicacionService.feed(
      pagina: pagina,
    );

    if (!mounted) return;

    if (resultado['success'] == true) {
      final paginacion =
          resultado['paginacion'];

      setState(() {
        publicaciones =
            resultado['publicaciones'];

        hayMas =
            paginacion != null &&
                paginacion['hay_mas'] ==
                    true;

        cargando = false;
      });

      return;
    }

    setState(() {
      cargando = false;

      error =
          resultado['message'] ??
          'No se pudo cargar el feed';
    });
  }

  // ============================================
  // CARGAR MÁS
  // ============================================

  Future<void> cargarMas() async {
    if (cargandoMas ||
        !hayMas ||
        cargando) {
      return;
    }

    setState(() {
      cargandoMas = true;
    });

    final siguiente =
        pagina + 1;

    final resultado =
        await PublicacionService.feed(
      pagina: siguiente,
    );

    if (!mounted) return;

    if (resultado['success'] == true) {
      final List<Publicacion> nuevas =
          List<Publicacion>.from(
        resultado['publicaciones'],
      );

      final idsExistentes =
          publicaciones
              .map(
                (e) => e.id,
              )
              .toSet();

      nuevas.removeWhere(
        (publicacion) =>
            idsExistentes.contains(
          publicacion.id,
        ),
      );

      final paginacion =
          resultado['paginacion'];

      setState(() {
        pagina = siguiente;

        publicaciones.addAll(
          nuevas,
        );

        hayMas =
            paginacion != null &&
                paginacion['hay_mas'] ==
                    true;
      });
    }

    if (!mounted) return;

    setState(() {
      cargandoMas = false;
    });
  }

  // ============================================
  // ABRIR DETALLE
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

    await cargarFeed();
  }

  // ============================================
  // LIKE
  // ============================================

  Future<void> toggleLike(
    Publicacion publicacion,
  ) async {
    final anterior =
        publicacion.meGusta;

    setState(() {
      publicacion.meGusta =
          !anterior;

      publicacion.totalMeGusta +=
          anterior ? -1 : 1;
    });

    final resultado =
        anterior
            ? await PublicacionService
                .quitarMeGusta(
                publicacion.id,
              )
            : await PublicacionService
                .darMeGusta(
                publicacion.id,
              );

    if (!mounted) return;

    if (resultado['success'] != true) {
      setState(() {
        publicacion.meGusta =
            anterior;

        publicacion.totalMeGusta +=
            anterior ? 1 : -1;
      });

      mostrarMensaje(
        resultado['message'] ??
            'No se pudo actualizar Me gusta',
      );
    }
  }

  // ============================================
  // GUARDAR / FAVORITOS
  // ============================================

  Future<void> toggleGuardado(
    Publicacion publicacion,
  ) async {
    final anterior =
        publicacion.guardado;

    setState(() {
      publicacion.guardado =
          !anterior;
    });

    final resultado =
        anterior
            ? await PublicacionService
                .quitarGuardado(
                publicacion.id,
              )
            : await PublicacionService
                .guardar(
                publicacion.id,
              );

    if (!mounted) return;

    if (resultado['success'] != true) {
      setState(() {
        publicacion.guardado =
            anterior;
      });

      mostrarMensaje(
        resultado['message'] ??
            'No se pudo actualizar favoritos',
      );
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

  @override
  void dispose() {
    scrollController.dispose();

    super.dispose();
  }

  // ============================================
  // UI
  // ============================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Recientes',
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
              ? _feedVacio()

          : RefreshIndicator(
              onRefresh: cargarFeed,

              child: ListView.builder(
                controller:
                    scrollController,

                physics:
                    const AlwaysScrollableScrollPhysics(),

                itemCount:
                    publicaciones.length +
                    (cargandoMas
                        ? 1
                        : 0),

                itemBuilder:
                    (
                  context,
                  index,
                ) {
                  if (index ==
                      publicaciones.length) {
                    return const Padding(
                      padding:
                          EdgeInsets.all(
                        20,
                      ),

                      child: Center(
                        child:
                            CircularProgressIndicator(
                          color:
                              Color(
                            0xFFFF7E01,
                          ),
                        ),
                      ),
                    );
                  }

                  return _tarjeta(
                    publicaciones[index],
                  );
                },
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
                  cargarFeed,

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
  // FEED VACÍO
  // ============================================

  Widget _feedVacio() {
    return RefreshIndicator(
      onRefresh:
          cargarFeed,

      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),

        children: const [
          SizedBox(
            height: 180,
          ),

          Icon(
            Icons.article_outlined,
            size: 80,
            color:
                Color(0xFFFF7E01),
          ),

          SizedBox(
            height: 20,
          ),

          Center(
            child: Text(
              'No hay publicaciones todavía',
              style:
                  TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),

          SizedBox(
            height: 8,
          ),

          Center(
            child: Text(
              'Las publicaciones de los emprendimientos aparecerán aquí.',
              textAlign:
                  TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // TARJETA PUBLICACIÓN
  // ============================================

  Widget _tarjeta(
    Publicacion p,
  ) {
    return Card(
      margin:
          const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),

      clipBehavior:
          Clip.antiAlias,

      child: InkWell(
        onTap: () {
          abrirPublicacion(
            p,
          );
        },

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment
                  .stretch,

          children: [
            // =================================
            // EMPRENDIMIENTO + FECHA
            // =================================

            ListTile(
              leading:
                  CircleAvatar(
                backgroundColor:
                    const Color(
                  0xFFFF7E01,
                ),

                backgroundImage:
                    p.emprendimientoImagen !=
                                null &&
                            p.emprendimientoImagen!
                                .isNotEmpty
                        ? NetworkImage(
                            p.emprendimientoImagen!,
                          )
                        : null,

                child:
                    p.emprendimientoImagen ==
                                null ||
                            p.emprendimientoImagen!
                                .isEmpty
                        ? const Icon(
                            Icons.store,
                            color:
                                Colors.white,
                          )
                        : null,
              ),

              title:
                  Text(
                p.emprendimientoNombre ??
                    'Emprendimiento',

                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              subtitle:
                  Text(
                formatearFecha(
                  p.fechaCreacion,
                ),
              ),

              trailing:
                  const Icon(
                Icons
                    .chevron_right,
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
                p.texto,

                style:
                    const TextStyle(
                  fontSize: 16,
                ),

                maxLines: 5,

                overflow:
                    TextOverflow
                        .ellipsis,
              ),
            ),

            // =================================
            // IMAGEN PRINCIPAL
            // =================================

            if (p.imagenPrincipal != null &&
                p.imagenPrincipal!
                    .isNotEmpty)
              Image.network(
                p.imagenPrincipal!,
                height: 280,
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
                    height: 220,
                    alignment:
                        Alignment.center,

                    child:
                        const Icon(
                      Icons
                          .broken_image_outlined,
                      size: 60,
                      color:
                          Color(
                        0xFFFF7E01,
                      ),
                    ),
                  );
                },
              ),

            // =================================
            // PRODUCTO ASOCIADO
            // =================================

            if (p.productoId != null)
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

                  title:
                      Text(
                    p.productoNombre ??
                        'Producto',
                  ),

                  subtitle:
                      p.productoPrecio !=
                              null
                          ? Text(
                              '\$${p.productoPrecio!.toStringAsFixed(2)}',
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
            // INTERACCIONES
            // =================================

            Row(
              children: [
                // LIKE

                IconButton(
                  tooltip:
                      p.meGusta
                          ? 'Quitar Me gusta'
                          : 'Me gusta',

                  onPressed: () {
                    toggleLike(
                      p,
                    );
                  },

                  icon:
                      Icon(
                    p.meGusta
                        ? Icons.favorite
                        : Icons
                            .favorite_border,

                    color:
                        p.meGusta
                            ? Colors.red
                            : null,
                  ),
                ),

                Text(
                  '${p.totalMeGusta}',
                ),

                const SizedBox(
                  width: 5,
                ),

                // COMENTARIOS

                IconButton(
                  tooltip:
                      'Comentarios',

                  onPressed: () {
                    abrirPublicacion(
                      p,
                    );
                  },

                  icon:
                      const Icon(
                    Icons
                        .chat_bubble_outline,
                  ),
                ),

                Text(
                  '${p.totalComentarios}',
                ),

                const Spacer(),

                // FAVORITO / GUARDAR

                IconButton(
                  tooltip:
                      p.guardado
                          ? 'Quitar de favoritos'
                          : 'Guardar en favoritos',

                  onPressed: () {
                    toggleGuardado(
                      p,
                    );
                  },

                  icon:
                      Icon(
                    p.guardado
                        ? Icons.bookmark
                        : Icons
                            .bookmark_border,

                    color:
                        p.guardado
                            ? const Color(
                                0xFFFF7E01,
                              )
                            : null,
                  ),
                ),

                const SizedBox(
                  width: 5,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}