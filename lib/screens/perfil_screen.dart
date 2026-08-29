import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../config/app_theme.dart';
import '../services/auth_service.dart';
import '../services/perfil_imagen_service.dart';
import '../services/session_service.dart';
import '../services/theme_service.dart';

import 'configuracion_screen.dart';
import 'login_screen.dart';

import 'publicaciones/guardados_screen.dart';
import 'publicaciones/mis_publicaciones_screen.dart';

import 'producto_actions/productos_screen.dart';
import 'tienda_actions/mi_tienda_screen.dart';

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

class _PerfilScreenState
    extends State<PerfilScreen> {
  final TextEditingController nombreController =
      TextEditingController();

  final TextEditingController correoController =
      TextEditingController();

  final ImagePicker picker =
      ImagePicker();

  String rol = '';

  String? fotoPerfilUrl;

  bool cargando = true;
  bool guardando = false;
  bool subiendoFoto = false;

  @override
  void initState() {
    super.initState();

    cargarPerfil();
  }

  // ============================================
  // CARGAR PERFIL
  // ============================================

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
      final usuario =
          resultado['usuario'];

      if (usuario != null) {
        nombreController.text =
            usuario['nombre']?.toString() ??
                '';

        correoController.text =
            usuario['correo']?.toString() ??
                '';

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

    setState(() {
      cargando = false;
    });
  }

  // ============================================
  // GUARDAR PERFIL
  // ============================================

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

  // ============================================
  // FOTO PERFIL
  // ============================================

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

  // ============================================
  // CERRAR SESIÓN
  // ============================================

  Future<void> cerrarSesion() async {
    await SessionService.cerrarSesion();

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

  // ============================================
  // NAVEGACIÓN
  // ============================================

  Future<void> abrirGuardados() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const GuardadosScreen(),
      ),
    );
  }

  Future<void>
      abrirMisPublicaciones() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const MisPublicacionesScreen(),
      ),
    );
  }

  Future<void> abrirProductos() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const ProductosScreen(),
      ),
    );
  }

  Future<void> abrirMiTienda() async {
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
  }

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

  // ============================================
  // MENSAJE
  // ============================================

  void mostrarMensaje(
    String mensaje,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content:
            Text(mensaje),
      ),
    );
  }

  @override
  void dispose() {
    nombreController.dispose();
    correoController.dispose();

    super.dispose();
  }

  // ============================================
  // BUILD
  // ============================================

  @override
  Widget build(
    BuildContext context,
  ) {
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

    final esEmprendedor =
        rol == 'emprendedor';

    return Scaffold(
      appBar: AppBar(
        title:
            const Text(
          'Mi perfil',
        ),
      ),

      body: RefreshIndicator(
        onRefresh:
            cargarPerfil,

        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),

          padding:
              const EdgeInsets.all(
            20,
          ),

          children: [
            // =================================
            // FOTO
            // =================================

            Center(
              child: Stack(
                clipBehavior:
                    Clip.none,

                children: [
                  CircleAvatar(
                    radius: 60,

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
                                Icons.person,
                                size: 70,
                                color:
                                    Colors.white,
                              )
                            : null,
                  ),

                  Positioned(
                    right: -3,
                    bottom: -3,

                    child: Material(
                      color:
                          AppColors.naranja,

                      shape:
                          const CircleBorder(),

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
                                        .camera_alt,
                                    color:
                                        Colors.white,
                                  ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            Text(
              nombreController.text,

              textAlign:
                  TextAlign.center,

              style:
                  const TextStyle(
                fontSize: 24,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 5,
            ),

            Text(
              esEmprendedor
                  ? 'Emprendedor'
                  : 'Usuario',

              textAlign:
                  TextAlign.center,

              style:
                  const TextStyle(
                color:
                    AppColors.naranja,
                fontWeight:
                    FontWeight.w600,
              ),
            ),

            const SizedBox(
              height: 30,
            ),

            // =================================
            // DATOS
            // =================================

            const Text(
              'Datos personales',

              style:
                  TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 15,
            ),

            TextField(
              controller:
                  nombreController,

              decoration:
                  const InputDecoration(
                labelText:
                    'Nombre',

                prefixIcon:
                    Icon(
                  Icons
                      .person_outline,
                ),
              ),
            ),

            const SizedBox(
              height: 15,
            ),

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
              height: 20,
            ),

            SizedBox(
              height: 50,

              child:
                  ElevatedButton.icon(
                onPressed:
                    guardando
                        ? null
                        : guardarPerfil,

                icon:
                    guardando
                        ? const SizedBox(
                            width: 22,
                            height: 22,

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

            const SizedBox(
              height: 35,
            ),

            // =================================
            // PANEL
            // =================================

            Text(
              esEmprendedor
                  ? 'Panel del emprendedor'
                  : 'Mi cuenta',

              style:
                  const TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            // =================================
            // OPCIONES EMPRENDEDOR
            // =================================

            if (esEmprendedor) ...[
              _opcion(
                icon:
                    Icons
                        .article_outlined,

                titulo:
                    'Mis publicaciones',

                descripcion:
                    'Crear, editar y administrar publicaciones',

                onTap:
                    abrirMisPublicaciones,
              ),

              _opcion(
                icon:
                    Icons
                        .inventory_2_outlined,

                titulo:
                    'Productos',

                descripcion:
                    'Administrar productos de tu tienda',

                onTap:
                    abrirProductos,
              ),

              _opcion(
                icon:
                    Icons
                        .storefront_outlined,

                titulo:
                    'Mi tienda',

                descripcion:
                    'Editar información de tu emprendimiento',

                onTap:
                    abrirMiTienda,
              ),
            ],

            // =================================
            // OPCIONES USUARIO
            // =================================

            if (!esEmprendedor)
              _opcion(
                icon:
                    Icons
                        .bookmark_outline,

                titulo:
                    'Guardados',

                descripcion:
                    'Publicaciones que has guardado',

                onTap:
                    abrirGuardados,
              ),

            // =================================
            // CONFIGURACIÓN
            // =================================

            _opcion(
              icon:
                  Icons
                      .settings_outlined,

              titulo:
                  'Configuración',

              descripcion:
                  'Tema y preferencias de la aplicación',

              onTap:
                  abrirConfiguracion,
            ),

            const SizedBox(
              height: 20,
            ),

            // =================================
            // LOGOUT
            // =================================

            OutlinedButton.icon(
              onPressed:
                  cerrarSesion,

              icon:
                  const Icon(
                Icons.logout,
              ),

              label:
                  const Text(
                'Cerrar sesión',
              ),
            ),

            const SizedBox(
              height: 30,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // ITEM DEL PANEL
  // ============================================

  Widget _opcion({
    required IconData icon,
    required String titulo,
    required String descripcion,
    required VoidCallback onTap,
  }) {
    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),

      child: ListTile(
        onTap:
            onTap,

        leading:
            Container(
          width: 46,
          height: 46,

          decoration:
              BoxDecoration(
            color:
                AppColors.naranja
                    .withValues(
              alpha: 0.12,
            ),

            borderRadius:
                BorderRadius.circular(
              12,
            ),
          ),

          child:
              Icon(
            icon,
            color:
                AppColors.naranja,
          ),
        ),

        title:
            Text(
          titulo,

          style:
              const TextStyle(
            fontWeight:
                FontWeight.w600,
          ),
        ),

        subtitle:
            Text(
          descripcion,
        ),

        trailing:
            const Icon(
          Icons.chevron_right,
        ),
      ),
    );
  }
}