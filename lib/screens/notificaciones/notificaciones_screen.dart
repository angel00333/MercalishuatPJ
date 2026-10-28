import 'package:flutter/material.dart';

import '../../models/conversacion.dart';
import '../../models/notificacion.dart';
import '../../services/chat_service.dart';
import '../../services/chat_socket_service.dart';
import '../../services/notificacion_service.dart';
import '../chat/chat_screen.dart';

class NotificacionesScreen
    extends StatefulWidget {
  const NotificacionesScreen({
    super.key,
  });

  @override
  State<NotificacionesScreen>
      createState() =>
          _NotificacionesScreenState();
}

class _NotificacionesScreenState
    extends State<NotificacionesScreen> {
  static const Color naranja =
      Color(0xFFFF7E01);

  static const Color panelOscuro =
      Color(0xFF3A2B5D);

  List<Notificacion>
      _notificaciones =
      [];

  final Map<int, Conversacion>
      _conversacionesPorId =
      {};

  bool _cargando =
      true;

  String? _error;

  @override
  void initState() {
    super.initState();

    _iniciar();
  }

  // ============================================================
  // INICIAR
  // ============================================================

  Future<void> _iniciar() async {
    await ChatSocketService
        .instance
        .conectar();

    if (!mounted) {
      return;
    }

    ChatSocketService
        .instance
        .escucharNuevaNotificacion(
      (
        data,
      ) {
        if (!mounted) {
          return;
        }

        _cargar(
          mostrarCarga:
              false,
        );
      },
    );

    await _cargar();
  }

  // ============================================================
  // CARGAR
  // ============================================================

  Future<void> _cargar({
    bool mostrarCarga =
        true,
  }) async {
    if (
      mostrarCarga &&
      mounted
    ) {
      setState(() {
        _cargando =
            true;

        _error =
            null;
      });
    }

    try {
      final resultado =
          await NotificacionService
              .listar();

      if (!mounted) {
        return;
      }

      if (
        resultado['success'] !=
        true
      ) {
        setState(() {
          _cargando =
              false;

          _error =
              resultado['message']
                      ?.toString() ??
                  'No se pudieron cargar las notificaciones';
        });

        return;
      }

      final List<Notificacion>
          lista =
          [];

      final dynamic raw =
          resultado[
              'notificaciones'];

      if (
        raw is List<Notificacion>
      ) {
        lista.addAll(
          raw,
        );
      } else if (
        raw is List
      ) {
        for (
          final item in raw
        ) {
          if (
            item is Notificacion
          ) {
            lista.add(
              item,
            );
          } else if (
            item is Map
          ) {
            lista.add(
              Notificacion.fromJson(
                Map<String, dynamic>.from(
                  item,
                ),
              ),
            );
          }
        }
      }

      // ========================================================
      // RESOLVER CONVERSACIONES
      // ========================================================

      final Map<int, Conversacion>
          conversaciones =
          {};

      try {
        final resultadoConversaciones =
            await ChatService
                .listarConversaciones();

        if (
          resultadoConversaciones[
                  'success'] ==
              true
        ) {
          final dynamic rawConversaciones =
              resultadoConversaciones[
                  'conversaciones'];

          if (
            rawConversaciones is List
          ) {
            for (
              final item
              in rawConversaciones
            ) {
              if (
                item is Conversacion
              ) {
                conversaciones[
                    item.id] =
                    item;
              } else if (
                item is Map
              ) {
                final Conversacion
                    conversacion =
                    Conversacion
                        .fromJson(
                  Map<String, dynamic>.from(
                    item,
                  ),
                );

                conversaciones[
                    conversacion.id] =
                    conversacion;
              }
            }
          }
        }
      } catch (
        e
      ) {
        debugPrint(
          'ERROR RESOLVIENDO CONVERSACIONES: $e',
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _notificaciones =
            lista;

        _conversacionesPorId
          ..clear()
          ..addAll(
            conversaciones,
          );

        _cargando =
            false;

        _error =
            null;
      });
    } catch (
      e
    ) {
      debugPrint(
        'ERROR CARGANDO NOTIFICACIONES: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _cargando =
            false;

        _error =
            'No se pudieron cargar las notificaciones';
      });
    }
  }

  // ============================================================
  // CONVERSACIÓN
  // ============================================================

  Conversacion? _conversacionDe(
    Notificacion notificacion,
  ) {
    if (
      notificacion.referenciaTipo !=
              'conversacion' ||
      notificacion.referenciaId ==
          null
    ) {
      return null;
    }

    return _conversacionesPorId[
        notificacion
            .referenciaId!];
  }

  // ============================================================
  // NOMBRE
  // ============================================================

  String _nombreMostrado(
    Notificacion notificacion,
  ) {
    final Conversacion?
        conversacion =
        _conversacionDe(
      notificacion,
    );

    final String?
        nombreConversacion =
        conversacion
            ?.nombreCompleto
            .trim();

    if (
      nombreConversacion !=
          null &&
      nombreConversacion
          .isNotEmpty
    ) {
      return nombreConversacion;
    }

    final String titulo =
        notificacion
            .titulo
            .trim();

    if (
      titulo.isNotEmpty &&
      titulo.toLowerCase() !=
          'nuevo mensaje'
    ) {
      return titulo;
    }

    return 'Usuario';
  }

  // ============================================================
  // IMAGEN
  // ============================================================

  String? _imagenMostrada(
    Notificacion notificacion,
  ) {
    final String? url =
        _conversacionDe(
      notificacion,
    )
            ?.imagenUsuarioUrl
            ?.trim();

    if (
      url == null ||
      url.isEmpty
    ) {
      return null;
    }

    return url;
  }

  // ============================================================
  // MARCAR TODAS
  // ============================================================

  Future<void>
      _marcarTodas() async {
    final bool ok =
        await NotificacionService
            .marcarTodasComoLeidas();

    if (
      !ok ||
      !mounted
    ) {
      return;
    }

    setState(() {
      _notificaciones =
          _notificaciones
              .map(
                (
                  notificacion,
                ) =>
                    notificacion
                        .copyWith(
                  leida:
                      true,
                ),
              )
              .toList();
    });
  }

  // ============================================================
  // ABRIR NOTIFICACIÓN
  // ============================================================

  Future<void> _abrir(
    Notificacion notificacion,
  ) async {
    if (
      !notificacion.leida
    ) {
      await NotificacionService
          .marcarComoLeida(
        notificacion.id,
      );
    }

    if (!mounted) {
      return;
    }

    if (
      notificacion.tipo ==
              'mensaje' &&
      notificacion
              .referenciaTipo ==
          'conversacion' &&
      notificacion
              .referenciaId !=
          null
    ) {
      final Conversacion?
          conversacion =
          _conversacionDe(
        notificacion,
      );

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) {
            return ChatScreen(
              conversacionId:
                  notificacion
                      .referenciaId!,

              nombreUsuario:
                  _nombreMostrado(
                notificacion,
              ),

              imagenUsuarioUrl:
                  conversacion
                      ?.imagenUsuarioUrl,
            );
          },
        ),
      );

      if (mounted) {
        await _cargar(
          mostrarCarga:
              false,
        );
      }
    }
  }

  // ============================================================
  // FECHA
  // ============================================================

  String _fecha(
    DateTime? fecha,
  ) {
    if (
      fecha == null
    ) {
      return '';
    }

    final DateTime ahora =
        DateTime.now();

    final DateTime local =
        fecha.toLocal();

    final Duration diferencia =
        ahora.difference(
      local,
    );

    if (
      diferencia.inSeconds <
      60
    ) {
      return 'Ahora';
    }

    if (
      diferencia.inMinutes <
      60
    ) {
      return '${diferencia.inMinutes} min';
    }

    if (
      diferencia.inHours <
      24
    ) {
      return '${diferencia.inHours} h';
    }

    if (
      diferencia.inDays <
      7
    ) {
      return '${diferencia.inDays} d';
    }

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }

  // ============================================================
  // AVATAR
  // ============================================================

  Widget _avatar(
    Notificacion notificacion,
  ) {
    final String nombre =
        _nombreMostrado(
      notificacion,
    );

    final String? imagen =
        _imagenMostrada(
      notificacion,
    );

    return CircleAvatar(
      radius:
          27,

      backgroundColor:
          naranja,

      foregroundColor:
          Colors.white,

      backgroundImage:
          imagen != null
              ? NetworkImage(
                  imagen,
                )
              : null,

      child:
          imagen == null
              ? Text(
                  nombre.isNotEmpty
                      ? nombre[0]
                          .toUpperCase()
                      : '?',

                  style:
                      const TextStyle(
                    color:
                        Colors.white,

                    fontSize:
                        18,

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
        .dejarDeEscucharNuevaNotificacion();

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
        // EN OSCURO YA NO ES NARANJA
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
          'Notificaciones',

          style:
              TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),

        actions: [
          if (
            _notificaciones
                .any(
              (
                item,
              ) =>
                  !item.leida,
            )
          )
            TextButton(
              onPressed:
                  _marcarTodas,

              child:
                  const Text(
                'Leer todas',

                style:
                    TextStyle(
                  color:
                      Colors.white,

                  fontWeight:
                      FontWeight.w600,
                ),
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
    if (_cargando) {
      return const Center(
        child:
            CircularProgressIndicator(
          color:
              naranja,
        ),
      );
    }

    if (
      _error != null
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

          children: [
            const SizedBox(
              height:
                  160,
            ),

            const Icon(
              Icons.error_outline,
              size:
                  60,
              color:
                  naranja,
            ),

            const SizedBox(
              height:
                  16,
            ),

            Text(
              _error!,

              textAlign:
                  TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (
      _notificaciones
          .isEmpty
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
              Icons.notifications_none,
              size:
                  72,
              color:
                  naranja,
            ),

            SizedBox(
              height:
                  18,
            ),

            Text(
              'No tienes notificaciones',

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
                  7,
            ),

            Text(
              'Tus novedades aparecerán aquí.',

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
          12,
          16,
          24,
        ),

        itemCount:
            _notificaciones
                .length,

        itemBuilder:
            (
              context,
              index,
            ) {
          final Notificacion
              notificacion =
              _notificaciones[
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

              border:
                  !notificacion
                          .leida
                      ? Border.all(
                          color:
                              naranja.withValues(
                            alpha:
                                0.65,
                          ),

                          width:
                              1,
                        )
                      : null,
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
                    notificacion,
                  );
                },

                child:
                    Padding(
                  padding:
                      const EdgeInsets.all(
                    14,
                  ),

                  child:
                      Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      _avatar(
                        notificacion,
                      ),

                      const SizedBox(
                        width:
                            13,
                      ),

                      Expanded(
                        child:
                            Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,

                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child:
                                      Text(
                                    _nombreMostrado(
                                      notificacion,
                                    ),

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
                                          FontWeight.bold,
                                    ),
                                  ),
                                ),

                                const SizedBox(
                                  width:
                                      8,
                                ),

                                Text(
                                  _fecha(
                                    notificacion
                                        .createdAt,
                                  ),

                                  style:
                                      TextStyle(
                                    color:
                                        oscuro
                                            ? Colors.white60
                                            : Colors.black54,

                                    fontSize:
                                        11,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(
                              height:
                                  5,
                            ),

                            Text(
                              notificacion
                                  .mensaje,

                              maxLines:
                                  2,

                              overflow:
                                  TextOverflow.ellipsis,

                              style:
                                  TextStyle(
                                color:
                                    oscuro
                                        ? Colors.white70
                                        : Colors.black54,

                                fontSize:
                                    14,
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (
                        !notificacion
                            .leida
                      ) ...[
                        const SizedBox(
                          width:
                              8,
                        ),

                        const Padding(
                          padding:
                              EdgeInsets.only(
                            top:
                                8,
                          ),

                          child:
                              CircleAvatar(
                            radius:
                                4,

                            backgroundColor:
                                naranja,
                          ),
                        ),
                      ],
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