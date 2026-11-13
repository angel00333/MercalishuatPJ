import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../config/app_theme.dart';

import '../services/auth_service.dart';
import '../services/perfil_imagen_service.dart';
import '../services/session_service.dart';
import '../services/theme_service.dart';
import '../services/firebase_messaging_service.dart';
import '../services/notificacion_service.dart';

import 'configuracion_screen.dart';
import 'dashboard_emprendedor_screen.dart';
import 'login_screen.dart';

import 'publicaciones/guardados_screen.dart';

import 'locales/locales_comerciales_screen.dart';

import 'admin/admin_dashboard_screen.dart';

class PerfilScreen extends StatefulWidget {
  final ThemeService themeService;

  const PerfilScreen({
    super.key,
    required this.themeService,
  });

  @override
  State<PerfilScreen> createState() =>
      _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  // ============================================================
  // CONTROLADORES
  // ============================================================

  final TextEditingController nombreController =
      TextEditingController();

  final TextEditingController correoController =
      TextEditingController();

  final ImagePicker picker = ImagePicker();

  // ============================================================
  // ESTADO
  // ============================================================

  String rol = '';

  String? fotoPerfilUrl;

  bool cargando = true;

  bool guardando = false;

  bool subiendoFoto = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    cargarPerfil();
  }

  // ============================================================
  // CARGAR PERFIL
  // ============================================================

  Future<void> cargarPerfil() async {
    if (mounted) {
      setState(() {
        cargando = true;
      });
    }

    final resultado =
        await AuthService.obtenerPerfil();

    if (!mounted) {
      return;
    }

    if (resultado['success'] == true) {
      final usuario = resultado['usuario'];

      if (usuario != null) {
        nombreController.text =
            usuario['nombre']?.toString() ?? '';

        correoController.text =
            usuario['correo']?.toString() ?? '';

        rol =
            usuario['rol']
                    ?.toString()
                    .toLowerCase() ??
                '';

        fotoPerfilUrl =
            usuario['foto_perfil_url']
                ?.toString();
      }
    } else {
      mostrarMensaje(
        resultado['message'] ??
            'No se pudo cargar el perfil',
      );
    }

    if (!mounted) {
      return;
    }

    setState(() {
      cargando = false;
    });
  }

  // ============================================================
  // GUARDAR PERFIL
  // ============================================================

  Future<void> guardarPerfil() async {
    final nombre =
        nombreController.text.trim();

    final correo =
        correoController.text.trim();

    if (nombre.isEmpty ||
        correo.isEmpty) {
      mostrarMensaje(
        'Completa nombre y correo',
      );

      return;
    }

    setState(() {
      guardando = true;
    });

    final resultado =
        await AuthService.editarPerfil(
      nombre: nombre,
      correo: correo,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      guardando = false;
    });

    if (resultado['success'] == true) {
      mostrarMensaje(
        resultado['message'] ??
            'Perfil actualizado correctamente',
      );

      return;
    }

    mostrarMensaje(
      resultado['message'] ??
          'No se pudo actualizar el perfil',
    );
  }

  // ============================================================
  // FOTO PERFIL
  // ============================================================

  Future<void> elegirFoto(
    ImageSource source,
  ) async {
    try {
      final imagen =
          await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
      );

      if (imagen == null) {
        return;
      }

      setState(() {
        subiendoFoto = true;
      });

      final resultado =
          await PerfilImagenService
              .subirFotoPerfil(
        imagen,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        subiendoFoto = false;
      });

      if (resultado['success'] == true) {
        final nuevaUrl =
            resultado[
                    'foto_perfil_url']
                ?.toString();

        if (nuevaUrl != null &&
            nuevaUrl.isNotEmpty) {
          setState(() {
            fotoPerfilUrl =
                nuevaUrl;
          });
        }

        mostrarMensaje(
          'Foto actualizada correctamente',
        );

        return;
      }

      mostrarMensaje(
        resultado['message'] ??
            'No se pudo subir la foto',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        subiendoFoto = false;
      });

      mostrarMensaje(
        'No se pudo seleccionar la imagen',
      );
    }
  }

  // ============================================================
  // OPCIONES FOTO
  // ============================================================

  void mostrarOpcionesFoto() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading:
                    const Icon(
                  Icons
                      .photo_library_outlined,
                ),
                title:
                    const Text(
                  'Elegir de galería',
                ),
                onTap: () {
                  Navigator.pop(
                    context,
                  );

                  elegirFoto(
                    ImageSource.gallery,
                  );
                },
              ),

              ListTile(
                leading:
                    const Icon(
                  Icons
                      .camera_alt_outlined,
                ),
                title:
                    const Text(
                  'Tomar foto',
                ),
                onTap: () {
                  Navigator.pop(
                    context,
                  );

                  elegirFoto(
                    ImageSource.camera,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // CERRAR SESIÓN
  // ============================================================

  Future<void> cerrarSesion() async {
    try {
      // ========================================================
      // OBTENER FID
      // ========================================================

      final String? fid =
          FirebaseMessagingService
              .instance
              .fid;

      // ========================================================
      // DESACTIVAR FID
      // ========================================================

      if (fid != null &&
          fid.isNotEmpty) {
        final bool eliminado =
            await NotificacionService
                .eliminarFid(
          fid: fid,
        );

        if (eliminado) {
          debugPrint(
            'FCM: FID desactivado correctamente',
          );
        } else {
          debugPrint(
            'FCM: no se pudo desactivar el FID',
          );
        }
      } else {
        debugPrint(
          'FCM: no existe FID para desactivar',
        );
      }

      // ========================================================
      // CERRAR FIREBASE
      // ========================================================

      await FirebaseMessagingService
          .instance
          .cerrar();

      // ========================================================
      // BORRAR SESIÓN
      // ========================================================

      await SessionService.cerrarSesion();

      debugPrint(
        'SESIÓN CERRADA CORRECTAMENTE',
      );
    } catch (e) {
      debugPrint(
        'ERROR CERRANDO SESIÓN: $e',
      );

      try {
        await FirebaseMessagingService
            .instance
            .cerrar();
      } catch (firebaseError) {
        debugPrint(
          'ERROR CERRANDO FCM: $firebaseError',
        );
      }

      await SessionService.cerrarSesion();
    }

    if (!mounted) {
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) =>
            LoginScreen(
          themeService:
              widget.themeService,
        ),
      ),
      (route) => false,
    );
  }

  // ============================================================
  // GUARDADOS
  // ============================================================

  Future<void> abrirGuardados() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const GuardadosScreen(),
      ),
    );
  }

  // ============================================================
  // CENTRO DE NEGOCIO
  // ============================================================

  Future<void>
      abrirDashboardEmprendedor() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            DashboardEmprendedorScreen(
          themeService:
              widget.themeService,
        ),
      ),
    );
  }

  // ============================================================
  // LOCALES COMERCIALES
  // ============================================================

  Future<void>
      abrirLocalesComerciales() async {
    final bool esEmprendedor =
        rol == 'emprendedor';

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            LocalesComercialesScreen(
          puedePublicar:
              esEmprendedor,
        ),
      ),
    );
  }

  // ============================================================
  // CONFIGURACIÓN
  // ============================================================

  Future<void>
      abrirConfiguracion() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ConfiguracionScreen(
          themeService:
              widget.themeService,
        ),
      ),
    );
  }

  // ============================================================
  // ADMIN
  // ============================================================

  Future<void> abrirPanelAdmin() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AdminDashboardScreen(
          themeService:
              widget.themeService,
        ),
      ),
    );
  }

  // ============================================================
  // MENSAJE
  // ============================================================

  void mostrarMensaje(
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
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    nombreController.dispose();

    correoController.dispose();

    super.dispose();
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
              CircularProgressIndicator(
            color:
                AppColors.naranja,
          ),
        ),
      );
    }

    // ==========================================================
    // ROLES
    // ==========================================================

    final bool esEmprendedor =
        rol == 'emprendedor';

    final bool esAdministrador =
        rol == 'administrador';

    // ==========================================================
    // TEMA
    // ==========================================================

    final bool oscuro =
        Theme.of(context).brightness ==
            Brightness.dark;

    final Color textoPrincipal =
        Theme.of(context)
            .colorScheme
            .onSurface;

    final Color textoSecundario =
        textoPrincipal.withValues(
      alpha: 0.60,
    );

    final Color borde =
        Theme.of(context)
            .dividerColor
            .withValues(
              alpha: 0.45,
            );

    return Scaffold(
      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        title:
            const Text(
          'Mi perfil',
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: RefreshIndicator(
        onRefresh:
            cargarPerfil,

        color:
            AppColors.naranja,

        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),

          padding:
              const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            36,
          ),

          children: [
            Center(
              child:
                  ConstrainedBox(
                constraints:
                    const BoxConstraints(
                  maxWidth: 850,
                ),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,

                  children: [
                    // ============================================
                    // PERFIL SUPERIOR
                    // ============================================

                    _cabeceraPerfil(
                      esEmprendedor:
                          esEmprendedor,

                      esAdministrador:
                          esAdministrador,

                      oscuro:
                          oscuro,

                      textoSecundario:
                          textoSecundario,
                    ),

                    const SizedBox(
                      height: 30,
                    ),

                    // ============================================
                    // DATOS PERSONALES
                    // ============================================

                    _tituloSeccion(
                      icono:
                          Icons.person_outline_rounded,

                      titulo:
                          'Datos personales',
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    Card(
                      child:
                          Padding(
                        padding:
                            const EdgeInsets.all(
                          18,
                        ),

                        child:
                            Column(
                          children: [
                            // =====================================
                            // NOMBRE
                            // =====================================

                            TextField(
                              controller:
                                  nombreController,

                              textCapitalization:
                                  TextCapitalization
                                      .words,

                              decoration:
                                  const InputDecoration(
                                labelText:
                                    'Nombre',

                                prefixIcon:
                                    Icon(
                                  Icons
                                      .person_outline_rounded,
                                ),
                              ),
                            ),

                            const SizedBox(
                              height: 15,
                            ),

                            // =====================================
                            // CORREO
                            // =====================================

                            TextField(
                              controller:
                                  correoController,

                              keyboardType:
                                  TextInputType
                                      .emailAddress,

                              decoration:
                                  const InputDecoration(
                                labelText:
                                    'Correo electrónico',

                                prefixIcon:
                                    Icon(
                                  Icons
                                      .email_outlined,
                                ),
                              ),
                            ),

                            const SizedBox(
                              height: 18,
                            ),

                            // =====================================
                            // GUARDAR
                            // =====================================

                            SizedBox(
                              width:
                                  double.infinity,

                              height:
                                  50,

                              child:
                                  ElevatedButton.icon(
                                onPressed:
                                    guardando
                                        ? null
                                        : guardarPerfil,

                                icon:
                                    guardando
                                        ? const SizedBox(
                                            width:
                                                21,

                                            height:
                                                21,

                                            child:
                                                CircularProgressIndicator(
                                              strokeWidth:
                                                  2,

                                              color:
                                                  Colors.white,
                                            ),
                                          )
                                        : const Icon(
                                            Icons
                                                .save_outlined,
                                          ),

                                label:
                                    Text(
                                  guardando
                                      ? 'Guardando...'
                                      : 'Guardar cambios',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ============================================
                    // MI NEGOCIO
                    // ============================================

                    if (esEmprendedor) ...[
                      const SizedBox(
                        height: 30,
                      ),

                      _tituloSeccion(
                        icono:
                            Icons
                                .storefront_rounded,

                        titulo:
                            'Mi negocio',
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      _tarjetaNegocio(
                        textoSecundario:
                            textoSecundario,

                        borde:
                            borde,
                      ),
                    ],

                    // ============================================
                    // ADMINISTRACIÓN
                    // ============================================

                    if (esAdministrador) ...[
                      const SizedBox(
                        height: 30,
                      ),

                      _tituloSeccion(
                        icono:
                            Icons
                                .admin_panel_settings_outlined,

                        titulo:
                            'Administración',
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      _opcion(
                        icon:
                            Icons
                                .admin_panel_settings_outlined,

                        titulo:
                            'Panel administrativo',

                        descripcion:
                            'Usuarios, estadísticas y administración de Mercalishuat',

                        onTap:
                            abrirPanelAdmin,
                      ),
                    ],

                    // ============================================
                    // MI CUENTA
                    // ============================================

                    const SizedBox(
                      height: 30,
                    ),

                    _tituloSeccion(
                      icono:
                          Icons
                              .account_circle_outlined,

                      titulo:
                          'Mi cuenta',
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    // ============================================
                    // GUARDADOS
                    // ============================================
                    //
                    // USUARIO Y EMPRENDEDOR.
                    //
                    // ============================================

                    if (!esAdministrador)
                      _opcion(
                        icon:
                            Icons
                                .bookmark_outline_rounded,

                        titulo:
                            'Guardados',

                        descripcion:
                            'Publicaciones que has guardado',

                        onTap:
                            abrirGuardados,
                      ),

                    // ============================================
                    // LOCALES COMERCIALES
                    // ============================================

                    if (!esAdministrador)
                      _opcion(
                        icon:
                            Icons
                                .business_outlined,

                        titulo:
                            'Locales comerciales',

                        descripcion:
                            'Explorar locales disponibles para venta o alquiler',

                        onTap:
                            abrirLocalesComerciales,
                      ),

                    // ============================================
                    // CONFIGURACIÓN
                    // ============================================

                    _opcion(
                      icon:
                          Icons
                              .settings_outlined,

                      titulo:
                          'Configuración',

                      descripcion:
                          'Tema, privacidad y preferencias de la aplicación',

                      onTap:
                          abrirConfiguracion,
                    ),

                    const SizedBox(
                      height: 24,
                    ),

                    // ============================================
                    // CERRAR SESIÓN
                    // ============================================

                    SizedBox(
                      height: 50,

                      child:
                          OutlinedButton.icon(
                        onPressed:
                            cerrarSesion,

                        icon:
                            const Icon(
                          Icons
                              .logout_rounded,
                        ),

                        label:
                            const Text(
                          'Cerrar sesión',
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CABECERA PERFIL
  // ============================================================

  Widget _cabeceraPerfil({
    required bool esEmprendedor,
    required bool esAdministrador,
    required bool oscuro,
    required Color textoSecundario,
  }) {
    final String textoRol =
        esAdministrador
            ? 'Administrador'
            : esEmprendedor
                ? 'Emprendedor'
                : 'Usuario';

    return Column(
      children: [
        // ======================================================
        // FOTO
        // ======================================================

        Stack(
          clipBehavior:
              Clip.none,

          children: [
            Container(
              padding:
                  const EdgeInsets.all(
                4,
              ),

              decoration:
                  BoxDecoration(
                shape:
                    BoxShape.circle,

                border:
                    Border.all(
                  color:
                      AppColors.naranja,

                  width:
                      3,
                ),
              ),

              child:
                  CircleAvatar(
                radius: 57,

                backgroundColor:
                    AppColors.naranja,

                backgroundImage:
                    fotoPerfilUrl !=
                                null &&
                            fotoPerfilUrl!
                                .isNotEmpty
                        ? NetworkImage(
                            fotoPerfilUrl!,
                          )
                        : null,

                child:
                    fotoPerfilUrl ==
                                null ||
                            fotoPerfilUrl!
                                .isEmpty
                        ? const Icon(
                            Icons
                                .person_rounded,

                            size: 68,

                            color:
                                Colors.white,
                          )
                        : null,
              ),
            ),

            // ==================================================
            // BOTÓN CÁMARA
            // ==================================================

            Positioned(
              right: -3,
              bottom: -3,

              child:
                  Material(
                color:
                    AppColors.naranja,

                shape:
                    const CircleBorder(),

                elevation: 3,

                child:
                    IconButton(
                  tooltip:
                      'Cambiar foto',

                  onPressed:
                      subiendoFoto
                          ? null
                          : mostrarOpcionesFoto,

                  icon:
                      subiendoFoto
                          ? const SizedBox(
                              width: 20,
                              height: 20,

                              child:
                                  CircularProgressIndicator(
                                strokeWidth:
                                    2,

                                color:
                                    Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons
                                  .camera_alt_rounded,

                              color:
                                  Colors.white,
                            ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 18,
        ),

        // ======================================================
        // NOMBRE
        // ======================================================

        Text(
          nombreController.text,

          textAlign:
              TextAlign.center,

          style:
              const TextStyle(
            fontSize: 25,

            height: 1.1,

            fontWeight:
                FontWeight.w900,

            fontFamily:
                'Outfit',
          ),
        ),

        const SizedBox(
          height: 6,
        ),

        // ======================================================
        // CORREO
        // ======================================================

        Text(
          correoController.text,

          textAlign:
              TextAlign.center,

          style:
              TextStyle(
            color:
                textoSecundario,

            fontSize: 13,

            fontFamily:
                'Outfit',
          ),
        ),

        const SizedBox(
          height: 11,
        ),

        // ======================================================
        // ROL
        // ======================================================

        Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 7,
          ),

          decoration:
              BoxDecoration(
            color:
                AppColors.naranja
                    .withValues(
              alpha:
                  oscuro
                      ? 0.18
                      : 0.10,
            ),

            borderRadius:
                BorderRadius.circular(
              20,
            ),
          ),

          child:
              Text(
            textoRol,

            style:
                const TextStyle(
              color:
                  AppColors.naranja,

              fontSize: 12,

              fontWeight:
                  FontWeight.w700,

              fontFamily:
                  'Outfit',
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // TARJETA MI NEGOCIO
  // ============================================================

  Widget _tarjetaNegocio({
    required Color textoSecundario,
    required Color borde,
  }) {
    return Material(
      color:
          Theme.of(context).cardColor,

      borderRadius:
          BorderRadius.circular(
        24,
      ),

      child:
          InkWell(
        onTap:
            abrirDashboardEmprendedor,

        borderRadius:
            BorderRadius.circular(
          24,
        ),

        child:
            Container(
          decoration:
              BoxDecoration(
            borderRadius:
                BorderRadius.circular(
              24,
            ),

            border:
                Border.all(
              color: borde,
            ),
          ),

          clipBehavior:
              Clip.antiAlias,

          child:
              Column(
            children: [
              // =================================================
              // CABECERA
              // =================================================

              Container(
                width:
                    double.infinity,

                padding:
                    const EdgeInsets.all(
                  19,
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
                      AppColors.naranja,
                      AppColors
                          .naranjaClaro,
                    ],
                  ),
                ),

                child:
                    Row(
                  children: [
                    Container(
                      width: 55,
                      height: 55,

                      decoration:
                          BoxDecoration(
                        color:
                            Colors.white
                                .withValues(
                          alpha: 0.20,
                        ),

                        borderRadius:
                            BorderRadius
                                .circular(
                          17,
                        ),
                      ),

                      child:
                          const Icon(
                        Icons
                            .storefront_rounded,

                        color:
                            Colors.white,

                        size: 31,
                      ),
                    ),

                    const SizedBox(
                      width: 15,
                    ),

                    const Expanded(
                      child:
                          Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,

                        children: [
                          Text(
                            'Centro de negocio',

                            style:
                                TextStyle(
                              color:
                                  Colors.white,

                              fontSize:
                                  19,

                              fontWeight:
                                  FontWeight
                                      .w900,

                              fontFamily:
                                  'Outfit',
                            ),
                          ),

                          SizedBox(
                            height: 4,
                          ),

                          Text(
                            'Administra tu emprendimiento desde un solo lugar',

                            style:
                                TextStyle(
                              color:
                                  Colors.white,

                              fontSize:
                                  12.5,

                              height: 1.3,

                              fontFamily:
                                  'Outfit',
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Icon(
                      Icons
                          .arrow_forward_ios_rounded,

                      color:
                          Colors.white,

                      size: 18,
                    ),
                  ],
                ),
              ),

              // =================================================
              // DESCRIPCIÓN
              // =================================================

              Padding(
                padding:
                    const EdgeInsets.all(
                  17,
                ),

                child:
                    Row(
                  children: [
                    Container(
                      width: 43,
                      height: 43,

                      decoration:
                          BoxDecoration(
                        color:
                            AppColors.naranja
                                .withValues(
                          alpha: 0.10,
                        ),

                        borderRadius:
                            BorderRadius
                                .circular(
                          13,
                        ),
                      ),

                      child:
                          const Icon(
                        Icons
                            .dashboard_customize_outlined,

                        color:
                            AppColors.naranja,
                      ),
                    ),

                    const SizedBox(
                      width: 13,
                    ),

                    Expanded(
                      child:
                          Text(
                        'Tienda, productos, publicaciones, mensajes y herramientas comerciales.',

                        style:
                            TextStyle(
                          color:
                              textoSecundario,

                          fontSize:
                              12.8,

                          height:
                              1.35,

                          fontFamily:
                              'Outfit',
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
    );
  }

  // ============================================================
  // TÍTULO SECCIÓN
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

          size: 23,
        ),

        const SizedBox(
          width: 9,
        ),

        Text(
          titulo,

          style:
              const TextStyle(
            fontSize: 19,

            fontWeight:
                FontWeight.w900,

            fontFamily:
                'Outfit',
          ),
        ),
      ],
    );
  }

  // ============================================================
  // OPCIÓN
  // ============================================================

  Widget _opcion({
    required IconData icon,
    required String titulo,
    required String descripcion,
    required VoidCallback onTap,
  }) {
    final Color textoSecundario =
        Theme.of(context)
            .colorScheme
            .onSurface
            .withValues(
              alpha: 0.60,
            );

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),

      child:
          InkWell(
        onTap: onTap,

        borderRadius:
            BorderRadius.circular(
          20,
        ),

        child:
            Padding(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),

          child:
              Row(
            children: [
              // =================================================
              // ICONO
              // =================================================

              Container(
                width: 46,
                height: 46,

                decoration:
                    BoxDecoration(
                  color:
                      AppColors.naranja
                          .withValues(
                    alpha: 0.10,
                  ),

                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),

                child:
                    Icon(
                  icon,

                  color:
                      AppColors.naranja,

                  size: 23,
                ),
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
                        fontSize: 15,

                        fontWeight:
                            FontWeight
                                .w700,

                        fontFamily:
                            'Outfit',
                      ),
                    ),

                    const SizedBox(
                      height: 3,
                    ),

                    Text(
                      descripcion,

                      style:
                          TextStyle(
                        color:
                            textoSecundario,

                        fontSize:
                            12.5,

                        height: 1.3,

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
                Icons.chevron_right_rounded,

                color:
                    textoSecundario,
              ),
            ],
          ),
        ),
      ),
    );
  }
}