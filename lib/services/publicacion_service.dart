import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/publicacion.dart';
import 'session_service.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

class PublicacionService {
  static Future<Map<String, String>> _headers() async {
    final token =
        await SessionService.obtenerToken();

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>>
      misPublicaciones() async {
    try {
      final headers =
          await _headers();

      final response =
          await http.get(
        Uri.parse(
          ApiConfig.misPublicaciones,
        ),
        headers: headers,
      );

      final data =
          jsonDecode(response.body);

      if (response.statusCode == 200) {
        final lista =
            (data['publicaciones'] as List)
                .map(
                  (e) =>
                      Publicacion.fromJson(e),
                )
                .toList();

        return {
          'success': true,
          'publicaciones': lista,
        };
      }

      return {
        'success': false,
        'message':
            data['message'] ??
            'No se pudieron cargar las publicaciones',
      };
    } catch (e) {
      return {
        'success': false,
        'message':
            'No se pudo conectar con el servidor',
      };
    }
  }

  static Future<Map<String, dynamic>> feed({
    int pagina = 1,
    int limite = 10,
  }) async {
    try {
      final headers =
          await _headers();

      final uri =
          Uri.parse(
        ApiConfig.feed,
      ).replace(
        queryParameters: {
          'pagina': pagina.toString(),
          'limite': limite.toString(),
        },
      );

      final response =
          await http.get(
        uri,
        headers: headers,
      );

      final data =
          jsonDecode(response.body);

      if (response.statusCode == 200) {
        final lista =
            (data['publicaciones'] as List)
                .map(
                  (e) =>
                      Publicacion.fromJson(e),
                )
                .toList();

        return {
          'success': true,
          'publicaciones': lista,
          'paginacion':
              data['paginacion'],
        };
      }

      return {
        'success': false,
        'message':
            data['message'] ??
            'No se pudo cargar el feed',
      };
    } catch (e) {
      return {
        'success': false,
        'message':
            'No se pudo cargar el feed',
      };
    }
  }

  static Future<Map<String, dynamic>> crear({
    required String texto,
    int? productoId,
  }) async {
    try {
      final headers =
          await _headers();

      final response =
          await http.post(
        Uri.parse(
          ApiConfig.publicaciones,
        ),
        headers: headers,
        body: jsonEncode({
          'texto': texto,
          'producto_id': productoId,
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
            'No se pudo crear la publicación',
      };
    }
  }

  static Future<Map<String, dynamic>>
      darMeGusta(
    int id,
  ) async {
    try {
      final headers =
          await _headers();

      final response =
          await http.post(
        Uri.parse(
          ApiConfig.meGusta(id),
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
            'No se pudo agregar Me gusta',
      };
    }
  }

  static Future<Map<String, dynamic>>
      quitarMeGusta(
    int id,
  ) async {
    try {
      final headers =
          await _headers();

      final response =
          await http.delete(
        Uri.parse(
          ApiConfig.meGusta(id),
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
            'No se pudo quitar Me gusta',
      };
    }
  }

  static Future<Map<String, dynamic>>
      guardar(
    int id,
  ) async {
    try {
      final headers =
          await _headers();

      final response =
          await http.post(
        Uri.parse(
          ApiConfig.guardarPublicacion(
            id,
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
            'No se pudo guardar la publicación',
      };
    }
  }

  static Future<Map<String, dynamic>>
      quitarGuardado(
    int id,
  ) async {
    try {
      final headers =
          await _headers();

      final response =
          await http.delete(
        Uri.parse(
          ApiConfig.guardarPublicacion(
            id,
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
            'No se pudo quitar de guardados',
      };
    }
  }

  static Future<Map<String, dynamic>> subirImagen({
  required int publicacionId,
  required XFile imagen,
}) async {
  try {
    final token =
        await SessionService.obtenerToken();

    final request =
        http.MultipartRequest(
      'POST',
      Uri.parse(
        ApiConfig.imagenesPublicacion(
          publicacionId,
        ),
      ),
    );

    request.headers['Authorization'] =
        'Bearer $token';

    final bytes =
        await imagen.readAsBytes();

    final extension =
        imagen.name
            .split('.')
            .last
            .toLowerCase();

    MediaType contentType;

    switch (extension) {
      case 'jpg':
      case 'jpeg':
        contentType =
            MediaType('image', 'jpeg');
        break;

      case 'png':
        contentType =
            MediaType('image', 'png');
        break;

      case 'webp':
        contentType =
            MediaType('image', 'webp');
        break;

      default:
        contentType =
            MediaType(
          'application',
          'octet-stream',
        );
    }

    request.files.add(
      http.MultipartFile.fromBytes(
        'imagen',
        bytes,
        filename: imagen.name,
        contentType: contentType,
      ),
    );

    final streamResponse =
        await request.send();

    final response =
        await http.Response.fromStream(
      streamResponse,
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
          'No se pudo subir la imagen',
    };
  }
}

static Future<Map<String, dynamic>> obtenerPorId(
  int id,
) async {
  try {
    final headers = await _headers();

    final response = await http.get(
      Uri.parse(
        ApiConfig.publicacion(id),
      ),
      headers: headers,
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return {
        'success': true,
        'publicacion': Publicacion.fromJson(
          data['publicacion'],
        ),
        'imagenes': data['imagenes'] ?? [],
      };
    }

    return {
      'success': false,
      'message':
          data['message'] ??
          'No se pudo cargar la publicación',
    };
  } catch (e) {
    return {
      'success': false,
      'message':
          'No se pudo conectar con el servidor',
    };
  }
}

static Future<Map<String, dynamic>> editar({
  required int id,
  required String texto,
  int? productoId,
}) async {
  try {
    final headers = await _headers();

    final response = await http.put(
      Uri.parse(
        ApiConfig.publicacion(id),
      ),
      headers: headers,
      body: jsonEncode({
        'texto': texto,
        'producto_id': productoId,
      }),
    );

    final data = jsonDecode(response.body);

    return {
      'success':
          response.statusCode == 200,
      ...data,
    };
  } catch (e) {
    return {
      'success': false,
      'message':
          'No se pudo editar la publicación',
    };
  }
}

static Future<Map<String, dynamic>>
    eliminar(
  int id,
) async {
  try {
    final headers = await _headers();

    final response = await http.delete(
      Uri.parse(
        ApiConfig.publicacion(id),
      ),
      headers: headers,
    );

    final data = jsonDecode(response.body);

    return {
      'success':
          response.statusCode == 200,
      ...data,
    };
  } catch (e) {
    return {
      'success': false,
      'message':
          'No se pudo eliminar la publicación',
    };
  }
}

static Future<Map<String, dynamic>>
    listarGuardados() async {
  try {
    final headers =
        await _headers();

    final response =
        await http.get(
      Uri.parse(
        ApiConfig.guardados,
      ),
      headers: headers,
    );

    final data =
        jsonDecode(
      response.body,
    );

    if (response.statusCode == 200) {
      final lista =
          (data['publicaciones'] as List)
              .map(
                (e) =>
                    Publicacion.fromJson(
                  e,
                ),
              )
              .toList();

      return {
        'success': true,
        'publicaciones':
            lista,
      };
    }

    return {
      'success': false,
      'message':
          data['message'] ??
          'No se pudieron cargar los guardados',
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