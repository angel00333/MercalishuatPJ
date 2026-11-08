import 'package:flutter/material.dart';

import '../../models/admin_dashboard.dart';
import '../../services/admin_service.dart';
import '../../services/session_service.dart';
import '../../services/theme_service.dart';
import '../login_screen.dart';
import 'admin_usuarios_screen.dart';
import 'admin_reportes_screen.dart';
import 'admin_locales_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final ThemeService themeService;

  const AdminDashboardScreen({
    super.key,
    required this.themeService,
  });

  @override
  State<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState
    extends State<AdminDashboardScreen> {
  AdminDashboard? _dashboard;

  bool _cargando = true;

  String? _error;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _cargarDashboard();
  }

  // ============================================================
  // CARGAR DASHBOARD
  // ============================================================

  Future<void> _cargarDashboard() async {
    if (mounted) {
      setState(() {
        _cargando = true;
        _error = null;
      });
    }

    try {
      final dashboard =
          await AdminService.obtenerDashboard();

      if (!mounted) {
        return;
      }

      setState(() {
        _dashboard = dashboard;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = e
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            );

        _cargando = false;
      });
    }
  }

  // ============================================================
  // CERRAR SESIÓN
  // ============================================================

  Future<void> _cerrarSesion() async {
    await SessionService.cerrarSesion();

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => LoginScreen(
          themeService: widget.themeService,
        ),
      ),
      (route) => false,
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

    final Color fondo = oscuro
        ? const Color(
            0xFF171320,
          )
        : const Color(
            0xFFF7F7F8,
          );

    return Scaffold(
      backgroundColor: fondo,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor: oscuro
            ? const Color(
                0xFF171320,
              )
            : const Color(
                0xFFFF7E01,
              ),

        surfaceTintColor:
            Colors.transparent,

        elevation: 0,

        // ======================================================
        // VOLVER AL PERFIL
        // ======================================================

        leading: IconButton(
          tooltip:
              'Volver al perfil',

          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),

          onPressed: () {
            Navigator.of(
              context,
            ).pop();
          },
        ),

        // ======================================================
        // TÍTULO
        // EN OSCURO NO MOSTRAR TEXTO EN APPBAR
        // ======================================================

        title: const Text(
  'Panel administrativo',
  style: TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.w800,
  ),
),

