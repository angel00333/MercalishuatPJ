import 'package:flutter/material.dart';

import '../../models/conversacion.dart';
import '../../services/chat_service.dart';
import '../../services/chat_socket_service.dart';
import 'chat_screen.dart';

class ConversacionesScreen
    extends StatefulWidget {
  const ConversacionesScreen({
    super.key,
  });

  @override
  State<ConversacionesScreen>
      createState() =>
          _ConversacionesScreenState();
}

class _ConversacionesScreenState
    extends State<
        ConversacionesScreen> {
  static const Color naranja =
      Color(0xFFFF7E01);

  static const Color panelOscuro =
      Color(0xFF3A2B5D);

  List<Conversacion>
      conversaciones =
      [];

  bool cargando =
      true;

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

    await _cargar();
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

    ChatSocketService
        .instance
        .escucharConversacionActualizada(
      (
        data,
      ) {
        if (!mounted) {
          return;
        }

        debugPrint(
          'CONVERSACIÓN ACTUALIZADA: $data',
        );

        _cargar(
          mostrarCarga:
              false,
        );
      },
    );

    _socketPreparado =
        true;
  }

  // ============================================================
  // CARGAR
  // ============================================================

  Future<void> _cargar({
    bool mostrarCarga =
        true,
  }) async {
    if (!mounted) {
      return;
    }

    if (mostrarCarga) {
      setState(() {
        cargando =
            true;

        error =
            null;
      });
    }

    try {
      final resultado =
          await ChatService
              .listarConversaciones();

      if (!mounted) {
        return;
      }

      if (
        resultado['success'] ==
        true
      ) {
        final dynamic raw =
            resultado[
                'conversaciones'];

        final List<Conversacion>
            lista =
            [];

        if (raw is List) {
          for (
            final item in raw
          ) {
            if (
              item is Conversacion
            ) {
              lista.add(
                item,
              );
            } else if (
              item is Map
            ) {
              lista.add(
                Conversacion.fromJson(
                  Map<String, dynamic>.from(
                    item,
                  ),
                ),
              );
            }
          }
        }

        setState(() {
          conversaciones =
              lista;

          cargando =
              false;

          error =
              null;
        });

        return;
      }

      setState(() {
        cargando =
            false;

        error =
            resultado['message']
                    ?.toString() ??
                'No se pudieron cargar las conversaciones';
      });
    } catch (
      e
    ) {
      debugPrint(
        'ERROR CONVERSACIONES: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        cargando =
            false;

        error =
            'Error cargando conversaciones';
      });
    }
  }

  // ============================================================
  // ABRIR CHAT
  // ============================================================

  Future<void> _abrir(
    Conversacion conversacion,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) {
          return ChatScreen(
            conversacionId:
                conversacion.id,

            nombreUsuario:
                conversacion
                    .nombreCompleto,

            imagenUsuarioUrl:
                conversacion
                    .imagenUsuarioUrl,
          );
        },
      ),
    );

    if (!mounted) {
      return;
    }

    await _cargar(
      mostrarCarga:
          false,
    );
  }

  // ============================================================
  // AVATAR
  // ============================================================

  Widget _avatar(
    Conversacion conversacion,
  ) {
    final String? url =
        conversacion
            .imagenUsuarioUrl;

    final bool tieneImagen =
        url != null &&
        url.trim().isNotEmpty;

    final String inicial =
        conversacion
                .nombre
                .trim()
                .isNotEmpty
            ? conversacion
                .nombre
                .trim()[0]
                .toUpperCase()
            : '?';

    return CircleAvatar(
      radius:
          25,

      backgroundColor:
          naranja,

      foregroundColor:
          Colors.white,

      backgroundImage:
          tieneImagen
              ? NetworkImage(
                  url!,
                )
              : null,

      child:
          !tieneImagen
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
        .dejarDeEscucharConversacionActualizada();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final bool oscuro =
        Theme.of(context)
                .brightness ==
            Brightness.dark;

    final Color fondo =
        Theme.of(context)
            .scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor:
          fondo,

      appBar:
          AppBar(
        automaticallyImplyLeading:
            false,

        // EN OSCURO NO HAY BARRA NARANJA
        backgroundColor:
            oscuro
                ? fondo
                : naranja,

        surfaceTintColor:
            Colors.transparent,

        elevation:
            0,

        foregroundColor:
            Colors.white,

        centerTitle:
            true,

        title:
            const Text(
          'Mensajes',

          style:
              TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),

        actions: [
          IconButton(
            tooltip:
                'Actualizar',

            onPressed:
                () {
              _cargar(
                mostrarCarga:
                    false,
              );
            },

            icon:
                const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),

      body:
          _contenido(
        oscuro,
      ),
    );
  }

  // ============================================================
  // CONTENIDO
  // ============================================================

  Widget _contenido(
    bool oscuro,
  ) {
    if (cargando) {
      return const Center(
        child:
            CircularProgressIndicator(
          color:
              naranja,
        ),
      );
    }

    if (error != null) {
      return RefreshIndicator(
        color:
            naranja,

        onRefresh:
            _cargar,

        child:
            ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),

          children: [
            const SizedBox(
              height:
                  150,
            ),

            const Icon(
              Icons.error_outline,
              size:
                  65,
              color:
                  naranja,
            ),

            const SizedBox(
              height:
                  18,
            ),

            Text(
              error!,

              textAlign:
                  TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (
      conversaciones.isEmpty
    ) {
      return RefreshIndicator(
        color:
            naranja,

        onRefresh:
            _cargar,

        child:
            ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),

          children:
              const [
            SizedBox(
              height:
                  170,
            ),

            Icon(
              Icons.chat_bubble_outline,
              size:
                  70,
              color:
                  naranja,
            ),

            SizedBox(
              height:
                  20,
            ),

            Text(
              'Todavía no tienes conversaciones',

              textAlign:
                  TextAlign.center,

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
                  8,
            ),

            Text(
              'Cuando inicies una conversación aparecerá aquí.',

              textAlign:
                  TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color:
          naranja,

      onRefresh:
          _cargar,

      child:
          ListView.builder(
        padding:
            const EdgeInsets.fromLTRB(
          16,
          10,
          16,
          24,
        ),

        itemCount:
            conversaciones.length,

        itemBuilder:
            (
              context,
              index,
            ) {
          final Conversacion
              conversacion =
              conversaciones[
                  index];

          return Container(
            margin:
                const EdgeInsets.only(
              bottom:
                  10,
            ),

            decoration:
                BoxDecoration(
              color:
                  oscuro
                      ? panelOscuro
                      : Colors.white,

              borderRadius:
                  BorderRadius.circular(
                18,
              ),
            ),

            child:
                Material(
              color:
                  Colors.transparent,

              child:
                  InkWell(
                borderRadius:
                    BorderRadius.circular(
                  18,
                ),

                onTap:
                    () {
                  _abrir(
                    conversacion,
                  );
                },

                child:
                    Padding(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal:
                        14,

                    vertical:
                        13,
                  ),

                  child:
                      Row(
                    children: [
                      _avatar(
                        conversacion,
                      ),

                      const SizedBox(
                        width:
                            12,
                      ),

                      Expanded(
                        child:
                            Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,

                          children: [
                            Text(
                              conversacion
                                  .nombreCompleto,

                              maxLines:
                                  1,

                              overflow:
                                  TextOverflow.ellipsis,

                              style:
                                  TextStyle(
                                color:
                                    oscuro
                                        ? Colors.white
                                        : Colors.black87,

                                fontSize:
                                    16,

                                fontWeight:
                                    conversacion
                                                .mensajesNoLeidos >
                                            0
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                              ),
                            ),

                            const SizedBox(
                              height:
                                  4,
                            ),

                            Text(
                              conversacion
                                      .ultimoMensaje ??
                                  'Nueva conversación',

                              maxLines:
                                  1,

                              overflow:
                                  TextOverflow.ellipsis,

                              style:
                                  TextStyle(
                                color:
                                    oscuro
                                        ? Colors.white60
                                        : Colors.black54,

                                fontSize:
                                    13,

                                fontWeight:
                                    conversacion
                                                .mensajesNoLeidos >
                                            0
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        width:
                            10,
                      ),

                      if (
                        conversacion
                                .mensajesNoLeidos >
                            0
                      )
                        Container(
                          constraints:
                              const BoxConstraints(
                            minWidth:
                                24,

                            minHeight:
                                24,
                          ),

                          padding:
                              const EdgeInsets.symmetric(
                            horizontal:
                                6,
                          ),

                          alignment:
                              Alignment.center,

                          decoration:
                              const BoxDecoration(
                            color:
                                naranja,

                            shape:
                                BoxShape.circle,
                          ),

                          child:
                              Text(
                            conversacion
                                .mensajesNoLeidos
                                .toString(),

                            style:
                                const TextStyle(
                              color:
                                  Colors.white,

                              fontSize:
                                  11,

                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        const Icon(
                          Icons.chevron_right,
                          color:
                              naranja,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}