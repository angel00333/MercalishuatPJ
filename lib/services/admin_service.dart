import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/admin_dashboard.dart';
import '../models/admin_usuario.dart';
import '../models/admin_dashboard.dart';
import 'session_service.dart';
import '../config/api_config.dart';

class AdminService {
  // ============================================================
  // HEADERS
  // ============================================================

  static Future<Map<String, String>>
      _headers() async {
    final token =
        await SessionService.obtenerToken();

    if (
        token == null ||
        token.isEmpty) {
      throw Exception(
        'No existe una sesión activa',
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
  // DECODIFICAR RESPUESTA
  // ============================================================

  static dynamic _decode(
    http.Response response,
  ) {
    try {
      return jsonDecode(
        response.body,
      );
    } catch (_) {
      throw Exception(
        'El servidor devolvió una respuesta inválida',
      );
    }
  }

  // ============================================================
  // VALIDAR RESPUESTA
  // ============================================================

  static void _validarRespuesta(
    http.Response response,
    dynamic body,
  ) {
    if (response.statusCode == 401) {
      throw Exception(
        'La sesión expiró. Inicia sesión nuevamente.',
      );
    }

    if (response.statusCode == 403) {
      throw Exception(
        'No tienes permisos de administrador.',
      );
    }

    if (
        response.statusCode < 200 ||
        response.statusCode >= 300) {
      String mensaje =
          'Ocurrió un error en el servidor';

      if (
          body is Map<String, dynamic>) {
        mensaje =
            body['mensaje']?.toString() ??
            body['message']?.toString() ??
            mensaje;
      }

      throw Exception(
        mensaje,
      );
    }
  }

  // ============================================================
  // DASHBOARD
  // ============================================================

  static Future<AdminDashboard>
      obtenerDashboard() async {
    final response =
        await http.get(
      Uri.parse(
        '${ApiConfig.baseUrl}/admin/dashboard',
      ),
      headers:
          await _headers(),
    );

    final body =
        _decode(
      response,
    );

    _validarRespuesta(
      response,
      body,
    );

    if (
        body is! Map<String, dynamic>) {
      throw Exception(
        'Respuesta inválida del servidor',
      );
    }

    final data =
        body['data'];

    if (
        data is! Map<String, dynamic>) {
      throw Exception(
        'El dashboard no contiene datos válidos',
      );
    }

    return AdminDashboard.fromJson(
      data,
    );
  }

  // ============================================================
  // LISTAR USUARIOS
  // ============================================================

  static Future<AdminUsuariosRespuesta>
      obtenerUsuarios({
    int pagina = 1,
    int limite = 20,
    String buscar = '',
    int? rolId,
  }) async {
    final query =
        <String, String>{
      'pagina':
          '$pagina',

      'limite':
          '$limite',
    };

    final texto =
        buscar.trim();

    if (texto.isNotEmpty) {
      query['buscar'] =
          texto;
    }

    if (rolId != null) {
      query['rol_id'] =
          '$rolId';
    }

    final uri =
        Uri.parse(
      '${ApiConfig.baseUrl}/admin/usuarios',
    ).replace(
      queryParameters:
          query,
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

    _validarRespuesta(
      response,
      body,
    );

    if (
        body is! Map<String, dynamic>) {
      throw Exception(
        'Respuesta inválida del servidor',
      );
    }

    final data =
        body['data'];

    final paginacion =
        body['paginacion'];

    if (data is! List) {
      throw Exception(
        'La lista de usuarios es inválida',
      );
    }

    final usuarios =
        data
            .whereType<
                Map>()
            .map(
              (
                item,
              ) =>
                  AdminUsuario.fromJson(
                Map<String, dynamic>.from(
                  item,
                ),
              ),
            )
            .toList();

    int paginaActual =
        pagina;

    int limiteActual =
        limite;

    int total =
        usuarios.length;

    int paginas =
        1;

    if (
        paginacion
            is Map) {
      final map =
          Map<String, dynamic>.from(
        paginacion,
      );

      paginaActual =
          _toInt(
        map['pagina'],
        pagina,
      );

      limiteActual =
          _toInt(
        map['limite'],
        limite,
      );

      total =
          _toInt(
        map['total'],
        usuarios.length,
      );

      paginas =
          _toInt(
        map['paginas'],
        1,
      );
    }

    return AdminUsuariosRespuesta(
      usuarios:
          usuarios,
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
  // USUARIO POR ID
  // ============================================================

  static Future<AdminUsuario>
      obtenerUsuario(
    int id,
  ) async {
    final response =
        await http.get(
      Uri.parse(
        '${ApiConfig.baseUrl}/admin/usuarios/$id',
      ),
      headers:
          await _headers(),
    );

    final body =
        _decode(
      response,
    );

    _validarRespuesta(
      response,
      body,
    );

    if (
        body is! Map<String, dynamic>) {
      throw Exception(
        'Respuesta inválida del servidor',
      );
    }

    final data =
        body['data'];

    if (
        data is! Map) {
      throw Exception(
        'El usuario no contiene datos válidos',
      );
    }

    return AdminUsuario.fromJson(
      Map<String, dynamic>.from(
        data,
      ),
    );
  }

  // ============================================================
  // CONVERTIR ENTERO
  // ============================================================

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