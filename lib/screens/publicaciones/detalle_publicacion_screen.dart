import 'package:flutter/material.dart';

import '../../models/comentario.dart';
import '../../models/publicacion.dart';
import '../../services/auth_service.dart';
import '../../services/comentario_service.dart';
import '../../services/publicacion_service.dart';
import '../../services/session_service.dart';

class DetallePublicacionScreen extends StatefulWidget {
  final int publicacionId;

  const DetallePublicacionScreen({
    super.key,
    required this.publicacionId,
  });

  @override
  State<DetallePublicacionScreen> createState() =>
      _DetallePublicacionScreenState();
}

class _DetallePublicacionScreenState
    extends State<DetallePublicacionScreen> {
  final TextEditingController comentarioController =
      TextEditingController();

  Publicacion? publicacion;

  List<Comentario> comentarios = [];
  List<dynamic> imagenes = [];

  String rolUsuario = '';
  int? usuarioIdActual;

  bool cargando = true;
  bool enviandoComentario = false;

  @override
  void initState() {
    super.initState();

    cargarUsuario();
    cargar();
  }

  // ============================================
  // CARGAR USUARIO ACTUAL
  // ============================================

  Future<void> cargarUsuario() async {
    final rol =
        await SessionService.obtenerRol();

    final resultadoPerfil =
        await AuthService.obtenerPerfil();

    if (!mounted) return;

    int? id;

    if (resultadoPerfil['success'] == true) {
      final usuario =
          resultadoPerfil['usuario'];

      if (usuario != null) {
        id = int.tryParse(
          usuario['id'].toString(),
        );
      }
    }

    setState(() {
      rolUsuario =
          (rol ?? '')
              .trim()
              .toLowerCase();

      usuarioIdActual =
          id;
    });
  }

  // ============================================
  // CARGAR PUBLICACIÓN Y COMENTARIOS
  // ============================================

  Future<void> cargar() async {
    final resultado =
        await PublicacionService.obtenerPorId(
      widget.publicacionId,
    );

    final resultadoComentarios =
        await ComentarioService.listar(
      widget.publicacionId,
    );

    if (!mounted) return;

    setState(() {
      if (resultado['success'] == true) {
        publicacion =
            resultado['publicacion'];

        imagenes =
            resultado['imagenes'] ?? [];
      }

      if (resultadoComentarios['success'] ==
          true) {
        comentarios =
            resultadoComentarios[
                'comentarios'];
      }

      cargando =
          false;
    });
  }

  // ============================================
  // FECHA
  // ============================================

  String formatearFecha(
    DateTime? fecha,
  ) {
    if (fecha == null) {
      return '';
    }

    final local =
        fecha.toLocal();

    final dia =
        local.day
            .toString()
            .padLeft(2, '0');

    final mes =
        local.month
            .toString()
            .padLeft(2, '0');

    final hora =
        local.hour
            .toString()
            .padLeft(2, '0');

    final minuto =
        local.minute
            .toString()
            .padLeft(2, '0');

    return '$dia/$mes/${local.year} · $hora:$minuto';
  }

  // ============================================
  // COMENTAR
  // ============================================

  Future<void> comentar() async {
    final texto =
        comentarioController.text
            .trim();

    if (texto.isEmpty) {
      return;
    }

    setState(() {
      enviandoComentario =
          true;
    });

    final resultado =
        await ComentarioService.crear(
      publicacionId:
          widget.publicacionId,
      texto:
          texto,
    );

    if (!mounted) return;

    setState(() {
      enviandoComentario =
          false;
    });

    if (resultado['success'] == true) {
      comentarioController.clear();

      await cargar();

      return;
    }

    mostrarMensaje(
      resultado['message'] ??
          'No se pudo comentar',
    );
  }

  // ============================================
  // RESPONDER COMENTARIO
  // ============================================

  Future<void> responderComentario(
    Comentario comentario,
  ) async {
    final controller =
        TextEditingController();

    final respuesta =
        await showDialog<String>(
      context:
          context,

      builder:
          (context) {
        return AlertDialog(
          title:
              Text(
            'Responder a ${comentario.usuarioNombre ?? 'usuario'}',
          ),

          content:
              TextField(
            controller:
                controller,

            autofocus:
                true,

            minLines:
                2,

            maxLines:
                5,

            decoration:
                const InputDecoration(
              hintText:
                  'Escribe tu respuesta...',
            ),
          ),

          actions: [
            TextButton(
              onPressed:
                  () {
                Navigator.pop(
                  context,
                );
              },

              child:
                  const Text(
                'Cancelar',
              ),
            ),

            ElevatedButton.icon(
              onPressed:
                  () {
                final texto =
                    controller.text
                        .trim();

                if (texto.isEmpty) {
                  return;
                }

                Navigator.pop(
                  context,
                  texto,
                );
              },

              icon:
                  const Icon(
                Icons.reply,
              ),

              label:
                  const Text(
                'Responder',
              ),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (respuesta == null ||
        respuesta.trim().isEmpty) {
      return;
    }

    final resultado =
        await ComentarioService.responder(
      comentarioId:
          comentario.id,

      texto:
          respuesta.trim(),
    );

    if (!mounted) return;

    if (resultado['success'] == true) {
      mostrarMensaje(
        'Respuesta publicada',
      );

      await cargar();

      return;
    }

    mostrarMensaje(
      resultado['message'] ??
          'No se pudo responder',
    );
  }

  // ============================================
  // ELIMINAR COMENTARIO / RESPUESTA
  // ============================================

  Future<void> eliminarComentario(
    Comentario comentario,
  ) async {
    final esRespuesta =
        comentario.comentarioPadreId !=
            null;

    final confirmar =
        await showDialog<bool>(
      context:
          context,

      builder:
          (context) {
        return AlertDialog(
          title:
              Text(
            esRespuesta
                ? 'Eliminar respuesta'
                : 'Eliminar comentario',
          ),

          content:
              Text(
            esRespuesta
                ? '¿Quieres eliminar esta respuesta?'
                : '¿Quieres eliminar este comentario? Si tiene respuestas, también serán eliminadas.',
          ),

          actions: [
            TextButton(
              onPressed:
                  () {
                Navigator.pop(
                  context,
                  false,
                );
              },

              child:
                  const Text(
                'Cancelar',
              ),
            ),

            TextButton(
              onPressed:
                  () {
                Navigator.pop(
                  context,
                  true,
                );
              },

              child:
                  const Text(
                'Eliminar',

                style:
                    TextStyle(
                  color:
                      Colors.red,

                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmar != true) {
      return;
    }

    final resultado =
        await ComentarioService.eliminar(
      comentario.id,
    );

    if (!mounted) return;

    if (resultado['success'] == true) {
      mostrarMensaje(
        esRespuesta
            ? 'Respuesta eliminada'
            : 'Comentario eliminado',
      );

      await cargar();

      return;
    }

    mostrarMensaje(
      resultado['message'] ??
          'No se pudo eliminar',
    );
  }

  // ============================================
  // LIKE
  // ============================================

  Future<void> toggleLike() async {
    final p =
        publicacion;

    if (p == null) {
      return;
    }

    final anterior =
        p.meGusta;

    setState(() {
      p.meGusta =
          !anterior;

      p.totalMeGusta +=
          anterior
              ? -1
              : 1;
    });

    final resultado =
        anterior
            ? await PublicacionService
                .quitarMeGusta(
                p.id,
              )
            : await PublicacionService
                .darMeGusta(
                p.id,
              );

    if (!mounted) return;

    if (resultado['success'] != true) {
      setState(() {
        p.meGusta =
            anterior;

        p.totalMeGusta +=
            anterior
                ? 1
                : -1;
      });
    }
  }

  // ============================================
  // GUARDAR
  // ============================================

  Future<void> toggleGuardado() async {
    final p =
        publicacion;

    if (p == null) {
      return;
    }

    final anterior =
        p.guardado;

    setState(() {
      p.guardado =
          !anterior;
    });

    final resultado =
        anterior
            ? await PublicacionService
                .quitarGuardado(
                p.id,
              )
            : await PublicacionService
                .guardar(
                p.id,
              );

    if (!mounted) return;

    if (resultado['success'] != true) {
      setState(() {
        p.guardado =
            anterior;
      });
    }
  }

  // ============================================
  // MENSAJES
  // ============================================

  void mostrarMensaje(
    String mensaje,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content:
            Text(
          mensaje,
        ),
      ),
    );
  }

  // ============================================
  // COMENTARIOS PRINCIPALES
  // ============================================

  List<Comentario>
      comentariosPrincipales() {
    return comentarios
        .where(
          (comentario) =>
              comentario
                  .comentarioPadreId ==
              null,
        )
        .toList();
  }

  // ============================================
  // RESPUESTAS
  // ============================================

  List<Comentario> respuestasDe(
    int comentarioId,
  ) {
    return comentarios
        .where(
          (comentario) =>
              comentario
                  .comentarioPadreId ==
              comentarioId,
        )
        .toList();
  }

  // ============================================
  // COMENTARIO
  // ============================================

  Widget construirComentario(
    Comentario comentario, {
    bool esRespuesta = false,
  }) {
    final rolComentario =
        (comentario.usuarioRol ?? '')
            .trim()
            .toLowerCase();

    final esEmprendedor =
        rolComentario ==
            'emprendedor';

    final tieneImagen =
        comentario.usuarioImagen !=
                null &&
            comentario.usuarioImagen!
                .trim()
                .isNotEmpty;

    final esPropio =
        usuarioIdActual != null &&
            comentario.usuarioId ==
                usuarioIdActual;

    return Padding(
      padding:
          EdgeInsets.only(
        left:
            esRespuesta
                ? 42
                : 0,
      ),

      child:
          ListTile(
        contentPadding:
            const EdgeInsets.fromLTRB(
          16,
          4,
          4,
          4,
        ),

        leading:
            CircleAvatar(
          radius:
              esRespuesta
                  ? 18
                  : 22,

          backgroundColor:
              const Color(
            0xFFFF7E01,
          ),

          backgroundImage:
              tieneImagen
                  ? NetworkImage(
                      comentario
                          .usuarioImagen!,
                    )
                  : null,

          child:
              !tieneImagen
                  ? const Icon(
                      Icons.person,
                      color:
                          Colors.white,
                    )
                  : null,
        ),

        title:
            Row(
          children: [
            Flexible(
              child:
                  Text(
                comentario.usuarioNombre ??
                    'Usuario',

                overflow:
                    TextOverflow.ellipsis,

                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),

            if (esEmprendedor) ...[
              const SizedBox(
                width:
                    8,
              ),

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal:
                      8,

                  vertical:
                      3,
                ),

                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFFFF7E01,
                  ),

                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),

                child:
                    const Text(
                  'Emprendedor',

                  style:
                      TextStyle(
                    color:
                        Colors.white,

                    fontSize:
                        10,

                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ],

            const Spacer(),

            // ===================================
            // TRES PUNTOS
            // ===================================

            if (esPropio)
              PopupMenuButton<String>(
                tooltip:
                    'Opciones',

                padding:
                    EdgeInsets.zero,

                icon:
                    const Icon(
                  Icons.more_vert,
                  size:
                      24,
                ),

                onSelected:
                    (valor) {
                  if (valor ==
                      'eliminar') {
                    eliminarComentario(
                      comentario,
                    );
                  }
                },

                itemBuilder:
                    (context) => [
                  PopupMenuItem<String>(
                    value:
                        'eliminar',

                    child:
                        Row(
                      children: [
                        const Icon(
                          Icons
                              .delete_outline,

                          color:
                              Colors.red,
                        ),

                        const SizedBox(
                          width:
                              10,
                        ),

                        Text(
                          esRespuesta
                              ? 'Eliminar respuesta'
                              : 'Eliminar comentario',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),

        subtitle:
            Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            const SizedBox(
              height:
                  4,
            ),

            Text(
              comentario.texto,
            ),

            const SizedBox(
              height:
                  5,
            ),

            Wrap(
              crossAxisAlignment:
                  WrapCrossAlignment.center,

              spacing:
                  12,

              children: [
                Text(
                  formatearFecha(
                    comentario
                        .fechaCreacion,
                  ),

                  style:
                      Theme.of(context)
                          .textTheme
                          .bodySmall,
                ),

                if (rolUsuario ==
                        'emprendedor' &&
                    !esRespuesta)
                  InkWell(
                    onTap:
                        () {
                      responderComentario(
                        comentario,
                      );
                    },

                    child:
                        const Padding(
                      padding:
                          EdgeInsets.symmetric(
                        vertical:
                            5,
                      ),

                      child:
                          Row(
                        mainAxisSize:
                            MainAxisSize.min,

                        children: [
                          Icon(
                            Icons.reply,

                            size:
                                16,

                            color:
                                Color(
                              0xFFFF7E01,
                            ),
                          ),

                          SizedBox(
                            width:
                                4,
                          ),

                          Text(
                            'Responder',

                            style:
                                TextStyle(
                              color:
                                  Color(
                                0xFFFF7E01,
                              ),

                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    comentarioController.dispose();

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
        body:
            Center(
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

    if (publicacion == null) {
      return Scaffold(
        appBar:
            AppBar(),

        body:
            const Center(
          child:
              Text(
            'Publicación no encontrada',
          ),
        ),
      );
    }

    final p =
        publicacion!;

    final principales =
        comentariosPrincipales();

    return Scaffold(
      appBar:
          AppBar(
        title:
            const Text(
          'Publicación',
        ),
      ),

      body:
          Column(
        children: [
          Expanded(
            child:
                RefreshIndicator(
              onRefresh:
                  cargar,

              child:
                  ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),

                padding:
                    const EdgeInsets.only(
                  bottom:
                      20,
                ),

                children: [
                  // =================================
                  // CABECERA
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
                  ),

                  // =================================
                  // TEXTO
                  // =================================

                  Padding(
                    padding:
                        const EdgeInsets.all(
                      16,
                    ),

                    child:
                        Text(
                      p.texto,

                      style:
                          const TextStyle(
                        fontSize:
                            17,
                      ),
                    ),
                  ),

                  // =================================
                  // IMÁGENES
                  // =================================

                  if (imagenes.isNotEmpty)
                    SizedBox(
                      height:
                          350,

                      child:
                          PageView.builder(
                        itemCount:
                            imagenes.length,

                        itemBuilder:
                            (
                          context,
                          index,
                        ) {
                          final url =
                              imagenes[index]
                                      ['url']
                                  ?.toString();

                          return Image.network(
                            url ?? '',

                            width:
                                double.infinity,

                            fit:
                                BoxFit.contain,

                            errorBuilder:
                                (
                              context,
                              error,
                              stackTrace,
                            ) {
                              return const Center(
                                child:
                                    Icon(
                                  Icons
                                      .broken_image_outlined,

                                  size:
                                      60,
                                ),
                              );
                            },
                          );
                        },
                      ),
                    )
                  else if (p.imagenPrincipal !=
                          null &&
                      p.imagenPrincipal!
                          .isNotEmpty)
                    SizedBox(
                      height:
                          350,

                      width:
                          double.infinity,

                      child:
                          Image.network(
                        p.imagenPrincipal!,

                        fit:
                            BoxFit.contain,

                        errorBuilder:
                            (
                          context,
                          error,
                          stackTrace,
                        ) {
                          return const Center(
                            child:
                                Icon(
                              Icons
                                  .broken_image_outlined,

                              size:
                                  60,
                            ),
                          );
                        },
                      ),
                    ),

                  // =================================
                  // PRODUCTO
                  // =================================

                  if (p.productoId !=
                      null)
                    Card(
                      margin:
                          const EdgeInsets.all(
                        12,
                      ),

                      child:
                          ListTile(
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

                  // =================================
                  // INTERACCIONES
                  // =================================

                  Padding(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal:
                          8,
                    ),

                    child:
                        Row(
                      children: [
                        IconButton(
                          tooltip:
                              'Me gusta',

                          onPressed:
                              toggleLike,

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
                          width:
                              15,
                        ),

                        const Icon(
                          Icons
                              .chat_bubble_outline,
                        ),

                        const SizedBox(
                          width:
                              6,
                        ),

                        Text(
                          '${comentarios.length}',
                        ),

                        const Spacer(),

                        IconButton(
                          tooltip:
                              p.guardado
                                  ? 'Quitar de guardados'
                                  : 'Guardar',

                          onPressed:
                              toggleGuardado,

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
                      ],
                    ),
                  ),

                  const Divider(),

                  // =================================
                  // COMENTARIOS
                  // =================================

                  const Padding(
                    padding:
                        EdgeInsets.fromLTRB(
                      16,
                      10,
                      16,
                      10,
                    ),

                    child:
                        Text(
                      'Comentarios',

                      style:
                          TextStyle(
                        fontSize:
                            20,

                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),

                  if (principales.isEmpty)
                    const Padding(
                      padding:
                          EdgeInsets.all(
                        25,
                      ),

                      child:
                          Center(
                        child:
                            Text(
                          'Todavía no hay comentarios.',
                        ),
                      ),
                    ),

                  // =================================
                  // COMENTARIO + RESPUESTAS
                  // =================================

                  ...principales.expand(
                    (
                      comentario,
                    ) {
                      final respuestas =
                          respuestasDe(
                        comentario.id,
                      );

                      return [
                        construirComentario(
                          comentario,
                        ),

                        ...respuestas.map(
                          (
                            respuesta,
                          ) =>
                              construirComentario(
                            respuesta,

                            esRespuesta:
                                true,
                          ),
                        ),

                        const Divider(
                          indent:
                              65,

                          endIndent:
                              16,
                        ),
                      ];
                    },
                  ),
                ],
              ),
            ),
          ),

          // =========================================
          // ESCRIBIR COMENTARIO
          // =========================================

          SafeArea(
            top:
                false,

            child:
                Container(
              padding:
                  const EdgeInsets.fromLTRB(
                12,
                8,
                8,
                8,
              ),

              decoration:
                  BoxDecoration(
                color:
                    Theme.of(context)
                        .scaffoldBackgroundColor,

                border:
                    Border(
                  top:
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
                  Expanded(
                    child:
                        TextField(
                      controller:
                          comentarioController,

                      minLines:
                          1,

                      maxLines:
                          4,

                      decoration:
                          const InputDecoration(
                        hintText:
                            'Escribe un comentario...',
                      ),
                    ),
                  ),

                  const SizedBox(
                    width:
                        5,
                  ),

                  IconButton(
                    tooltip:
                        'Comentar',

                    onPressed:
                        enviandoComentario
                            ? null
                            : comentar,

                    icon:
                        enviandoComentario
                            ? const SizedBox(
                                width:
                                    22,

                                height:
                                    22,

                                child:
                                    CircularProgressIndicator(
                                  strokeWidth:
                                      2,
                                ),
                              )
                            : const Icon(
                                Icons
                                    .send_rounded,

                                color:
                                    Color(
                                  0xFFFF7E01,
                                ),
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
}