import 'package:flutter/material.dart';

import '../screens/notificaciones/notificaciones_screen.dart';
import '../services/chat_socket_service.dart';
import '../services/notificacion_service.dart';

class CampanaNotificaciones
    extends StatefulWidget {
  const CampanaNotificaciones({
    super.key,
  });

  @override
  State<CampanaNotificaciones>
      createState() =>
          _CampanaNotificacionesState();
}

class _CampanaNotificacionesState
    extends State<
        CampanaNotificaciones> {
  static const Color naranja =
      Color(0xFFFF7E01);

  int _noLeidas = 0;

  bool _iniciando = false;

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

    _iniciando = true;

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

    // ==========================================================
    // EL BACKEND EMITE ESTO CUANDO CREA UNA NOTIFICACIÓN
    // ==========================================================

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

    // ==========================================================
    // CUANDO EL CHAT MARCA NOTIFICACIONES COMO LEÍDAS
    // ==========================================================

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

    _iniciando = false;
  }

  // ============================================================
  // CONTADOR
  // ============================================================

  Future<void>
      _actualizarContador() async {
    final int total =
        await NotificacionService
            .contarNoLeidas();

    if (!mounted) {
      return;
    }

    setState(() {
      _noLeidas = total;
    });
  }

  // ============================================================
  // ABRIR CENTRO DE NOTIFICACIONES
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
    return Material(
      color:
          Theme.of(context)
              .cardColor,

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
              52,

          height:
              52,

          child:
              Stack(
            clipBehavior:
                Clip.none,

            alignment:
                Alignment.center,

            children: [
              Icon(
                _noLeidas > 0
                    ? Icons.notifications
                    : Icons.notifications_none,

                color:
                    naranja,

                size:
                    28,
              ),

              if (
                _noLeidas >
                0
              )
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
                          Colors.red,

                      shape:
                          BoxShape.circle,
                    ),

                    child:
                        Text(
                      _noLeidas >
                              99
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
          ),
        ),
      ),
    );
  }
}