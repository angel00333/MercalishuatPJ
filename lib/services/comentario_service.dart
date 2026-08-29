import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/comentario.dart';
import 'session_service.dart';

class ComentarioService {
  static Future<Map<String, String>>
      _headers() async {
    final token =
        await SessionService.obtenerToken();

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>>
      listar(
    int publicacionId,
  ) async {
    try {
      final headers = await _headers();

      final response = await http.get(
        Uri.parse(
          ApiConfig.comentarios(
            publicacionId,
          ),
        ),
        headers: headers,
      );

print(
  'RESPUESTA BACKEND: ${response.body}',
);

      final data =
          jsonDecode(response.body);

      if (response.statusCode == 200) {
        final lista =
            (data['comentarios'] as List)
                .map(
                  (e) =>
                      Comentario.fromJson(e),
                )
                .toList();

        return {
          'success': true,
          'comentarios': lista,
        };
      }

      return {
        'success': false,
        'message':
            data['message'] ??
            'No se pudieron cargar los comentarios',
      };
    } catch (e) {
      return {
        'success': false,
        'message':
            'No se pudieron cargar los comentarios',
      };
    }
  }

  static Future<Map<String, dynamic>>
      crear({
    required int publicacionId,
    required String texto,
  }) async {
    try {
      final headers = await _headers();

      final response = await http.post(
        Uri.parse(
          ApiConfig.comentarios(
            publicacionId,
          ),
        ),
        headers: headers,
        body: jsonEncode({
          'texto': texto,
        }),
      );

      final data =
          jsonDecode(response.body);

      return {
        'success':
            response.statusCode == 201,
        ...data,
      };
    } catch (e) {
      return {
        'success': false,
        'message':
            'No se pudo publicar el comentario',
      };
    }
  }

  static Future<Map<String, dynamic>>
      eliminar(
    int comentarioId,
  ) async {
    try {
      final headers = await _headers();

      final response =
          await http.delete(
        Uri.parse(
          ApiConfig.eliminarComentario(
            comentarioId,
          ),
        ),
        headers: headers,
      );

      final data =
          jsonDecode(response.body);

      return {
        'success':
            response.statusCode == 200,
        ...data,
      };
    } catch (e) {
      return {
        'success': false,
        'message':
            'No se pudo eliminar el comentario',
      };
    }
  }

  static Future<Map<String, dynamic>>
    responder({
  required int comentarioId,
  required String texto,
}) async {
  try {
    final headers =
        await _headers();

    final response =
        await http.post(
      Uri.parse(
        ApiConfig.responderComentario(
          comentarioId,
        ),
      ),
      headers: headers,
      body: jsonEncode({
        'texto': texto,
      }),
    );

    final data =
        jsonDecode(
      response.body,
    );

    return {
      'success':
          response.statusCode == 201,
      ...data,
    };
  } catch (e) {
    return {
      'success': false,
      'message':
          'No se pudo enviar la respuesta',
    };
  }
}

}