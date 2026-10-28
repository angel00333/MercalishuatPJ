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

  bool _conectando = false;

  bool get conectado =>
      _socket?.connected ?? false;

  bool get conectando =>
      _conectando;

  String? get socketId =>
      _socket?.id;

  // ============================================================
  // CALLBACK DE CONEXIÓN
  // ============================================================

  void Function()? _callbackConexion;

  // ============================================================
  // BACKEND
  //
  // Socket.IO usa la raíz.
  // NO agregar /api.
  // ============================================================

  static const String _socketUrl =
      'https://mercalishuatbackend-production-f311.up.railway.app';

  // ============================================================
  // CONECTAR
  // ============================================================

  Future<void> conectar() async {
    if (_socket?.connected == true) {
      debugPrint(
        'SOCKET: ya estaba conectado ${_socket?.id}',
      );

      return;
    }

    if (_conectando) {
      debugPrint(
        'SOCKET: conexión ya en proceso',
      );

      return;
    }

    _conectando = true;

    // ==========================================================
    // TOKEN
    // ==========================================================

    final String? token =
        await SessionService.obtenerToken();

    if (
      token == null ||
      token.trim().isEmpty
    ) {
      _conectando = false;

      debugPrint(
        'SOCKET: no hay token disponible',
      );

      return;
    }

    // ==========================================================
    // LIMPIAR SOCKET ANTERIOR
    // ==========================================================

    if (_socket != null) {
      try {
        _socket!.disconnect();
        _socket!.dispose();
      } catch (e) {
        debugPrint(
          'SOCKET: error limpiando conexión anterior: $e',
        );
      }

      _socket = null;
    }

    // ==========================================================
    // CREAR SOCKET
    // ==========================================================

    _socket = io.io(
      _socketUrl,
      io.OptionBuilder()
          .setTransports(
            [
              'polling',
              'websocket',
            ],
          )
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(
            20,
          )
          .setReconnectionDelay(
            1000,
          )
          .setReconnectionDelayMax(
            5000,
          )
          .setTimeout(
            10000,
          )
          .setAuth(
            {
              'token': token,
            },
          )
          .build(),
    );

    // ==========================================================
    // CONECTADO
    // ==========================================================

    _socket!.onConnect(
      (_) {
        _conectando = false;

        debugPrint(
          'SOCKET CONECTADO: ${_socket?.id}',
        );

        final callback =
            _callbackConexion;

        if (
          callback != null
        ) {
          callback();
        }
      },
    );

    // ==========================================================
    // DESCONECTADO
    // ==========================================================

    _socket!.onDisconnect(
      (
        motivo,
      ) {
        _conectando = false;

        debugPrint(
          'SOCKET DESCONECTADO: $motivo',
        );
      },
    );

    // ==========================================================
    // ERROR DE CONEXIÓN
    // ==========================================================

    _socket!.onConnectError(
      (
        error,
      ) {
        _conectando = false;

        debugPrint(
          'SOCKET ERROR CONEXIÓN: $error',
        );
      },
    );

    // ==========================================================
    // ERROR GENERAL
    // ==========================================================

    _socket!.onError(
      (
        error,
      ) {
        debugPrint(
          'SOCKET ERROR: $error',
        );
      },
    );

    // ==========================================================
    // RECONECTADO
    // ==========================================================

    _socket!.onReconnect(
      (
        intento,
      ) {
        _conectando = false;

        debugPrint(
          'SOCKET RECONECTADO. Intento: $intento',
        );

        final callback =
            _callbackConexion;

        if (
          callback != null
        ) {
          callback();
        }
      },
    );

    // ==========================================================
    // INTENTO DE RECONECTAR
    // ==========================================================

    _socket!.onReconnectAttempt(
      (
        intento,
      ) {
        debugPrint(
          'SOCKET INTENTANDO RECONECTAR: $intento',
        );
      },
    );

    // ==========================================================
    // ERROR RECONECTANDO
    // ==========================================================

    _socket!.onReconnectError(
      (
        error,
      ) {
        debugPrint(
          'SOCKET ERROR RECONECTANDO: $error',
        );
      },
    );

    // ==========================================================
    // RECONEXIÓN FALLIDA
    // ==========================================================

    _socket!.onReconnectFailed(
      (_) {
        _conectando = false;

        debugPrint(
          'SOCKET: falló la reconexión',
        );
      },
    );

    // ==========================================================
    // CONECTAR
    // ==========================================================

    debugPrint(
      'SOCKET: conectando a $_socketUrl',
    );

    _socket!.connect();
  }

  // ============================================================
  // ENTRAR A CONVERSACIÓN
  // ============================================================

  void entrarConversacion(
    int conversacionId,
  ) {
    if (
      _socket == null
    ) {
      debugPrint(
        'SOCKET: no existe socket para entrar a conversación',
      );

      return;
    }

    if (
      !_socket!.connected
    ) {
      debugPrint(
        'SOCKET: todavía no conectado. '
        'Se entrará a conversación $conversacionId '
        'cuando conecte.',
      );

      return;
    }

    _socket!.emit(
      'entrar_conversacion',
      conversacionId,
    );

    debugPrint(
      'SOCKET: entrar_conversacion -> $conversacionId',
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
      'SOCKET: salir_conversacion -> $conversacionId',
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
    if (
      _socket == null
    ) {
      debugPrint(
        'SOCKET: no existe para escuchar nuevo_mensaje',
      );

      return;
    }

    _socket!.off(
      'nuevo_mensaje',
    );

    _socket!.on(
      'nuevo_mensaje',
      (
        data,
      ) {
        debugPrint(
          'SOCKET nuevo_mensaje: $data',
        );

        if (
          data is Map
        ) {
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
  // DEJAR DE ESCUCHAR NUEVO MENSAJE
  // ============================================================

  void dejarDeEscucharNuevoMensaje() {
    _socket?.off(
      'nuevo_mensaje',
    );
  }

  // ============================================================
  // ESCUCHAR CONVERSACIÓN ACTUALIZADA
  // ============================================================

  void escucharConversacionActualizada(
    void Function(
      Map<String, dynamic> data,
    ) callback,
  ) {
    if (
      _socket == null
    ) {
      debugPrint(
        'SOCKET: no existe para escuchar conversacion_actualizada',
      );

      return;
    }

    _socket!.off(
      'conversacion_actualizada',
    );

    _socket!.on(
      'conversacion_actualizada',
      (
        data,
      ) {
        debugPrint(
          'SOCKET conversacion_actualizada: $data',
        );

        if (
          data is Map
        ) {
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
  // DEJAR DE ESCUCHAR CONVERSACIÓN ACTUALIZADA
  // ============================================================

  void dejarDeEscucharConversacionActualizada() {
    _socket?.off(
      'conversacion_actualizada',
    );
  }

  // ============================================================
  // ESCUCHAR MENSAJES LEÍDOS
  // ============================================================

  void escucharMensajesLeidos(
    void Function(
      Map<String, dynamic> data,
    ) callback,
  ) {
    if (
      _socket == null
    ) {
      debugPrint(
        'SOCKET: no existe para escuchar mensajes_leidos',
      );

      return;
    }

    _socket!.off(
      'mensajes_leidos',
    );

    _socket!.on(
      'mensajes_leidos',
      (
        data,
      ) {
        debugPrint(
          'SOCKET mensajes_leidos: $data',
        );

        if (
          data is Map
        ) {
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
  // DEJAR DE ESCUCHAR MENSAJES LEÍDOS
  // ============================================================

  void dejarDeEscucharMensajesLeidos() {
    _socket?.off(
      'mensajes_leidos',
    );
  }

  // ============================================================
  // ESCUCHAR CONEXIÓN
  // ============================================================

  void escucharConexion(
    void Function() callback,
  ) {
    _callbackConexion =
        callback;

    if (
      _socket?.connected ==
      true
    ) {
      callback();
    }
  }

  // ============================================================
  // DEJAR DE ESCUCHAR CONEXIÓN
  // ============================================================

  void dejarDeEscucharConexion() {
    _callbackConexion =
        null;
  }

  // ============================================================
  // NUEVA NOTIFICACIÓN
  // ============================================================

  void escucharNuevaNotificacion(
    void Function(
      Map<String, dynamic> data,
    ) callback,
  ) {
    if (
      _socket == null
    ) {
      debugPrint(
        'SOCKET: no existe para escuchar nueva_notificacion',
      );

      return;
    }

    _socket!.off(
      'nueva_notificacion',
    );

    _socket!.on(
      'nueva_notificacion',
      (
        data,
      ) {
        debugPrint(
          'SOCKET nueva_notificacion: $data',
        );

        if (
          data is Map
        ) {
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
  // DEJAR DE ESCUCHAR NUEVA NOTIFICACIÓN
  // ============================================================

  void dejarDeEscucharNuevaNotificacion() {
    _socket?.off(
      'nueva_notificacion',
    );
  }

  // ============================================================
  // CONTADOR DE NOTIFICACIONES
  // ============================================================

  void escucharContadorNotificaciones(
    void Function(
      Map<String, dynamic> data,
    ) callback,
  ) {
    if (
      _socket == null
    ) {
      debugPrint(
        'SOCKET: no existe para escuchar contador_notificaciones',
      );

      return;
    }

    _socket!.off(
      'contador_notificaciones',
    );

    _socket!.on(
      'contador_notificaciones',
      (
        data,
      ) {
        debugPrint(
          'SOCKET contador_notificaciones: $data',
        );

        if (
          data is Map
        ) {
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
  // DEJAR DE ESCUCHAR CONTADOR
  // ============================================================

  void dejarDeEscucharContadorNotificaciones() {
    _socket?.off(
      'contador_notificaciones',
    );
  }

  // ============================================================
  // NOTIFICACIONES ACTUALIZADAS
  // ============================================================

  void escucharNotificacionesActualizadas(
    void Function(
      Map<String, dynamic> data,
    ) callback,
  ) {
    if (
      _socket == null
    ) {
      debugPrint(
        'SOCKET: no existe para escuchar notificaciones_actualizadas',
      );

      return;
    }

    _socket!.off(
      'notificaciones_actualizadas',
    );

    _socket!.on(
      'notificaciones_actualizadas',
      (
        data,
      ) {
        debugPrint(
          'SOCKET notificaciones_actualizadas: $data',
        );

        if (
          data is Map
        ) {
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
  // DEJAR DE ESCUCHAR NOTIFICACIONES ACTUALIZADAS
  // ============================================================

  void dejarDeEscucharNotificacionesActualizadas() {
    _socket?.off(
      'notificaciones_actualizadas',
    );
  }

  // ============================================================
  // EMITIR EVENTO GENÉRICO
  // ============================================================

  void emitir(
    String evento,
    dynamic data,
  ) {
    if (
      _socket == null ||
      !_socket!.connected
    ) {
      debugPrint(
        'SOCKET: no conectado. '
        'No se pudo emitir $evento',
      );

      return;
    }

    _socket!.emit(
      evento,
      data,
    );
  }

  // ============================================================
  // DESCONECTAR
  //
  // Usar al cerrar sesión.
  // NO al cambiar de pantalla.
  // ============================================================

  void desconectar() {
    _conectando =
        false;

    _callbackConexion =
        null;

    if (
      _socket == null
    ) {
      return;
    }

    try {
      // ========================================================
      // CHAT
      // ========================================================

      _socket!.off(
        'nuevo_mensaje',
      );

      _socket!.off(
        'conversacion_actualizada',
      );

      _socket!.off(
        'mensajes_leidos',
      );

      // ========================================================
      // NOTIFICACIONES
      // ========================================================

      _socket!.off(
        'nueva_notificacion',
      );

      _socket!.off(
        'contador_notificaciones',
      );

      _socket!.off(
        'notificaciones_actualizadas',
      );

      // ========================================================
      // CERRAR
      // ========================================================

      _socket!.disconnect();

      _socket!.dispose();
    } catch (
      error
    ) {
      debugPrint(
        'ERROR CERRANDO SOCKET: $error',
      );
    }

    _socket =
        null;

    debugPrint(
      'SOCKET CERRADO',
    );
  }
}