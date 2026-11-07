import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/admin_reporte.dart';
import 'session_service.dart';

class AdminReporteService {
  // ============================================================
  // HEADERS
  // ============================================================

  static Future<Map<String, String>>
      _headers() async {
    final token =
        await SessionService.obtenerToken();

    if (token == null ||
        token.trim().isEmpty) {
      throw Exception(
        'No existe una sesión válida',
      );
    }

    return {
      'Content-Type':
          'application/json',
      'Accept':
          'application/json',
      'Authorization':
          'Bearer $token',
    };
  }

  // ============================================================
  // LISTAR REPORTES
  // ============================================================

  static Future<AdminReportesRespuesta>
      obtenerReportes({
    int pagina = 1,
    int limite = 20,
    String estado = 'pendiente',
  }) async {
    final uri =
        Uri.parse(
      '${ApiConfig.baseUrl}/admin/reportes',
    ).replace(
      queryParameters: {
        'pagina':
            pagina.toString(),
        'limite':
            limite.toString(),
        if (estado.trim().isNotEmpty)
          'estado':
              estado.trim(),
      },
    );

    final response =
        await http.get(
      uri,
      headers:
          await _headers(),
    );

    final body =
        _decode(
      response,
    );

    _validar(
      response,
      body,
    );

    if (body
        is! Map<String, dynamic>) {
      throw Exception(
        'Respuesta inválida del servidor',
      );
    }

    final data =
        body['data'];

    final paginacion =
        body['paginacion'];

    final reportes =
        <AdminReporte>[];

    if (data is List) {
      for (final item in data) {
        if (item is Map) {
          reportes.add(
            AdminReporte.fromJson(
              Map<String, dynamic>.from(
                item,
              ),
            ),
          );
        }
      }
    }

    final paginaActual =
        _toInt(
      paginacion is Map
          ? paginacion['pagina']
          : null,
      1,
    );

    final limiteActual =
        _toInt(
      paginacion is Map
          ? paginacion['limite']
          : null,
      limite,
    );

    final total =
        _toInt(
      paginacion is Map
          ? paginacion['total']
          : null,
      reportes.length,
    );

    final paginas =
        _toInt(
      paginacion is Map
          ? paginacion['paginas']
          : null,
      1,
    );

    return AdminReportesRespuesta(
      reportes:
          reportes,
      pagina:
          paginaActual,
      limite:
          limiteActual,
      total:
          total,
      paginas:
          paginas,
    );
  }

  // ============================================================
  // RESOLVER REPORTE
  // ============================================================

  static Future<void> resolverReporte({
    required int reporteId,
    required String accion,
  }) async {
    if (accion != 'ocultar' &&
        accion != 'descartar') {
      throw Exception(
        'Acción de moderación inválida',
      );
    }

    final response =
        await http.patch(
      Uri.parse(
        '${ApiConfig.baseUrl}/admin/reportes/$reporteId/resolver',
      ),
      headers:
          await _headers(),
      body:
          jsonEncode({
        'accion':
            accion,
      }),
    );

    final body =
        _decode(
      response,
    );

    _validar(
      response,
      body,
    );
  }

  // ============================================================
  // RESTAURAR / OCULTAR PUBLICACIÓN
  // ============================================================

  static Future<void>
      cambiarEstadoPublicacion({
    required int publicacionId,
    required bool activo,
  }) async {
    final response =
        await http.patch(
      Uri.parse(
        '${ApiConfig.baseUrl}/admin/moderacion/publicaciones/$publicacionId/estado',
      ),
      headers:
          await _headers(),
      body:
          jsonEncode({
        'activo':
            activo,
      }),
    );

    final body =
        _decode(
      response,
    );

    _validar(
      response,
      body,
    );
  }

  // ============================================================
  // RESTAURAR / OCULTAR COMENTARIO
  // ============================================================

  static Future<void>
      cambiarEstadoComentario({
    required int comentarioId,
    required bool activo,
  }) async {
    final response =
        await http.patch(
      Uri.parse(
        '${ApiConfig.baseUrl}/admin/moderacion/comentarios/$comentarioId/estado',
      ),
      headers:
          await _headers(),
      body:
          jsonEncode({
        'activo':
            activo,
      }),
    );

    final body =
        _decode(
      response,
    );

    _validar(
      response,
      body,
    );
  }

  // ============================================================
  // RESTAURAR CONTENIDO
  // ============================================================

  static Future<void> restaurarContenido(
    AdminReporte reporte,
  ) async {
    if (reporte.tipo ==
        'comentario') {
      if (reporte.comentarioId ==
          null) {
        throw Exception(
          'Comentario inválido',
        );
      }

      await cambiarEstadoComentario(
        comentarioId:
            reporte.comentarioId!,
        activo:
            true,
      );

      return;
    }

    if (reporte.publicacionId ==
        null) {
      throw Exception(
        'Publicación inválida',
      );
    }

    await cambiarEstadoPublicacion(
      publicacionId:
          reporte.publicacionId!,
      activo:
          true,
    );
  }

  // ============================================================
  // JSON
  // ============================================================

  static dynamic _decode(
    http.Response response,
  ) {
    if (response.body.trim().isEmpty) {
      return null;
    }

    try {
      return jsonDecode(
        response.body,
      );
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // VALIDAR
  // ============================================================

  static void _validar(
    http.Response response,
    dynamic body,
  ) {
    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return;
    }

    String mensaje =
        'Error del servidor';

    if (body is Map) {
      final valor =
          body['mensaje'] ??
              body['message'];

      if (valor != null) {
        mensaje =
            valor.toString();
      }
    }

    throw Exception(
      mensaje,
    );
  }

  static int _toInt(
    dynamic value,
    int fallback,
  ) {
    if (value is int) {
      return value;
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        fallback;
  }
}