centerTitle: true,

        actions: [
          // ====================================================
          // ACTUALIZAR
          // ====================================================

          IconButton(
            tooltip:
                'Actualizar',

            onPressed:
                _cargarDashboard,

            icon: const Icon(
              Icons.refresh_rounded,
              color: Colors.white,
            ),
          ),

          // ====================================================
          // MENÚ
          // ====================================================

          PopupMenuButton<String>(
            iconColor:
                Colors.white,

            onSelected: (
              value,
            ) {
              if (value ==
                  'logout') {
                _cerrarSesion();
              }
            },

            itemBuilder: (
              context,
            ) =>
                const [
              PopupMenuItem(
                value:
                    'logout',

                child: Row(
                  children: [
                    Icon(
                      Icons.logout_rounded,
                    ),

                    SizedBox(
                      width: 12,
                    ),

                    Text(
                      'Cerrar sesión',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: RefreshIndicator(
        onRefresh:
            _cargarDashboard,

        child: _contenido(
          oscuro,
        ),
      ),
    );
  }

  // ============================================================
  // CONTENIDO
  // ============================================================

  Widget _contenido(
    bool oscuro,
  ) {
    // ==========================================================
    // CARGANDO
    // ==========================================================

    if (_cargando) {
      return ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),

        children: const [
          SizedBox(
            height: 200,
          ),

          Center(
            child:
                CircularProgressIndicator(
              color: Color(
                0xFFFF7E01,
              ),
            ),
          ),
        ],
      );
    }

    // ==========================================================
    // ERROR
    // ==========================================================

    if (_error != null) {
      return ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),

        padding:
            const EdgeInsets.all(
          24,
        ),

        children: [
          const SizedBox(
            height: 120,
          ),

          Icon(
            Icons.error_outline_rounded,
            size: 64,
            color:
                Colors.red.shade400,
          ),

          const SizedBox(
            height: 20,
          ),

          Text(
            _error!,
            textAlign:
                TextAlign.center,

            style:
                const TextStyle(
              fontSize: 16,
            ),
          ),

          const SizedBox(
            height: 20,
          ),

          Center(
            child:
                FilledButton.icon(
              onPressed:
                  _cargarDashboard,

              icon: const Icon(
                Icons.refresh_rounded,
              ),

              label: const Text(
                'Reintentar',
              ),

              style:
                  FilledButton.styleFrom(
                backgroundColor:
                    const Color(
                  0xFFFF7E01,
                ),

                foregroundColor:
                    Colors.white,
              ),
            ),
          ),
        ],
      );
    }

    final dashboard =
        _dashboard;

    if (dashboard == null) {
      return ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),

        children: const [
          SizedBox(
            height: 180,
          ),

          Center(
            child: Text(
              'No hay información disponible',
            ),
          ),
        ],
      );
    }

    // ==========================================================
    // DASHBOARD
    // ==========================================================

    return LayoutBuilder(
      builder: (
        context,
        constraints,
      ) {
        int columnas = 2;

        if (constraints.maxWidth >=
            900) {
          columnas = 4;
        } else if (
            constraints.maxWidth >=
                600) {
          columnas = 3;
        }

        return ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),

          padding:
              const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            32,
          ),

          children: [
            // =================================================
            // BANNER PANEL ADMINISTRATIVO
            // SIEMPRE VISIBLE
            // =================================================

            _encabezado(),

            const SizedBox(
              height: 24,
            ),

            // =================================================
            // ESTADÍSTICAS
            // =================================================

            GridView.count(
              crossAxisCount:
                  columnas,

              shrinkWrap:
                  true,

              physics:
                  const NeverScrollableScrollPhysics(),

              mainAxisSpacing:
                  14,

              crossAxisSpacing:
                  14,

              childAspectRatio:
                  columnas >= 3
                      ? 1.45
                      : 1.25,

              children: [
                _tarjetaEstadistica(
                  titulo:
                      'Usuarios',

                  cantidad:
                      dashboard.usuarios,

                  icono:
                      Icons.people_alt_outlined,

                  oscuro:
                      oscuro,
                ),

                _tarjetaEstadistica(
                  titulo:
                      'Emprendedores',

                  cantidad:
                      dashboard.emprendedores,

                  icono:
                      Icons.storefront_outlined,

                  oscuro:
                      oscuro,
                ),

                _tarjetaEstadistica(
                  titulo:
                      'Administradores',

                  cantidad:
                      dashboard.administradores,

                  icono:
                      Icons
                          .admin_panel_settings_outlined,

                  oscuro:
                      oscuro,
                ),

                _tarjetaEstadistica(
                  titulo:
                      'Emprendimientos',

                  cantidad:
                      dashboard.emprendimientos,

                  icono:
                      Icons.business_outlined,

                  oscuro:
                      oscuro,
                ),

                _tarjetaEstadistica(
                  titulo:
                      'Publicaciones',

                  cantidad:
                      dashboard.publicaciones,

                  icono:
                      Icons.article_outlined,

                  oscuro:
                      oscuro,
                ),

                _tarjetaEstadistica(
                  titulo:
                      'Comentarios',

                  cantidad:
                      dashboard.comentarios,

                  icono:
                      Icons.mode_comment_outlined,

                  oscuro:
                      oscuro,
                ),
              ],
            ),

            const SizedBox(
              height: 30,
            ),

            // =================================================
            // ADMINISTRACIÓN
            // =================================================

            Text(
              'Administración',

              style:
                  Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(
                fontWeight:
                    FontWeight.w700,
              ),
            ),

            const SizedBox(
              height: 14,
            ),

            // =================================================
            // GESTIONAR USUARIOS
            // =================================================

            _opcionAdministrativa(
              titulo:
                  'Gestionar usuarios',

              subtitulo:
                  'Consultar usuarios, roles y cuentas',

              icono:
                  Icons.manage_accounts_outlined,

              habilitado:
                  true,

              oscuro:
                  oscuro,

              onTap: () {
                Navigator.of(
                  context,
                ).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        const AdminUsuariosScreen(),
                  ),
                );
              },
            ),

            // =================================================
            // REPORTES Y MODERACIÓN
            // =================================================

            _opcionAdministrativa(
              titulo:
                  'Reportes y moderación',

              subtitulo:
                  'Revisar reportes y moderar contenido',

              icono:
                  Icons.flag_outlined,

              habilitado:
                  true,

              oscuro:
                  oscuro,

              onTap: () {
                Navigator.of(
                  context,
                ).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        const AdminReportesScreen(),
                  ),
                );
              },
            ),

            // =================================================
            // LOCALES COMERCIALES
            // =================================================

            

