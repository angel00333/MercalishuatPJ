import 'dart:async';

import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../models/conversacion.dart';
import '../screens/notificaciones/notificaciones_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/explorar/detalle_tienda_screen.dart';
import '../screens/producto_actions/detalle_producto_screen.dart';
import '../screens/publicaciones/detalle_publicacion_screen.dart';
import '../services/chat_socket_service.dart';
import '../services/chat_service.dart';
import '../services/firebase_messaging_service.dart';
import '../services/notificacion_service.dart';

class CampanaNotificaciones
    extends StatefulWidget {
  final bool integrada;

  final Color? colorIcono;

  final Color? colorFondo;

  final double size;

  const CampanaNotificaciones({
    super.key,
    this.integrada = false,
    this.colorIcono,
    this.colorFondo,
    this.size = 52,
  });

  @override
  State<CampanaNotificaciones>
      createState() =>
          _CampanaNotificacionesState();
}

class _CampanaNotificacionesState
    extends State<CampanaNotificaciones> {
  int _noLeidas =
      0;

  bool _iniciando =
      false;


  bool _procesandoPush =
      false;

  StreamSubscription<
      Map<String, dynamic>>?
      _aperturaPushSubscription;

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
    if (_iniciando) {
      return;
    }

    _iniciando =
        true;

    await ChatSocketService
        .instance
        .conectar();

    if (!mounted) {
      return;
    }

    await _actualizarContador();

    if (!mounted) {
      return;
    }

    ChatSocketService
        .instance
        .escucharContadorNotificaciones(
      (
        data,
      ) {
        if (!mounted) {
          return;
        }

        _actualizarContador();
      },
    );

    ChatSocketService
        .instance
        .escucharNotificacionesActualizadas(
      (
        data,
      ) {
        if (!mounted) {
          return;
        }

        _actualizarContador();
      },
    );

    // ==========================================================
    // APERTURA DE PUSH
    // ==========================================================

    await _aperturaPushSubscription
        ?.cancel();

    _aperturaPushSubscription =
        FirebaseMessagingService
            .instance
            .onNotificacionAbierta
            .listen(
      (
        data,
      ) {
        if (!mounted) {
          return;
        }

        _abrirDesdePush(
          data,
        );
      },
    );

    final Map<String, dynamic>?
        pendiente =
        FirebaseMessagingService
            .instance
            .consumirNotificacionInicial();

    if (
      pendiente != null &&
      mounted
    ) {
      WidgetsBinding.instance
          .addPostFrameCallback(
        (_) {
          if (!mounted) {
            return;
          }

          _abrirDesdePush(
            pendiente,
          );
        },
      );
    }

    _iniciando =
        false;
  }

  // ============================================================
  // CONTADOR
  // ============================================================

  Future<void>
      _actualizarContador() async {
    final total =
        await NotificacionService
            .contarNoLeidas();

    if (!mounted) {
      return;
    }

    setState(() {
      _noLeidas =
          total;
    });
  }

  // ============================================================
  // ABRIR DESDE PUSH
  // ============================================================

  Future<void> _abrirDesdePush(
    Map<String, dynamic> data,
  ) async {
    if (
      _procesandoPush ||
      !mounted
    ) {
      return;
    }

    final String tipo =
        data['tipo']
                ?.toString()
                .trim()
                .toLowerCase() ??
            '';

    final String referenciaTipo =
        data['referencia_tipo']
                ?.toString()
                .trim()
                .toLowerCase() ??
            '';

    final int? referenciaId =
        int.tryParse(
      data['referencia_id']
              ?.toString() ??
          '',
    );

    if (
      referenciaId == null ||
      referenciaId <= 0
    ) {
      return;
    }

    _procesandoPush =
        true;

    // Si este evento era el mensaje inicial de una app
    // recién abierta, evitamos que vuelva a procesarse.
    FirebaseMessagingService
        .instance
        .descartarNotificacionInicial();

    try {
      // ========================================================
      // MENSAJE
      // ========================================================

      if (
        tipo == 'mensaje' &&
        referenciaTipo ==
            'conversacion'
      ) {
        final Conversacion?
            conversacion =
            await _buscarConversacion(
          referenciaId,
        );

        if (
          conversacion != null &&
          mounted
        ) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) =>
                      ChatScreen(
                conversacionId:
                    referenciaId,

                nombreUsuario:
                    conversacion
                        .nombreCompleto,

                imagenUsuarioUrl:
                    conversacion
                        .imagenUsuarioUrl,
              ),
            ),
          );
        }

        return;
      }

      // ========================================================
      // EMPRENDIMIENTO
      // ========================================================

      if (
        referenciaTipo ==
            'emprendimiento'
      ) {
        if (!mounted) {
          return;
        }

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) =>
                    DetalleTiendaScreen(
              emprendimientoId:
                  referenciaId,
            ),
          ),
        );

        return;
      }

      // ========================================================
      // PUBLICACIÓN
      // ========================================================

      if (
        referenciaTipo ==
            'publicacion'
      ) {
        if (!mounted) {
          return;
        }

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) =>
                    DetallePublicacionScreen(
              publicacionId:
                  referenciaId,
            ),
          ),
        );

        return;
      }

      // ========================================================
      // PRODUCTO
      // ========================================================

      if (
        referenciaTipo ==
            'producto'
      ) {
        if (!mounted) {
          return;
        }

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) =>
                    DetalleProductoScreen(
              productoId:
                  referenciaId,
            ),
          ),
        );
      }
    } catch (
      e
    ) {
      debugPrint(
        'ERROR ABRIENDO NOTIFICACIÓN PUSH: $e',
      );
    } finally {
      _procesandoPush =
          false;

      if (mounted) {
        await _actualizarContador();
      }
    }
  }

  // ============================================================
  // BUSCAR CONVERSACIÓN
  // ============================================================

  Future<Conversacion?>
      _buscarConversacion(
    int conversacionId,
  ) async {
    try {
      final resultado =
          await ChatService
              .listarConversaciones();

      if (
        resultado['success'] !=
        true
      ) {
        return null;
      }

      final dynamic raw =
          resultado[
              'conversaciones'];

      if (raw is! List) {
        return null;
      }

      for (
        final item in raw
      ) {
        final Conversacion
            conversacion;

        if (
          item is Conversacion
        ) {
          conversacion =
              item;
        } else if (
          item is Map
        ) {
          conversacion =
              Conversacion.fromJson(
            Map<String, dynamic>.from(
              item,
            ),
          );
        } else {
          continue;
        }

        if (
          conversacion.id ==
          conversacionId
        ) {
          return conversacion;
        }
      }
    } catch (
      e
    ) {
      debugPrint(
        'ERROR BUSCANDO CONVERSACIÓN DEL PUSH: $e',
      );
    }

    return null;
  }

  // ============================================================
  // ABRIR
  // ============================================================

  Future<void>
      _abrirNotificaciones() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) =>
                const NotificacionesScreen(),
      ),
    );

    if (!mounted) {
      return;
    }

    await _actualizarContador();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _aperturaPushSubscription
        ?.cancel();

    ChatSocketService
        .instance
        .dejarDeEscucharContadorNotificaciones();

    ChatSocketService
        .instance
        .dejarDeEscucharNotificacionesActualizadas();

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

    final colorIcono =
        widget.colorIcono ??
            AppColors.naranja;

    final colorFondo =
        widget.colorFondo ??
            (
              oscuro
                  ? AppColors.tarjetaOscura
                  : Colors.white
            );

    if (widget.integrada) {
      return Material(
        color:
            colorFondo,

        borderRadius:
            BorderRadius.circular(
          18,
        ),

        elevation:
            0,

        child:
            InkWell(
          onTap:
              _abrirNotificaciones,

          borderRadius:
              BorderRadius.circular(
            18,
          ),

          child:
              SizedBox(
            width:
                widget.size,

            height:
                widget.size,

            child:
                _contenido(
              colorIcono,
            ),
          ),
        ),
      );
    }

    return Material(
      color:
          colorFondo,

      elevation:
          5,

      shape:
          const CircleBorder(),

      child:
          InkWell(
        customBorder:
            const CircleBorder(),

        onTap:
            _abrirNotificaciones,

        child:
            SizedBox(
          width:
              widget.size,

          height:
              widget.size,

          child:
              _contenido(
            colorIcono,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CONTENIDO
  // ============================================================

  Widget _contenido(
    Color colorIcono,
  ) {
    return Stack(
      clipBehavior:
          Clip.none,

      alignment:
          Alignment.center,

      children: [
        Icon(
          _noLeidas > 0
              ? Icons.notifications_rounded
              : Icons.notifications_none_rounded,

          color:
              colorIcono,

          size:
              28,
        ),

        if (_noLeidas >
            0)
          Positioned(
            top:
                5,

            right:
                4,

            child:
                Container(
              constraints:
                  const BoxConstraints(
                minWidth:
                    19,

                minHeight:
                    19,
              ),

              padding:
                  const EdgeInsets.symmetric(
                horizontal:
                    4,
              ),

              alignment:
                  Alignment.center,

              decoration:
                  const BoxDecoration(
                color:
                    AppColors.error,

                shape:
                    BoxShape.circle,
              ),

              child:
                  Text(
                _noLeidas > 99
                    ? '99+'
                    : _noLeidas
                        .toString(),

                style:
                    const TextStyle(
                  color:
                      Colors.white,

                  fontSize:
                      10,

                  height:
                      1,

                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}