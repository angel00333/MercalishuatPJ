import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../services/theme_service.dart';

import '../chat/conversaciones_screen.dart';
import '../explorar/explorar_emprendimientos_screen.dart';
import '../inicio_usuario_screen.dart';
import '../mapa_screen.dart';
import '../perfil_screen.dart';

class UsuarioNavScreen extends StatefulWidget {
  final ThemeService themeService;

  const UsuarioNavScreen({
    super.key,
    required this.themeService,
  });

  @override
  State<UsuarioNavScreen> createState() =>
      _UsuarioNavScreenState();
}

class _UsuarioNavScreenState extends State<UsuarioNavScreen> {
  // ============================================================
  // PÁGINA ACTUAL
  // ============================================================

  int indexActual = 0;

  late final List<Widget> paginas;

  // ============================================================
  // MEDIDAS
  // ============================================================

  static const double alturaMenu = 72;

  // Proporción aproximada de assets/nav/nav.png
  // 2048 x 201
  static const double proporcionSkyline =
      2048 / 201;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    paginas = [
      // ========================================================
      // 0 - INICIO
      // ========================================================

      InicioUsuarioScreen(
        onExplorar: () {
          _cambiarPagina(1);
        },
        onMapa: () {
          _cambiarPagina(2);
        },
        onMensajes: () {
          _cambiarPagina(3);
        },
      ),

      // ========================================================
      // 1 - EXPLORAR
      // ========================================================

      const ExplorarEmprendimientosScreen(),

      // ========================================================
      // 2 - MAPA
      // ========================================================

      const MapaScreen(),

      // ========================================================
      // 3 - MENSAJES
      // ========================================================

      const ConversacionesScreen(),

      // ========================================================
      // 4 - PERFIL
      // ========================================================

      PerfilScreen(
        themeService: widget.themeService,
      ),
    ];
  }

  // ============================================================
  // CAMBIAR PÁGINA
  // ============================================================

  void _cambiarPagina(int index) {
    if (!mounted) {
      return;
    }

    if (index < 0 || index >= paginas.length) {
      return;
    }

    if (index == indexActual) {
      return;
    }

    setState(() {
      indexActual = index;
    });
  }

  // ============================================================
  // ANCHO DEL SKYLINE RESPONSIVE
  // ============================================================

  double _anchoSkyline(
    double anchoPantalla,
  ) {
    // PC grande
    if (anchoPantalla >= 1400) {
      return 760;
    }

    // Laptop / PC normal
    if (anchoPantalla >= 1000) {
      return 680;
    }

    // Tablet / web medio
    if (anchoPantalla >= 700) {
      return 600;
    }

    // Móvil
    return anchoPantalla;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final double anchoPantalla =
        MediaQuery.sizeOf(context).width;

    final double bottomInset =
        MediaQuery.paddingOf(context).bottom;

    final double anchoSkyline =
        _anchoSkyline(
      anchoPantalla,
    );

    final double alturaSkyline =
        anchoSkyline /
            proporcionSkyline;

    return Scaffold(
      // ========================================================
      // IMPORTANTE
      //
      // Permitimos que el body continúe detrás del nav para que
      // la transparencia real del PNG se vea correctamente.
      // ========================================================

      extendBody: true,

      backgroundColor:
          Theme.of(context)
              .scaffoldBackgroundColor,

      // ========================================================
      // BODY
      // ========================================================

      body: Stack(
        children: [
          // ====================================================
          // CONTENIDO DE LA APP
          // ====================================================
          //
          // Solo reservamos espacio para el menú inferior.
          //
          // NO reservamos espacio extra para el skyline.
          //
          // ====================================================

          Positioned.fill(
            child: Padding(
              padding:
                  EdgeInsets.only(
                bottom:
                    alturaMenu +
                    bottomInset,
              ),
              child: IndexedStack(
                index: indexActual,
                children: paginas,
              ),
            ),
          ),

          // ====================================================
          // SKYLINE SAN SALVADOR
          // ====================================================
          //
          // Visible en móvil Y web.
          //
          // Se dibuja encima del contenido.
          // El PNG mantiene su transparencia.
          //
          // ====================================================

          Positioned(
            left: 0,
            right: 0,

            bottom:
                alturaMenu +
                bottomInset -
                2,

            child:
                IgnorePointer(
              child: Center(
                child:
                    SizedBox(
                  width:
                      anchoSkyline,

                  height:
                      alturaSkyline,

                  child:
                      Image.asset(
                    'assets/nav/nav.png',

                    width:
                        anchoSkyline,

                    height:
                        alturaSkyline,

                    fit:
                        BoxFit.contain,

                    alignment:
                        Alignment.bottomCenter,

                    filterQuality:
                        FilterQuality.high,

                    gaplessPlayback:
                        true,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      // ========================================================
      // BOTTOM NAV
      // ========================================================

      bottomNavigationBar:
          _BarraUsuario(
        index:
            indexActual,

        onChanged:
            _cambiarPagina,
      ),
    );
  }
}

// ============================================================
// BARRA DE NAVEGACIÓN
// ============================================================

class _BarraUsuario extends StatelessWidget {
  final int index;

  final ValueChanged<int>
      onChanged;

  const _BarraUsuario({
    required this.index,
    required this.onChanged,
  });

  static const double
      alturaMenu = 72;

  @override
  Widget build(
    BuildContext context,
  ) {
    final bool oscuro =
        Theme.of(context)
                .brightness ==
            Brightness.dark;

    // ==========================================================
    // COLORES
    // ==========================================================

    final Color fondoMenu =
        oscuro
            ? AppColors
                .moradoOscuro
            : Colors.white;

    final Color
        iconoInactivo =
        oscuro
            ? AppColors
                .textoSecundarioOscuro
            : AppColors.morado;

    final Color
        textoInactivo =
        oscuro
            ? AppColors
                .textoSecundarioOscuro
            : AppColors
                .textoClaro;

    return Material(
      color:
          fondoMenu,

      elevation:
          0,

      child:
          SafeArea(
        top:
            false,

        child:
            Container(
          height:
              alturaMenu,

          decoration:
              BoxDecoration(
            color:
                fondoMenu,

            border:
                Border(
              top:
                  BorderSide(
                color:
                    oscuro
                        ? AppColors
                            .bordeOscuro
                        : AppColors
                            .bordeClaro,

                width:
                    0.6,
              ),
            ),

            boxShadow: [
              BoxShadow(
                color:
                    Colors.black
                        .withValues(
                  alpha:
                      oscuro
                          ? 0.18
                          : 0.07,
                ),

                blurRadius:
                    8,

                offset:
                    const Offset(
                  0,
                  -1,
                ),
              ),
            ],
          ),

          child:
              Center(
            child:
                ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxWidth:
                    760,
              ),

              child:
                  Padding(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal:
                      8,
                ),

                child:
                    Row(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .center,

                  children: [
                    // =============================================
                    // INICIO
                    // =============================================

                    Expanded(
                      child:
                          _ItemBarra(
                        seleccionado:
                            index ==
                                0,

                        icono:
                            Icons
                                .home_outlined,

                        iconoSeleccionado:
                            Icons
                                .home_rounded,

                        texto:
                            'Inicio',

                        colorIcono:
                            iconoInactivo,

                        colorTexto:
                            textoInactivo,

                        onTap:
                            () {
                          onChanged(
                            0,
                          );
                        },
                      ),
                    ),

                    // =============================================
                    // EXPLORAR
                    // =============================================

                    Expanded(
                      child:
                          _ItemBarra(
                        seleccionado:
                            index ==
                                1,

                        icono:
                            Icons
                                .search_rounded,

                        iconoSeleccionado:
                            Icons
                                .manage_search_rounded,

                        texto:
                            'Explorar',

                        colorIcono:
                            iconoInactivo,

                        colorTexto:
                            textoInactivo,

                        onTap:
                            () {
                          onChanged(
                            1,
                          );
                        },
                      ),
                    ),

                    // =============================================
                    // MAPA
                    // =============================================

                    Expanded(
                      child:
                          _ItemBarra(
                        seleccionado:
                            index ==
                                2,

                        icono:
                            Icons
                                .map_outlined,

                        iconoSeleccionado:
                            Icons
                                .map_rounded,

                        texto:
                            'Mapa',

                        colorIcono:
                            iconoInactivo,

                        colorTexto:
                            textoInactivo,

                        onTap:
                            () {
                          onChanged(
                            2,
                          );
                        },
                      ),
                    ),

                    // =============================================
                    // MENSAJES
                    // =============================================

                    Expanded(
                      child:
                          _ItemBarra(
                        seleccionado:
                            index ==
                                3,

                        icono:
                            Icons
                                .chat_bubble_outline_rounded,

                        iconoSeleccionado:
                            Icons
                                .chat_bubble_rounded,

                        texto:
                            'Mensajes',

                        colorIcono:
                            iconoInactivo,

                        colorTexto:
                            textoInactivo,

                        onTap:
                            () {
                          onChanged(
                            3,
                          );
                        },
                      ),
                    ),

                    // =============================================
                    // PERFIL
                    // =============================================

                    Expanded(
                      child:
                          _ItemBarra(
                        seleccionado:
                            index ==
                                4,

                        icono:
                            Icons
                                .person_outline_rounded,

                        iconoSeleccionado:
                            Icons
                                .person_rounded,

                        texto:
                            'Perfil',

                        colorIcono:
                            iconoInactivo,

                        colorTexto:
                            textoInactivo,

                        onTap:
                            () {
                          onChanged(
                            4,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ITEM DEL MENÚ
// ============================================================

class _ItemBarra extends StatelessWidget {
  final bool seleccionado;

  final IconData icono;

  final IconData
      iconoSeleccionado;

  final String texto;

  final Color colorIcono;

  final Color colorTexto;

  final VoidCallback onTap;

  const _ItemBarra({
    required this.seleccionado,
    required this.icono,
    required this.iconoSeleccionado,
    required this.texto,
    required this.colorIcono,
    required this.colorTexto,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color:
          Colors.transparent,

      child:
          InkWell(
        onTap:
            onTap,

        borderRadius:
            BorderRadius.circular(
          22,
        ),

        child:
            SizedBox(
          height:
              68,

          child:
              Column(
            mainAxisAlignment:
                MainAxisAlignment
                    .center,

            mainAxisSize:
                MainAxisSize.min,

            children: [
              // =================================================
              // CÁPSULA
              // =================================================

              AnimatedContainer(
                duration:
                    const Duration(
                  milliseconds:
                      220,
                ),

                curve:
                    Curves
                        .easeOutCubic,

                width:
                    seleccionado
                        ? 54
                        : 42,

                height:
                    36,

                alignment:
                    Alignment.center,

                decoration:
                    BoxDecoration(
                  // ===============================================
                  // ACTIVO SIEMPRE NARANJA
                  // ===============================================

                  color:
                      seleccionado
                          ? AppColors
                              .naranja
                          : Colors
                              .transparent,

                  borderRadius:
                      BorderRadius
                          .circular(
                    22,
                  ),

                  boxShadow:
                      seleccionado
                          ? [
                              BoxShadow(
                                color:
                                    AppColors
                                        .naranja
                                        .withValues(
                                  alpha:
                                      0.28,
                                ),

                                blurRadius:
                                    9,

                                offset:
                                    const Offset(
                                  0,
                                  3,
                                ),
                              ),
                            ]
                          : null,
                ),

                child:
                    AnimatedSwitcher(
                  duration:
                      const Duration(
                    milliseconds:
                        180,
                  ),

                  switchInCurve:
                      Curves
                          .easeOut,

                  switchOutCurve:
                      Curves
                          .easeIn,

                  child:
                      Icon(
                    seleccionado
                        ? iconoSeleccionado
                        : icono,

                    key:
                        ValueKey<bool>(
                      seleccionado,
                    ),

                    size:
                        23,

                    color:
                        seleccionado
                            ? Colors
                                .white
                            : colorIcono,
                  ),
                ),
              ),

              const SizedBox(
                height:
                    3,
              ),

              // =================================================
              // TEXTO
              // =================================================

              AnimatedDefaultTextStyle(
                duration:
                    const Duration(
                  milliseconds:
                      180,
                ),

                curve:
                    Curves
                        .easeOut,

                style:
                    TextStyle(
                  color:
                      seleccionado
                          ? AppColors
                              .naranja
                          : colorTexto,

                  fontSize:
                      10.5,

                  height:
                      1.05,

                  fontWeight:
                      seleccionado
                          ? FontWeight
                              .w800
                          : FontWeight
                              .w600,

                  fontFamily:
                      'Outfit',
                ),

                child:
                    Text(
                  texto,

                  maxLines:
                      1,

                  overflow:
                      TextOverflow
                          .ellipsis,

                  textAlign:
                      TextAlign
                          .center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}