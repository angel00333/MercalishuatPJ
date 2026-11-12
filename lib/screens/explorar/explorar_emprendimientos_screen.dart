import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../config/app_theme.dart';

import '../../models/emprendimiento.dart';
import '../../models/publicacion.dart';

import '../../services/emprendimiento_service.dart';
import '../../services/publicacion_service.dart';

import '../publicaciones/detalle_publicacion_screen.dart';

import 'detalle_tienda_screen.dart';

enum _SeccionExplorar {
  publicaciones,
  tiendas,
}

class ExplorarEmprendimientosScreen extends StatefulWidget {
  const ExplorarEmprendimientosScreen({
    super.key,
  });

  @override
  State<ExplorarEmprendimientosScreen> createState() =>
      _ExplorarEmprendimientosScreenState();
}

class _ExplorarEmprendimientosScreenState
    extends State<ExplorarEmprendimientosScreen> {
  // ============================================================
  // SECCIÓN ACTUAL
  // ============================================================

  _SeccionExplorar _seccion =
      _SeccionExplorar.publicaciones;

  // ============================================================
  // EMPRENDIMIENTOS
  // ============================================================

  List<Emprendimiento> _emprendimientos = [];

  List<Emprendimiento> _emprendimientosFiltrados = [];

  // ============================================================
  // PUBLICACIONES
  // ============================================================

  List<Publicacion> _publicaciones = [];

  List<Publicacion> _publicacionesFiltradas = [];

  // ============================================================
  // ESTADO
  // ============================================================

  bool _cargando = true;

  String? _error;

  final Set<int> _procesandoLikes = {};

  // ============================================================
  // BUSCADOR
  // ============================================================

  final TextEditingController _buscarController =
      TextEditingController();

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _cargarTodo();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _buscarController.dispose();

    super.dispose();
  }

  // ============================================================
  // CARGAR TODO
  // ============================================================

  Future<void> _cargarTodo() async {
    if (mounted) {
      setState(() {
        _cargando = true;
        _error = null;
      });
    }

    try {
      final resultados = await Future.wait([
        EmprendimientoService.listar(),
        PublicacionService.feed(
          pagina: 1,
          limite: 30,
        ),
      ]);

      if (!mounted) {
        return;
      }

      final resultadoEmprendimientos =
          resultados[0];

      final resultadoPublicaciones =
          resultados[1];

      final List<Emprendimiento> emprendimientosCargados = [];

      final List<Publicacion> publicacionesCargadas = [];

      // ========================================================
      // EMPRENDIMIENTOS
      // ========================================================

      if (resultadoEmprendimientos['success'] == true) {
        final raw =
            resultadoEmprendimientos['emprendimientos'];

        if (raw is List) {
          emprendimientosCargados.addAll(
            raw.whereType<Emprendimiento>(),
          );
        }
      }

      // ========================================================
      // PUBLICACIONES
      // ========================================================

      if (resultadoPublicaciones['success'] == true) {
        final raw =
            resultadoPublicaciones['publicaciones'];

        if (raw is List) {
          publicacionesCargadas.addAll(
            raw.whereType<Publicacion>(),
          );
        }
      }

      setState(() {
        _emprendimientos =
            emprendimientosCargados;

        _emprendimientosFiltrados =
            List<Emprendimiento>.from(
          emprendimientosCargados,
        );

        _publicaciones =
            publicacionesCargadas;

        _publicacionesFiltradas =
            List<Publicacion>.from(
          publicacionesCargadas,
        );

        _cargando = false;

        if (emprendimientosCargados.isEmpty &&
            publicacionesCargadas.isEmpty) {
          _error =
              'No se pudo cargar el contenido de Explorar.';
        }
      });

      _filtrar(
        _buscarController.text,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _cargando = false;
        _error =
            'No se pudo cargar el contenido.';
      });
    }
  }

  // ============================================================
  // CAMBIAR SECCIÓN
  // ============================================================

  void _cambiarSeccion(
    _SeccionExplorar nuevaSeccion,
  ) {
    if (_seccion == nuevaSeccion) {
      return;
    }

    setState(() {
      _seccion =
          nuevaSeccion;

      _buscarController.clear();

      _emprendimientosFiltrados =
          List<Emprendimiento>.from(
        _emprendimientos,
      );

      _publicacionesFiltradas =
          List<Publicacion>.from(
        _publicaciones,
      );
    });
  }

  // ============================================================
  // FILTRAR
  // ============================================================

  void _filtrar(
    String texto,
  ) {
    final consulta =
        texto.trim().toLowerCase();

    setState(() {
      if (consulta.isEmpty) {
        _emprendimientosFiltrados =
            List<Emprendimiento>.from(
          _emprendimientos,
        );

        _publicacionesFiltradas =
            List<Publicacion>.from(
          _publicaciones,
        );

        return;
      }

      // ========================================================
      // TIENDAS
      // ========================================================

      _emprendimientosFiltrados =
          _emprendimientos.where(
        (
          emprendimiento,
        ) {
          final nombre =
              emprendimiento.nombre
                  .toLowerCase();

          final descripcion =
              (emprendimiento.descripcion ?? '')
                  .toLowerCase();

          final propietario =
              (emprendimiento.propietario ?? '')
                  .toLowerCase();

          return nombre.contains(
                consulta,
              ) ||
              descripcion.contains(
                consulta,
              ) ||
              propietario.contains(
                consulta,
              );
        },
      ).toList();

      // ========================================================
      // PUBLICACIONES
      // ========================================================

      _publicacionesFiltradas =
          _publicaciones.where(
        (
          publicacion,
        ) {
          final textoPublicacion =
              publicacion.texto
                  .toLowerCase();

          final emprendimiento =
              (publicacion.emprendimientoNombre ?? '')
                  .toLowerCase();

          final producto =
              (publicacion.productoNombre ?? '')
                  .toLowerCase();

          return textoPublicacion.contains(
                consulta,
              ) ||
              emprendimiento.contains(
                consulta,
              ) ||
              producto.contains(
                consulta,
              );
        },
      ).toList();
    });
  }

  // ============================================================
  // ABRIR TIENDA
  // ============================================================

  Future<void> _abrirTienda(
    Emprendimiento tienda,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            DetalleTiendaScreen(
          emprendimientoId:
              tienda.id,
        ),
      ),
    );
  }

  // ============================================================
  // ABRIR PUBLICACIÓN
  // ============================================================

  Future<void> _abrirPublicacion(
    Publicacion publicacion,
  ) async {
    await Navigator.of(context).push(
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

    await _recargarPublicaciones();
  }

  // ============================================================
  // RECARGAR PUBLICACIONES
  // ============================================================

  Future<void> _recargarPublicaciones() async {
    final resultado =
        await PublicacionService.feed(
      pagina: 1,
      limite: 30,
    );

    if (!mounted) {
      return;
    }

    if (resultado['success'] != true) {
      return;
    }

    final raw =
        resultado['publicaciones'];

    if (raw is! List) {
      return;
    }

    setState(() {
      _publicaciones =
          raw.whereType<Publicacion>()
              .toList();
    });

    _filtrar(
      _buscarController.text,
    );
  }

  // ============================================================
  // ME GUSTA
  // ============================================================

  Future<void> _alternarMeGusta(
    Publicacion publicacion,
  ) async {
    if (_procesandoLikes.contains(
      publicacion.id,
    )) {
      return;
    }

    _procesandoLikes.add(
      publicacion.id,
    );

    final bool teniaMeGusta =
        publicacion.meGusta;

    final int cantidadAnterior =
        publicacion.totalMeGusta;

    // ==========================================================
    // ACTUALIZACIÓN OPTIMISTA
    // ==========================================================

    setState(() {
      publicacion.meGusta =
          !teniaMeGusta;

      publicacion.totalMeGusta =
          teniaMeGusta
              ? math.max(
                  0,
                  cantidadAnterior - 1,
                )
              : cantidadAnterior + 1;
    });

    final resultado =
        teniaMeGusta
            ? await PublicacionService
                .quitarMeGusta(
                publicacion.id,
              )
            : await PublicacionService
                .darMeGusta(
                publicacion.id,
              );

    if (!mounted) {
      _procesandoLikes.remove(
        publicacion.id,
      );

      return;
    }

    if (resultado['success'] != true) {
      setState(() {
        publicacion.meGusta =
            teniaMeGusta;

        publicacion.totalMeGusta =
            cantidadAnterior;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo actualizar Me gusta.',
            ),
          ),
        );
    }

    _procesandoLikes.remove(
      publicacion.id,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final bool oscuro =
        Theme.of(context).brightness ==
            Brightness.dark;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _cargarTodo,
          child: CustomScrollView(
            physics:
                const AlwaysScrollableScrollPhysics(),
            slivers: [
              // =================================================
              // ENCABEZADO
              // =================================================

              SliverToBoxAdapter(
                child: _encabezado(
                  oscuro,
                ),
              ),

              // =================================================
              // BUSCADOR
              // =================================================

              SliverToBoxAdapter(
                child: _buscador(),
              ),

              // =================================================
              // SELECTOR
              // =================================================

              SliverToBoxAdapter(
                child: _selectorSeccion(
                  oscuro,
                ),
              ),

              // =================================================
              // CONTENIDO
              // =================================================

              if (_cargando)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child:
                        CircularProgressIndicator(),
                  ),
                )
              else if (_error != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _estadoError(),
                )
              else if (_seccion ==
                  _SeccionExplorar.publicaciones)
                _listaPublicaciones(
                  oscuro,
                )
              else
                _listaTiendas(
                  oscuro,
                ),

              const SliverToBoxAdapter(
                child: SizedBox(
                  height: 30,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ENCABEZADO
  // ============================================================

  Widget _encabezado(
    bool oscuro,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        8,
      ),
      child: Row(
        children: [
          // ====================================================
          // ICONO
          // ====================================================

          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient:
                  const LinearGradient(
                begin:
                    Alignment.topLeft,
                end:
                    Alignment.bottomRight,
                colors: [
                  AppColors.naranja,
                  AppColors.naranjaClaro,
                ],
              ),
              borderRadius:
                  BorderRadius.circular(
                15,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      AppColors.naranja.withValues(
                    alpha: 0.25,
                  ),
                  blurRadius: 12,
                  offset: const Offset(
                    0,
                    5,
                  ),
                ),
              ],
            ),
            child: const Icon(
              Icons.explore_rounded,
              color: Colors.white,
              size: 27,
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Explorar',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(
                    fontSize: 25,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
                const SizedBox(
                  height: 2,
                ),
                Text(
                  'Descubre novedades y negocios locales',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // ====================================================
          // DECORACIÓN
          // ====================================================

          _GotaPequena(
            color: oscuro
                ? AppColors.naranja
                    .withValues(
                    alpha: 0.30,
                  )
                : AppColors.morado
                    .withValues(
                    alpha: 0.10,
                  ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUSCADOR
  // ============================================================

  Widget _buscador() {
    final hint =
        _seccion ==
                _SeccionExplorar.publicaciones
            ? 'Buscar publicaciones...'
            : 'Buscar emprendimientos...';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        10,
        20,
        16,
      ),
      child: TextField(
        controller:
            _buscarController,
        onChanged:
            _filtrar,
        textInputAction:
            TextInputAction.search,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon:
              const Icon(
            Icons.search_rounded,
          ),
          suffixIcon:
              _buscarController.text.isNotEmpty
                  ? IconButton(
                      tooltip:
                          'Limpiar',
                      onPressed: () {
                        _buscarController
                            .clear();

                        _filtrar('');
                      },
                      icon:
                          const Icon(
                        Icons.close_rounded,
                      ),
                    )
                  : const Icon(
                      Icons.tune_rounded,
                    ),
        ),
      ),
    );
  }

  // ============================================================
  // SELECTOR PUBLICACIONES / TIENDAS
  // ============================================================

  Widget _selectorSeccion(
    bool oscuro,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20,
      ),
      child: Container(
        padding: const EdgeInsets.all(
          5,
        ),
        decoration: BoxDecoration(
          color: oscuro
              ? AppColors.tarjetaOscura
              : Colors.white,
          borderRadius:
              BorderRadius.circular(
            20,
          ),
          border: Border.all(
            color: oscuro
                ? AppColors.bordeOscuro
                : AppColors.bordeClaro,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withValues(
                alpha: oscuro
                    ? 0.12
                    : 0.05,
              ),
              blurRadius: 12,
              offset: const Offset(
                0,
                4,
              ),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child:
                  _botonSeccion(
                seleccionado:
                    _seccion ==
                        _SeccionExplorar
                            .publicaciones,
                icono:
                    Icons
                        .article_outlined,
                iconoSeleccionado:
                    Icons.article_rounded,
                texto:
                    'Publicaciones',
                onTap: () {
                  _cambiarSeccion(
                    _SeccionExplorar
                        .publicaciones,
                  );
                },
              ),
            ),
            const SizedBox(
              width: 6,
            ),
            Expanded(
              child:
                  _botonSeccion(
                seleccionado:
                    _seccion ==
                        _SeccionExplorar
                            .tiendas,
                icono:
                    Icons
                        .storefront_outlined,
                iconoSeleccionado:
                    Icons
                        .storefront_rounded,
                texto:
                    'Tiendas',
                onTap: () {
                  _cambiarSeccion(
                    _SeccionExplorar
                        .tiendas,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BOTÓN SECCIÓN
  // ============================================================

  Widget _botonSeccion({
    required bool seleccionado,
    required IconData icono,
    required IconData iconoSeleccionado,
    required String texto,
    required VoidCallback onTap,
  }) {
    return Material(
      color:
          Colors.transparent,
      child: InkWell(
        borderRadius:
            BorderRadius.circular(
          16,
        ),
        onTap:
            onTap,
        child: AnimatedContainer(
          duration:
              const Duration(
            milliseconds: 220,
          ),
          curve:
              Curves.easeOut,
          padding:
              const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: seleccionado
                ? AppColors.naranja
                : Colors.transparent,
            borderRadius:
                BorderRadius.circular(
              16,
            ),
            boxShadow: seleccionado
                ? [
                    BoxShadow(
                      color:
                          AppColors.naranja.withValues(
                        alpha: 0.24,
                      ),
                      blurRadius: 10,
                      offset: const Offset(
                        0,
                        4,
                      ),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Icon(
                seleccionado
                    ? iconoSeleccionado
                    : icono,
                color: seleccionado
                    ? Colors.white
                    : AppColors.naranja,
                size: 21,
              ),
              const SizedBox(
                width: 7,
              ),
              Flexible(
                child: Text(
                  texto,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: TextStyle(
                    color: seleccionado
                        ? Colors.white
                        : null,
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LISTA PUBLICACIONES
  // ============================================================

  Widget _listaPublicaciones(
    bool oscuro,
  ) {
    if (_publicacionesFiltradas.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _estadoVacio(
          icono:
              Icons.article_outlined,
          titulo:
              'No encontramos publicaciones',
          descripcion:
              'Prueba con otra búsqueda o vuelve a intentarlo más tarde.',
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
      ),
      sliver: SliverList(
        delegate:
            SliverChildBuilderDelegate(
          (
            context,
            index,
          ) {
            final publicacion =
                _publicacionesFiltradas[
                    index];

            return Padding(
              padding:
                  const EdgeInsets.only(
                bottom: 16,
              ),
              child:
                  _tarjetaPublicacion(
                publicacion,
                oscuro,
              ),
            );
          },
          childCount:
              _publicacionesFiltradas
                  .length,
        ),
      ),
    );
  }

  // ============================================================
  // TARJETA PUBLICACIÓN
  // ============================================================

  Widget _tarjetaPublicacion(
    Publicacion publicacion,
    bool oscuro,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: oscuro
            ? AppColors.tarjetaOscura
            : Colors.white,
        borderRadius:
            BorderRadius.circular(
          24,
        ),
        border: Border.all(
          color: oscuro
              ? AppColors.bordeOscuro
              : AppColors.bordeClaro,
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(
              alpha: oscuro
                  ? 0.14
                  : 0.06,
            ),
            blurRadius: 16,
            offset: const Offset(
              0,
              6,
            ),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius:
            BorderRadius.circular(
          24,
        ),
        clipBehavior:
            Clip.antiAlias,
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // ==================================================
            // CABECERA PUBLICACIÓN
            // ==================================================

            InkWell(
              onTap: () {
                _abrirPublicacion(
                  publicacion,
                );
              },
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(
                  14,
                  13,
                  12,
                  10,
                ),
                child: Row(
                  children: [
                    _avatarEmprendimiento(
                      publicacion,
                    ),
                    const SizedBox(
                      width: 11,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Text(
                            publicacion
                                    .emprendimientoNombre ??
                                'Emprendimiento',
                            maxLines: 1,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                            style:
                                const TextStyle(
                              fontSize: 15,
                              fontWeight:
                                  FontWeight
                                      .w800,
                            ),
                          ),
                          const SizedBox(
                            height: 2,
                          ),
                          Text(
                            _formatearFecha(
                              publicacion
                                  .fechaCreacion,
                            ),
                            style: Theme.of(
                              context,
                            )
                                .textTheme
                                .bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip:
                          'Ver publicación',
                      onPressed: () {
                        _abrirPublicacion(
                          publicacion,
                        );
                      },
                      icon:
                          const Icon(
                        Icons
                            .more_horiz_rounded,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ==================================================
            // TEXTO
            // ==================================================

            if (publicacion.texto
                .trim()
                .isNotEmpty)
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  14,
                ),
                child: Text(
                  publicacion.texto,
                  style:
                      const TextStyle(
                    fontSize: 15,
                    height: 1.35,
                  ),
                ),
              ),

            // ==================================================
            // PRODUCTO VINCULADO
            // ==================================================

            if (publicacion.productoNombre !=
                null)
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  12,
                ),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        AppColors.naranja.withValues(
                      alpha: 0.09,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      13,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons
                            .shopping_bag_outlined,
                        color:
                            AppColors.naranja,
                        size: 18,
                      ),
                      const SizedBox(
                        width: 7,
                      ),
                      Expanded(
                        child: Text(
                          publicacion
                              .productoNombre!,
                          maxLines: 1,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight
                                    .w700,
                          ),
                        ),
                      ),
                      if (publicacion
                              .productoPrecio !=
                          null)
                        Text(
                          '\$${publicacion.productoPrecio!.toStringAsFixed(2)}',
                          style:
                              const TextStyle(
                            color:
                                AppColors
                                    .naranja,
                            fontWeight:
                                FontWeight
                                    .w900,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

            // ==================================================
            // IMAGEN
            // ==================================================

            if (publicacion.imagenPrincipal !=
                    null &&
                publicacion.imagenPrincipal!
                    .trim()
                    .isNotEmpty)
              InkWell(
                onTap: () {
                  _abrirPublicacion(
                    publicacion,
                  );
                },
                child: Image.network(
                  publicacion
                      .imagenPrincipal!,
                  width:
                      double.infinity,
                  height:
                      245,
                  fit:
                      BoxFit.cover,
                  errorBuilder: (
                    context,
                    error,
                    stackTrace,
                  ) {
                    return Container(
                      height: 150,
                      width:
                          double.infinity,
                      color:
                          AppColors.naranja.withValues(
                        alpha: 0.05,
                      ),
                      child:
                          const Icon(
                        Icons
                            .broken_image_outlined,
                        color:
                            AppColors.naranja,
                        size: 42,
                      ),
                    );
                  },
                ),
              ),

            // ==================================================
            // CONTADORES
            // ==================================================

            Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                15,
                10,
                15,
                5,
              ),
              child: Row(
                children: [
                  if (publicacion.totalMeGusta >
                      0) ...[
                    Container(
                      width: 20,
                      height: 20,
                      decoration:
                          const BoxDecoration(
                        color:
                            AppColors.naranja,
                        shape:
                            BoxShape.circle,
                      ),
                      child:
                          const Icon(
                        Icons
                            .favorite_rounded,
                        color:
                            Colors.white,
                        size: 12,
                      ),
                    ),
                    const SizedBox(
                      width: 5,
                    ),
                    Text(
                      '${publicacion.totalMeGusta}',
                      style: Theme.of(
                        context,
                      )
                          .textTheme
                          .bodySmall,
                    ),
                  ],
                  const Spacer(),
                  if (publicacion
                          .totalComentarios >
                      0)
                    Text(
                      '${publicacion.totalComentarios} comentarios',
                      style: Theme.of(
                        context,
                      )
                          .textTheme
                          .bodySmall,
                    ),
                ],
              ),
            ),

            Divider(
              height: 1,
              color:
                  Theme.of(context)
                      .dividerColor,
            ),

            // ==================================================
            // ACCIONES TIPO FACEBOOK
            // ==================================================

            Row(
              children: [
                Expanded(
                  child: _accionPublicacion(
                    icono:
                        publicacion.meGusta
                            ? Icons
                                .favorite_rounded
                            : Icons
                                .favorite_border_rounded,
                    texto:
                        'Me gusta',
                    color:
                        publicacion.meGusta
                            ? AppColors.error
                            : null,
                    onTap:
                        _procesandoLikes
                                .contains(
                          publicacion.id,
                        )
                            ? null
                            : () {
                                _alternarMeGusta(
                                  publicacion,
                                );
                              },
                  ),
                ),
                Expanded(
                  child: _accionPublicacion(
                    icono:
                        Icons
                            .chat_bubble_outline_rounded,
                    texto:
                        'Comentar',
                    onTap: () {
                      _abrirPublicacion(
                        publicacion,
                      );
                    },
                  ),
                ),
                Expanded(
                  child: _accionPublicacion(
                    icono:
                        Icons
                            .storefront_outlined,
                    texto:
                        'Tienda',
                    onTap: () {
                      Navigator.of(
                        context,
                      ).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              DetalleTiendaScreen(
                            emprendimientoId:
                                publicacion
                                    .emprendimientoId,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // AVATAR PUBLICACIÓN
  // ============================================================

  Widget _avatarEmprendimiento(
    Publicacion publicacion,
  ) {
    final imagen =
        publicacion.emprendimientoImagen;

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color:
            AppColors.naranja,
        border: Border.all(
          color:
              AppColors.naranja.withValues(
            alpha: 0.30,
          ),
          width: 2,
        ),
      ),
      child: ClipOval(
        child: imagen != null &&
                imagen.trim().isNotEmpty
            ? Image.network(
                imagen,
                fit: BoxFit.cover,
                errorBuilder: (
                  context,
                  error,
                  stackTrace,
                ) {
                  return const Icon(
                    Icons
                        .storefront_rounded,
                    color:
                        Colors.white,
                  );
                },
              )
            : const Icon(
                Icons.storefront_rounded,
                color:
                    Colors.white,
              ),
      ),
    );
  }

  // ============================================================
  // ACCIÓN PUBLICACIÓN
  // ============================================================

  Widget _accionPublicacion({
    required IconData icono,
    required String texto,
    required VoidCallback? onTap,
    Color? color,
  }) {
    return InkWell(
      onTap:
          onTap,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 5,
        ),
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              icono,
              size: 20,
              color: color,
            ),
            const SizedBox(
              width: 6,
            ),
            Flexible(
              child: Text(
                texto,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LISTA TIENDAS
  // ============================================================

  Widget _listaTiendas(
    bool oscuro,
  ) {
    if (_emprendimientosFiltrados.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _estadoVacio(
          icono:
              Icons.storefront_outlined,
          titulo:
              'No encontramos tiendas',
          descripcion:
              'Prueba con otro nombre o descripción.',
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
      ),
      sliver: SliverList(
        delegate:
            SliverChildBuilderDelegate(
          (
            context,
            index,
          ) {
            final tienda =
                _emprendimientosFiltrados[
                    index];

            return Padding(
              padding:
                  const EdgeInsets.only(
                bottom: 13,
              ),
              child: _tarjetaTienda(
                tienda,
                oscuro,
              ),
            );
          },
          childCount:
              _emprendimientosFiltrados
                  .length,
        ),
      ),
    );
  }

  // ============================================================
  // TARJETA TIENDA
  // ============================================================

  Widget _tarjetaTienda(
    Emprendimiento tienda,
    bool oscuro,
  ) {
    return Material(
      color: oscuro
          ? AppColors.tarjetaOscura
          : Colors.white,
      borderRadius:
          BorderRadius.circular(
        22,
      ),
      child: InkWell(
        onTap: () {
          _abrirTienda(
            tienda,
          );
        },
        borderRadius:
            BorderRadius.circular(
          22,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(
              22,
            ),
            border: Border.all(
              color: oscuro
                  ? AppColors.bordeOscuro
                  : AppColors.bordeClaro,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withValues(
                  alpha: oscuro
                      ? 0.12
                      : 0.05,
                ),
                blurRadius: 14,
                offset: const Offset(
                  0,
                  5,
                ),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius:
                BorderRadius.circular(
              22,
            ),
            child: Stack(
              children: [
                // ==============================================
                // GOTA DECORATIVA
                // ==============================================

                Positioned(
                  right: -30,
                  top: -38,
                  child: _GotaGrande(
                    color:
                        AppColors.naranja.withValues(
                      alpha: oscuro
                          ? 0.20
                          : 0.08,
                    ),
                  ),
                ),

                Padding(
                  padding:
                      const EdgeInsets.all(
                    14,
                  ),
                  child: Row(
                    children: [
                      // ========================================
                      // FOTO TIENDA
                      // ========================================

                      _imagenTienda(
                        tienda,
                      ),

                      const SizedBox(
                        width: 14,
                      ),

                      // ========================================
                      // DATOS
                      // ========================================

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Text(
                              tienda.nombre,
                              maxLines: 1,
                              overflow:
                                  TextOverflow
                                      .ellipsis,
                              style:
                                  const TextStyle(
                                fontSize: 17,
                                fontWeight:
                                    FontWeight
                                        .w900,
                              ),
                            ),

                            const SizedBox(
                              height: 5,
                            ),

                            Text(
                              tienda.descripcion ??
                                  'Emprendimiento local',
                              maxLines: 2,
                              overflow:
                                  TextOverflow
                                      .ellipsis,
                              style: Theme.of(
                                context,
                              )
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                height: 1.3,
                              ),
                            ),

                            const SizedBox(
                              height: 9,
                            ),

                            Row(
                              children: [
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(
                                    horizontal:
                                        9,
                                    vertical:
                                        5,
                                  ),
                                  decoration:
                                      BoxDecoration(
                                    color:
                                        AppColors.naranja.withValues(
                                      alpha:
                                          0.10,
                                    ),
                                    borderRadius:
                                        BorderRadius.circular(
                                      20,
                                    ),
                                  ),
                                  child:
                                      const Row(
                                    mainAxisSize:
                                        MainAxisSize
                                            .min,
                                    children: [
                                      Icon(
                                        Icons
                                            .storefront_outlined,
                                        color:
                                            AppColors
                                                .naranja,
                                        size: 14,
                                      ),
                                      SizedBox(
                                        width: 4,
                                      ),
                                      Text(
                                        'Ver tienda',
                                        style:
                                            TextStyle(
                                          color:
                                              AppColors
                                                  .naranja,
                                          fontSize:
                                              11,
                                          fontWeight:
                                              FontWeight
                                                  .w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        width: 8,
                      ),

                      Container(
                        width: 38,
                        height: 38,
                        decoration:
                            BoxDecoration(
                          color:
                              AppColors.naranja.withValues(
                            alpha: 0.10,
                          ),
                          shape:
                              BoxShape.circle,
                        ),
                        child:
                            const Icon(
                          Icons
                              .chevron_right_rounded,
                          color:
                              AppColors.naranja,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // IMAGEN TIENDA
  // ============================================================

  Widget _imagenTienda(
    Emprendimiento tienda,
  ) {
    final imagen =
        tienda.imagenUrl;

    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color:
            AppColors.naranja,
        borderRadius:
            BorderRadius.circular(
          19,
        ),
      ),
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(
          19,
        ),
        child: imagen != null &&
                imagen.trim().isNotEmpty
            ? Image.network(
                imagen,
                fit: BoxFit.cover,
                errorBuilder: (
                  context,
                  error,
                  stackTrace,
                ) {
                  return const Icon(
                    Icons
                        .storefront_rounded,
                    color:
                        Colors.white,
                    size: 34,
                  );
                },
              )
            : const Icon(
                Icons.storefront_rounded,
                color:
                    Colors.white,
                size: 34,
              ),
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _estadoError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(
          30,
        ),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color:
                    AppColors.error.withValues(
                  alpha: 0.10,
                ),
                shape:
                    BoxShape.circle,
              ),
              child: const Icon(
                Icons
                    .cloud_off_outlined,
                color:
                    AppColors.error,
                size: 35,
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            Text(
              _error!,
              textAlign:
                  TextAlign.center,
              style: const TextStyle(
                fontWeight:
                    FontWeight.w700,
              ),
            ),
            const SizedBox(
              height: 12,
            ),
            FilledButton.icon(
              onPressed:
                  _cargarTodo,
              icon:
                  const Icon(
                Icons.refresh_rounded,
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

  // ============================================================
  // VACÍO
  // ============================================================

  Widget _estadoVacio({
    required IconData icono,
    required String titulo,
    required String descripcion,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(
          32,
        ),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color:
                    AppColors.naranja.withValues(
                  alpha: 0.10,
                ),
                shape:
                    BoxShape.circle,
              ),
              child: Icon(
                icono,
                color:
                    AppColors.naranja,
                size: 37,
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            Text(
              titulo,
              textAlign:
                  TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
            const SizedBox(
              height: 5,
            ),
            Text(
              descripcion,
              textAlign:
                  TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FECHA
  // ============================================================

  String _formatearFecha(
    DateTime? fecha,
  ) {
    if (fecha == null) {
      return '';
    }

    final ahora =
        DateTime.now();

    final local =
        fecha.toLocal();

    final diferencia =
        ahora.difference(
      local,
    );

    if (diferencia.inMinutes < 1) {
      return 'Ahora';
    }

    if (diferencia.inHours < 1) {
      return 'Hace ${diferencia.inMinutes} min';
    }

    if (diferencia.inHours < 24) {
      return 'Hace ${diferencia.inHours} h';
    }

    if (diferencia.inDays < 7) {
      return 'Hace ${diferencia.inDays} días';
    }

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

    return '$dia/$mes/${local.year}';
  }
}

// ============================================================
// GOTA PEQUEÑA
// ============================================================

class _GotaPequena extends StatelessWidget {
  final Color color;

  const _GotaPequena({
    required this.color,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Transform.rotate(
      angle: 0.6,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color,
          borderRadius:
              const BorderRadius.only(
            topLeft:
                Radius.circular(
              30,
            ),
            topRight:
                Radius.circular(
              30,
            ),
            bottomLeft:
                Radius.circular(
              30,
            ),
            bottomRight:
                Radius.circular(
              8,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// GOTA GRANDE
// ============================================================

class _GotaGrande extends StatelessWidget {
  final Color color;

  const _GotaGrande({
    required this.color,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Transform.rotate(
      angle: 0.55,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: color,
          borderRadius:
              const BorderRadius.only(
            topLeft:
                Radius.circular(
              100,
            ),
            topRight:
                Radius.circular(
              100,
            ),
            bottomLeft:
                Radius.circular(
              100,
            ),
            bottomRight:
                Radius.circular(
              24,
            ),
          ),
        ),
      ),
    );
  }
}