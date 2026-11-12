import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../screens/notificaciones/notificaciones_screen.dart';
import '../services/chat_socket_service.dart';
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