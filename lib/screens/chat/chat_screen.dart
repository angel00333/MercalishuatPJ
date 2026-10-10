import 'package:flutter/material.dart';

import '../../models/mensaje.dart';
import '../../services/chat_service.dart';
import '../../services/chat_socket_service.dart';

class ChatScreen extends StatefulWidget {
  final int conversacionId;
  final String nombreUsuario;
  final String? imagenUsuarioUrl;

  const ChatScreen({
    super.key,
    required this.conversacionId,
    required this.nombreUsuario,
    this.imagenUsuarioUrl,
  });

  @override
  State<ChatScreen> createState() =>
      _ChatScreenState();
}

class _ChatScreenState
    extends State<ChatScreen> {
  static const Color naranja =
      Color(0xFFFF7E01);

  static const Color panelOscuro =
      Color(0xFF2A2045);

  final TextEditingController
      mensajeController =
      TextEditingController();

  final ScrollController
      scrollController =
      ScrollController();

  List<Mensaje> mensajes =
      [];

  bool cargando =
      true;

  bool enviando =
      false;

  String? error;

  bool _socketPreparado =
      false;

  @override
  void initState() {
    super.initState();

    _iniciar();
  }

  // ============================================================
  // INICIAR
  // ============================================================

  Future<void> _iniciar() async {
    await _prepararSocket();

    await _cargarMensajes();
  }

  // ============================================================
  // SOCKET
  // ============================================================

  Future<void> _prepararSocket() async {
    if (_socketPreparado) {
      return;
    }

    await ChatSocketService
        .instance
        .conectar();

    if (!mounted) {
      return;
    }

    // ==========================================================
    // ENTRAR A LA SALA
    // ==========================================================

    ChatSocketService
        .instance
        .entrarConversacion(
      widget.conversacionId,
    );

    // ==========================================================
    // ESCUCHAR MENSAJES
    // ==========================================================

    ChatSocketService
        .instance
        .escucharNuevoMensaje(
      (
        data,
      ) async {
        if (!mounted) {
          return;
        }

        final int? conversacionId =
            int.tryParse(
          data['conversacion_id']
              ?.toString() ??
              '',
        );

        if (
          conversacionId !=
          widget.conversacionId
        ) {
          return;
        }

        try {
          final mensaje =
              Mensaje.fromJson(
            data,
          );

          final yaExiste =
              mensajes.any(
            (m) =>
                m.id ==
                mensaje.id,
          );

          if (yaExiste) {
            return;
          }

          setState(() {
            mensajes.add(
              mensaje,
            );
          });

          await ChatService
              .marcarComoLeidos(
            conversacionId:
                widget
                    .conversacionId,
          );

          _bajar();
        } catch (e) {
          debugPrint(
            'ERROR PARSEANDO MENSAJE SOCKET: $e',
          );
        }
      },
    );

    _socketPreparado =
        true;
  }

  // ============================================================
  // CARGAR MENSAJES
  // ============================================================

  Future<void> _cargarMensajes({
    bool mostrarCarga = true,
  }) async {
    if (
      mostrarCarga &&
      mounted
    ) {
      setState(() {
        cargando =
            true;

        error =
            null;
      });
    }

    final resultado =
        await ChatService
            .obtenerMensajes(
      conversacionId:
          widget.conversacionId,
    );

    if (!mounted) {
      return;
    }

    if (
      resultado['success'] ==
      true
    ) {
      final dynamic raw =
          resultado[
              'mensajes'];

      final List<Mensaje> lista =
          [];

      if (raw is List) {
        for (final item in raw) {
          if (item is Mensaje) {
            lista.add(
              item,
            );
          }
        }
      }

      setState(() {
        mensajes =
            lista;

        cargando =
            false;

        error =
            null;
      });

      await ChatService
          .marcarComoLeidos(
        conversacionId:
            widget
                .conversacionId,
      );

      _bajar();

      return;
    }

    setState(() {
      cargando =
          false;

      error =
          resultado['message']
                  ?.toString() ??
              'No se pudieron cargar los mensajes';
    });
  }

  // ============================================================
  // BAJAR AL ÚLTIMO MENSAJE
  // ============================================================

  void _bajar() {
    WidgetsBinding
        .instance
        .addPostFrameCallback(
      (_) {
        if (
          !scrollController
              .hasClients
        ) {
          return;
        }

        scrollController
            .animateTo(
          scrollController
              .position
              .maxScrollExtent,

          duration:
              const Duration(
            milliseconds:
                250,
          ),

          curve:
              Curves.easeOut,
        );
      },
    );
  }

  // ============================================================
  // ENVIAR
  // ============================================================

  Future<void> _enviarMensaje() async {
    final contenido =
        mensajeController.text
            .trim();

    if (
      contenido.isEmpty ||
      enviando
    ) {
      return;
    }

    setState(() {
      enviando =
          true;
    });

    final resultado =
        await ChatService
            .enviarMensaje(
      conversacionId:
          widget.conversacionId,

      contenido:
          contenido,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      enviando =
          false;
    });

    if (
      resultado['success'] !=
      true
    ) {
      ScaffoldMessenger.of(
        context,
      )
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content:
                Text(
              resultado['message']
                      ?.toString() ??
                  'No se pudo enviar el mensaje',
            ),
          ),
        );

      return;
    }

    mensajeController
        .clear();

    // ==========================================================
    // AGREGAR MENSAJE DIRECTAMENTE
    // ==========================================================

    final dynamic rawMensaje =
        resultado['mensaje'];

    if (
      rawMensaje is Mensaje
    ) {
      final yaExiste =
          mensajes.any(
        (m) =>
            m.id ==
            rawMensaje.id,
      );

      if (!yaExiste) {
        setState(() {
          mensajes.add(
            rawMensaje,
          );
        });
      }
    } else if (
      rawMensaje is Map
    ) {
      try {
        final mensaje =
            Mensaje.fromJson(
          Map<String, dynamic>.from(
            rawMensaje,
          ),
        );

        final yaExiste =
            mensajes.any(
          (m) =>
              m.id ==
              mensaje.id,
        );

        if (!yaExiste) {
          setState(() {
            mensajes.add(
              mensaje,
            );
          });
        }
      } catch (e) {
        debugPrint(
          'ERROR AGREGANDO MENSAJE ENVIADO: $e',
        );

        await _cargarMensajes(
          mostrarCarga:
              false,
        );
      }
    } else {
      await _cargarMensajes(
        mostrarCarga:
            false,
      );
    }

    _bajar();
  }

  // ============================================================
  // HORA
  // ============================================================

  String _hora(
    DateTime fecha,
  ) {
    final local =
        fecha.toLocal();

    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // AVATAR SUPERIOR
  // ============================================================

  Widget _avatarUsuario() {
    final String? url =
        widget
            .imagenUsuarioUrl;

    final String inicial =
        widget
                .nombreUsuario
                .trim()
                .isNotEmpty
            ? widget
                .nombreUsuario
                .trim()[0]
                .toUpperCase()
            : '?';

    return CircleAvatar(
      radius:
          19,

      backgroundColor:
          naranja,

      foregroundColor:
          Colors.white,

      backgroundImage:
          url != null &&
                  url.isNotEmpty
              ? NetworkImage(
                  url,
                )
              : null,

      child:
          url == null ||
                  url.isEmpty
              ? Text(
                  inicial,
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                )
              : null,
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    ChatSocketService
        .instance
        .salirConversacion(
      widget.conversacionId,
    );

    ChatSocketService
        .instance
        .dejarDeEscucharNuevoMensaje();

    mensajeController
        .dispose();

    scrollController
        .dispose();

    super.dispose();
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
      appBar:
          AppBar(
        titleSpacing:
            6,

        title:
            Row(
          children: [
            // ==================================================
            // FOTO DEL USUARIO
            // ==================================================

            _avatarUsuario(),

            const SizedBox(
              width:
                  10,
            ),

            // ==================================================
            // NOMBRE
            // ==================================================

            Expanded(
              child:
                  Text(
                widget
                    .nombreUsuario,

                overflow:
                    TextOverflow
                        .ellipsis,

                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),

      body:
          Column(
        children: [
          Expanded(
            child:
                _listaMensajes(
              oscuro,
            ),
          ),

          _barraEnviar(
            oscuro,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LISTA MENSAJES
  // ============================================================

  Widget _listaMensajes(
    bool oscuro,
  ) {
    // ==========================================================
    // CARGANDO
    // ==========================================================

    if (cargando) {
      return const Center(
        child:
            CircularProgressIndicator(
          color:
              naranja,
        ),
      );
    }

    // ==========================================================
    // ERROR
    // ==========================================================

    if (error != null) {
      return Center(
        child:
            Padding(
          padding:
              const EdgeInsets.all(
            30,
          ),

          child:
              Column(
            mainAxisSize:
                MainAxisSize.min,

            children: [
              const Icon(
                Icons
                    .error_outline,
                color:
                    naranja,
                size:
                    50,
              ),

              const SizedBox(
                height:
                    15,
              ),

              Text(
                error!,
                textAlign:
                    TextAlign.center,
              ),

              const SizedBox(
                height:
                    15,
              ),

              FilledButton(
                style:
                    FilledButton.styleFrom(
                  backgroundColor:
                      naranja,

                  foregroundColor:
                      Colors.white,
                ),

                onPressed:
                    () {
                  _cargarMensajes();
                },

                child:
                    const Text(
                  'Reintentar',
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ==========================================================
    // VACÍO
    // ==========================================================

    if (
      mensajes.isEmpty
    ) {
      return const Center(
        child:
            Padding(
          padding:
              EdgeInsets.all(
            30,
          ),

          child:
              Column(
            mainAxisSize:
                MainAxisSize.min,

            children: [
              Icon(
                Icons
                    .waving_hand_outlined,
                size:
                    55,
                color:
                    naranja,
              ),

              SizedBox(
                height:
                    15,
              ),

              Text(
                'Inicia la conversación',
                style:
                    TextStyle(
                  fontSize:
                      18,

                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              SizedBox(
                height:
                    6,
              ),

              Text(
                'Envía el primer mensaje.',
              ),
            ],
          ),
        ),
      );
    }

    // ==========================================================
    // MENSAJES
    // ==========================================================

    return ListView.builder(
      controller:
          scrollController,

      padding:
          const EdgeInsets.fromLTRB(
        14,
        18,
        14,
        18,
      ),

      itemCount:
          mensajes.length,

      itemBuilder:
          (
            context,
            index,
          ) {
        final mensaje =
            mensajes[
                index];

        final bool esMio =
            mensaje
                .esMio;

        return Align(
          alignment:
              esMio
                  ? Alignment
                      .centerRight
                  : Alignment
                      .centerLeft,

          child:
              Container(
            constraints:
                BoxConstraints(
              maxWidth:
                  MediaQuery.of(
                        context,
                      ).size.width *
                      0.76,
            ),

            margin:
                const EdgeInsets.only(
              bottom:
                  8,
            ),

            padding:
                const EdgeInsets.fromLTRB(
              13,
              9,
              10,
              6,
            ),

            decoration:
                BoxDecoration(
              color:
                  esMio
                      ? naranja
                      : oscuro
                          ? panelOscuro
                          : Colors
                              .grey
                              .shade200,

              borderRadius:
                  BorderRadius.only(
                topLeft:
                    const Radius.circular(
                  17,
                ),

                topRight:
                    const Radius.circular(
                  17,
                ),

                bottomLeft:
                    Radius.circular(
                  esMio
                      ? 17
                      : 4,
                ),

                bottomRight:
                    Radius.circular(
                  esMio
                      ? 4
                      : 17,
                ),
              ),
            ),

            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.end,

              children: [
                Align(
                  alignment:
                      Alignment.centerLeft,

                  child:
                      Text(
                    mensaje
                        .contenido,

                    style:
                        TextStyle(
                      color:
                          esMio ||
                                  oscuro
                              ? Colors.white
                              : Colors.black87,

                      fontSize:
                          15,
                    ),
                  ),
                ),

                const SizedBox(
                  height:
                      3,
                ),

                Row(
                  mainAxisSize:
                      MainAxisSize.min,

                  children: [
                    Text(
                      _hora(
                        mensaje
                            .createdAt,
                      ),

                      style:
                          TextStyle(
                        color:
                            esMio
                                ? Colors.white70
                                : oscuro
                                    ? Colors.white60
                                    : Colors.black54,

                        fontSize:
                            10,
                      ),
                    ),

                    if (esMio) ...[
                      const SizedBox(
                        width:
                            4,
                      ),

                      Icon(
                        mensaje
                                .leido
                            ? Icons
                                .done_all
                            : Icons
                                .done,

                        size:
                            15,

                        color:
                            Colors.white70,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // BARRA ENVIAR
  // ============================================================

  Widget _barraEnviar(
    bool oscuro,
  ) {
    return SafeArea(
      top:
          false,

      child:
          Container(
        padding:
            const EdgeInsets.fromLTRB(
          10,
          8,
          10,
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
                      .dividerColor
                      .withValues(
                    alpha:
                        0.35,
                  ),
            ),
          ),
        ),

        child:
            Row(
          crossAxisAlignment:
              CrossAxisAlignment.end,

          children: [
            Expanded(
              child:
                  TextField(
                controller:
                    mensajeController,

                minLines:
                    1,

                maxLines:
                    5,

                textCapitalization:
                    TextCapitalization
                        .sentences,

                onSubmitted:
                    (_) {
                  if (
                    !enviando
                  ) {
                    _enviarMensaje();
                  }
                },

                decoration:
                    InputDecoration(
                  hintText:
                      'Escribe un mensaje...',

                  filled:
                      true,

                  fillColor:
                      oscuro
                          ? panelOscuro
                          : Colors
                              .grey
                              .shade100,

                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      24,
                    ),

                    borderSide:
                        BorderSide.none,
                  ),

                  contentPadding:
                      const EdgeInsets.symmetric(
                    horizontal:
                        17,

                    vertical:
                        11,
                  ),
                ),
              ),
            ),

            const SizedBox(
              width:
                  8,
            ),

            Material(
              color:
                  naranja,

              shape:
                  const CircleBorder(),

              child:
                  IconButton(
                onPressed:
                    enviando
                        ? null
                        : _enviarMensaje,

                color:
                    Colors.white,

                icon:
                    enviando
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
                            Icons.send_rounded,
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}