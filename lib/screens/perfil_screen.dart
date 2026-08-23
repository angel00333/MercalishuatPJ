import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../config/app_theme.dart';
import '../services/auth_service.dart';
import '../services/perfil_imagen_service.dart';
import '../services/session_service.dart';
import '../services/theme_service.dart';
import 'login_screen.dart';

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

  final ImagePicker picker = ImagePicker();

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

  Future<void> cargarPerfil() async {
    if (mounted) {
      setState(() {
        cargando = true;
      });
    }

    final resultado =
        await AuthService.obtenerPerfil();

    if (!mounted) return;

    if (resultado['success'] == true) {
      final usuario =
          resultado['usuario'] as Map<String, dynamic>?;

      if (usuario != null) {
        nombreController.text =
            usuario['nombre']?.toString() ?? '';

        correoController.text =
            usuario['correo']?.toString() ?? '';

        rol =
            usuario['rol']?.toString() ?? '';

        fotoPerfilUrl =
            usuario['foto_perfil_url']?.toString();
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

    if (!mounted) return;

    setState(() {
      guardando = false;
    });

    if (resultado['success'] == true) {
      await SessionService.actualizarDatos(
        nombre: nombre,
        correo: correo,
      );

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

      if (imagen == null) return;

      setState(() {
        subiendoFoto = true;
      });

      final resultado =
          await PerfilImagenService
              .subirFotoPerfil(
        imagen,
      );

      if (!mounted) return;

      setState(() {
        subiendoFoto = false;
      });

      if (resultado['success'] == true) {
        final nuevaUrl =
            resultado['foto_perfil_url']
                ?.toString();

        if (nuevaUrl != null &&
            nuevaUrl.isNotEmpty) {
          setState(() {
            fotoPerfilUrl = nuevaUrl;
          });
        }

        mostrarMensaje(
          resultado['message'] ??
              'Foto actualizada correctamente',
        );

        return;
      }

      mostrarMensaje(
        resultado['message'] ??
            'No se pudo subir la foto',
      );
    } catch (e) {
      if (!mounted) return;

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
                leading: const Icon(
                  Icons.photo_library_outlined,
                ),
                title: const Text(
                  'Elegir de galería',
                ),
                onTap: () {
                  Navigator.pop(context);

                  elegirFoto(
                    ImageSource.gallery,
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_outlined,
                ),
                title: const Text(
                  'Tomar foto',
                ),
                onTap: () {
                  Navigator.pop(context);

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

  Future<void> cerrarSesion() async {
    await SessionService.cerrarSesion();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => LoginScreen(
          themeService:
              widget.themeService,
        ),
      ),
      (route) => false,
    );
  }

  void mostrarMensaje(String mensaje) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(mensaje),
      ),
    );
  }

  @override
  void dispose() {
    nombreController.dispose();
    correoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mi perfil',
        ),
      ),

      body: RefreshIndicator(
        onRefresh: cargarPerfil,

        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),

          padding:
              const EdgeInsets.all(
            24,
          ),

          children: [
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
                        fotoPerfilUrl != null &&
                                fotoPerfilUrl!
                                    .isNotEmpty
                            ? NetworkImage(
                                fotoPerfilUrl!,
                              )
                            : null,

                    child:
                        fotoPerfilUrl == null ||
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
                    right: -2,
                    bottom: -2,

                    child: Material(
                      color:
                          AppColors.naranja,

                      shape:
                          const CircleBorder(),

                      child: IconButton(
                        tooltip:
                            'Cambiar foto',

                        onPressed:
                            subiendoFoto
                                ? null
                                : mostrarOpcionesFoto,

                        icon:
                            subiendoFoto
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
              height: 30,
            ),

            TextField(
              controller:
                  nombreController,

              textInputAction:
                  TextInputAction.next,

              decoration:
                  const InputDecoration(
                labelText:
                    'Nombre',

                prefixIcon:
                    Icon(
                  Icons.person_outline,
                ),
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            TextField(
              controller:
                  correoController,

              keyboardType:
                  TextInputType
                      .emailAddress,

              textInputAction:
                  TextInputAction.done,

              decoration:
                  const InputDecoration(
                labelText:
                    'Correo electrónico',

                prefixIcon:
                    Icon(
                  Icons.email_outlined,
                ),
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            ListTile(
              contentPadding:
                  EdgeInsets.zero,

              leading:
                  const Icon(
                Icons.badge_outlined,
                color:
                    AppColors.naranja,
              ),

              title:
                  const Text(
                'Tipo de cuenta',
              ),

              subtitle:
                  Text(
                rol.isEmpty
                    ? 'Sin rol'
                    : rol,
              ),
            ),

            const SizedBox(
              height: 25,
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
                            width:
                                22,
                            height:
                                22,

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
              height: 15,
            ),

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
          ],
        ),
      ),
    );
  }
}