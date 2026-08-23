import 'dart:convert';

import 'package:http/http.dart'
    as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../config/api_config.dart';
import 'session_service.dart';

class PerfilImagenService {
  static MediaType _tipo(
    String nombre,
  ) {
    final extension =
        nombre
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
      subirFotoPerfil(
    XFile imagen,
  ) async {
    return _subir(
      url:
          ApiConfig.fotoPerfil,
      imagen:
          imagen,
    );
  }

  static Future<Map<String, dynamic>>
      subirImagenEmprendimiento(
    XFile imagen,
  ) async {
    return _subir(
      url:
          ApiConfig
              .imagenEmprendimiento,
      imagen:
          imagen,
    );
  }

  static Future<Map<String, dynamic>>
      _subir({
    required String url,
    required XFile imagen,
  }) async {
    try {
      final token =
          await SessionService
              .obtenerToken();

      final request =
          http.MultipartRequest(
        'POST',
        Uri.parse(url),
      );

      request.headers[
              'Authorization'] =
          'Bearer $token';

      final bytes =
          await imagen.readAsBytes();

      request.files.add(
        http.MultipartFile.fromBytes(
          'imagen',
          bytes,
          filename:
              imagen.name,
          contentType:
              _tipo(
            imagen.name,
          ),
        ),
      );

      final stream =
          await request.send();

      final response =
          await http.Response
              .fromStream(
        stream,
      );

      final data =
          jsonDecode(
        response.body,
      );

      return {
        'success':
            response.statusCode >=
                200 &&
            response.statusCode <
                300,

        ...data,
      };
    } catch (e) {
      return {
        'success': false,
        'message':
            'No se pudo subir la imagen',
      };
    }
  }
}