import 'dart:convert';

import 'package:http/http.dart'
    as http;

import '../config/api_config.dart';
import '../models/local_comercial.dart';
import 'session_service.dart';

class AdminLocalesResumen {
  final int total;
  final int activos;
  final int ocultos;
  final int disponibles;
  final int noDisponibles;

  const AdminLocalesResumen({
    required this.total,
    required this.activos,
    required this.ocultos,
    required this.disponibles,
    required this.noDisponibles,
  });

  factory AdminLocalesResumen.fromJson(
    Map<String, dynamic> json,
  ) {
    return AdminLocalesResumen(
      total:
          _int(
        json['total'],
      ),
      activos:
          _int(
        json['activos'],
      ),
      ocultos:
          _int(
        json['ocultos'],
      ),
      disponibles:
          _int(
        json['disponibles'],
      ),
      noDisponibles:
          _int(
        json['no_disponibles'],
      ),
    );
  }

  static int _int(
    dynamic value,
  ) {
    if (value is int) {
      return value;
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }
}

class AdminLocalesResultado {
  final List<LocalComercial> locales;

  final AdminLocalesResumen resumen;

  final int pagina;
  final int paginas;
  final int total;

  const AdminLocalesResultado({
    required this.locales,
    required this.resumen,
    required this.pagina,
    required this.paginas,
    required this.total,
  });
}

class AdminLocalesService {
  // ==========================================================
  // HEADERS
  // ==========================================================

  static Future<Map<String, String>>
      _headers() async {
    final token =
        await SessionService.obtenerToken();

    if (
      token == null ||
      token.trim().isEmpty
    ) {
      throw Exception(
        'Sesión no válida',
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

  // ==========================================================
  // LISTAR
  // ==========================================================

  static Future<AdminLocalesResultado>
      listar({
    int pagina = 1,
    int limite = 20,
    String? buscar,
    String estado = 'todos',
    String? tipoOperacion,
  }) async {
    final parametros =
        <String, String>{
      'pagina':
          '$pagina',

      'limite':
          '$limite',

      'estado':
          estado,
    };

    if (
      buscar != null &&
      buscar.trim().isNotEmpty
    ) {
      parametros['buscar'] =
          buscar.trim();
    }

    if (
      tipoOperacion != null &&
      tipoOperacion.trim().isNotEmpty
    ) {
      parametros['tipo_operacion'] =
          tipoOperacion;
    }

    final uri =
        Uri.parse(
      '${ApiConfig.baseUrl}/admin/locales',
    ).replace(
      queryParameters:
          parametros,
    );

    final response =
        await http.get(
      uri,
      headers:
          await _headers(),
    );

    final body =
        _json(
      response.body,
    );

    if (
      response.statusCode < 200 ||
      response.statusCode >= 300
    ) {
      throw Exception(
        _mensaje(
          body,
          'No fue posible cargar los locales',
        ),
      );
    }

    final data =
        body['data'];

    final locales =
        <LocalComercial>[];

    if (data is List) {
      for (
        final item in data
      ) {
        if (item is Map) {
          locales.add(
            LocalComercial.fromJson(
              Map<String, dynamic>.from(
                item,
              ),
            ),
          );
        }
      }
    }

    final paginacion =
        body['paginacion']
                is Map
            ? Map<String, dynamic>.from(
                body[
                    'paginacion'],
              )
            : <String, dynamic>{};

    final resumen =
        body['resumen']
                is Map
            ? AdminLocalesResumen
                .fromJson(
                Map<String, dynamic>.from(
                  body[
                      'resumen'],
                ),
              )
            : const AdminLocalesResumen(
                total: 0,
                activos: 0,
                ocultos: 0,
                disponibles: 0,
                noDisponibles: 0,
              );

    return AdminLocalesResultado(
      locales:
          locales,

      resumen:
          resumen,

      pagina:
          _int(
        paginacion[
            'pagina'],
        pagina,
      ),

      paginas:
          _int(
        paginacion[
            'paginas'],
        1,
      ),

      total:
          _int(
        paginacion[
            'total'],
        locales.length,
      ),
    );
  }

  // ==========================================================
  // OBTENER
  // ==========================================================

  static Future<LocalComercial>
      obtener(
    int id,
  ) async {
    final response =
        await http.get(
      Uri.parse(
        '${ApiConfig.baseUrl}/admin/locales/$id',
      ),
      headers:
          await _headers(),
    );

    return _local(
      response,
      'No fue posible cargar el local',
    );
  }

  // ==========================================================
  // ACTIVO / OCULTO
  // ==========================================================

  static Future<LocalComercial>
      cambiarEstado({
    required int id,
    required bool activo,
  }) async {
    final response =
        await http.patch(
      Uri.parse(
        '${ApiConfig.baseUrl}/admin/locales/$id/estado',
      ),
      headers:
          await _headers(),
      body:
          jsonEncode({
        'activo':
            activo,
      }),
    );

    return _local(
      response,
      'No fue posible cambiar el estado',
    );
  }

  // ==========================================================
  // DISPONIBILIDAD
  // ==========================================================

  static Future<LocalComercial>
      cambiarDisponibilidad({
    required int id,
    required bool disponible,
  }) async {
    final response =
        await http.patch(
      Uri.parse(
        '${ApiConfig.baseUrl}/admin/locales/$id/disponibilidad',
      ),
      headers:
          await _headers(),
      body:
          jsonEncode({
        'disponible':
            disponible,
      }),
    );

    return _local(
      response,
      'No fue posible cambiar la disponibilidad',
    );
  }

  // ==========================================================
  // HELPERS
  // ==========================================================

  static LocalComercial _local(
    http.Response response,
    String fallback,
  ) {
    final body =
        _json(
      response.body,
    );

    if (
      response.statusCode < 200 ||
      response.statusCode >= 300
    ) {
      throw Exception(
        _mensaje(
          body,
          fallback,
        ),
      );
    }

    final data =
        body['data'];

    if (data is! Map) {
      throw Exception(
        'Respuesta inválida del servidor',
      );
    }

    return LocalComercial.fromJson(
      Map<String, dynamic>.from(
        data,
      ),
    );
  }

  static Map<String, dynamic> _json(
    String value,
  ) {
    if (
      value.trim().isEmpty
    ) {
      return {};
    }

    try {
      final decoded =
          jsonDecode(
        value,
      );

      if (decoded is Map) {
        return Map<String, dynamic>.from(
          decoded,
        );
      }
    } catch (_) {}

    return {};
  }

  static String _mensaje(
    Map<String, dynamic> body,
    String fallback,
  ) {
    return (
          body['message'] ??
          body['mensaje'] ??
          fallback
        )
        .toString();
  }

  static int _int(
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