_opcionAdministrativa(
  titulo:
      'Locales comerciales',

  subtitulo:
      'Consultar y moderar locales publicados',

  icono:
      Icons.apartment_outlined,

  habilitado:
      true,

  oscuro:
      oscuro,

  onTap: () {
    Navigator.of(
      context,
    ).push(
      MaterialPageRoute(
        builder: (_) =>
            const AdminLocalesScreen(),
      ),
    );
  },
),

            // =================================================
            // MAPA ADMINISTRATIVO
            // =================================================

            _opcionAdministrativa(
              titulo:
                  'Mapa administrativo',

              subtitulo:
                  'Indicadores por departamento',

              icono:
                  Icons.map_outlined,

              habilitado:
                  false,

              oscuro:
                  oscuro,
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // BANNER PANEL ADMINISTRATIVO
  // SIEMPRE VISIBLE
  // ============================================================

  Widget _encabezado() {
    final dashboard =
        _dashboard!;

    return Container(
      width:
          double.infinity,

      padding:
          const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 20,
      ),

      decoration:
          BoxDecoration(
        borderRadius:
            BorderRadius.circular(
          20,
        ),

        gradient:
            const LinearGradient(
          begin:
              Alignment.topLeft,

          end:
              Alignment.bottomRight,

          colors: [
            Color(
              0xFFFF7E01,
            ),

            Color(
              0xFFFFA33B,
            ),
          ],
        ),

        boxShadow: [
          BoxShadow(
            color:
                const Color(
                  0xFFFF7E01,
                ).withValues(
              alpha:
                  0.18,
            ),

            blurRadius:
                18,

            offset:
                const Offset(
              0,
              8,
            ),
          ),
        ],
      ),

      child: Row(
        children: [
          Container(
            width:
                54,

            height:
                54,

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
                16,
              ),
            ),

            child:
                const Icon(
              Icons.dashboard_rounded,

              color:
                  Colors.white,

              size:
                  30,
            ),
          ),

          const SizedBox(
            width:
                16,
          ),

          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                const Text(
                  'Panel administrativo',

                  style:
                      TextStyle(
                    color:
                        Colors.white,

                    fontSize:
                        20,

                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                const SizedBox(
                  height:
                      5,
                ),

                Text(
                  '${dashboard.totalUsuarios} usuarios registrados',

                  style:
                      TextStyle(
                    color:
                        Colors.white
                            .withValues(
                      alpha:
                          0.90,
                    ),

                    fontSize:
                        14,

                    fontWeight:
                        FontWeight.w500,
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
  // TARJETA ESTADÍSTICA
  // ============================================================

  Widget _tarjetaEstadistica({
    required String titulo,
    required int cantidad,
    required IconData icono,
    required bool oscuro,
  }) {
    return Container(
      padding:
          const EdgeInsets.all(
        16,
      ),

      decoration:
          BoxDecoration(
        color: oscuro
            ? const Color(
                0xFF2A2045,
              )
            : Colors.white,

        borderRadius:
            BorderRadius.circular(
          18,
        ),

        border: Border.all(
          color: oscuro
              ? Colors.white
                  .withValues(
                  alpha:
                      0.06,
                )
              : Colors.black
                  .withValues(
                  alpha:
                      0.06,
                ),
        ),

        boxShadow:
            oscuro
                ? null
                : [
                    BoxShadow(
                      color:
                          Colors.black
                              .withValues(
                        alpha:
                            0.04,
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

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        mainAxisAlignment:
            MainAxisAlignment
                .spaceBetween,

        children: [
          Container(
            padding:
                const EdgeInsets.all(
              8,
            ),

            decoration:
                BoxDecoration(
              color:
                  const Color(
                    0xFFFF7E01,
                  ).withValues(
                alpha:
                    0.12,
              ),

              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),

            child: Icon(
              icono,

              color:
                  const Color(
                0xFFFF7E01,
              ),
            ),
          ),

          const SizedBox(
            height:
                10,
          ),

          Text(
            '$cantidad',

            style:
                const TextStyle(
              fontSize:
                  28,

              fontWeight:
                  FontWeight.w800,
            ),
          ),

          Text(
            titulo,

            maxLines:
                1,

            overflow:
                TextOverflow.ellipsis,

            style:
                TextStyle(
              fontSize:
                  13,

              color: oscuro
                  ? Colors.white70
                  : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // OPCIÓN ADMINISTRATIVA
  // ============================================================

  Widget _opcionAdministrativa({
    required String titulo,
    required String subtitulo,
    required IconData icono,
    required bool habilitado,
    required bool oscuro,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom:
            12,
      ),

      child: Material(
        color: oscuro
            ? const Color(
                0xFF2A2045,
              )
            : Colors.white,

        borderRadius:
            BorderRadius.circular(
          16,
        ),

        child: InkWell(
          borderRadius:
              BorderRadius.circular(
            16,
          ),

          onTap:
              habilitado
                  ? onTap
                  : null,

          child: Padding(
            padding:
                const EdgeInsets.all(
              16,
            ),

            child: Row(
              children: [
                Container(
                  width:
                      46,

                  height:
                      46,

                  decoration:
                      BoxDecoration(
                    color:
                        const Color(
                          0xFFFF7E01,
                        ).withValues(
                      alpha:
                          habilitado
                              ? 0.12
                              : 0.05,
                    ),

                    borderRadius:
                        BorderRadius.circular(
                      13,
                    ),
                  ),

                  child: Icon(
                    icono,

                    color:
                        habilitado
                            ? const Color(
                                0xFFFF7E01,
                              )
                            : Colors.grey,
                  ),
                ),

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
                        titulo,

                        style:
                            TextStyle(
                          fontSize:
                              16,

                          fontWeight:
                              FontWeight.w700,

                          color:
                              habilitado
                                  ? null
                                  : Colors.grey,
                        ),
                      ),

                      const SizedBox(
                        height:
                            3,
                      ),

                      Text(
                        subtitulo,

                        style:
                            TextStyle(
                          fontSize:
                              13,

                          color:
                              Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),

                if (habilitado)
                  const Icon(
                    Icons.chevron_right_rounded,
                  )
                else
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
                          Colors.grey
                              .withValues(
                        alpha:
                            0.12,
                      ),

                      borderRadius:
                          BorderRadius.circular(
                        20,
                      ),
                    ),

                    child:
                        const Text(
                      'Próximamente',

                      style:
                          TextStyle(
                        fontSize:
                            11,

                        color:
                            Colors.grey,
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