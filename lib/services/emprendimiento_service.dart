import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/emprendimiento.dart';
import 'session_service.dart';

class EmprendimientoService {
  // =========================================
  // TOKEN
  // =========================================

  static Future<Map<String, String>>
      _headersConToken() async {
    final token =
        await SessionService.obtenerToken();

    return {
      'Content-Type':
          'application/json',
      'Authorization':
          'Bearer $token',
    };
  }

  // =========================================
  // MI TIENDA
  // =========================================

  static Future<
      Map<String, dynamic>>
      obtenerMiTienda() async {
    try {
      final headers =
          await _headersConToken();

      final response =
          await http.get(
        Uri.parse(
          ApiConfig.miTienda,
        ),
        headers: headers,
      );

      final data =
          jsonDecode(
        response.body,
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'emprendimiento':
              Emprendimiento.fromJson(
            data['emprendimiento'],
          ),
        };
      }

      return {
        'success': false,
        'statusCode':
            response.statusCode,
        'message':
            data['message'] ??
                'No se pudo obtener la tienda',
      };
    } catch (e) {
      return {
        'success': false,
        'message':
            'No se pudo conectar con el servidor',
      };
    }
  }

  // =========================================
  // CREAR
  // =========================================

  static Future<
      Map<String, dynamic>>
      crear({
    required String nombre,
    String? descripcion,
    String? telefono,
    String? correoContacto,
  }) async {
    try {
      final headers =
          await _headersConToken();

      final response =
          await http.post(
        Uri.parse(
          ApiConfig.emprendimientos,
        ),
        headers: headers,
        body: jsonEncode({
          'nombre': nombre,
          'descripcion': descripcion,
          'telefono': telefono,
          'correo_contacto':
              correoContacto,
        }),
      );

      final data =
          jsonDecode(
        response.body,
      );

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message':
              data['message'],
          'emprendimiento':
              Emprendimiento.fromJson(
            data['emprendimiento'],
          ),
        };
      }

      return {
        'success': false,
        'message':
            data['message'] ??
                'No se pudo crear el emprendimiento',
      };
    } catch (e) {
      return {
        'success': false,
        'message':
            'No se pudo conectar con el servidor',
      };
    }
  }

  // =========================================
  // EDITAR
  // =========================================

  static Future<
      Map<String, dynamic>>
      editar({
    required String nombre,
    String? descripcion,
    String? telefono,
    String? correoContacto,
  }) async {
    try {
      final headers =
          await _headersConToken();

      final response =
          await http.put(
        Uri.parse(
          ApiConfig.emprendimientos,
        ),
        headers: headers,
        body: jsonEncode({
          'nombre': nombre,
          'descripcion': descripcion,
          'telefono': telefono,
          'correo_contacto':
              correoContacto,
        }),
      );

      final data =
          jsonDecode(
        response.body,
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message':
              data['message'],
          'emprendimiento':
              Emprendimiento.fromJson(
            data['emprendimiento'],
          ),
        };
      }

      return {
        'success': false,
        'message':
            data['message'] ??
                'No se pudo actualizar la tienda',
      };
    } catch (e) {
      return {
        'success': false,
        'message':
            'No se pudo conectar con el servidor',
      };
    }
  }

  // =========================================
  // LISTAR TODAS
  // =========================================

  static Future<
      Map<String, dynamic>>
      listar() async {
    try {
      final response =
          await http.get(
        Uri.parse(
          ApiConfig.emprendimientos,
        ),
      );

      final data =
          jsonDecode(
        response.body,
      );

      if (response.statusCode == 200) {
        final lista =
            (data['emprendimientos']
                    as List)
                .map(
                  (item) =>
                      Emprendimiento
                          .fromJson(
                    item,
                  ),
                )
                .toList();

        return {
          'success': true,
          'emprendimientos': lista,
        };
      }

      return {
        'success': false,
        'message':
            data['message'] ??
                'No se pudieron cargar los emprendimientos',
      };
    } catch (e) {
      return {
        'success': false,
        'message':
            'No se pudo conectar con el servidor',
      };
    }
  }

  // =========================================
  // DETALLE
  // =========================================

  static Future<
      Map<String, dynamic>>
      obtenerPorId(
    int id,
  ) async {
    try {
      final response =
          await http.get(
        Uri.parse(
          ApiConfig
              .emprendimientoDetalle(
            id,
          ),
        ),
      );

      final data =
          jsonDecode(
        response.body,
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'emprendimiento':
              Emprendimiento.fromJson(
            data['emprendimiento'],
          ),
        };
      }

      return {
        'success': false,
        'message':
            data['message'] ??
                'Emprendimiento no encontrado',
      };
    } catch (e) {
      return {
        'success': false,
        'message':
            'No se pudo conectar con el servidor',
      };
    }
  }
}