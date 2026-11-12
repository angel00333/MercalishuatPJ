import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/app_theme.dart';

import '../models/publicacion.dart';

import '../services/auth_service.dart';
import '../services/publicacion_service.dart';
import '../services/session_service.dart';

import '../widgets/campana_notificaciones.dart';

import 'locales/locales_comerciales_screen.dart';

import 'publicaciones/detalle_publicacion_screen.dart';
import 'publicaciones/feed_screen.dart';
import 'publicaciones/guardados_screen.dart';

class InicioUsuarioScreen
    extends StatefulWidget {
  final VoidCallback onExplorar;

  final VoidCallback onMapa;

  final VoidCallback onMensajes;

  const InicioUsuarioScreen({
    super.key,
    required this.onExplorar,
    required this.onMapa,
    required this.onMensajes,
  });

  @override
  State<InicioUsuarioScreen>
      createState() =>
          _InicioUsuarioScreenState();
}

class _InicioUsuarioScreenState
    extends State<InicioUsuarioScreen> {
  // ============================================================
  // BANNERS
  // ============================================================

  static const List<String>
      _banners = [
    'assets/banners/banner1.png',
    'assets/banners/banner2.png',
    'assets/banners/banner3.png',
    'assets/banners/banner4.png',
    'assets/banners/banner5.png',
    'assets/banners/banner6.png',
  ];

  final PageController
      _bannerController =
      PageController();

  Timer? _bannerTimer;

  int _bannerActual =
      0;

  // ============================================================
  // USUARIO
  // ============================================================

  String _nombre =
      'Usuario';

  String? _fotoPerfilUrl;

  bool _cargandoPerfil =
      true;

  // ============================================================
  // PUBLICACIONES
  // ============================================================

  List<Publicacion>
      _publicaciones =
      [];

  bool _cargandoPublicaciones =
      true;

  String? _errorPublicaciones;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _cargarTodo();

    _iniciarCarrusel();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _bannerTimer
        ?.cancel();

    _bannerController
        .dispose();

    super.dispose();
  }

  // ============================================================
  // CARGAR TODO
  // ============================================================

  Future<void> _cargarTodo() async {
    await Future.wait([
      _cargarPerfil(),
      _cargarPublicaciones(),
    ]);
  }

  // ============================================================
  // PERFIL
  // ============================================================

  Future<void> _cargarPerfil() async {
    try {
      final resultado =
          await AuthService
              .obtenerPerfil();

      if (!mounted) {
        return;
      }

      if (resultado['success'] ==
          true) {
        final usuario =
            resultado[
                'usuario'];

        if (usuario is Map) {
          final nombre =
              usuario['nombre']
                  ?.toString()
                  .trim();

          final foto =
              usuario[
                      'foto_perfil_url']
                  ?.toString()
                  .trim();

          setState(() {
            _nombre =
                nombre != null &&
                        nombre.isNotEmpty
                    ? nombre
                    : 'Usuario';

            _fotoPerfilUrl =
                foto != null &&
                        foto.isNotEmpty &&
                        foto.toLowerCase() !=
                            'null'
                    ? foto
                    : null;

            _cargandoPerfil =
                false;
          });

          return;
        }
      }

      await _cargarPerfilLocal();
    } catch (_) {
      await _cargarPerfilLocal();
    }
  }

  // ============================================================
  // FALLBACK LOCAL
  // ============================================================

  Future<void>
      _cargarPerfilLocal() async {
    final nombre =
        await SessionService
            .obtenerNombre();

    if (!mounted) {
      return;
    }

    setState(() {
      _nombre =
          nombre?.trim().isNotEmpty ==
                  true
              ? nombre!.trim()
              : 'Usuario';

      _fotoPerfilUrl =
          null;

      _cargandoPerfil =
          false;
    });
  }

  // ============================================================
  // PUBLICACIONES
  // ============================================================

  Future<void>
      _cargarPublicaciones() async {
    if (mounted) {
      setState(() {
        _cargandoPublicaciones =
            true;

        _errorPublicaciones =
            null;
      });
    }

    try {
      final resultado =
          await PublicacionService.feed(
        pagina:
            1,

        limite:
            3,
      );

      if (!mounted) {
        return;
      }

      if (resultado['success'] ==
          true) {
        final raw =
            resultado[
                'publicaciones'];

        setState(() {
          _publicaciones =
              raw is List
                  ? raw
                      .whereType<
                          Publicacion>()
                      .take(
                        3,
                      )
                      .toList()
                  : [];

          _cargandoPublicaciones =
              false;
        });

        return;
      }

      setState(() {
        _errorPublicaciones =
            resultado['message']
                    ?.toString() ??
                'No se pudieron cargar las publicaciones';

        _cargandoPublicaciones =
            false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorPublicaciones =
            'No se pudieron cargar las publicaciones';

        _cargandoPublicaciones =
            false;
      });
    }
  }

  // ============================================================
  // CARRUSEL
  // ============================================================

  void _iniciarCarrusel() {
    _bannerTimer =
        Timer.periodic(
      const Duration(
        seconds:
            5,
      ),
      (
        _,
      ) {
        if (!mounted ||
            !_bannerController
                .hasClients) {
          return;
        }

        final siguiente =
            (_bannerActual + 1) %
                _banners.length;

        _bannerController
            .animateToPage(
          siguiente,

          duration:
              const Duration(
            milliseconds:
                500,
          ),

          curve:
              Curves.easeInOut,
        );
      },
    );
  }

  // ============================================================
  // PRIMER NOMBRE
  // ============================================================

  String get _primerNombre {
    final nombre =
        _nombre.trim();

    if (nombre.isEmpty) {
      return 'Usuario';
    }

    return nombre
        .split(
          RegExp(
            r'\s+',
          ),
        )
        .first;
  }

  // ============================================================
  // INICIAL
  // ============================================================

  String get _inicial {
    final nombre =
        _nombre.trim();

    if (nombre.isEmpty) {
      return 'U';
    }

    return nombre[0]
        .toUpperCase();
  }

  // ============================================================
  // NAVEGACIONES
  // ============================================================

  void _abrirLocales() {
    Navigator.of(
      context,
    ).push(
      MaterialPageRoute(
        builder:
            (_) =>
                const LocalesComercialesScreen(
          puedePublicar:
              false,
        ),
      ),
    );
  }

  void _abrirGuardados() {
    Navigator.of(
      context,
    ).push(
      MaterialPageRoute(
        builder:
            (_) =>
                const GuardadosScreen(),
      ),
    );
  }

  void _abrirFeed() {
    Navigator.of(
      context,
    ).push(
      MaterialPageRoute(
        builder:
            (_) =>
                const FeedScreen(),
      ),
    );
  }

  Future<void> _abrirPublicacion(
    Publicacion publicacion,
  ) async {
    await Navigator.of(
      context,
    ).push(
      MaterialPageRoute(
        builder:
            (_) =>
                DetallePublicacionScreen(
          publicacionId:
              publicacion.id,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    await _cargarPublicaciones();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final oscuro =
        Theme.of(context)
                .brightness ==
            Brightness.dark;

    return Scaffold(
      body:
          SafeArea(
        bottom:
            false,

        child:
            RefreshIndicator(
          onRefresh:
              _cargarTodo,

          child:
              LayoutBuilder(
            builder:
                (
              context,
              constraints,
            ) {
              return ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),

                padding:
                    const EdgeInsets.only(
                  bottom:
                      32,
                ),

                children: [
                  Center(
                    child:
                        ConstrainedBox(
                      constraints:
                          const BoxConstraints(
                        maxWidth:
                            760,
                      ),

                      child:
                          Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.stretch,

                        children: [
                          // =====================================
                          // MARCA
                          // =====================================

                          _marca(
                            oscuro,
                          ),

                          // =====================================
                          // HERO
                          // =====================================

                          _hero(
                            oscuro,
                          ),

                          const SizedBox(
                            height:
                                18,
                          ),

                          // =====================================
                          // BUSCADOR
                          // =====================================

                          _buscador(
                            oscuro,
                          ),

                          const SizedBox(
                            height:
                                20,
                          ),

                          // =====================================
                          // BANNERS
                          // =====================================

                          _carrusel(),

                          const SizedBox(
                            height:
                                26,
                          ),

                          // =====================================
                          // ACCESOS
                          // =====================================

                          _encabezadoSeccion(
                            titulo:
                                'Accesos rápidos',

                            icono:
                                Icons.bolt_rounded,

                            accion:
                                'Guardados',

                            onAccion:
                                _abrirGuardados,
                          ),

                          const SizedBox(
                            height:
                                12,
                          ),

                          _accesosRapidos(
                            oscuro,
                          ),

                          const SizedBox(
                            height:
                                28,
                          ),

                          // =====================================
                          // PUBLICACIONES
                          // =====================================

                          _encabezadoSeccion(
                            titulo:
                                'Publicaciones recientes',

                            icono:
                                Icons.layers_rounded,

                            accion:
                                'Ver todas',

                            onAccion:
                                _abrirFeed,
                          ),

                          const SizedBox(
                            height:
                                12,
                          ),

                          _contenidoPublicaciones(
                            oscuro,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MARCA
  // ============================================================

  Widget _marca(
    bool oscuro,
  ) {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        20,
        14,
        20,
        10,
      ),

      child:
          Row(
        children: [
          SizedBox(
            width:
                44,

            height:
                44,

            child:
                Image.asset(
              'assets/logo.png',

              fit:
                  BoxFit.contain,

              errorBuilder:
                  (
                context,
                error,
                stackTrace,
              ) {
                return const Icon(
                  Icons.storefront_rounded,

                  color:
                      AppColors.naranja,

                  size:
                      34,
                );
              },
            ),
          ),

          const SizedBox(
            width:
                8,
          ),

          RichText(
            text:
                TextSpan(
              style:
                  const TextStyle(
                fontFamily:
                    'Outfit',

                fontSize:
                    24,

                fontWeight:
                    FontWeight.w900,
              ),

              children: [
                TextSpan(
                  text:
                      'Mercali',

                  style:
                      TextStyle(
                    color:
                        oscuro
                            ? Colors.white
                            : AppColors.morado,
                  ),
                ),

                const TextSpan(
                  text:
                      'shuat',

                  style:
                      TextStyle(
                    color:
                        AppColors.naranja,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HERO
  // ============================================================

  Widget _hero(
    bool oscuro,
  ) {
    final colores =
        oscuro
            ? const [
                Color(
                  0xFF6D228D,
                ),
                Color(
                  0xFF9B2E83,
                ),
                Color(
                  0xFFB83868,
                ),
              ]
            : const [
                Color(
                  0xFFFF7E01,
                ),
                Color(
                  0xFFFF8E1C,
                ),
                Color(
                  0xFFFFA347,
                ),
              ];

    return Container(
      margin:
          const EdgeInsets.symmetric(
        horizontal:
            16,
      ),

      decoration:
          BoxDecoration(
        borderRadius:
            BorderRadius.circular(
          30,
        ),

        boxShadow: [
          BoxShadow(
            color:
                (
                  oscuro
                      ? AppColors.moradoClaro
                      : AppColors.naranja
                ).withValues(
              alpha:
                  oscuro
                      ? 0.18
                      : 0.25,
            ),

            blurRadius:
                24,

            offset:
                const Offset(
              0,
              10,
            ),
          ),
        ],
      ),

      child:
          ClipRRect(
        borderRadius:
            BorderRadius.circular(
          30,
        ),

        child:
            Stack(
          children: [
            Positioned.fill(
              child:
                  Container(
                decoration:
                    BoxDecoration(
                  gradient:
                      LinearGradient(
                    begin:
                        Alignment.topLeft,

                    end:
                        Alignment.bottomRight,

                    colors:
                        colores,
                  ),
                ),
              ),
            ),

            // ================================================
            // GOTA MORADA / NARANJA GRANDE
            // ================================================

            Positioned(
              right:
                  -35,

              top:
                  -50,

              child:
                  _GotaDecorativa(
                width:
                    150,

                height:
                    150,

                color:
                    (
                      oscuro
                          ? AppColors.naranja
                          : AppColors.morado
                    ).withValues(
                  alpha:
                      0.95,
                ),

                rotation:
                    0.65,
              ),
            ),

            // ================================================
            // GOTA TRANSPARENTE
            // ================================================

            Positioned(
              right:
                  90,

              bottom:
                  -55,

              child:
                  _GotaDecorativa(
                width:
                    120,

                height:
                    120,

                color:
                    Colors.white
                        .withValues(
                  alpha:
                      0.10,
                ),

                rotation:
                    -0.45,
              ),
            ),

            Positioned(
              left:
                  -40,

              bottom:
                  -55,

              child:
                  _GotaDecorativa(
                width:
                    105,

                height:
                    105,

                color:
                    (
                      oscuro
                          ? AppColors.naranja
                          : Colors.white
                    ).withValues(
                  alpha:
                      oscuro
                          ? 0.30
                          : 0.10,
                ),

                rotation:
                    0.8,
              ),
            ),

            Positioned(
              right:
                  115,

              top:
                  18,

              child:
                  Transform.rotate(
                angle:
                    0.7,

                child:
                    Container(
                  width:
                      25,

                  height:
                      12,

                  decoration:
                      BoxDecoration(
                    color:
                        Colors.white
                            .withValues(
                      alpha:
                          0.18,
                    ),

                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                  ),
                ),
              ),
            ),

            // ================================================
            // CONTENIDO
            // ================================================

            Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                18,
                22,
                16,
                22,
              ),

              child:
                  Row(
                children: [
                  _fotoPerfil(),

                  const SizedBox(
                    width:
                        14,
                  ),

                  Expanded(
                    child:
                        Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [
                        Text(
                          _cargandoPerfil
                              ? '¡Hola!'
                              : '¡Hola, $_primerNombre!',

                          maxLines:
                              1,

                          overflow:
                              TextOverflow.ellipsis,

                          style:
                              const TextStyle(
                            color:
                                Colors.white,

                            fontSize:
                                25,

                            height:
                                1,

                            fontWeight:
                                FontWeight.w900,
                          ),
                        ),

                        const SizedBox(
                          height:
                              7,
                        ),

                        Text(
                          '¿Qué deseas descubrir hoy?',

                          style:
                              TextStyle(
                            color:
                                Colors.white
                                    .withValues(
                              alpha:
                                  0.92,
                            ),

                            fontSize:
                                14,

                            fontWeight:
                                FontWeight.w500,
                          ),
                        ),

                        const SizedBox(
                          height:
                              12,
                        ),

                        Container(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal:
                                12,

                            vertical:
                                7,
                          ),

                          decoration:
                              BoxDecoration(
                            color:
                                Colors.white
                                    .withValues(
                              alpha:
                                  0.15,
                            ),

                            borderRadius:
                                BorderRadius.circular(
                              30,
                            ),

                            border:
                                Border.all(
                              color:
                                  Colors.white
                                      .withValues(
                                alpha:
                                    0.16,
                              ),
                            ),
                          ),

                          child:
                              const Row(
                            mainAxisSize:
                                MainAxisSize.min,

                            children: [
                              Icon(
                                Icons
                                    .location_on_outlined,

                                color:
                                    Colors.white,

                                size:
                                    16,
                              ),

                              SizedBox(
                                width:
                                    4,
                              ),

                              Text(
                                'Descubre lo local',

                                style:
                                    TextStyle(
                                  color:
                                      Colors.white,

                                  fontSize:
                                      12,

                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    width:
                        8,
                  ),

                  CampanaNotificaciones(
                    integrada:
                        true,

                    colorFondo:
                        Colors.white
                            .withValues(
                      alpha:
                          0.97,
                    ),

                    colorIcono:
                        AppColors.morado,

                    size:
                        54,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FOTO
  // ============================================================

  Widget _fotoPerfil() {
    return Container(
      width:
          68,

      height:
          68,

      padding:
          const EdgeInsets.all(
        3,
      ),

      decoration:
          BoxDecoration(
        color:
            Colors.white,

        shape:
            BoxShape.circle,

        boxShadow: [
          BoxShadow(
            color:
                Colors.black
                    .withValues(
              alpha:
                  0.16,
            ),

            blurRadius:
                14,

            offset:
                const Offset(
              0,
              5,
            ),
          ),
        ],
      ),

      child:
          ClipOval(
        child:
            _fotoPerfilUrl !=
                    null
                ? Image.network(
                    _fotoPerfilUrl!,

                    width:
                        62,

                    height:
                        62,

                    fit:
                        BoxFit.cover,

                    errorBuilder:
                        (
                      context,
                      error,
                      stackTrace,
                    ) {
                      return _avatarFallback();
                    },
                  )
                : _avatarFallback(),
      ),
    );
  }

  Widget _avatarFallback() {
    return Container(
      color:
          AppColors.morado,

      alignment:
          Alignment.center,

      child:
          Text(
        _inicial,

        style:
            const TextStyle(
          color:
              Colors.white,

          fontSize:
              25,

          fontWeight:
              FontWeight.w900,
        ),
      ),
    );
  }

  // ============================================================
  // BUSCADOR
  // ============================================================

  Widget _buscador(
    bool oscuro,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal:
            18,
      ),

      child:
          Container(
        decoration:
            BoxDecoration(
          borderRadius:
              BorderRadius.circular(
            21,
          ),

          boxShadow: [
            BoxShadow(
              color:
                  Colors.black
                      .withValues(
                alpha:
                    oscuro
                        ? 0.12
                        : 0.07,
              ),

              blurRadius:
                  15,

              offset:
                  const Offset(
                0,
                5,
              ),
            ),
          ],
        ),

        child:
            TextField(
          readOnly:
              true,

          onTap:
              widget.onExplorar,

          decoration:
              InputDecoration(
            hintText:
                'Buscar emprendimientos, productos...',

            prefixIcon:
                const Icon(
              Icons.search_rounded,

              size:
                  28,
            ),

            suffixIcon:
                Container(
              margin:
                  const EdgeInsets.all(
                7,
              ),

              decoration:
                  BoxDecoration(
                color:
                    AppColors.morado
                        .withValues(
                  alpha:
                      oscuro
                          ? 0.35
                          : 0.08,
                ),

                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
              ),

              child:
                  const Icon(
                Icons.tune_rounded,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CARRUSEL
  // ============================================================

  Widget _carrusel() {
    return Column(
      children: [
        Padding(
          padding:
              const EdgeInsets.symmetric(
            horizontal:
                18,
          ),

          child:
              Container(
            decoration:
                BoxDecoration(
              borderRadius:
                  BorderRadius.circular(
                25,
              ),

              boxShadow: [
                BoxShadow(
                  color:
                      Colors.black
                          .withValues(
                    alpha:
                        0.10,
                  ),

                  blurRadius:
                      18,

                  offset:
                      const Offset(
                    0,
                    7,
                  ),
                ),
              ],
            ),

            child:
                ClipRRect(
              borderRadius:
                  BorderRadius.circular(
                25,
              ),

              child:
                  AspectRatio(
                aspectRatio:
                    827 / 413,

                child:
                    PageView.builder(
                  controller:
                      _bannerController,

                  itemCount:
                      _banners.length,

                  onPageChanged:
                      (
                        index,
                      ) {
                    if (!mounted) {
                      return;
                    }

                    setState(() {
                      _bannerActual =
                          index;
                    });
                  },

                  itemBuilder:
                      (
                        context,
                        index,
                      ) {
                    return GestureDetector(
                      onTap:
                          widget.onExplorar,

                      child:
                          Image.asset(
                        _banners[index],

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
                            color:
                                AppColors.morado,

                            alignment:
                                Alignment.center,

                            child:
                                const Icon(
                              Icons.image_outlined,

                              color:
                                  Colors.white,

                              size:
                                  48,
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),

        const SizedBox(
          height:
              11,
        ),

        Row(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children:
              List.generate(
            _banners.length,
            (
              index,
            ) {
              final activo =
                  index ==
                      _bannerActual;

              return AnimatedContainer(
                duration:
                    const Duration(
                  milliseconds:
                      250,
                ),

                margin:
                    const EdgeInsets.symmetric(
                  horizontal:
                      3,
                ),

                width:
                    activo
                        ? 22
                        : 7,

                height:
                    7,

                decoration:
                    BoxDecoration(
                  color:
                      activo
                          ? AppColors.naranja
                          : Theme.of(context)
                              .dividerColor,

                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ENCABEZADO SECCIÓN
  // ============================================================

  Widget _encabezadoSeccion({
    required String titulo,
    required IconData icono,
    required String accion,
    required VoidCallback onAccion,
  }) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal:
            18,
      ),

      child:
          Row(
        children: [
          Icon(
            icono,

            color:
                AppColors.naranja,

            size:
                26,
          ),

          const SizedBox(
            width:
                8,
          ),

          Expanded(
            child:
                Text(
              titulo,

              style:
                  Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(
                fontSize:
                    21,

                fontWeight:
                    FontWeight.w900,
              ),
            ),
          ),

          TextButton(
            onPressed:
                onAccion,

            style:
                TextButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(
                horizontal:
                    6,
              ),
            ),

            child:
                Row(
              mainAxisSize:
                  MainAxisSize.min,

              children: [
                Text(
                  accion,

                  style:
                      const TextStyle(
                    color:
                        AppColors.naranja,

                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                const Icon(
                  Icons.chevron_right_rounded,

                  color:
                      AppColors.naranja,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACCESOS RÁPIDOS
  // ============================================================

  Widget _accesosRapidos(
    bool oscuro,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal:
            18,
      ),

      child:
          Row(
        children: [
          Expanded(
            child:
                _TarjetaAcceso(
              titulo:
                  'Negocios',

              subtitulo:
                  'Emprendimientos',

              icono:
                  Icons.storefront_rounded,

              color:
                  AppColors.naranja,

              oscuro:
                  oscuro,

              onTap:
                  widget.onExplorar,
            ),
          ),

          const SizedBox(
            width:
                10,
          ),

          Expanded(
            child:
                _TarjetaAcceso(
              titulo:
                  'Cerca de mí',

              subtitulo:
                  'Ver mapa',

              icono:
                  Icons.location_on_rounded,

              color:
                  AppColors.moradoClaro,

              oscuro:
                  oscuro,

              onTap:
                  widget.onMapa,
            ),
          ),

          const SizedBox(
            width:
                10,
          ),

          Expanded(
            child:
                _TarjetaAcceso(
              titulo:
                  'Locales',

              subtitulo:
                  'Comerciales',

              icono:
                  Icons.apartment_rounded,

              color:
                  AppColors.naranja,

              oscuro:
                  oscuro,

              onTap:
                  _abrirLocales,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PUBLICACIONES
  // ============================================================

  Widget _contenidoPublicaciones(
    bool oscuro,
  ) {
    if (_cargandoPublicaciones) {
      return const Padding(
        padding:
            EdgeInsets.symmetric(
          vertical:
              38,
        ),

        child:
            Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    if (_errorPublicaciones !=
        null) {
      return Padding(
        padding:
            const EdgeInsets.symmetric(
          horizontal:
              18,
        ),

        child:
            Card(
          child:
              Padding(
            padding:
                const EdgeInsets.all(
              22,
            ),

            child:
                Column(
              children: [
                const Icon(
                  Icons.cloud_off_outlined,

                  color:
                      AppColors.naranja,

                  size:
                      42,
                ),

                const SizedBox(
                  height:
                      10,
                ),

                Text(
                  _errorPublicaciones!,

                  textAlign:
                      TextAlign.center,
                ),

                const SizedBox(
                  height:
                      8,
                ),

                TextButton.icon(
                  onPressed:
                      _cargarPublicaciones,

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
        ),
      );
    }

    if (_publicaciones.isEmpty) {
      return Padding(
        padding:
            const EdgeInsets.symmetric(
          horizontal:
              18,
        ),

        child:
            Card(
          child:
              Padding(
            padding:
                const EdgeInsets.all(
              24,
            ),

            child:
                Column(
              children: [
                const Icon(
                  Icons.article_outlined,

                  size:
                      44,

                  color:
                      AppColors.naranja,
                ),

                const SizedBox(
                  height:
                      10,
                ),

                const Text(
                  'No hay publicaciones recientes',

                  style:
                      TextStyle(
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                const SizedBox(
                  height:
                      5,
                ),

                Text(
                  'Las novedades de los emprendimientos aparecerán aquí.',

                  textAlign:
                      TextAlign.center,

                  style:
                      Theme.of(context)
                          .textTheme
                          .bodySmall,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children:
          _publicaciones
              .map(
                (
                  publicacion,
                ) =>
                    _tarjetaPublicacion(
                  publicacion,
                  oscuro,
                ),
              )
              .toList(),
    );
  }

  // ============================================================
  // TARJETA PUBLICACIÓN
  // ============================================================

  Widget _tarjetaPublicacion(
    Publicacion publicacion,
    bool oscuro,
  ) {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        18,
        0,
        18,
        14,
      ),

      child:
          Container(
        decoration:
            BoxDecoration(
          color:
              oscuro
                  ? AppColors.tarjetaOscura
                  : Colors.white,

          borderRadius:
              BorderRadius.circular(
            24,
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
                        ? 0.14
                        : 0.06,
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
            Material(
          color:
              Colors.transparent,

          borderRadius:
              BorderRadius.circular(
            24,
          ),

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
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                ListTile(
                  contentPadding:
                      const EdgeInsets.fromLTRB(
                    14,
                    9,
                    12,
                    4,
                  ),

                  leading:
                      CircleAvatar(
                    radius:
                        23,

                    backgroundColor:
                        AppColors.naranja,

                    backgroundImage:
                        publicacion.emprendimientoImagen !=
                                    null &&
                                publicacion
                                    .emprendimientoImagen!
                                    .trim()
                                    .isNotEmpty
                            ? NetworkImage(
                                publicacion
                                    .emprendimientoImagen!,
                              )
                            : null,

                    child:
                        publicacion.emprendimientoImagen ==
                                    null ||
                                publicacion
                                    .emprendimientoImagen!
                                    .trim()
                                    .isEmpty
                            ? const Icon(
                                Icons.storefront_rounded,

                                color:
                                    Colors.white,
                              )
                            : null,
                  ),

                  title:
                      Text(
                    publicacion
                            .emprendimientoNombre ??
                        'Emprendimiento',

                    maxLines:
                        1,

                    overflow:
                        TextOverflow.ellipsis,

                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),

                  subtitle:
                      Text(
                    _formatearFecha(
                      publicacion
                          .fechaCreacion,
                    ),
                  ),

                  trailing:
                      const Icon(
                    Icons.more_vert_rounded,
                  ),
                ),

                if (publicacion.texto
                    .trim()
                    .isNotEmpty)
                  Padding(
                    padding:
                        const EdgeInsets.fromLTRB(
                      16,
                      7,
                      16,
                      14,
                    ),

                    child:
                        Text(
                      publicacion.texto,

                      maxLines:
                          3,

                      overflow:
                          TextOverflow.ellipsis,

                      style:
                          const TextStyle(
                        fontSize:
                            15,
                      ),
                    ),
                  ),

                if (publicacion
                                .imagenPrincipal !=
                            null &&
                        publicacion
                            .imagenPrincipal!
                            .trim()
                            .isNotEmpty)
                  Image.network(
                    publicacion
                        .imagenPrincipal!,

                    width:
                        double.infinity,

                    height:
                        210,

                    fit:
                        BoxFit.cover,

                    errorBuilder:
                        (
                      context,
                      error,
                      stackTrace,
                    ) {
                      return Container(
                        width:
                            double.infinity,

                        height:
                            130,

                        alignment:
                            Alignment.center,

                        child:
                            const Icon(
                          Icons.broken_image_outlined,

                          color:
                              AppColors.naranja,

                          size:
                              40,
                        ),
                      );
                    },
                  ),

                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(
                    16,
                    12,
                    16,
                    14,
                  ),

                  child:
                      Row(
                    children: [
                      Icon(
                        publicacion.meGusta
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,

                        color:
                            publicacion.meGusta
                                ? AppColors.error
                                : null,

                        size:
                            20,
                      ),

                      const SizedBox(
                        width:
                            5,
                      ),

                      Text(
                        '${publicacion.totalMeGusta}',
                      ),

                      const SizedBox(
                        width:
                            18,
                      ),

                      const Icon(
                        Icons.chat_bubble_outline_rounded,

                        size:
                            19,
                      ),

                      const SizedBox(
                        width:
                            5,
                      ),

                      Text(
                        '${publicacion.totalComentarios}',
                      ),

                      const Spacer(),

                      const Text(
                        'Ver publicación',

                        style:
                            TextStyle(
                          color:
                              AppColors.naranja,

                          fontSize:
                              12,

                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),

                      const Icon(
                        Icons.chevron_right_rounded,

                        color:
                            AppColors.naranja,

                        size:
                            18,
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

    if (diferencia.inMinutes <
        1) {
      return 'Ahora';
    }

    if (diferencia.inHours <
        1) {
      return 'Hace ${diferencia.inMinutes} min';
    }

    if (diferencia.inHours <
        24) {
      return 'Hace ${diferencia.inHours} h';
    }

    if (diferencia.inDays <
        7) {
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
// TARJETA ACCESO RÁPIDO
// ============================================================

class _TarjetaAcceso
    extends StatelessWidget {
  final String titulo;

  final String subtitulo;

  final IconData icono;

  final Color color;

  final bool oscuro;

  final VoidCallback onTap;

  const _TarjetaAcceso({
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.color,
    required this.oscuro,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color:
          oscuro
              ? AppColors.tarjetaOscura
              : Colors.white,

      borderRadius:
          BorderRadius.circular(
        22,
      ),

      child:
          InkWell(
        onTap:
            onTap,

        borderRadius:
            BorderRadius.circular(
          22,
        ),

        child:
            Container(
          height:
              142,

          decoration:
              BoxDecoration(
            borderRadius:
                BorderRadius.circular(
              22,
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
                          ? 0.10
                          : 0.05,
                ),

                blurRadius:
                    12,

                offset:
                    const Offset(
                  0,
                  5,
                ),
              ),
            ],
          ),

          child:
              ClipRRect(
            borderRadius:
                BorderRadius.circular(
              22,
            ),

            child:
                Stack(
              children: [
                Positioned(
                  right:
                      -20,

                  top:
                      -22,

                  child:
                      _GotaDecorativa(
                    width:
                        64,

                    height:
                        64,

                    color:
                        color.withValues(
                      alpha:
                          oscuro
                              ? 0.28
                              : 0.16,
                    ),

                    rotation:
                        0.55,
                  ),
                ),

                Positioned(
                  left:
                      -22,

                  bottom:
                      -30,

                  child:
                      _GotaDecorativa(
                    width:
                        58,

                    height:
                        58,

                    color:
                        color.withValues(
                      alpha:
                          oscuro
                              ? 0.18
                              : 0.08,
                    ),

                    rotation:
                        -0.5,
                  ),
                ),

                Center(
                  child:
                      Padding(
                    padding:
                        const EdgeInsets.all(
                      10,
                    ),

                    child:
                        Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,

                      children: [
                        Container(
                          width:
                              50,

                          height:
                              50,

                          decoration:
                              BoxDecoration(
                            color:
                                color.withValues(
                              alpha:
                                  oscuro
                                      ? 0.28
                                      : 0.12,
                            ),

                            shape:
                                BoxShape.circle,
                          ),

                          child:
                              Icon(
                            icono,

                            color:
                                color,

                            size:
                                28,
                          ),
                        ),

                        const SizedBox(
                          height:
                              10,
                        ),

                        Text(
                          titulo,

                          maxLines:
                              1,

                          textAlign:
                              TextAlign.center,

                          overflow:
                              TextOverflow.ellipsis,

                          style:
                              const TextStyle(
                            fontSize:
                                14,

                            fontWeight:
                                FontWeight.w900,
                          ),
                        ),

                        const SizedBox(
                          height:
                              2,
                        ),

                        Text(
                          subtitulo,

                          maxLines:
                              2,

                          textAlign:
                              TextAlign.center,

                          overflow:
                              TextOverflow.ellipsis,

                          style:
                              Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                            fontSize:
                                11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// GOTA DECORATIVA
// ============================================================

class _GotaDecorativa
    extends StatelessWidget {
  final double width;

  final double height;

  final Color color;

  final double rotation;

  const _GotaDecorativa({
    required this.width,
    required this.height,
    required this.color,
    this.rotation = 0,
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
            width,

        height:
            height,

        decoration:
            BoxDecoration(
          color:
              color,

          borderRadius:
              BorderRadius.only(
            topLeft:
                Radius.circular(
              width,
            ),

            topRight:
                Radius.circular(
              width,
            ),

            bottomLeft:
                Radius.circular(
              width,
            ),

            bottomRight:
                Radius.circular(
              math.max(
                18,
                width * 0.22,
              ),
            ),
          ),
        ),
      ),
    );
  }
}