import 'package:flutter/material.dart';

import '../../models/conversacion.dart';
import '../../services/chat_service.dart';
import '../../services/chat_socket_service.dart';
import 'chat_screen.dart';

class ConversacionesScreen extends StatefulWidget {
  const ConversacionesScreen({
    super.key,
  });

  @override
  State<ConversacionesScreen> createState() =>
      _ConversacionesScreenState();
}

class _ConversacionesScreenState
    extends State<ConversacionesScreen> {
  static const Color naranja =
      Color(0xFFFF7E01);

  List<Conversacion> conversaciones =
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
  // SOCKET.IO
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
    // CUANDO CAMBIA ALGUNA CONVERSACIÓN
    // ==========================================================

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
          mostrarCarga: false,
        );
      },
    );

    // ==========================================================
    // CUANDO LLEGA UN MENSAJE
    //
    // También actualizamos la lista para que:
    // - aparezca último mensaje
    // - cambie el contador
    // - suba la conversación
    // ==========================================================

    ChatSocketService
        .instance
        .escucharNuevoMensaje(
      (
        data,
      ) {
        if (!mounted) {
          return;
        }

        debugPrint(
          'NUEVO MENSAJE EN LISTA: $data',
        );

        _cargar(
          mostrarCarga: false,
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
    bool mostrarCarga = true,
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

      if (resultado['success'] == true) {
        final dynamic raw =
            resultado[
                'conversaciones'];

        final List<Conversacion> lista =
            [];

        if (raw is List) {
          for (final item in raw) {
            if (item is Conversacion) {
              lista.add(
                item,
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
    } catch (e, stack) {
      debugPrint(
        'ERROR PANTALLA CONVERSACIONES: $e',
      );

      debugPrint(
        '$stack',
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
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    ChatSocketService
        .instance
        .dejarDeEscucharConversacionActualizada();

    ChatSocketService
        .instance
        .dejarDeEscucharNuevoMensaje();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          Theme.of(context)
              .scaffoldBackgroundColor,

      appBar:
          AppBar(
        automaticallyImplyLeading:
            false,

        backgroundColor:
            naranja,

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
          SizedBox.expand(
        child:
            _contenido(),
      ),
    );
  }

  // ============================================================
  // CONTENIDO
  // ============================================================

  Widget _contenido() {
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
                  20,
            ),

            Padding(
              padding:
                  const EdgeInsets.symmetric(
                horizontal:
                    30,
              ),

              child:
                  Text(
                error!,
                textAlign:
                    TextAlign.center,
              ),
            ),

            const SizedBox(
              height:
                  20,
            ),

            Center(
              child:
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
                  _cargar();
                },

                child:
                    const Text(
                  'Reintentar',
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ==========================================================
    // SIN CONVERSACIONES
    // ==========================================================

    if (conversaciones.isEmpty) {
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
              Icons
                  .chat_bubble_outline,
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

            Padding(
              padding:
                  EdgeInsets.symmetric(
                horizontal:
                    40,
              ),

              child:
                  Text(
                'Cuando inicies una conversación aparecerá aquí.',
                textAlign:
                    TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    // ==========================================================
    // LISTA
    // ==========================================================

    return RefreshIndicator(
      color:
          naranja,

      onRefresh:
          _cargar,

      child:
          ListView.separated(
        physics:
            const AlwaysScrollableScrollPhysics(),

        padding:
            const EdgeInsets.symmetric(
          vertical:
              8,
        ),

        itemCount:
            conversaciones.length,

        separatorBuilder:
            (
              _,
              __,
            ) {
          return const Divider(
            height:
                1,
          );
        },

        itemBuilder:
            (
              context,
              index,
            ) {
          final conversacion =
              conversaciones[
                  index];

          return ListTile(
            contentPadding:
                const EdgeInsets.symmetric(
              horizontal:
                  18,

              vertical:
                  7,
            ),

            // ==================================================
            // AVATAR
            // ==================================================

            leading:
                CircleAvatar(
              radius:
                  26,

              backgroundColor:
                  naranja,

              foregroundColor:
                  Colors.white,

              child:
                  Text(
                conversacion
                        .nombre
                        .isNotEmpty
                    ? conversacion
                        .nombre[0]
                        .toUpperCase()
                    : '?',

                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),

            // ==================================================
            // NOMBRE
            // ==================================================

            title:
                Text(
              conversacion
                  .nombreCompleto,

              maxLines:
                  1,

              overflow:
                  TextOverflow
                      .ellipsis,

              style:
                  TextStyle(
                fontWeight:
                    conversacion
                                .mensajesNoLeidos >
                            0
                        ? FontWeight.bold
                        : FontWeight.w600,
              ),
            ),

            // ==================================================
            // ÚLTIMO MENSAJE
            // ==================================================

            subtitle:
                Text(
              conversacion
                      .ultimoMensaje ??
                  'Nueva conversación',

              maxLines:
                  1,

              overflow:
                  TextOverflow
                      .ellipsis,

              style:
                  TextStyle(
                fontWeight:
                    conversacion
                                .mensajesNoLeidos >
                            0
                        ? FontWeight.w600
                        : FontWeight.normal,
              ),
            ),

            // ==================================================
            // NO LEÍDOS
            // ==================================================

            trailing:
                conversacion
                            .mensajesNoLeidos >
                        0
                    ? Container(
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
                              7,
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
                    : const Icon(
                        Icons
                            .chevron_right,
                      ),

            // ==================================================
            // ABRIR
            // ==================================================

            onTap:
                () {
              _abrir(
                conversacion,
              );
            },
          );
        },
      ),
    );
  }
}