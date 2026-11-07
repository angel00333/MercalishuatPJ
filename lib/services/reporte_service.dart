import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'session_service.dart';

class ReporteService {
  // ============================================================
  // CREAR REPORTE
  // ============================================================

  static Future<void> crearReporte({
    required String tipo,
    required int objetivoId,
    required String motivo,
    String? descripcion,
  }) async {
    if (tipo != 'publicacion' &&
        tipo != 'comentario') {
      throw Exception(
        'Tipo de reporte inválido',
      );
    }

    if (objetivoId <= 0) {
      throw Exception(
        'Contenido inválido',
      );
    }

    if (motivo.trim().isEmpty) {
      throw Exception(
        'Debes seleccionar un motivo',
      );
    }

    final token =
        await SessionService.obtenerToken();

    if (token == null ||
        token.trim().isEmpty) {
      throw Exception(
        'Debes iniciar sesión para reportar contenido',
      );
    }

    final response =
        await http.post(
      Uri.parse(
        '${ApiConfig.baseUrl}/reportes',
      ),
      headers: {
        'Content-Type':
            'application/json',
        'Accept':
            'application/json',
        'Authorization':
            'Bearer $token',
      },
      body: jsonEncode({
        'tipo':
            tipo,
        'objetivo_id':
            objetivoId,
        'motivo':
            motivo.trim(),
        'descripcion':
            descripcion
                        ?.trim()
                        .isNotEmpty ==
                    true
                ? descripcion!.trim()
                : null,
      }),
    );

    dynamic body;

    try {
      if (response.body.trim().isNotEmpty) {
        body = jsonDecode(
          response.body,
        );
      }
    } catch (_) {
      body = null;
    }

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return;
    }

    String mensaje =
        'No fue posible enviar el reporte';

    if (body is Map) {
      final respuesta =
          body['mensaje'] ??
              body['message'];

      if (respuesta != null) {
        mensaje =
            respuesta.toString();
      }
    }

    throw Exception(
      mensaje,
    );
  }
}