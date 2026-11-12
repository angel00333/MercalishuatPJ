import 'package:flutter/material.dart';

import '../../config/app_theme.dart';

import '../../models/mensaje.dart';

import '../../services/chat_service.dart';
import '../../services/chat_socket_service.dart';

class ChatScreen extends StatefulWidget {
  final int conversacionId;

  // ============================================================
  // PROPIETARIO
  // ============================================================

  final String nombreUsuario;

  final String? imagenUsuarioUrl;

  // ============================================================
  // EMPRENDIMIENTO
  // ============================================================

  final String? nombreEmprendimiento;

  final String? imagenEmprendimientoUrl;

  const ChatScreen({
    super.key,
    required this.conversacionId,
    required this.nombreUsuario,
    this.imagenUsuarioUrl,
    this.nombreEmprendimiento,
    this.imagenEmprendimientoUrl,
  });

  @override
  State<ChatScreen> createState() =>
      _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController mensajeController =
      TextEditingController();

  final ScrollController scrollController =
      ScrollController();

  // ============================================================
  // DATOS
  // ============================================================

  List<Mensaje> mensajes = [];

  bool cargando = true;

  bool enviando = false;

  String? error;

  bool _socketPreparado = false;

  // ============================================================
  // DATOS VISUALES DEL CHAT
  // ============================================================

  bool get _tieneEmprendimiento {
    return widget.nombreEmprendimiento != null &&
        widget.nombreEmprendimiento!
            .trim()
            .isNotEmpty;
  }

  String get _tituloChat {
    if (_tieneEmprendimiento) {
      return widget.nombreEmprendimiento!
          .trim();
    }

    final nombre =
        widget.nombreUsuario.trim();

    return nombre.isNotEmpty
        ? nombre
        : 'Conversación';
  }

  String get _subtituloChat {
    if (_tieneEmprendimiento) {
      final propietario =
          widget.nombreUsuario.trim();

      return propietario.isNotEmpty
          ? propietario
          : 'Propietario';
    }

    return 'Conversación';
  }

  String? get _imagenChat {
    final emprendimiento =
        widget.imagenEmprendimientoUrl
            ?.trim();

    if (emprendimiento != null &&
        emprendimiento.isNotEmpty) {
      return emprendimiento;
    }

    final usuario =
        widget.imagenUsuarioUrl?.trim();

    if (usuario != null &&
        usuario.isNotEmpty) {
      return usuario;
    }

    return null;
  }

  // ============================================================
  // INIT
  // ============================================================

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

    await ChatSocketService.instance.conectar();

    if (!mounted) {
      return;
    }

    // ==========================================================
    // ENTRAR A LA CONVERSACIÓN
    // ==========================================================

    ChatSocketService.instance.entrarConversacion(
      widget.conversacionId,
    );

    // ==========================================================
    // RECONEXIÓN
    // ==========================================================

    ChatSocketService.instance.escucharConexion(
      () {
        if (!mounted) {
          return;
        }

        ChatSocketService.instance.entrarConversacion(
          widget.conversacionId,
        );
      },
    );

    // ==========================================================
    // NUEVO MENSAJE
    // ==========================================================

    ChatSocketService.instance.escucharNuevoMensaje(
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

        if (conversacionId !=
            widget.conversacionId) {
          return;
        }

        try {
          final mensaje =
              Mensaje.fromJson(
            Map<String, dynamic>.from(
              data,
            ),
          );

          final bool yaExiste =
              mensajes.any(
            (
              actual,
            ) =>
                actual.id ==
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

          await ChatService.marcarComoLeidos(
            conversacionId:
                widget.conversacionId,
          );

          _bajar();
        } catch (e) {
          debugPrint(
            'ERROR PARSEANDO MENSAJE SOCKET: $e',
          );
        }
      },
    );

    // ==========================================================
    // MENSAJES LEÍDOS
    // ==========================================================

    ChatSocketService.instance.escucharMensajesLeidos(
      (
        data,
      ) {
        if (!mounted) {
          return;
        }

        final int? conversacionId =
            int.tryParse(
          data['conversacion_id']
                  ?.toString() ??
              '',
        );

        if (conversacionId !=
            widget.conversacionId) {
          return;
        }

        _marcarMensajesPropiosComoLeidos();
      },
    );

