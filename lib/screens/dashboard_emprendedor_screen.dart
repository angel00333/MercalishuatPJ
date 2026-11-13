import 'package:flutter/material.dart';

import '../config/app_theme.dart';

import '../models/conversacion.dart';
import '../models/emprendimiento.dart';

import '../services/chat_service.dart';
import '../services/emprendimiento_service.dart';
import '../services/producto_service.dart';
import '../services/publicacion_service.dart';
import '../services/theme_service.dart';

import 'chat/conversaciones_screen.dart';

import 'explorar/detalle_tienda_screen.dart';

import 'locales/locales_comerciales_screen.dart';

import 'producto_actions/crear_producto_screen.dart';
import 'producto_actions/productos_screen.dart';

import 'publicaciones/crear_publicacion_screen.dart';
import 'publicaciones/mis_publicaciones_screen.dart';

import 'tienda_actions/mi_tienda_screen.dart';

class DashboardEmprendedorScreen
    extends StatefulWidget {
  final ThemeService themeService;

  const DashboardEmprendedorScreen({
    super.key,
    required this.themeService,
  });

  @override
  State<DashboardEmprendedorScreen>
      createState() =>
          _DashboardEmprendedorScreenState();
}

class _DashboardEmprendedorScreenState
    extends State<
        DashboardEmprendedorScreen> {
  // ============================================================
  // ESTADO
  // ============================================================

  bool cargando = true;

  bool recargando = false;

  Emprendimiento? emprendimiento;

  int totalProductos = 0;

  int totalPublicaciones = 0;

  int totalConversaciones = 0;

  int mensajesNoLeidos = 0;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    cargarDashboard();
  }

  // ============================================================
  // CARGAR DASHBOARD
  // ============================================================

  Future<void> cargarDashboard({
    bool mostrarCargaCompleta = true,
  }) async {
    if (mostrarCargaCompleta) {
      if (mounted) {
        setState(() {
          cargando = true;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          recargando = true;
        });
      }
    }

    try {
      final resultados =
          await Future.wait<
              Map<String, dynamic>>([
        EmprendimientoService
            .obtenerMiTienda(),

        ProductoService
            .listarMisProductos(),

        PublicacionService
            .misPublicaciones(),

        ChatService
            .listarConversaciones(),
      ]);

      if (!mounted) {
        return;
      }

      // ========================================================
      // TIENDA
      // ========================================================

      final tiendaResultado =
          resultados[0];

      Emprendimiento? tienda;

      if (tiendaResultado['success'] ==
          true) {
        final valor =
            tiendaResultado[
                'emprendimiento'];

        if (valor
            is Emprendimiento) {
          tienda = valor;
        }
      }

      // ========================================================
      // PRODUCTOS
      // ========================================================

      final productosResultado =
          resultados[1];

      int productos = 0;

      if (productosResultado[
              'success'] ==
          true) {
        final lista =
            productosResultado[
                'productos'];

        if (lista is List) {
          productos = lista.length;
        }
      }

      // ========================================================
      // PUBLICACIONES
      // ========================================================

      final publicacionesResultado =
          resultados[2];

      int publicaciones = 0;

      if (publicacionesResultado[
              'success'] ==
          true) {
        final lista =
            publicacionesResultado[
                'publicaciones'];

        if (lista is List) {
          publicaciones =
              lista.length;
        }
      }

      // ========================================================
      // MENSAJES
      // ========================================================

      final chatResultado =
          resultados[3];

      int conversaciones = 0;
      int noLeidos = 0;

      if (chatResultado['success'] ==
          true) {
        final lista =
            chatResultado[
                'conversaciones'];

        if (lista is List) {
          conversaciones =
              lista.length;

          for (final item in lista) {
            if (item
                is Conversacion) {
              noLeidos +=
                  item
                      .mensajesNoLeidos;
            }
          }
        }
      }

      // ========================================================
      // ACTUALIZAR UI
      // ========================================================

      setState(() {
        emprendimiento = tienda;

        totalProductos =
            productos;

        totalPublicaciones =
            publicaciones;

        totalConversaciones =
            conversaciones;

        mensajesNoLeidos =
            noLeidos;

        cargando = false;

        recargando = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        cargando = false;
        recargando = false;
      });

      _mostrarMensaje(
        'No se pudo actualizar el panel',
      );
    }
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> _actualizar() async {
    await cargarDashboard(
      mostrarCargaCompleta: false,
    );
  }

  // ============================================================
  // MI TIENDA
  // ============================================================

  Future<void> _abrirMiTienda() async {
    await Navigator.push(
      context,

      MaterialPageRoute(
        builder: (_) =>
            MiTiendaScreen(
          themeService:
              widget.themeService,
        ),
      ),
    );

    await _actualizar();
  }

  // ============================================================
  // VER TIENDA COMO CLIENTE
  // ============================================================

  Future<void>
      _verTiendaPublica() async {
    final tienda =
        emprendimiento;

    if (tienda == null) {
      await _abrirMiTienda();

      return;
    }

    await Navigator.push(
      context,

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
  // PRODUCTOS
  // ============================================================

  Future<void>
      _abrirProductos() async {
    await Navigator.push(
      context,

      MaterialPageRoute(
        builder: (_) =>
            const ProductosScreen(),
      ),
    );

    await _actualizar();
  }

  // ============================================================
  // CREAR PRODUCTO
  // ============================================================

  Future<void>
      _crearProducto() async {
    if (!_validarTienda()) {
      return;
    }

    await Navigator.push(
      context,

      MaterialPageRoute(
        builder: (_) =>
            const CrearProductoScreen(),
      ),
    );

    await _actualizar();
  }

  // ============================================================
  // PUBLICACIONES
  // ============================================================

  Future<void>
      _abrirPublicaciones() async {
    await Navigator.push(
      context,

      MaterialPageRoute(
        builder: (_) =>
            const MisPublicacionesScreen(),
      ),
    );

    await _actualizar();
  }

  // ============================================================
  // CREAR PUBLICACIÓN
  // ============================================================

  Future<void>
      _crearPublicacion() async {
    if (!_validarTienda()) {
      return;
    }

    await Navigator.push(
      context,

      MaterialPageRoute(
        builder: (_) =>
            const CrearPublicacionScreen(),
      ),
    );

    await _actualizar();
  }

  // ============================================================
  // MENSAJES
  // ============================================================

  Future<void>
      _abrirMensajes() async {
    await Navigator.push(
      context,

      MaterialPageRoute(
        builder: (_) =>
            const ConversacionesScreen(),
      ),
    );

    await _actualizar();
  }

  // ============================================================
  // LOCALES COMERCIALES
  // ============================================================

  Future<void>
      _abrirLocales() async {
    await Navigator.push(
      context,

      MaterialPageRoute(
        builder: (_) =>
            const LocalesComercialesScreen(
          puedePublicar: true,
        ),
      ),
    );
  }

  // ============================================================
  // VALIDAR TIENDA
  // ============================================================

  bool _validarTienda() {
    if (emprendimiento != null) {
      return true;
    }

    _mostrarMensaje(
      'Primero debes configurar tu tienda',
    );

    return false;
  }

  // ============================================================
  // MENSAJE
  // ============================================================

  void _mostrarMensaje(
    String mensaje,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content:
              Text(
            mensaje,
          ),
        ),
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

    final Color textoPrincipal =
        Theme.of(context)
            .colorScheme
            .onSurface;

    final Color textoSecundario =
        textoPrincipal.withValues(
      alpha: 0.62,
    );

    final Color borde =
        Theme.of(context)
            .dividerColor
            .withValues(
              alpha: 0.45,
            );

    if (cargando) {
      return Scaffold(
        appBar:
            AppBar(
          title:
              const Text(
            'Centro de negocio',
          ),
        ),

        body:
            const Center(
          child:
              CircularProgressIndicator(
            color:
                AppColors.naranja,
          ),
        ),
      );
    }

    return Scaffold(
      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        title:
            const Text(
          'Centro de negocio',
        ),

        actions: [
          IconButton(
            tooltip:
                'Actualizar',

            onPressed:
                recargando
                    ? null
                    : _actualizar,

            icon:
                recargando
                    ? const SizedBox(
                        width:
                            20,

                        height:
                            20,

                        child:
                            CircularProgressIndicator(
                          strokeWidth:
                              2,

                          color:
                              AppColors.naranja,
                        ),
                      )
                    : const Icon(
                        Icons
                            .refresh_rounded,
                      ),
          ),
        ],
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: RefreshIndicator(
        onRefresh:
            _actualizar,

        color:
            AppColors.naranja,

        child:
            SingleChildScrollView(
          physics:
              const AlwaysScrollableScrollPhysics(),

          padding:
              const EdgeInsets.fromLTRB(
            18,
            18,
            18,
            40,
          ),

          child:
              Center(
            child:
                ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxWidth:
                    1050,
              ),

              child:
                  Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,

                children: [
                  // =============================================
                  // TIENDA
                  // =============================================

                  if (emprendimiento !=
                      null)
                    _cabeceraTienda(
                      oscuro:
                          oscuro,

                      textoSecundario:
                          textoSecundario,
                    )
                  else
                    _sinTienda(),

                  const SizedBox(
                    height: 26,
                  ),

                  // =============================================
                  // RESUMEN
                  // =============================================

                  _tituloSeccion(
                    icono:
                        Icons
                            .analytics_outlined,

                    titulo:
                        'Resumen',
                  ),

                  const SizedBox(
                    height: 14,
                  ),

                  _resumenResponsive(
                    borde:
                        borde,

                    textoSecundario:
                        textoSecundario,
                  ),

                  const SizedBox(
                    height: 30,
                  ),

                  // =============================================
                  // ACCIONES RÁPIDAS
                  // =============================================

                  _tituloSeccion(
                    icono:
                        Icons
                            .bolt_rounded,

                    titulo:
                        'Acciones rápidas',
                  ),

                  const SizedBox(
                    height: 14,
                  ),

                  _accionesRapidas(),

                  const SizedBox(
                    height: 30,
                  ),

                  // =============================================
                  // ADMINISTRACIÓN
                  // =============================================

                  _tituloSeccion(
                    icono:
                        Icons
                            .dashboard_customize_outlined,

                    titulo:
                        'Administrar negocio',
                  ),

                  const SizedBox(
                    height: 14,
                  ),

                  _administracionResponsive(
                    borde:
                        borde,

                    textoSecundario:
                        textoSecundario,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CABECERA TIENDA
  // ============================================================

  Widget _cabeceraTienda({
    required bool oscuro,
    required Color textoSecundario,
  }) {
    final tienda =
        emprendimiento!;

    return Container(
      decoration:
          BoxDecoration(
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
          28,
        ),
      ),

      clipBehavior:
          Clip.antiAlias,

      child:
          Stack(
        children: [
          // ====================================================
          // DECORACIÓN
          // ====================================================

          Positioned(
            right:
                -55,

            top:
                -65,

            child:
                Container(
              width:
                  190,

              height:
                  190,

              decoration:
                  BoxDecoration(
                color:
                    Colors.white
                        .withValues(
                  alpha:
                      0.10,
                ),

                shape:
                    BoxShape.circle,
              ),
            ),
          ),

          Positioned(
            right:
                55,

            bottom:
                -75,

            child:
                Container(
              width:
                  150,

              height:
                  150,

              decoration:
                  BoxDecoration(
                color:
                    AppColors.morado
                        .withValues(
                  alpha:
                      0.12,
                ),

                shape:
                    BoxShape.circle,
              ),
            ),
          ),

          // ====================================================
          // CONTENIDO
          // ====================================================

          Padding(
            padding:
                const EdgeInsets.all(
              22,
            ),

            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Row(
                  children: [
                    // ===========================================
                    // IMAGEN
                    // ===========================================

                    Container(
                      width:
                          68,

                      height:
                          68,

                      decoration:
                          BoxDecoration(
                        color:
                            Colors.white,

                        borderRadius:
                            BorderRadius.circular(
                          20,
                        ),

                        image:
                            tienda.imagenUrl !=
                                        null &&
                                    tienda
                                        .imagenUrl!
                                        .isNotEmpty
                                ? DecorationImage(
                                    image:
                                        NetworkImage(
                                      tienda
                                          .imagenUrl!,
                                    ),

                                    fit:
                                        BoxFit.cover,
                                  )
                                : null,
                      ),

                      child:
                          tienda.imagenUrl ==
                                      null ||
                                  tienda
                                      .imagenUrl!
                                      .isEmpty
                              ? const Icon(
                                  Icons
                                      .storefront_rounded,

                                  color:
                                      AppColors.naranja,

                                  size:
                                      36,
                                )
                              : null,
                    ),

                    const SizedBox(
                      width: 16,
                    ),

                    // ===========================================
                    // INFORMACIÓN
                    // ===========================================

                    Expanded(
                      child:
                          Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [
                          Text(
                            tienda.nombre,

                            maxLines:
                                2,

                            overflow:
                                TextOverflow.ellipsis,

                            style:
                                const TextStyle(
                              color:
                                  Colors.white,

                              fontSize:
                                  23,

                              height:
                                  1.1,

                              fontWeight:
                                  FontWeight.w900,

                              fontFamily:
                                  'Outfit',
                            ),
                          ),

                          const SizedBox(
                            height: 6,
                          ),

                          Row(
                            children: [
                              Container(
                                width:
                                    8,

                                height:
                                    8,

                                decoration:
                                    BoxDecoration(
                                  color:
                                      tienda.activo
                                          ? Colors
                                              .lightGreenAccent
                                          : Colors
                                              .white60,

                                  shape:
                                      BoxShape.circle,
                                ),
                              ),

                              const SizedBox(
                                width: 7,
                              ),

                              Text(
                                tienda.activo
                                    ? 'Emprendimiento activo'
                                    : 'Emprendimiento inactivo',

                                style:
                                    TextStyle(
                                  color:
                                      Colors.white
                                          .withValues(
                                    alpha:
                                        0.90,
                                  ),

                                  fontSize:
                                      12.5,

                                  fontWeight:
                                      FontWeight.w600,

                                  fontFamily:
                                      'Outfit',
                                ),
                              ),
                            ],
                          ),

                          if (tienda.propietario !=
                                  null &&
                              tienda
                                  .propietario!
                                  .trim()
                                  .isNotEmpty) ...[
                            const SizedBox(
                              height: 5,
                            ),

                            Text(
                              'Administrado por ${tienda.propietario}',

                              style:
                                  TextStyle(
                                color:
                                    Colors.white
                                        .withValues(
                                  alpha:
                                      0.78,
                                ),

                                fontSize:
                                    12,

                                fontFamily:
                                    'Outfit',
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 20,
                ),

                // ===============================================
                // BOTONES
                // ===============================================

                Wrap(
                  spacing:
                      10,

                  runSpacing:
                      10,

                  children: [
                    FilledButton.icon(
                      style:
                          FilledButton.styleFrom(
                        backgroundColor:
                            Colors.white,

                        foregroundColor:
                            AppColors.naranja,
                      ),

                      onPressed:
                          _verTiendaPublica,

                      icon:
                          const Icon(
                        Icons
                            .visibility_outlined,
                      ),

                      label:
                          const Text(
                        'Ver tienda',
                      ),
                    ),

                    OutlinedButton.icon(
                      style:
                          OutlinedButton.styleFrom(
                        foregroundColor:
                            Colors.white,

                        side:
                            const BorderSide(
                          color:
                              Colors.white,
                        ),
                      ),

                      onPressed:
                          _abrirMiTienda,

                      icon:
                          const Icon(
                        Icons
                            .edit_outlined,
                      ),

                      label:
                          const Text(
                        'Administrar',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SIN TIENDA
  // ============================================================

  Widget _sinTienda() {
    return Container(
      padding:
          const EdgeInsets.all(
        24,
      ),

      decoration:
          BoxDecoration(
        color:
            AppColors.naranja
                .withValues(
          alpha:
              0.09,
        ),

        borderRadius:
            BorderRadius.circular(
          24,
        ),

        border:
            Border.all(
          color:
              AppColors.naranja
                  .withValues(
            alpha:
                0.30,
          ),
        ),
      ),

      child:
          Column(
        children: [
          Container(
            width:
                70,

            height:
                70,

            decoration:
                BoxDecoration(
              color:
                  AppColors.naranja
                      .withValues(
                alpha:
                    0.14,
              ),

              shape:
                  BoxShape.circle,
            ),

            child:
                const Icon(
              Icons
                  .storefront_outlined,

              color:
                  AppColors.naranja,

              size:
                  36,
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          const Text(
            'Configura tu negocio',

            textAlign:
                TextAlign.center,

            style:
                TextStyle(
              fontSize:
                  21,

              fontWeight:
                  FontWeight.w900,

              fontFamily:
                  'Outfit',
            ),
          ),

          const SizedBox(
            height: 7,
          ),

          Text(
            'Necesitas configurar tu tienda antes de publicar productos o contenido comercial.',

            textAlign:
                TextAlign.center,

            style:
                TextStyle(
              color:
                  Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(
                        alpha:
                            0.62,
                      ),

              fontSize:
                  13.5,

              height:
                  1.4,

              fontFamily:
                  'Outfit',
            ),
          ),

          const SizedBox(
            height: 18,
          ),

          FilledButton.icon(
            onPressed:
                _abrirMiTienda,

            icon:
                const Icon(
              Icons
                  .add_business_outlined,
            ),

            label:
                const Text(
              'Configurar mi tienda',
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RESUMEN RESPONSIVE
  // ============================================================

  Widget _resumenResponsive({
    required Color borde,
    required Color textoSecundario,
  }) {
    return LayoutBuilder(
      builder:
          (
            context,
            constraints,
          ) {
        final bool escritorio =
            constraints.maxWidth >=
                700;

        final double ancho;

        if (escritorio) {
          ancho =
              (constraints.maxWidth -
                      36) /
                  4;
        } else {
          ancho =
              (constraints.maxWidth -
                      12) /
                  2;
        }

        return Wrap(
          spacing:
              12,

          runSpacing:
              12,

          children: [
            SizedBox(
              width:
                  ancho,

              child:
                  _tarjetaResumen(
                icono:
                    Icons
                        .inventory_2_outlined,

                valor:
                    '$totalProductos',

                titulo:
                    'Productos',

                onTap:
                    _abrirProductos,

                borde:
                    borde,

                textoSecundario:
                    textoSecundario,
              ),
            ),

            SizedBox(
              width:
                  ancho,

              child:
                  _tarjetaResumen(
                icono:
                    Icons
                        .article_outlined,

                valor:
                    '$totalPublicaciones',

                titulo:
                    'Publicaciones',

                onTap:
                    _abrirPublicaciones,

                borde:
                    borde,

                textoSecundario:
                    textoSecundario,
              ),
            ),

            SizedBox(
              width:
                  ancho,

              child:
                  _tarjetaResumen(
                icono:
                    Icons
                        .chat_bubble_outline_rounded,

                valor:
                    '$totalConversaciones',

                titulo:
                    'Conversaciones',

                onTap:
                    _abrirMensajes,

                borde:
                    borde,

                textoSecundario:
                    textoSecundario,
              ),
            ),

            SizedBox(
              width:
                  ancho,

              child:
                  _tarjetaResumen(
                icono:
                    Icons
                        .mark_chat_unread_outlined,

                valor:
                    '$mensajesNoLeidos',

                titulo:
                    'No leídos',

                onTap:
                    _abrirMensajes,

                borde:
                    borde,

                textoSecundario:
                    textoSecundario,
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // TARJETA RESUMEN
  // ============================================================

  Widget _tarjetaResumen({
    required IconData icono,
    required String valor,
    required String titulo,
    required VoidCallback onTap,
    required Color borde,
    required Color textoSecundario,
  }) {
    return Material(
      color:
          Theme.of(context).cardColor,

      borderRadius:
          BorderRadius.circular(
        20,
      ),

      child:
          InkWell(
        onTap:
            onTap,

        borderRadius:
            BorderRadius.circular(
          20,
        ),

        child:
            Container(
          padding:
              const EdgeInsets.all(
            16,
          ),

          decoration:
              BoxDecoration(
            borderRadius:
                BorderRadius.circular(
              20,
            ),

            border:
                Border.all(
              color:
                  borde,
            ),
          ),

          child:
              Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Container(
                width:
                    42,

                height:
                    42,

                decoration:
                    BoxDecoration(
                  color:
                      AppColors.naranja
                          .withValues(
                    alpha:
                        0.10,
                  ),

                  borderRadius:
                      BorderRadius.circular(
                    13,
                  ),
                ),

                child:
                    Icon(
                  icono,

                  color:
                      AppColors.naranja,

                  size:
                      22,
                ),
              ),

              const SizedBox(
                height: 13,
              ),

              Text(
                valor,

                style:
                    const TextStyle(
                  fontSize:
                      24,

                  height:
                      1,

                  fontWeight:
                      FontWeight.w900,

                  fontFamily:
                      'Outfit',
                ),
              ),

              const SizedBox(
                height: 5,
              ),

              Text(
                titulo,

                style:
                    TextStyle(
                  color:
                      textoSecundario,

                  fontSize:
                      12.5,

                  fontWeight:
                      FontWeight.w600,

                  fontFamily:
                      'Outfit',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ACCIONES RÁPIDAS
  // ============================================================

  Widget _accionesRapidas() {
    return LayoutBuilder(
      builder:
          (
            context,
            constraints,
          ) {
        final bool horizontal =
            constraints.maxWidth >=
                600;

        if (horizontal) {
          return Row(
            children: [
              Expanded(
                child:
                    _botonAccion(
                  icono:
                      Icons
                          .add_box_outlined,

                  titulo:
                      'Nuevo producto',

                  onTap:
                      _crearProducto,
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child:
                    _botonAccion(
                  icono:
                      Icons
                          .post_add_rounded,

                  titulo:
                      'Nueva publicación',

                  onTap:
                      _crearPublicacion,
                ),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,

          children: [
            _botonAccion(
              icono:
                  Icons
                      .add_box_outlined,

              titulo:
                  'Nuevo producto',

              onTap:
                  _crearProducto,
            ),

            const SizedBox(
              height: 10,
            ),

            _botonAccion(
              icono:
                  Icons
                      .post_add_rounded,

              titulo:
                  'Nueva publicación',

              onTap:
                  _crearPublicacion,
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // BOTÓN ACCIÓN
  // ============================================================

  Widget _botonAccion({
    required IconData icono,
    required String titulo,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height:
          54,

      child:
          FilledButton.icon(
        onPressed:
            onTap,

        icon:
            Icon(
          icono,
        ),

        label:
            Text(
          titulo,
        ),
      ),
    );
  }

  // ============================================================
  // ADMINISTRACIÓN RESPONSIVE
  // ============================================================

  Widget _administracionResponsive({
    required Color borde,
    required Color textoSecundario,
  }) {
    return LayoutBuilder(
      builder:
          (
            context,
            constraints,
          ) {
        final bool escritorio =
            constraints.maxWidth >=
                720;

        final double ancho =
            escritorio
                ? (constraints.maxWidth -
                        12) /
                    2
                : constraints.maxWidth;

        return Wrap(
          spacing:
              12,

          runSpacing:
              12,

          children: [
            SizedBox(
              width:
                  ancho,

              child:
                  _tarjetaGestion(
                icono:
                    Icons
                        .storefront_outlined,

                titulo:
                    'Mi tienda',

                descripcion:
                    'Información, imágenes, contacto y ubicación comercial.',

                onTap:
                    _abrirMiTienda,

                borde:
                    borde,

                textoSecundario:
                    textoSecundario,
              ),
            ),

            SizedBox(
              width:
                  ancho,

              child:
                  _tarjetaGestion(
                icono:
                    Icons
                        .inventory_2_outlined,

                titulo:
                    'Productos',

                descripcion:
                    'Crea, edita y administra el catálogo de tu negocio.',

                onTap:
                    _abrirProductos,

                borde:
                    borde,

                textoSecundario:
                    textoSecundario,
              ),
            ),

            SizedBox(
              width:
                  ancho,

              child:
                  _tarjetaGestion(
                icono:
                    Icons
                        .article_outlined,

                titulo:
                    'Publicaciones',

                descripcion:
                    'Administra las publicaciones comerciales de tu tienda.',

                onTap:
                    _abrirPublicaciones,

                borde:
                    borde,

                textoSecundario:
                    textoSecundario,
              ),
            ),

            SizedBox(
              width:
                  ancho,

              child:
                  _tarjetaGestion(
                icono:
                    Icons
                        .chat_bubble_outline_rounded,

                titulo:
                    'Mensajes',

                descripcion:
                    mensajesNoLeidos > 0
                        ? 'Tienes $mensajesNoLeidos mensajes pendientes de leer.'
                        : 'Consulta las conversaciones con tus clientes.',

                onTap:
                    _abrirMensajes,

                borde:
                    borde,

                textoSecundario:
                    textoSecundario,

                badge:
                    mensajesNoLeidos > 0
                        ? '$mensajesNoLeidos'
                        : null,
              ),
            ),

            SizedBox(
              width:
                  ancho,

              child:
                  _tarjetaGestion(
                icono:
                    Icons
                        .business_outlined,

                titulo:
                    'Locales comerciales',

                descripcion:
                    'Consulta o administra oportunidades de locales comerciales.',

                onTap:
                    _abrirLocales,

                borde:
                    borde,

                textoSecundario:
                    textoSecundario,
              ),
            ),

            if (emprendimiento != null)
              SizedBox(
                width:
                    ancho,

                child:
                    _tarjetaGestion(
                  icono:
                      Icons
                          .visibility_outlined,

                  titulo:
                      'Ver como cliente',

                  descripcion:
                      'Revisa cómo ven los usuarios tu tienda y catálogo.',

                  onTap:
                      _verTiendaPublica,

                  borde:
                      borde,

                  textoSecundario:
                      textoSecundario,
                ),
              ),
          ],
        );
      },
    );
  }

  // ============================================================
  // TARJETA GESTIÓN
  // ============================================================

  Widget _tarjetaGestion({
    required IconData icono,
    required String titulo,
    required String descripcion,
    required VoidCallback onTap,
    required Color borde,
    required Color textoSecundario,
    String? badge,
  }) {
    return Material(
      color:
          Theme.of(context).cardColor,

      borderRadius:
          BorderRadius.circular(
        20,
      ),

      child:
          InkWell(
        onTap:
            onTap,

        borderRadius:
            BorderRadius.circular(
          20,
        ),

        child:
            Container(
          padding:
              const EdgeInsets.all(
            17,
          ),

          decoration:
              BoxDecoration(
            borderRadius:
                BorderRadius.circular(
              20,
            ),

            border:
                Border.all(
              color:
                  borde,
            ),
          ),

          child:
              Row(
            children: [
              // =================================================
              // ICONO
              // =================================================

              Stack(
                clipBehavior:
                    Clip.none,

                children: [
                  Container(
                    width:
                        50,

                    height:
                        50,

                    decoration:
                        BoxDecoration(
                      color:
                          AppColors.naranja
                              .withValues(
                        alpha:
                            0.10,
                      ),

                      borderRadius:
                          BorderRadius.circular(
                        15,
                      ),
                    ),

                    child:
                        Icon(
                      icono,

                      color:
                          AppColors.naranja,

                      size:
                          25,
                    ),
                  ),

                  if (badge != null)
                    Positioned(
                      right:
                          -7,

                      top:
                          -7,

                      child:
                          Container(
                        constraints:
                            const BoxConstraints(
                          minWidth:
                              21,

                          minHeight:
                              21,
                        ),

                        padding:
                            const EdgeInsets.symmetric(
                          horizontal:
                              5,
                        ),

                        alignment:
                            Alignment.center,

                        decoration:
                            const BoxDecoration(
                          color:
                              AppColors.naranja,

                          shape:
                              BoxShape.circle,
                        ),

                        child:
                            Text(
                          badge,

                          style:
                              const TextStyle(
                            color:
                                Colors.white,

                            fontSize:
                                10,

                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(
                width: 14,
              ),

              // =================================================
              // TEXTO
              // =================================================

              Expanded(
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Text(
                      titulo,

                      style:
                          const TextStyle(
                        fontSize:
                            15.5,

                        fontWeight:
                            FontWeight.w800,

                        fontFamily:
                            'Outfit',
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    Text(
                      descripcion,

                      style:
                          TextStyle(
                        color:
                            textoSecundario,

                        fontSize:
                            12.5,

                        height:
                            1.35,

                        fontFamily:
                            'Outfit',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              Icon(
                Icons
                    .chevron_right_rounded,

                color:
                    textoSecundario,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TÍTULO
  // ============================================================

  Widget _tituloSeccion({
    required IconData icono,
    required String titulo,
  }) {
    return Row(
      children: [
        Icon(
          icono,

          color:
              AppColors.naranja,

          size:
              24,
        ),

        const SizedBox(
          width: 9,
        ),

        Text(
          titulo,

          style:
              const TextStyle(
            fontSize:
                20,

            fontWeight:
                FontWeight.w900,

            fontFamily:
                'Outfit',
          ),
        ),
      ],
    );
  }
}