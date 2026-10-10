import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart'
    as io;

import 'session_service.dart';

class ChatSocketService {
  // ============================================================
  // SINGLETON
  // ============================================================

  ChatSocketService._();

  static final ChatSocketService instance =
      ChatSocketService._();

  // ============================================================
  // SOCKET
  // ============================================================

  io.Socket? _socket;

  bool get conectado =>
      _socket?.connected ?? false;

  // ============================================================
  // URL BACKEND
  //
  // IMPORTANTE:
  // Socket.IO usa la raíz del backend.
  //
  // NO:
  // https://...railway.app/api
  //
  // SÍ:
  // https://...railway.app
  // ============================================================

  static const String _socketUrl =
      'https://mercalishuatbackend-production.up.railway.app';

  // ============================================================
  // CONECTAR
  // ============================================================

  Future<void> conectar() async {
    if (
      _socket != null &&
      _socket!.connected
    ) {
      return;
    }

    final String? token =
        await SessionService.obtenerToken();

    if (
      token == null ||
      token.isEmpty
    ) {
      debugPrint(
        'SOCKET: no hay token',
      );

      return;
    }

    // ==========================================================
    // CERRAR SOCKET ANTERIOR
    // ==========================================================

    _socket?.dispose();

    // ==========================================================
    // CREAR SOCKET
    // ==========================================================

    _socket =
        io.io(
      _socketUrl,
      io.OptionBuilder()
          .setTransports(
            [
              'websocket',
            ],
          )
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(
            999999,
          )
          .setReconnectionDelay(
            1000,
          )
          .setAuth({
            'token':
                token,
          })
          .build(),
    );

    // ==========================================================
    // EVENTOS CONEXIÓN
    // ==========================================================

    _socket!.onConnect(
      (_) {
        debugPrint(
          'SOCKET CONECTADO: ${_socket!.id}',
        );
      },
    );

    _socket!.onDisconnect(
      (motivo) {
        debugPrint(
          'SOCKET DESCONECTADO: $motivo',
        );
      },
    );

    _socket!.onConnectError(
      (error) {
        debugPrint(
          'SOCKET ERROR CONEXIÓN: $error',
        );
      },
    );

    _socket!.onError(
      (error) {
        debugPrint(
          'SOCKET ERROR: $error',
        );
      },
    );

    _socket!.onReconnect(
      (_) {
        debugPrint(
          'SOCKET RECONECTADO',
        );
      },
    );

    // ==========================================================
    // CONECTAR
    // ==========================================================

    _socket!.connect();
  }

  // ============================================================
  // ENTRAR A CONVERSACIÓN
  // ============================================================

  void entrarConversacion(
    int conversacionId,
  ) {
    if (
      _socket == null ||
      !_socket!.connected
    ) {
      return;
    }

    _socket!.emit(
      'entrar_conversacion',
      conversacionId,
    );

    debugPrint(
      'SOCKET: entrar conversación $conversacionId',
    );
  }

  // ============================================================
  // SALIR DE CONVERSACIÓN
  // ============================================================

  void salirConversacion(
    int conversacionId,
  ) {
    if (
      _socket == null ||
      !_socket!.connected
    ) {
      return;
    }

    _socket!.emit(
      'salir_conversacion',
      conversacionId,
    );

    debugPrint(
      'SOCKET: salir conversación $conversacionId',
    );
  }

  // ============================================================
  // ESCUCHAR NUEVO MENSAJE
  // ============================================================

  void escucharNuevoMensaje(
    void Function(
      Map<String, dynamic> mensaje,
    ) callback,
  ) {
    _socket?.off(
      'nuevo_mensaje',
    );

    _socket?.on(
      'nuevo_mensaje',
      (
        data,
      ) {
        if (data is Map) {
          callback(
            Map<String, dynamic>.from(
              data,
            ),
          );
        }
      },
    );
  }

  // ============================================================
  // ESCUCHAR CAMBIOS EN CONVERSACIONES
  // ============================================================

  void escucharConversacionActualizada(
    void Function(
      Map<String, dynamic> data,
    ) callback,
  ) {
    _socket?.off(
      'conversacion_actualizada',
    );

    _socket?.on(
      'conversacion_actualizada',
      (
        data,
      ) {
        if (data is Map) {
          callback(
            Map<String, dynamic>.from(
              data,
            ),
          );
        }
      },
    );
  }

  // ============================================================
  // QUITAR LISTENER NUEVO MENSAJE
  // ============================================================

  void dejarDeEscucharNuevoMensaje() {
    _socket?.off(
      'nuevo_mensaje',
    );
  }

  // ============================================================
  // QUITAR LISTENER CONVERSACIONES
  // ============================================================

  void dejarDeEscucharConversacionActualizada() {
    _socket?.off(
      'conversacion_actualizada',
    );
  }

  // ============================================================
  // DESCONECTAR
  // ============================================================

  void desconectar() {
    _socket?.disconnect();
    _socket?.dispose();

    _socket =
        null;

    debugPrint(
      'SOCKET CERRADO',
    );
  }
}