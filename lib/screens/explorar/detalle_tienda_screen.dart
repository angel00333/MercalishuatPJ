import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../config/app_theme.dart';

import '../../helpers/chat_helper.dart';

import '../../models/emprendimiento.dart';
import '../../models/producto.dart';
import '../../models/publicacion.dart';

import '../../services/emprendimiento_service.dart';
import '../../services/producto_service.dart';
import '../../services/publicacion_service.dart';

import '../producto_actions/detalle_producto_screen.dart';
import '../publicaciones/detalle_publicacion_screen.dart';

// ============================================================
// SECCIONES DEL PERFIL COMERCIAL
// ============================================================

enum _SeccionTienda {
  productos,
  publicaciones,
}

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
  // ============================================================
  // DATOS
  // ============================================================

  Emprendimiento? emprendimiento;

  List<Producto> productos = [];

  List<Publicacion> publicaciones = [];

  // ============================================================
  // ESTADO
  // ============================================================

  bool cargando = true;

  String? errorProductos;

  String? errorPublicaciones;

  // ============================================================
  // SECCIÓN ACTUAL
  // ============================================================

  _SeccionTienda _seccion =
      _SeccionTienda.productos;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    cargar();
  }

  // ============================================================
  // CARGAR TIENDA + PRODUCTOS + PUBLICACIONES
  // ============================================================

  Future<void> cargar() async {
    if (mounted) {
      setState(() {
        cargando = true;

        errorProductos = null;

        errorPublicaciones = null;
      });
    }

    try {
      final resultados =
          await Future.wait<Map<String, dynamic>>([
        EmprendimientoService.obtenerPorId(
          widget.emprendimientoId,
        ),

        ProductoService.listarPorEmprendimiento(
          widget.emprendimientoId,
        ),

        // ======================================================
        // Con el backend actual obtenemos el feed y filtramos
        // las publicaciones pertenecientes a esta tienda.
        // ======================================================

        PublicacionService.feed(
          pagina: 1,
          limite: 100,
        ),
      ]);

      if (!mounted) {
        return;
      }

      final resultadoTienda =
          resultados[0];

      final resultadoProductos =
          resultados[1];

      final resultadoPublicaciones =
          resultados[2];

      Emprendimiento? tiendaCargada;

      List<Producto> productosCargados =
          [];

      List<Publicacion> publicacionesCargadas =
          [];

      String? errorProductosLocal;

      String? errorPublicacionesLocal;

      // ========================================================
      // TIENDA
      // ========================================================

      if (resultadoTienda['success'] == true) {
        final valor =
            resultadoTienda['emprendimiento'];

        if (valor is Emprendimiento) {
          tiendaCargada =
              valor;
        }
      }

      // ========================================================
      // PRODUCTOS
      // ========================================================

      if (resultadoProductos['success'] == true) {
        final raw =
            resultadoProductos['productos'];

        if (raw is List) {
          productosCargados =
              raw.whereType<Producto>()
                  .toList();
        }
      } else {
        errorProductosLocal =
            resultadoProductos['message']
                    ?.toString() ??
                'No se pudo cargar el catálogo.';
      }

      // ========================================================
      // PUBLICACIONES
      // ========================================================

      if (resultadoPublicaciones['success'] == true) {
        final raw =
            resultadoPublicaciones['publicaciones'];

        if (raw is List) {
          publicacionesCargadas =
              raw
                  .whereType<Publicacion>()
                  .where(
                    (
                      publicacion,
                    ) =>
                        publicacion.emprendimientoId ==
                        widget.emprendimientoId,
                  )
                  .toList();

          // Más recientes primero.

          publicacionesCargadas.sort(
            (
              a,
              b,
            ) {
              final fechaA =
                  a.fechaCreacion;

              final fechaB =
                  b.fechaCreacion;

              if (fechaA == null &&
                  fechaB == null) {
                return 0;
              }

              if (fechaA == null) {
                return 1;
              }

              if (fechaB == null) {
                return -1;
              }

              return fechaB.compareTo(
                fechaA,
              );
            },
          );
        }
      } else {
        errorPublicacionesLocal =
            resultadoPublicaciones['message']
                    ?.toString() ??
                'No se pudieron cargar las publicaciones.';
      }

      setState(() {
        emprendimiento =
            tiendaCargada;

        productos =
            productosCargados;

        publicaciones =
            publicacionesCargadas;

        errorProductos =
            errorProductosLocal;

        errorPublicaciones =
            errorPublicacionesLocal;

        cargando = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        cargando = false;

        errorProductos =
            'No se pudo cargar el catálogo.';

        errorPublicaciones =
            'No se pudieron cargar las publicaciones.';
      });
    }
  }

  // ============================================================
  // RECARGAR SOLO PUBLICACIONES
  // ============================================================

  Future<void>
      _recargarPublicaciones() async {
    try {
      final resultado =
          await PublicacionService.feed(
        pagina: 1,
        limite: 100,
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

      final lista =
          raw
              .whereType<Publicacion>()
              .where(
                (
                  publicacion,
                ) =>
                    publicacion.emprendimientoId ==
                    widget.emprendimientoId,
              )
              .toList();

      lista.sort(
        (
          a,
          b,
        ) {
          final fechaA =
              a.fechaCreacion;

          final fechaB =
              b.fechaCreacion;

          if (fechaA == null &&
              fechaB == null) {
            return 0;
          }

          if (fechaA == null) {
            return 1;
          }

          if (fechaB == null) {
            return -1;
          }

          return fechaB.compareTo(
            fechaA,
          );
        },
      );

      setState(() {
        publicaciones =
            lista;

        errorPublicaciones =
            null;
      });
    } catch (_) {
      // No bloqueamos la pantalla.
    }
  }

  // ============================================================
  // CHAT
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
  // CAMBIAR SECCIÓN
  // ============================================================

  void _cambiarSeccion(
    _SeccionTienda seccion,
  ) {
    if (_seccion == seccion) {
      return;
    }

    setState(() {
      _seccion =
          seccion;
    });
  }

  // ============================================================
  // ABRIR PRODUCTO
  // ============================================================

  Future<void> _abrirProducto(
    Producto producto,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            DetalleProductoScreen(
          productoId:
              producto.id,
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
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    // ==========================================================
    // CARGANDO
    // ==========================================================

    if (cargando) {
      return const Scaffold(
        body: Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    // ==========================================================
    // NO ENCONTRADO
    // ==========================================================

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

    final oscuro =
        Theme.of(context).brightness ==
            Brightness.dark;

    return Scaffold(
      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor:
            Theme.of(context)
                .scaffoldBackgroundColor,

        foregroundColor:
            Theme.of(context)
                .colorScheme
                .onSurface,

        surfaceTintColor:
            Colors.transparent,

        elevation:
            0,

        centerTitle:
            true,

        title: Text(
          tienda.nombre,

          maxLines:
              1,

          overflow:
              TextOverflow.ellipsis,

          style: const TextStyle(
            fontWeight:
                FontWeight.w900,
          ),
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: RefreshIndicator(
        onRefresh:
            cargar,

        child: CustomScrollView(
          physics:
              const AlwaysScrollableScrollPhysics(),

          slivers: [
            // ==================================================
            // PERFIL COMERCIAL
            // ==================================================

            SliverToBoxAdapter(
              child: Center(
                child:
                    ConstrainedBox(
                  constraints:
                      const BoxConstraints(
                    maxWidth:
                        760,
                  ),

                  child:
                      _perfilTienda(
                    tienda,
                    oscuro,
                  ),
                ),
              ),
            ),

            // ==================================================
            // SELECTOR
            // ==================================================

            SliverToBoxAdapter(
              child: Center(
                child:
                    ConstrainedBox(
                  constraints:
                      const BoxConstraints(
                    maxWidth:
                        760,
                  ),

                  child:
                      _selectorSecciones(
                    oscuro,
                  ),
                ),
              ),
            ),

            // ==================================================
            // PRODUCTOS
            // ==================================================

            if (_seccion ==
                _SeccionTienda.productos)
              _contenidoProductos(
                oscuro,
              ),

            // ==================================================
            // PUBLICACIONES
            // ==================================================

            if (_seccion ==
                _SeccionTienda.publicaciones)
              _contenidoPublicaciones(
                oscuro,
              ),

            const SliverToBoxAdapter(
              child: SizedBox(
                height:
                    32,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PERFIL DE TIENDA
  // ============================================================

  Widget _perfilTienda(
    Emprendimiento tienda,
    bool oscuro,
  ) {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        20,
        12,
        20,
        8,
      ),

      child: Column(
        children: [
          // ====================================================
          // CABECERA VISUAL
          // ====================================================

          Container(
            width:
                double.infinity,

            decoration:
                BoxDecoration(
              borderRadius:
                  BorderRadius.circular(
                28,
              ),

              gradient:
                  LinearGradient(
                begin:
                    Alignment.topLeft,

                end:
                    Alignment.bottomRight,

                colors:
                    oscuro
                        ? const [
                            Color(
                              0xFF352951,
                            ),
                            Color(
                              0xFF2A2045,
                            ),
                          ]
                        : const [
                            Color(
                              0xFFFFFFFF,
                            ),
                            Color(
                              0xFFFFF5EC,
                            ),
                          ],
              ),

              border:
                  Border.all(
                color:
                    oscuro
                        ? AppColors.bordeOscuro
                        : AppColors.bordeClaro,
              ),

              boxShadow: [
                BoxShadow(
                  color:
                      Colors.black
                          .withValues(
                    alpha:
                        oscuro
                            ? 0.15
                            : 0.06,
                  ),

                  blurRadius:
                      20,

                  offset:
                      const Offset(
                    0,
                    8,
                  ),
                ),
              ],
            ),

            child:
                ClipRRect(
              borderRadius:
                  BorderRadius.circular(
                28,
              ),

              child:
                  Stack(
                children: [
                  // ============================================
                  // DECORACIÓN NARANJA
                  // ============================================

                  Positioned(
                    right:
                        -45,

                    top:
                        -65,

                    child:
                        _GotaDecorativa(
                      size:
                          150,

                      color:
                          AppColors.naranja
                              .withValues(
                        alpha:
                            oscuro
                                ? 0.24
                                : 0.13,
                      ),
                    ),
                  ),

                  // ============================================
                  // DECORACIÓN MORADA
                  // ============================================

                  Positioned(
                    left:
                        -40,

                    bottom:
                        -60,

                    child:
                        _GotaDecorativa(
                      size:
                          120,

                      rotation:
                          -0.45,

                      color:
                          AppColors.moradoClaro
                              .withValues(
                        alpha:
                            oscuro
                                ? 0.16
                                : 0.08,
                      ),
                    ),
                  ),

                  // ============================================
                  // CONTENIDO
                  // ============================================

                  Padding(
                    padding:
                        const EdgeInsets.fromLTRB(
                      20,
                      24,
                      20,
                      22,
                    ),

                    child:
                        Column(
                      children: [
                        // ======================================
                        // FOTO
                        // ======================================

                        _imagenPerfilTienda(
                          tienda,
                        ),

                        const SizedBox(
                          height:
                              15,
                        ),

                        // ======================================
                        // NOMBRE
                        // ======================================

                        Text(
                          tienda.nombre,

                          textAlign:
                              TextAlign.center,

                          style:
                              const TextStyle(
                            fontSize:
                                26,

                            fontWeight:
                                FontWeight.w900,
                          ),
                        ),

                        // ======================================
                        // DESCRIPCIÓN
                        // ======================================

                        if (tienda.descripcion !=
                                null &&
                            tienda.descripcion!
                                .trim()
                                .isNotEmpty) ...[
                          const SizedBox(
                            height:
                                9,
                          ),

                          Padding(
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal:
                                  12,
                            ),

                            child:
                                Text(
                              tienda.descripcion!,

                              textAlign:
                                  TextAlign.center,

                              style:
                                  Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                height:
                                    1.35,

                                fontSize:
                                    14,
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(
                          height:
                              22,
                        ),

                        // ======================================
                        // CONTADORES
                        // ======================================

                        Row(
                          children: [
                            Expanded(
                              child:
                                  _metricaPerfil(
                                valor:
                                    productos.length,

                                titulo:
                                    'Productos',
                              ),
                            ),

                            Container(
                              width:
                                  1,

                              height:
                                  40,

                              color:
                                  Theme.of(context)
                                      .dividerColor,
                            ),

                            Expanded(
                              child:
                                  _metricaPerfil(
                                valor:
                                    publicaciones.length,

                                titulo:
                                    'Publicaciones',
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(
                          height:
                              22,
                        ),

                        // ======================================
                        // MENSAJE
                        // ======================================

                        SizedBox(
                          width:
                              double.infinity,

                          height:
                              50,

                          child:
                              FilledButton.icon(
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
                                  .chat_bubble_outline_rounded,
                            ),

                            label:
                                const Text(
                              'Enviar mensaje',

                              style:
                                  TextStyle(
                                fontWeight:
                                    FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FOTO TIENDA
  // ============================================================

  Widget _imagenPerfilTienda(
    Emprendimiento tienda,
  ) {
    return Container(
      width:
          116,

      height:
          116,

      padding:
          const EdgeInsets.all(
        4,
      ),

      decoration:
          BoxDecoration(
        color:
            Colors.white,

        shape:
            BoxShape.circle,

        border:
            Border.all(
          color:
              AppColors.naranja,

          width:
              3,
        ),

        boxShadow: [
          BoxShadow(
            color:
                Colors.black
                    .withValues(
              alpha:
                  0.14,
            ),

            blurRadius:
                16,

            offset:
                const Offset(
              0,
              6,
            ),
          ),
        ],
      ),

      child:
          ClipOval(
        child:
            tienda.imagenUrl !=
                        null &&
                    tienda.imagenUrl!
                        .trim()
                        .isNotEmpty
                ? Image.network(
                    tienda.imagenUrl!,

                    width:
                        108,

                    height:
                        108,

                    fit:
                        BoxFit.cover,

                    errorBuilder:
                        (
                      context,
                      error,
                      stackTrace,
                    ) {
                      return _fallbackTienda();
                    },
                  )
                : _fallbackTienda(),
      ),
    );
  }

  Widget _fallbackTienda() {
    return Container(
      color:
          AppColors.naranja,

      alignment:
          Alignment.center,

      child:
          const Icon(
        Icons.storefront_rounded,

        size:
            52,

        color:
            Colors.white,
      ),
    );
  }

  // ============================================================
  // MÉTRICA
  // ============================================================

  Widget _metricaPerfil({
    required int valor,
    required String titulo,
  }) {
    return Column(
      children: [
        Text(
          '$valor',

          style:
              const TextStyle(
            fontSize:
                21,

            fontWeight:
                FontWeight.w900,
          ),
        ),

        const SizedBox(
          height:
              2,
        ),

        Text(
          titulo,

          style:
              Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(
            fontWeight:
                FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SELECTOR TIPO INSTAGRAM
  // ============================================================

  Widget _selectorSecciones(
    bool oscuro,
  ) {
    return Container(
      margin:
          const EdgeInsets.fromLTRB(
        20,
        16,
        20,
        18,
      ),

      decoration:
          BoxDecoration(
        border:
            Border(
          bottom:
              BorderSide(
            color:
                Theme.of(context)
                    .dividerColor,
          ),
        ),
      ),

      child:
          Row(
        children: [
          // ====================================================
          // PRODUCTOS
          // ====================================================

          Expanded(
            child:
                _botonSeccion(
              seleccionado:
                  _seccion ==
                      _SeccionTienda.productos,

              icono:
                  Icons.grid_view_rounded,

              texto:
                  'Productos',

              onTap:
                  () {
                _cambiarSeccion(
                  _SeccionTienda.productos,
                );
              },
            ),
          ),

          // ====================================================
          // PUBLICACIONES
          // ====================================================

          Expanded(
            child:
                _botonSeccion(
              seleccionado:
                  _seccion ==
                      _SeccionTienda.publicaciones,

              icono:
                  Icons
                      .photo_library_outlined,

              texto:
                  'Publicaciones',

              onTap:
                  () {
                _cambiarSeccion(
                  _SeccionTienda.publicaciones,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOTÓN SECCIÓN
  // ============================================================

  Widget _botonSeccion({
    required bool seleccionado,
    required IconData icono,
    required String texto,
    required VoidCallback onTap,
  }) {
    return Material(
      color:
          Colors.transparent,

      child:
          InkWell(
        onTap:
            onTap,

        child:
            AnimatedContainer(
          duration:
              const Duration(
            milliseconds:
                200,
          ),

          padding:
              const EdgeInsets.only(
            top:
                12,

            bottom:
                11,
          ),

          decoration:
              BoxDecoration(
            border:
                Border(
              bottom:
                  BorderSide(
                color:
                    seleccionado
                        ? AppColors.naranja
                        : Colors.transparent,

                width:
                    3,
              ),
            ),
          ),

          child:
              Row(
            mainAxisAlignment:
                MainAxisAlignment.center,

            children: [
              Icon(
                icono,

                color:
                    seleccionado
                        ? AppColors.naranja
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(
                              alpha:
                                  0.55,
                            ),

                size:
                    21,
              ),

              const SizedBox(
                width:
                    7,
              ),

              Text(
                texto,

                style:
                    TextStyle(
                  color:
                      seleccionado
                          ? AppColors.naranja
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(
                                alpha:
                                    0.65,
                              ),

                  fontSize:
                      13,

                  fontWeight:
                      seleccionado
                          ? FontWeight.w800
                          : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CONTENIDO PRODUCTOS
  // ============================================================

  Widget _contenidoProductos(
    bool oscuro,
  ) {
    // ==========================================================
    // ERROR
    // ==========================================================

    if (errorProductos != null &&
        productos.isEmpty) {
      return SliverToBoxAdapter(
        child:
            _estadoContenido(
          icono:
              Icons
                  .inventory_2_outlined,

          titulo:
              'No se pudo cargar el catálogo',

          descripcion:
              errorProductos!,

          onReintentar:
              cargar,
        ),
      );
    }

    // ==========================================================
    // VACÍO
    // ==========================================================

    if (productos.isEmpty) {
      return const SliverToBoxAdapter(
        child:
            _EstadoVacio(
          icono:
              Icons
                  .inventory_2_outlined,

          titulo:
              'Sin productos todavía',

          descripcion:
              'Esta tienda aún no ha publicado productos.',
        ),
      );
    }

    // ==========================================================
    // GRID
    // ==========================================================

    return SliverPadding(
      padding:
          const EdgeInsets.symmetric(
        horizontal:
            20,
      ),

      sliver:
          SliverGrid(
        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount:
              2,

          crossAxisSpacing:
              12,

          mainAxisSpacing:
              12,

          childAspectRatio:
              0.72,
        ),

        delegate:
            SliverChildBuilderDelegate(
          (
            context,
            index,
          ) {
            final producto =
                productos[index];

            return _tarjetaProducto(
              producto,
              oscuro,
            );
          },

          childCount:
              productos.length,
        ),
      ),
    );
  }

  // ============================================================
  // TARJETA PRODUCTO
  // ============================================================

  Widget _tarjetaProducto(
    Producto producto,
    bool oscuro,
  ) {
    return Material(
      color:
          oscuro
              ? AppColors.tarjetaOscura
              : Colors.white,

      borderRadius:
          BorderRadius.circular(
        20,
      ),

      clipBehavior:
          Clip.antiAlias,

      child:
          InkWell(
        onTap:
            () {
          _abrirProducto(
            producto,
          );
        },

        child:
            Container(
          decoration:
              BoxDecoration(
            border:
                Border.all(
              color:
                  oscuro
                      ? AppColors.bordeOscuro
                      : AppColors.bordeClaro,
            ),

            borderRadius:
                BorderRadius.circular(
              20,
            ),
          ),

          child:
              Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              // ================================================
              // IMAGEN
              // ================================================

              Expanded(
                child:
                    Stack(
                  fit:
                      StackFit.expand,

                  children: [
                    producto.imagenPrincipal !=
                                null &&
                            producto
                                .imagenPrincipal!
                                .trim()
                                .isNotEmpty
                        ? Image.network(
                            producto
                                .imagenPrincipal!,

                            fit:
                                BoxFit.cover,

                            errorBuilder:
                                (
                              context,
                              error,
                              stackTrace,
                            ) {
                              return _sinImagenProducto();
                            },
                          )
                        : _sinImagenProducto(),

                    // ==========================================
                    // DISPONIBILIDAD
                    // ==========================================

                    if (!producto.disponible)
                      Positioned(
                        top:
                            8,

                        left:
                            8,

                        child:
                            Container(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal:
                                8,

                            vertical:
                                4,
                          ),

                          decoration:
                              BoxDecoration(
                            color:
                                Colors.black
                                    .withValues(
                              alpha:
                                  0.68,
                            ),

                            borderRadius:
                                BorderRadius.circular(
                              20,
                            ),
                          ),

                          child:
                              const Text(
                            'No disponible',

                            style:
                                TextStyle(
                              color:
                                  Colors.white,

                              fontSize:
                                  10,

                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // ================================================
              // DATOS
              // ================================================

              Padding(
                padding:
                    const EdgeInsets.fromLTRB(
                  12,
                  11,
                  12,
                  12,
                ),

                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Text(
                      producto.nombre,

                      maxLines:
                          2,

                      overflow:
                          TextOverflow.ellipsis,

                      style:
                          const TextStyle(
                        fontSize:
                            14,

                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),

                    const SizedBox(
                      height:
                          6,
                    ),

                    Row(
                      children: [
                        Expanded(
                          child:
                              Text(
                            '\$${producto.precio.toStringAsFixed(2)}',

                            style:
                                const TextStyle(
                              color:
                                  AppColors.naranja,

                              fontSize:
                                  16,

                              fontWeight:
                                  FontWeight.w900,
                            ),
                          ),
                        ),

                        Container(
                          width:
                              30,

                          height:
                              30,

                          decoration:
                              BoxDecoration(
                            color:
                                AppColors.naranja
                                    .withValues(
                              alpha:
                                  0.10,
                            ),

                            shape:
                                BoxShape.circle,
                          ),

                          child:
                              const Icon(
                            Icons
                                .arrow_forward_ios_rounded,

                            color:
                                AppColors.naranja,

                            size:
                                13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sinImagenProducto() {
    return Container(
      color:
          AppColors.naranja
              .withValues(
        alpha:
            0.08,
      ),

      alignment:
          Alignment.center,

      child:
          const Icon(
        Icons.image_outlined,

        color:
            AppColors.naranja,

        size:
            42,
      ),
    );
  }

  // ============================================================
  // CONTENIDO PUBLICACIONES
  // ============================================================

  Widget _contenidoPublicaciones(
    bool oscuro,
  ) {
    // ==========================================================
    // ERROR
    // ==========================================================

    if (errorPublicaciones !=
            null &&
        publicaciones.isEmpty) {
      return SliverToBoxAdapter(
        child:
            _estadoContenido(
          icono:
              Icons
                  .photo_library_outlined,

          titulo:
              'No se pudieron cargar las publicaciones',

          descripcion:
              errorPublicaciones!,

          onReintentar:
              cargar,
        ),
      );
    }

    // ==========================================================
    // VACÍO
    // ==========================================================

    if (publicaciones.isEmpty) {
      return const SliverToBoxAdapter(
        child:
            _EstadoVacio(
          icono:
              Icons
                  .photo_library_outlined,

          titulo:
              'Sin publicaciones todavía',

          descripcion:
              'Las publicaciones de esta tienda aparecerán aquí.',
        ),
      );
    }

    // ==========================================================
    // GRID TIPO INSTAGRAM
    // ==========================================================

    return SliverPadding(
      padding:
          const EdgeInsets.symmetric(
        horizontal:
            20,
      ),

      sliver:
          SliverGrid(
        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount:
              3,

          crossAxisSpacing:
              3,

          mainAxisSpacing:
              3,

          childAspectRatio:
              1,
        ),

        delegate:
            SliverChildBuilderDelegate(
          (
            context,
            index,
          ) {
            final publicacion =
                publicaciones[index];

            return _cuadroPublicacion(
              publicacion,
            );
          },

          childCount:
              publicaciones.length,
        ),
      ),
    );
  }

  // ============================================================
  // CUADRO PUBLICACIÓN
  // ============================================================

  Widget _cuadroPublicacion(
    Publicacion publicacion,
  ) {
    final tieneImagen =
        publicacion.imagenPrincipal !=
                null &&
            publicacion.imagenPrincipal!
                .trim()
                .isNotEmpty;

    return Material(
      color:
          AppColors.morado,

      clipBehavior:
          Clip.antiAlias,

      child:
          InkWell(
        onTap:
            () {
          _abrirPublicacion(
            publicacion,
          );
        },

        child:
            Stack(
          fit:
              StackFit.expand,

          children: [
            // ==================================================
            // IMAGEN
            // ==================================================

            if (tieneImagen)
              Image.network(
                publicacion
                    .imagenPrincipal!,

                fit:
                    BoxFit.cover,

                errorBuilder:
                    (
                  context,
                  error,
                  stackTrace,
                ) {
                  return _publicacionSinImagen(
                    publicacion,
                  );
                },
              )
            else
              _publicacionSinImagen(
                publicacion,
              ),

            // ==================================================
            // GRADIENTE
            // ==================================================

            Positioned(
              left:
                  0,

              right:
                  0,

              bottom:
                  0,

              height:
                  48,

              child:
                  DecoratedBox(
                decoration:
                    BoxDecoration(
                  gradient:
                      LinearGradient(
                    begin:
                        Alignment.topCenter,

                    end:
                        Alignment.bottomCenter,

                    colors: [
                      Colors.transparent,

                      Colors.black
                          .withValues(
                        alpha:
                            0.70,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ==================================================
            // MÉTRICAS
            // ==================================================

            Positioned(
              left:
                  7,

              right:
                  7,

              bottom:
                  6,

              child:
                  Row(
                children: [
                  const Icon(
                    Icons.favorite_rounded,

                    color:
                        Colors.white,

                    size:
                        14,
                  ),

                  const SizedBox(
                    width:
                        3,
                  ),

                  Text(
                    '${publicacion.totalMeGusta}',

                    style:
                        const TextStyle(
                      color:
                          Colors.white,

                      fontSize:
                          10,

                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),

                  const SizedBox(
                    width:
                        8,
                  ),

                  const Icon(
                    Icons
                        .chat_bubble_rounded,

                    color:
                        Colors.white,

                    size:
                        13,
                  ),

                  const SizedBox(
                    width:
                        3,
                  ),

                  Text(
                    '${publicacion.totalComentarios}',

                    style:
                        const TextStyle(
                      color:
                          Colors.white,

                      fontSize:
                          10,

                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            // ==================================================
            // PRODUCTO VINCULADO
            // ==================================================

            if (publicacion.productoId !=
                null)
              Positioned(
                top:
                    7,

                right:
                    7,

                child:
                    Container(
                  width:
                      26,

                  height:
                      26,

                  decoration:
                      BoxDecoration(
                    color:
                        Colors.black
                            .withValues(
                      alpha:
                          0.55,
                    ),

                    shape:
                        BoxShape.circle,
                  ),

                  child:
                      const Icon(
                    Icons
                        .shopping_bag_outlined,

                    color:
                        Colors.white,

                    size:
                        14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PUBLICACIÓN SIN IMAGEN
  // ============================================================

  Widget _publicacionSinImagen(
    Publicacion publicacion,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(
        10,
      ),

      decoration:
          const BoxDecoration(
        gradient:
            LinearGradient(
          begin:
              Alignment.topLeft,

          end:
              Alignment.bottomRight,

          colors: [
            AppColors.morado,
            Color(
              0xFF5B2A75,
            ),
            AppColors.naranjaOscuro,
          ],
        ),
      ),

      child:
          Column(
        mainAxisAlignment:
            MainAxisAlignment.center,

        children: [
          const Icon(
            Icons
                .format_quote_rounded,

            color:
                Colors.white70,

            size:
                25,
          ),

          const SizedBox(
            height:
                4,
          ),

          Text(
            publicacion.texto
                    .trim()
                    .isEmpty
                ? 'Publicación'
                : publicacion.texto,

            maxLines:
                4,

            overflow:
                TextOverflow.ellipsis,

            textAlign:
                TextAlign.center,

            style:
                const TextStyle(
              color:
                  Colors.white,

              fontSize:
                  11,

              height:
                  1.15,

              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ESTADO DE ERROR
  // ============================================================

  Widget _estadoContenido({
    required IconData icono,
    required String titulo,
    required String descripcion,
    required VoidCallback onReintentar,
  }) {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        30,
        40,
        30,
        60,
      ),

      child:
          Column(
        children: [
          Container(
            width:
                72,

            height:
                72,

            decoration:
                BoxDecoration(
              color:
                  AppColors.naranja
                      .withValues(
                alpha:
                    0.10,
              ),

              shape:
                  BoxShape.circle,
            ),

            child:
                Icon(
              icono,

              color:
                  AppColors.naranja,

              size:
                  35,
            ),
          ),

          const SizedBox(
            height:
                15,
          ),

          Text(
            titulo,

            textAlign:
                TextAlign.center,

            style:
                const TextStyle(
              fontSize:
                  17,

              fontWeight:
                  FontWeight.w800,
            ),
          ),

          const SizedBox(
            height:
                6,
          ),

          Text(
            descripcion,

            textAlign:
                TextAlign.center,

            style:
                Theme.of(context)
                    .textTheme
                    .bodySmall,
          ),

          const SizedBox(
            height:
                15,
          ),

          FilledButton.icon(
            onPressed:
                onReintentar,

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
    );
  }
}

// ============================================================
// ESTADO VACÍO
// ============================================================

class _EstadoVacio extends StatelessWidget {
  final IconData icono;

  final String titulo;

  final String descripcion;

  const _EstadoVacio({
    required this.icono,
    required this.titulo,
    required this.descripcion,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        30,
        42,
        30,
        70,
      ),

      child:
          Column(
        mainAxisSize:
            MainAxisSize.min,

        children: [
          Container(
            width:
                76,

            height:
                76,

            decoration:
                BoxDecoration(
              color:
                  AppColors.naranja
                      .withValues(
                alpha:
                    0.10,
              ),

              shape:
                  BoxShape.circle,
            ),

            child:
                Icon(
              icono,

              color:
                  AppColors.naranja,

              size:
                  36,
            ),
          ),

          const SizedBox(
            height:
                16,
          ),

          Text(
            titulo,

            textAlign:
                TextAlign.center,

            style:
                const TextStyle(
              fontSize:
                  17,

              fontWeight:
                  FontWeight.w800,
            ),
          ),

          const SizedBox(
            height:
                6,
          ),

          Text(
            descripcion,

            textAlign:
                TextAlign.center,

            style:
                Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(
              fontSize:
                  13,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// GOTA DECORATIVA
// ============================================================

class _GotaDecorativa extends StatelessWidget {
  final double size;

  final Color color;

  final double rotation;

  const _GotaDecorativa({
    required this.size,
    required this.color,
    this.rotation = 0.55,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Transform.rotate(
      angle:
          rotation,

      child:
          Container(
        width:
            size,

        height:
            size,

        decoration:
            BoxDecoration(
          color:
              color,

          borderRadius:
              BorderRadius.only(
            topLeft:
                Radius.circular(
              size,
            ),

            topRight:
                Radius.circular(
              size,
            ),

            bottomLeft:
                Radius.circular(
              size,
            ),

            bottomRight:
                Radius.circular(
              math.max(
                20,
                size * 0.20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}