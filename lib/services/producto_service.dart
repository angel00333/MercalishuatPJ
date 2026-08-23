import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/producto.dart';
import 'session_service.dart';

class ProductoService {
  static Future<Map<String, String>>
      _headers() async {
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
  // CREAR
  // =========================================

  static Future<
      Map<String, dynamic>>
      crear({
    required int categoriaId,
    required String nombre,
    String? descripcion,
    required double precio,
    bool disponible = true,
  }) async {
    try {
      final headers =
          await _headers();

      final response =
          await http.post(
        Uri.parse(
          ApiConfig.productos,
        ),
        headers: headers,
        body: jsonEncode({
          'categoria_id':
              categoriaId,
          'nombre':
              nombre,
          'descripcion':
              descripcion,
          'precio':
              precio,
          'disponible':
              disponible,
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
          'producto':
              Producto.fromJson(
            data['producto'],
          ),
        };
      }

      return {
        'success': false,
        'message':
            data['message'] ??
                'No se pudo crear el producto',
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
  // MIS PRODUCTOS
  // =========================================

  static Future<
      Map<String, dynamic>>
      listarMisProductos() async {
    try {
      final headers =
          await _headers();

      final response =
          await http.get(
        Uri.parse(
          ApiConfig.misProductos,
        ),
        headers: headers,
      );

      final data =
          jsonDecode(
        response.body,
      );

      if (response.statusCode == 200) {
        final productos =
            (data['productos']
                    as List)
                .map(
                  (item) =>
                      Producto.fromJson(
                    item,
                  ),
                )
                .toList();

        return {
          'success': true,
          'productos': productos,
        };
      }

      return {
        'success': false,
        'message':
            data['message'] ??
                'No se pudieron cargar los productos',
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
  // PRODUCTOS DE TIENDA
  // =========================================

  static Future<
      Map<String, dynamic>>
      listarPorEmprendimiento(
    int emprendimientoId,
  ) async {
    try {
      final response =
          await http.get(
        Uri.parse(
          ApiConfig
              .productosEmprendimiento(
            emprendimientoId,
          ),
        ),
      );

      final data =
          jsonDecode(
        response.body,
      );

      if (response.statusCode == 200) {
        final productos =
            (data['productos']
                    as List)
                .map(
                  (item) =>
                      Producto.fromJson(
                    item,
                  ),
                )
                .toList();

        return {
          'success': true,
          'productos': productos,
        };
      }

      return {
        'success': false,
        'message':
            data['message'] ??
                'No se pudo cargar el catálogo',
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
          ApiConfig.productoDetalle(
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
          'producto':
              Producto.fromJson(
            data['producto'],
          ),
        };
      }

      return {
        'success': false,
        'message':
            data['message'] ??
                'Producto no encontrado',
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
    required int id,
    required int categoriaId,
    required String nombre,
    String? descripcion,
    required double precio,
    required bool disponible,
  }) async {
    try {
      final headers =
          await _headers();

      final response =
          await http.put(
        Uri.parse(
          ApiConfig.producto(id),
        ),
        headers: headers,
        body: jsonEncode({
          'categoria_id':
              categoriaId,
          'nombre':
              nombre,
          'descripcion':
              descripcion,
          'precio':
              precio,
          'disponible':
              disponible,
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
          'producto':
              Producto.fromJson(
            data['producto'],
          ),
        };
      }

      return {
        'success': false,
        'message':
            data['message'] ??
                'No se pudo actualizar el producto',
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
  // ELIMINAR
  // =========================================

  static Future<
      Map<String, dynamic>>
      eliminar(
    int id,
  ) async {
    try {
      final headers =
          await _headers();

      final response =
          await http.delete(
        Uri.parse(
          ApiConfig.producto(id),
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
          'message':
              data['message'],
        };
      }

      return {
        'success': false,
        'message':
            data['message'] ??
                'No se pudo eliminar el producto',
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