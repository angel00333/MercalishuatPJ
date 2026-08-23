import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../config/api_config.dart';
import '../models/imagen_producto.dart';
import 'session_service.dart';

class ImagenService {
  static MediaType _obtenerTipoArchivo(String nombre) {
    final extension = nombre
        .split('.')
        .last
        .toLowerCase();

    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return MediaType(
          'image',
          'jpeg',
        );

      case 'png':
        return MediaType(
          'image',
          'png',
        );

      case 'webp':
        return MediaType(
          'image',
          'webp',
        );

      default:
        return MediaType(
          'application',
          'octet-stream',
        );
    }
  }

  static Future<Map<String, dynamic>>
      subirImagen({
    required int productoId,
    required XFile imagen,
  }) async {
    try {
      final token =
          await SessionService.obtenerToken();

      if (token == null ||
          token.isEmpty) {
        return {
          'success': false,
          'message':
              'Sesión no encontrada',
        };
      }

      final request =
          http.MultipartRequest(
        'POST',
        Uri.parse(
          ApiConfig.imagenesProducto(
            productoId,
          ),
        ),
      );

      request.headers[
              'Authorization'] =
          'Bearer $token';

      final bytes =
          await imagen.readAsBytes();

      final multipart =
          http.MultipartFile.fromBytes(
        'imagen',
        bytes,
        filename: imagen.name,
        contentType:
            _obtenerTipoArchivo(
          imagen.name,
        ),
      );

      request.files.add(
        multipart,
      );

      final streamedResponse =
          await request.send();

      final response =
          await http.Response
              .fromStream(
        streamedResponse,
      );

      Map<String, dynamic> data;

      try {
        data = jsonDecode(
          response.body,
        );
      } catch (_) {
        return {
          'success': false,
          'message':
              'Respuesta inválida del servidor',
        };
      }

      if (response.statusCode ==
          201) {
        return {
          'success': true,
          'message':
              data['message'] ??
                  'Imagen subida correctamente',
          'imagen':
              ImagenProducto.fromJson(
            data['imagen'],
          ),
        };
      }

      return {
        'success': false,
        'message':
            data['message'] ??
                'No se pudo subir la imagen',
      };
    } catch (e) {
      return {
        'success': false,
        'message':
            'Error subiendo la imagen: $e',
      };
    }
  }

  static Future<Map<String, dynamic>>
      listar(
    int productoId,
  ) async {
    try {
      final response =
          await http.get(
        Uri.parse(
          ApiConfig.imagenesProducto(
            productoId,
          ),
        ),
      );

      final data =
          jsonDecode(
        response.body,
      );

      if (response.statusCode ==
          200) {
        final imagenes =
            (data['imagenes']
                    as List)
                .map(
                  (item) =>
                      ImagenProducto
                          .fromJson(
                    Map<String, dynamic>
                        .from(item),
                  ),
                )
                .toList();

        return {
          'success': true,
          'imagenes': imagenes,
        };
      }

      return {
        'success': false,
        'message':
            data['message'] ??
                'No se pudieron cargar las imágenes',
      };
    } catch (e) {
      return {
        'success': false,
        'message':
            'No se pudo conectar con el servidor',
      };
    }
  }

  static Future<Map<String, dynamic>>
      marcarPrincipal({
    required int productoId,
    required int imagenId,
  }) async {
    try {
      final token =
          await SessionService.obtenerToken();

      final response =
          await http.put(
        Uri.parse(
          ApiConfig.imagenPrincipal(
            productoId:
                productoId,
            imagenId:
                imagenId,
          ),
        ),
        headers: {
          'Authorization':
              'Bearer $token',
        },
      );

      final data =
          jsonDecode(
        response.body,
      );

      return {
        'success':
            response.statusCode ==
                200,
        'message':
            data['message'],
      };
    } catch (e) {
      return {
        'success': false,
        'message':
            'No se pudo cambiar la imagen principal',
      };
    }
  }

  static Future<Map<String, dynamic>>
      eliminar({
    required int productoId,
    required int imagenId,
  }) async {
    try {
      final token =
          await SessionService.obtenerToken();

      final response =
          await http.delete(
        Uri.parse(
          ApiConfig.eliminarImagen(
            productoId:
                productoId,
            imagenId:
                imagenId,
          ),
        ),
        headers: {
          'Authorization':
              'Bearer $token',
        },
      );

      final data =
          jsonDecode(
        response.body,
      );

      return {
        'success':
            response.statusCode ==
                200,
        'message':
            data['message'],
      };
    } catch (e) {
      return {
        'success': false,
        'message':
            'No se pudo eliminar la imagen',
      };
    }
  }
}