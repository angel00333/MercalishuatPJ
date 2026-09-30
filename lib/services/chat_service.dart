import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/conversacion.dart';
import '../models/mensaje.dart';
import 'session_service.dart';

class ChatService {
  // ============================================================
  // HEADERS
  // ============================================================

  static Future<Map<String, String>> _headers() async {
    final String? token =
        await SessionService.obtenerToken();

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty)
        'Authorization': 'Bearer $token',
    };
  }

  // ============================================================
  // DECODIFICAR RESPUESTA
  // ============================================================

  static Map<String, dynamic> _decodificarRespuesta(
    http.Response response,
  ) {
    try {
      final dynamic data =
          jsonDecode(response.body);

      if (data is Map<String, dynamic>) {
        return data;
      }

      if (data is Map) {
        return Map<String, dynamic>.from(
          data,
        );
      }

      return {
        'success': false,
        'message': 'Respuesta inválida del servidor',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'El servidor devolvió una respuesta inválida',
        'statusCode': response.statusCode,
      };
    }
  }

  // ============================================================
  // CREAR O BUSCAR CONVERSACIÓN
  //
  // POST /api/chat/conversacion
  // ============================================================

  static Future<Map<String, dynamic>> crearConversacion({
    required int usuarioDestinoId,
  }) async {
    try {
      final response =
          await http.post(
        Uri.parse(
          '${ApiConfig.baseUrl}/chat/conversacion',
        ),
        headers:
            await _headers(),
        body:
            jsonEncode({
          'usuario_destino_id':
              usuarioDestinoId,
        }),
      );

      final data =
          _decodificarRespuesta(
        response,
      );

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        return data;
      }

      return {
        ...data,
        'success':
            false,
        'message':
            data['message'] ??
                'No se pudo iniciar la conversación',
      };
    } catch (e) {
      return {
        'success':
            false,
        'message':
            'No se pudo iniciar la conversación',
        'error':
            e.toString(),
      };
    }
  }

  // ============================================================
  // LISTAR CONVERSACIONES
  //
  // GET /api/chat/conversaciones
  // ============================================================

  static Future<Map<String, dynamic>>
      listarConversaciones() async {
    try {
      final response =
          await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/chat/conversaciones',
        ),
        headers:
            await _headers(),
      );

      final data =
          _decodificarRespuesta(
        response,
      );

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        return {
          ...data,
          'success':
              false,
          'message':
              data['message'] ??
                  'No se pudieron cargar las conversaciones',
        };
      }

      if (data['success'] != true) {
        return data;
      }

      final dynamic raw =
          data['conversaciones'];

      final List<Conversacion>
          conversaciones =
          [];

      if (raw is List) {
        for (final item in raw) {
          if (item is Map<String, dynamic>) {
            conversaciones.add(
              Conversacion.fromJson(
                item,
              ),
            );
          } else if (item is Map) {
            conversaciones.add(
              Conversacion.fromJson(
                Map<String, dynamic>.from(
                  item,
                ),
              ),
            );
          }
        }
      }

      return {
        'success':
            true,
        'conversaciones':
            conversaciones,
      };
    } catch (e) {
      return {
        'success':
            false,
        'message':
            'No se pudieron cargar las conversaciones',
        'error':
            e.toString(),
      };
    }
  }

  // ============================================================
  // OBTENER MENSAJES
  //
  // GET /api/chat/conversacion/:id/mensajes
  // ============================================================

  static Future<Map<String, dynamic>> obtenerMensajes({
    required int conversacionId,
  }) async {
    try {
      final response =
          await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/chat/conversacion/$conversacionId/mensajes',
        ),
        headers:
            await _headers(),
      );

      final data =
          _decodificarRespuesta(
        response,
      );

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        return {
          ...data,
          'success':
              false,
          'message':
              data['message'] ??
                  'No se pudieron cargar los mensajes',
        };
      }

      if (data['success'] != true) {
        return data;
      }

      final dynamic raw =
          data['mensajes'];

      final List<Mensaje>
          mensajes =
          [];

      if (raw is List) {
        for (final item in raw) {
          if (item is Map<String, dynamic>) {
            mensajes.add(
              Mensaje.fromJson(
                item,
              ),
            );
          } else if (item is Map) {
            mensajes.add(
              Mensaje.fromJson(
                Map<String, dynamic>.from(
                  item,
                ),
              ),
            );
          }
        }
      }

      return {
        'success':
            true,
        'mensajes':
            mensajes,
      };
    } catch (e) {
      return {
        'success':
            false,
        'message':
            'No se pudieron cargar los mensajes',
        'error':
            e.toString(),
      };
    }
  }

  // ============================================================
  // ENVIAR MENSAJE
  //
  // POST /api/chat/conversacion/:id/mensaje
  // ============================================================

  static Future<Map<String, dynamic>> enviarMensaje({
    required int conversacionId,
    required String contenido,
  }) async {
    try {
      final String mensaje =
          contenido.trim();

      if (mensaje.isEmpty) {
        return {
          'success':
              false,
          'message':
              'El mensaje no puede estar vacío',
        };
      }

      final response =
          await http.post(
        Uri.parse(
          '${ApiConfig.baseUrl}/chat/conversacion/$conversacionId/mensaje',
        ),
        headers:
            await _headers(),
        body:
            jsonEncode({
          'contenido':
              mensaje,
        }),
      );

      final data =
          _decodificarRespuesta(
        response,
      );

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        return {
          ...data,
          'success':
              false,
          'message':
              data['message'] ??
                  'No se pudo enviar el mensaje',
        };
      }

      if (data['success'] == true &&
          data['mensaje'] is Map) {
        final Map<String, dynamic>
            mensajeJson =
            Map<String, dynamic>.from(
          data['mensaje'],
        );

        return {
          ...data,
          'mensaje':
              Mensaje.fromJson(
            mensajeJson,
          ),
        };
      }

      return data;
    } catch (e) {
      return {
        'success':
            false,
        'message':
            'No se pudo enviar el mensaje',
        'error':
            e.toString(),
      };
    }
  }

  // ============================================================
  // MARCAR MENSAJES COMO LEÍDOS
  //
  // PUT /api/chat/conversacion/:id/leidos
  // ============================================================

  static Future<Map<String, dynamic>> marcarComoLeidos({
    required int conversacionId,
  }) async {
    try {
      final response =
          await http.put(
        Uri.parse(
          '${ApiConfig.baseUrl}/chat/conversacion/$conversacionId/leidos',
        ),
        headers:
            await _headers(),
      );

      final data =
          _decodificarRespuesta(
        response,
      );

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        return data;
      }

      return {
        ...data,
        'success':
            false,
        'message':
            data['message'] ??
                'No se pudieron marcar los mensajes como leídos',
      };
    } catch (e) {
      return {
        'success':
            false,
        'message':
            'No se pudieron marcar los mensajes como leídos',
        'error':
            e.toString(),
      };
    }
  }
}