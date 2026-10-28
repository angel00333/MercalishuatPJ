import 'dart:convert';

import 'package:http/http.dart'
    as http;

import '../config/api_config.dart';
import '../models/notificacion.dart';
import 'session_service.dart';

class NotificacionService {
  // ============================================================
  // HEADERS
  // ============================================================

  static Future<Map<String, String>>
      _headers() async {
    final String? token =
        await SessionService
            .obtenerToken();

    return {
      'Content-Type':
          'application/json',

      'Accept':
          'application/json',

      if (
        token != null &&
        token.isNotEmpty
      )
        'Authorization':
            'Bearer $token',
    };
  }

  // ============================================================
  // DECODIFICAR
  // ============================================================

  static Map<String, dynamic>
      _decodificarRespuesta(
    http.Response response,
  ) {
    try {
      final dynamic data =
          jsonDecode(
        response.body,
      );

      if (
        data is Map<String, dynamic>
      ) {
        return data;
      }

      return {
        'success':
            false,

        'message':
            'Respuesta inválida del servidor',
      };
    } catch (_) {
      return {
        'success':
            false,

        'message':
            response.body.isNotEmpty
                ? response.body
                : 'Respuesta inválida del servidor',
      };
    }
  }

  // ============================================================
  // LISTAR
  // ============================================================

  static Future<
      Map<String, dynamic>>
      listar() async {
    try {
      final response =
          await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/notificaciones',
        ),
        headers:
            await _headers(),
      );

      final data =
          _decodificarRespuesta(
        response,
      );

      if (
        response.statusCode >= 200 &&
        response.statusCode < 300
      ) {
        final dynamic raw =
            data[
                'notificaciones'];

        final List<Notificacion>
            lista =
            [];

        if (raw is List) {
          for (
            final item in raw
          ) {
            if (
              item is Map
            ) {
              lista.add(
                Notificacion
                    .fromJson(
                  Map<String, dynamic>
                      .from(
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

          'notificaciones':
              lista,
        };
      }

      return {
        'success':
            false,

        'message':
            data['message'] ??
            'No se pudieron cargar las notificaciones',
      };
    } catch (e) {
      return {
        'success':
            false,

        'message':
            'Error de conexión: $e',
      };
    }
  }

  // ============================================================
  // CONTAR NO LEÍDAS
  // ============================================================

  static Future<int>
      contarNoLeidas() async {
    try {
      final response =
          await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/notificaciones/no-leidas',
        ),
        headers:
            await _headers(),
      );

      final data =
          _decodificarRespuesta(
        response,
      );

      if (
        response.statusCode >= 200 &&
        response.statusCode < 300
      ) {
        return int.tryParse(
              data['total']
                  ?.toString() ??
                  '0',
            ) ??
            0;
      }

      return 0;
    } catch (_) {
      return 0;
    }
  }

  // ============================================================
  // MARCAR UNA COMO LEÍDA
  // ============================================================

  static Future<bool>
      marcarComoLeida(
    int id,
  ) async {
    try {
      final response =
          await http.put(
        Uri.parse(
          '${ApiConfig.baseUrl}/notificaciones/$id/leida',
        ),
        headers:
            await _headers(),
      );

      return response.statusCode >=
              200 &&
          response.statusCode <
              300;
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // MARCAR TODAS COMO LEÍDAS
  // ============================================================

  static Future<bool>
      marcarTodasComoLeidas() async {
    try {
      final response =
          await http.put(
        Uri.parse(
          '${ApiConfig.baseUrl}/notificaciones/leer-todas',
        ),
        headers:
            await _headers(),
      );

      return response.statusCode >=
              200 &&
          response.statusCode <
              300;
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // REGISTRAR FID
  // ============================================================

static Future<bool>
    registrarFid({
  required String fid,
}) async {
  try {
    final response =
        await http.post(
      Uri.parse(
        '${ApiConfig.baseUrl}/notificaciones/fcm-token',
      ),
      headers:
          await _headers(),
      body:
          jsonEncode(
        {
          'fid':
              fid,

          'plataforma':
              'web',
        },
      ),
    );

    return response.statusCode >=
            200 &&
        response.statusCode <
            300;
  } catch (
    e
  ) {
    return false;
  }
}


// ============================================================
// DESACTIVAR FID
// ============================================================

static Future<bool>
    eliminarFid({
  required String fid,
}) async {
  try {
    final request =
        http.Request(
      'DELETE',
      Uri.parse(
        '${ApiConfig.baseUrl}/notificaciones/fcm-token',
      ),
    );

    request.headers.addAll(
      await _headers(),
    );

    request.body =
        jsonEncode(
      {
        'fid':
            fid,
      },
    );

    final response =
        await request.send();

    return response.statusCode >=
            200 &&
        response.statusCode <
            300;
  } catch (
    e
  ) {
    return false;
  }
}
}