    _socketPreparado = true;
  }

  // ============================================================
  // MARCAR MENSAJES PROPIOS COMO LEÍDOS
  // ============================================================

  void _marcarMensajesPropiosComoLeidos() {
    if (!mounted) {
      return;
    }

    bool huboCambios =
        false;

    final actualizados =
        mensajes.map(
      (
        mensaje,
      ) {
        if (mensaje.esMio &&
            !mensaje.leido) {
          huboCambios =
              true;

          return Mensaje(
            id:
                mensaje.id,

            conversacionId:
                mensaje.conversacionId,

            remitenteId:
                mensaje.remitenteId,

            contenido:
                mensaje.contenido,

            leido:
                true,

            createdAt:
                mensaje.createdAt,

            esMio:
                mensaje.esMio,
          );
        }

        return mensaje;
      },
    ).toList();

    if (!huboCambios) {
      return;
    }

    setState(() {
      mensajes =
          actualizados;
    });
  }

  // ============================================================
  // CARGAR MENSAJES
  // ============================================================

  Future<void> _cargarMensajes({
    bool mostrarCarga = true,
  }) async {
    if (mostrarCarga &&
        mounted) {
      setState(() {
        cargando =
            true;

        error =
            null;
      });
    }

    try {
      final resultado =
          await ChatService.obtenerMensajes(
        conversacionId:
            widget.conversacionId,
      );

      if (!mounted) {
        return;
      }

      if (resultado['success'] == true) {
        final dynamic raw =
            resultado['mensajes'];

        final List<Mensaje> lista = [];

        if (raw is List) {
          for (final item in raw) {
            if (item is Mensaje) {
              lista.add(
                item,
              );
            } else if (item is Map) {
              try {
                lista.add(
                  Mensaje.fromJson(
                    Map<String, dynamic>.from(
                      item,
                    ),
                  ),
                );
              } catch (e) {
                debugPrint(
                  'ERROR PARSEANDO MENSAJE: $e',
                );
              }
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

        await ChatService.marcarComoLeidos(
          conversacionId:
              widget.conversacionId,
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
    } catch (e) {
      debugPrint(
        'ERROR CARGANDO CHAT: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        cargando =
            false;

        error =
            'No se pudieron cargar los mensajes';
      });
    }
  }

  // ============================================================
  // SCROLL ABAJO
  // ============================================================

  void _bajar() {
    WidgetsBinding.instance.addPostFrameCallback(
      (
        _,
      ) {
        if (!mounted ||
            !scrollController.hasClients) {
          return;
        }

        final destino =
            scrollController
                .position
                .maxScrollExtent;

        scrollController.animateTo(
          destino,

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
  // ENVIAR MENSAJE
  // ============================================================

  Future<void> _enviarMensaje() async {
    final contenido =
        mensajeController.text.trim();

    if (contenido.isEmpty ||
        enviando) {
      return;
    }

    setState(() {
      enviando =
          true;
    });

    try {
      final resultado =
          await ChatService.enviarMensaje(
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

      if (resultado['success'] != true) {
        ScaffoldMessenger.of(context)
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

      mensajeController.clear();

      setState(() {});

      final dynamic rawMensaje =
          resultado['mensaje'];

      // ========================================================
      // MENSAJE YA CONVERTIDO
      // ========================================================

      if (rawMensaje is Mensaje) {
        final bool yaExiste =
            mensajes.any(
          (
            mensaje,
          ) =>
              mensaje.id ==
              rawMensaje.id,
        );

        if (!yaExiste) {
          setState(() {
            mensajes.add(
              rawMensaje,
            );
          });
        }
      }

      // ========================================================
      // MENSAJE JSON
      // ========================================================

      else if (rawMensaje is Map) {
        try {
          final mensaje =
              Mensaje.fromJson(
            Map<String, dynamic>.from(
              rawMensaje,
            ),
          );

          final bool yaExiste =
              mensajes.any(
            (
              actual,
            ) =>
                actual.id ==
                mensaje.id,
          );

          if (!yaExiste) {
            setState(() {
              mensajes.add(
                mensaje,
              );
            });
          }
        } catch (_) {
          await _cargarMensajes(
            mostrarCarga:
                false,
          );
        }
      }

      // ========================================================
      // FALLBACK
      // ========================================================

      else {
        await _cargarMensajes(
          mostrarCarga:
              false,
        );
      }

      _bajar();
    } catch (e) {
      debugPrint(
        'ERROR ENVIANDO MENSAJE: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        enviando =
            false;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content:
                Text(
              'No se pudo enviar el mensaje',
            ),
          ),
        );
    }
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
  // MISMO DÍA
  // ============================================================

  bool _mismoDia(
    DateTime a,
    DateTime b,
  ) {
    final localA =
        a.toLocal();

    final localB =
        b.toLocal();

    return localA.year ==
            localB.year &&
        localA.month ==
            localB.month &&
        localA.day ==
            localB.day;
  }

  // ============================================================
  // TEXTO FECHA
  // ============================================================

  String _fechaTexto(
    DateTime fecha,
  ) {
    final local =
        fecha.toLocal();

    final ahora =
        DateTime.now();

    final hoy =
        DateTime(
      ahora.year,
      ahora.month,
      ahora.day,
    );

    final dia =
        DateTime(
      local.year,
      local.month,
      local.day,
    );

    final diferencia =
        hoy.difference(
      dia,
    );

    if (diferencia.inDays == 0) {
      return 'Hoy';
    }

    if (diferencia.inDays == 1) {
      return 'Ayer';
    }

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }

  // ============================================================
  // AVATAR
  // ============================================================

  Widget _avatarUsuario({
    double radio = 20,
  }) {
    final String? url =
        _imagenChat;

    final bool tieneImagen =
        url != null &&
        url.trim().isNotEmpty;

    final String titulo =
        _tituloChat.trim();

    final String inicial =
        titulo.isNotEmpty
            ? titulo[0].toUpperCase()
            : '?';

    return Container(
      width:
          radio * 2,

      height:
          radio * 2,

      padding:
          const EdgeInsets.all(
        2,
      ),

      decoration:
          const BoxDecoration(
        shape:
            BoxShape.circle,

        color:
            Colors.white,
      ),

      child:
          ClipOval(
        child:
            tieneImagen
                ? Image.network(
                    url,

                    fit:
                        BoxFit.cover,

                    errorBuilder:
                        (
                      context,
                      error,
                      stackTrace,
                    ) {
                      return _avatarFallback(
                        inicial,
                      );
                    },
                  )
                : _avatarFallback(
                    inicial,
                  ),
      ),
    );
  }

  Widget _avatarFallback(
    String inicial,
  ) {
    return Container(
      color:
          AppColors.morado,

      alignment:
          Alignment.center,

      child:
          Text(
        inicial,

        style:
            const TextStyle(
          color:
              Colors.white,

          fontSize:
              16,

          fontWeight:
              FontWeight.w900,
        ),
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    ChatSocketService.instance.salirConversacion(
      widget.conversacionId,
    );

    ChatSocketService
        .instance
        .dejarDeEscucharNuevoMensaje();

    ChatSocketService
        .instance
        .dejarDeEscucharMensajesLeidos();

    ChatSocketService
        .instance
        .dejarDeEscucharConexion();

    mensajeController.dispose();

    scrollController.dispose();

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
        Theme.of(context).brightness ==
            Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset:
          true,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar:
          AppBar(
        backgroundColor:
            oscuro
                ? AppColors.moradoOscuro
                : AppColors.naranja,

        foregroundColor:
            Colors.white,

        surfaceTintColor:
            Colors.transparent,

        elevation:
            0,

        titleSpacing:
            2,

        title:
            Row(
          children: [
            // ==================================================
            // LOGO EMPRENDIMIENTO
            // ==================================================

            _avatarUsuario(
              radio:
                  20,
            ),

            const SizedBox(
              width:
                  10,
            ),

            // ==================================================
            // EMPRENDIMIENTO + PROPIETARIO
            // ==================================================

            Expanded(
              child:
                  Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                mainAxisAlignment:
                    MainAxisAlignment.center,

                children: [
                  // ============================================
                  // EMPRENDIMIENTO
                  // ============================================

                  Text(
                    _tituloChat,

                    maxLines:
                        1,

                    overflow:
                        TextOverflow.ellipsis,

                    style:
                        const TextStyle(
                      color:
                          Colors.white,

                      fontSize:
                          17,

                      height:
                          1.10,

                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),

                  const SizedBox(
                    height:
                        2,
                  ),

                  // ============================================
                  // PROPIETARIO
                  // ============================================

                  Row(
                    children: [
                      Icon(
                        _tieneEmprendimiento
                            ? Icons.person_outline_rounded
                            : Icons.chat_bubble_outline_rounded,

                        color:
                            Colors.white.withValues(
                          alpha:
                              0.78,
                        ),

                        size:
                            11,
                      ),

                      const SizedBox(
                        width:
                            4,
                      ),

                      Expanded(
                        child:
                            Text(
                          _subtituloChat,

                          maxLines:
                              1,

                          overflow:
                              TextOverflow.ellipsis,

                          style:
                              TextStyle(
                            color:
                                Colors.white.withValues(
                              alpha:
                                  0.80,
                            ),

                            fontSize:
                                11,

                            fontWeight:
                                FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        actions: [
          IconButton(
            tooltip:
                'Actualizar',

            onPressed:
                () {
              _cargarMensajes(
                mostrarCarga:
                    false,
              );
            },

            icon:
                const Icon(
              Icons.refresh_rounded,
            ),
          ),

          const SizedBox(
            width:
                4,
          ),
        ],
      ),

      // ========================================================
      // BODY
      // ========================================================

      body:
          Column(
        children: [
          // ====================================================
          // MENSAJES
          // ====================================================

          Expanded(
            child:
                Container(
              decoration:
                  BoxDecoration(
                gradient:
                    LinearGradient(
                  begin:
                      Alignment.topCenter,

                  end:
                      Alignment.bottomCenter,

                  colors:
                      oscuro
                          ? const [
                              Color(
                                0xFF171320,
                              ),
                              Color(
                                0xFF20182D,
                              ),
                            ]
                          : const [
                              Color(
                                0xFFF7F5F9,
                              ),
                              Color(
                                0xFFFFFFFF,
                              ),
                            ],
                ),
              ),

              child:
                  _listaMensajes(
                oscuro,
              ),
            ),
          ),

          // ====================================================
          // INPUT
          // ====================================================

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
            CircularProgressIndicator(),
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
                Icons.cloud_off_outlined,

                color:
                    AppColors.naranja,

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

              FilledButton.icon(
                onPressed:
                    _cargarMensajes,

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
      );
    }

    // ==========================================================
    // VACÍO
    // ==========================================================

    if (mensajes.isEmpty) {
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
              Container(
                width:
                    80,

                height:
                    80,

                decoration:
                    BoxDecoration(
                  color:
                      AppColors.naranja.withValues(
                    alpha:
                        0.10,
                  ),

                  shape:
                      BoxShape.circle,
                ),

                child:
                    const Icon(
                  Icons.waving_hand_rounded,

                  size:
                      38,

                  color:
                      AppColors.naranja,
                ),
              ),

              const SizedBox(
                height:
                    16,
              ),

              Text(
                _tieneEmprendimiento
                    ? 'Escribe a $_tituloChat'
                    : 'Inicia la conversación',

                textAlign:
                    TextAlign.center,

                style:
                    const TextStyle(
                  fontSize:
                      18,

                  fontWeight:
                      FontWeight.w800,
                ),
              ),

              const SizedBox(
                height:
                    5,
              ),

              Text(
                _tieneEmprendimiento
                    ? 'Consulta productos, disponibilidad o información del emprendimiento.'
                    : 'Envía el primer mensaje.',

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
      );
    }

    // ==========================================================
    // LISTA
    // ==========================================================

    return ListView.builder(
      controller:
          scrollController,

      keyboardDismissBehavior:
          ScrollViewKeyboardDismissBehavior
              .onDrag,

      padding:
          const EdgeInsets.fromLTRB(
        12,
        14,
        12,
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
            mensajes[index];

        final bool mostrarFecha =
            index == 0 ||
                !_mismoDia(
                  mensajes[index - 1].createdAt,
                  mensaje.createdAt,
                );

        return Column(
          children: [
            if (mostrarFecha)
              _separadorFecha(
                mensaje.createdAt,
                oscuro,
              ),

            _burbujaMensaje(
              mensaje,
              oscuro,
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // FECHA
  // ============================================================

  Widget _separadorFecha(
    DateTime fecha,
    bool oscuro,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical:
            12,
      ),

      child:
          Center(
        child:
            Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal:
                12,

            vertical:
                6,
          ),

          decoration:
              BoxDecoration(
            color:
                oscuro
                    ? AppColors.tarjetaOscura
                    : Colors.white,

            borderRadius:
                BorderRadius.circular(
              20,
            ),

            border:
                Border.all(
              color:
                  oscuro
                      ? AppColors.bordeOscuro
                      : AppColors.bordeClaro,
            ),
          ),

          child:
              Text(
            _fechaTexto(
              fecha,
            ),

            style:
                TextStyle(
              fontSize:
                  11,

              fontWeight:
                  FontWeight.w700,

              color:
                  Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(
                        alpha:
                            0.65,
                      ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BURBUJA MENSAJE
  // ============================================================

  Widget _burbujaMensaje(
    Mensaje mensaje,
    bool oscuro,
  ) {
    final bool esMio =
        mensaje.esMio;

    final Color fondoRecibido =
        oscuro
            ? AppColors.tarjetaOscura
            : Colors.white;

    return Align(
      alignment:
          esMio
              ? Alignment.centerRight
              : Alignment.centerLeft,

      child:
          Container(
        constraints:
            BoxConstraints(
          maxWidth:
              MediaQuery.of(context)
                      .size
                      .width *
                  0.78,
        ),

        margin:
            const EdgeInsets.only(
          bottom:
              5,
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
          // ====================================================
          // MIS MENSAJES = NARANJA
          // RECIBIDOS = TARJETA
          // ====================================================

          color:
              esMio
                  ? AppColors.naranja
                  : fondoRecibido,

          borderRadius:
              BorderRadius.only(
            topLeft:
                const Radius.circular(
              18,
            ),

            topRight:
                const Radius.circular(
              18,
            ),

            bottomLeft:
                Radius.circular(
              esMio
                  ? 18
                  : 5,
            ),

            bottomRight:
                Radius.circular(
              esMio
                  ? 5
                  : 18,
            ),
          ),

          border:
              esMio
                  ? null
                  : Border.all(
                      color:
                          oscuro
                              ? AppColors.bordeOscuro
                              : AppColors.bordeClaro,
                    ),

          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withValues(
                alpha:
                    oscuro
                        ? 0.12
                        : 0.04,
              ),

              blurRadius:
                  6,

              offset:
                  const Offset(
                0,
                2,
              ),
            ),
          ],
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
                mensaje.contenido,

                style:
                    TextStyle(
                  color:
                      esMio
                          ? Colors.white
                          : Theme.of(context)
                              .colorScheme
                              .onSurface,

                  fontSize:
                      15,

                  height:
                      1.28,
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
                    mensaje.createdAt,
                  ),

                  style:
                      TextStyle(
                    color:
                        esMio
                            ? Colors.white70
                            : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(
                                  alpha:
                                      0.50,
                                ),

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
                    mensaje.leido
                        ? Icons.done_all_rounded
                        : Icons.done_rounded,

                    size:
                        15,

                    color:
                        mensaje.leido
                            ? const Color(
                                0xFFB9E5FF,
                              )
                            : Colors.white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BARRA DE ENVÍO
  // ============================================================

  Widget _barraEnviar(
    bool oscuro,
  ) {
    final bool hayTexto =
        mensajeController.text
            .trim()
            .isNotEmpty;

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
              oscuro
                  ? AppColors.moradoOscuro
                  : Colors.white,

          border:
              Border(
            top:
                BorderSide(
              color:
                  Theme.of(context)
                      .dividerColor
                      .withValues(
                        alpha:
                            0.40,
                      ),
            ),
          ),
        ),

        child:
            Row(
          crossAxisAlignment:
              CrossAxisAlignment.end,

          children: [
            // ==================================================
            // INPUT
            // ==================================================

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
                    TextCapitalization.sentences,

                onChanged:
                    (
                  _,
                ) {
                  setState(() {});
                },

                decoration:
                    InputDecoration(
                  hintText:
                      _tieneEmprendimiento
                          ? 'Escribe a $_tituloChat...'
                          : 'Escribe un mensaje...',

                  filled:
                      true,

                  fillColor:
                      oscuro
                          ? AppColors.tarjetaOscura
                          : const Color(
                              0xFFF3F1F5,
                            ),

                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      26,
                    ),

                    borderSide:
                        BorderSide.none,
                  ),

                  enabledBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      26,
                    ),

                    borderSide:
                        BorderSide.none,
                  ),

                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      26,
                    ),

                    borderSide:
                        const BorderSide(
                      color:
                          AppColors.naranja,

                      width:
                          1,
                    ),
                  ),

                  contentPadding:
                      const EdgeInsets.symmetric(
                    horizontal:
                        18,

                    vertical:
                        12,
                  ),
                ),
              ),
            ),

            const SizedBox(
              width:
                  8,
            ),

            // ==================================================
            // ENVIAR
            // ==================================================

            AnimatedContainer(
              duration:
                  const Duration(
                milliseconds:
                    180,
              ),

              width:
                  50,

              height:
                  50,

              decoration:
                  BoxDecoration(
                color:
                    hayTexto &&
                            !enviando
                        ? AppColors.naranja
                        : AppColors.naranja.withValues(
                            alpha:
                                0.55,
                          ),

                shape:
                    BoxShape.circle,

                boxShadow: [
                  if (hayTexto &&
                      !enviando)
                    BoxShadow(
                      color:
                          AppColors.naranja.withValues(
                        alpha:
                            0.25,
                      ),

                      blurRadius:
                          10,

                      offset:
                          const Offset(
                        0,
                        4,
                      ),
                    ),
                ],
              ),

              child:
                  IconButton(
                tooltip:
                    'Enviar',

                onPressed:
                    enviando ||
                            !hayTexto
                        ? null
                        : _enviarMensaje,

                color:
                    Colors.white,

                disabledColor:
                    Colors.white70,

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