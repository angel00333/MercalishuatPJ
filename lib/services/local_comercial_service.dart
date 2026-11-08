import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../config/api_config.dart';
import '../models/local_comercial.dart';
import 'session_service.dart';

class LocalComercialService {
  static Future<Map<String, String>> _headers({
    bool json = true,
  }) async {
    final token = await SessionService.obtenerToken();

    if (token == null || token.trim().isEmpty) {
      throw Exception('Debes iniciar sesión');
    }

    return {
      'Accept': 'application/json',
      if (json) 'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<LocalesComercialesResultado> listar({
    int pagina = 1,
    int limite = 20,
    String? buscar,
    String? tipoOperacion,
    String? tipoLocal,
    String? departamento,
    String? municipio,
    double? precioMin,
    double? precioMax,
  }) async {
    final parametros = <String, String>{
      'pagina': '$pagina',
      'limite': '$limite',
    };

    if (buscar != null && buscar.trim().isNotEmpty) {
      parametros['buscar'] = buscar.trim();
    }

    if (tipoOperacion != null && tipoOperacion.trim().isNotEmpty) {
      parametros['tipo_operacion'] = tipoOperacion.trim();
    }

    if (tipoLocal != null && tipoLocal.trim().isNotEmpty) {
      parametros['tipo_local'] = tipoLocal.trim();
    }

    if (departamento != null && departamento.trim().isNotEmpty) {
      parametros['departamento'] = departamento.trim();
    }

    if (municipio != null && municipio.trim().isNotEmpty) {
      parametros['municipio'] = municipio.trim();
    }

    if (precioMin != null) {
      parametros['precio_min'] = '$precioMin';
    }

    if (precioMax != null) {
      parametros['precio_max'] = '$precioMax';
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/locales',
    ).replace(
      queryParameters: parametros,
    );

    final response = await http.get(
      uri,
      headers: await _headers(),
    );

    final body = _json(response.body);

    if (!_ok(response.statusCode)) {
      throw Exception(
        _mensajeError(
          body,
          'No fue posible cargar los locales',
        ),
      );
    }

    final locales = _listaLocales(body['data']);

    final paginacion = body['paginacion'] is Map
        ? Map<String, dynamic>.from(body['paginacion'])
        : <String, dynamic>{};

    return LocalesComercialesResultado(
      locales: locales,
      pagina: _entero(paginacion['pagina'], pagina),
      limite: _entero(paginacion['limite'], limite),
      total: _entero(paginacion['total'], locales.length),
      paginas: _entero(paginacion['paginas'], 1),
    );
  }

  static Future<List<LocalComercial>> listarMios() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/locales/mios'),
      headers: await _headers(),
    );

    final body = _json(response.body);

    if (!_ok(response.statusCode)) {
      throw Exception(
        _mensajeError(
          body,
          'No fue posible cargar tus locales',
        ),
      );
    }

    return _listaLocales(body['data']);
  }

  static Future<LocalComercial> obtener(int id) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/locales/$id'),
      headers: await _headers(),
    );

    final body = _json(response.body);

    if (!_ok(response.statusCode)) {
      throw Exception(
        _mensajeError(
          body,
          'No fue posible cargar el local',
        ),
      );
    }

    final data = body['data'];

    if (data is! Map) {
      throw Exception('Respuesta inválida del servidor');
    }

    return LocalComercial.fromJson(
      Map<String, dynamic>.from(data),
    );
  }

  static Future<LocalComercial> crear({
    required String titulo,
    required String descripcion,
    required String tipoOperacion,
    required String tipoLocal,
    required double precio,
    required String departamento,
    required String municipio,
    required String direccion,
    double? latitud,
    double? longitud,
    String? contactoNombre,
    String? contactoTelefono,
    String? contactoWhatsapp,
    String? contactoCorreo,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/locales'),
      headers: await _headers(),
      body: jsonEncode({
        'titulo': titulo.trim(),
        'descripcion': descripcion.trim(),
        'tipo_operacion': tipoOperacion,
        'tipo_local': tipoLocal,
        'precio': precio,
        'departamento': departamento,
        'municipio': municipio.trim(),
        'direccion': direccion.trim(),
        'latitud': latitud,
        'longitud': longitud,
        'contacto_nombre': _nullable(contactoNombre),
        'contacto_telefono': _nullable(contactoTelefono),
        'contacto_whatsapp': _nullable(contactoWhatsapp),
        'contacto_correo': _nullable(contactoCorreo),
      }),
    );

    return _localDesdeRespuesta(
      response,
      'No fue posible publicar el local',
    );
  }

  static Future<LocalComercial> actualizar({
    required int id,
    required String titulo,
    required String descripcion,
    required String tipoOperacion,
    required String tipoLocal,
    required double precio,
    required String departamento,
    required String municipio,
    required String direccion,
    double? latitud,
    double? longitud,
    String? contactoNombre,
    String? contactoTelefono,
    String? contactoWhatsapp,
    String? contactoCorreo,
  }) async {
    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/locales/$id'),
      headers: await _headers(),
      body: jsonEncode({
        'titulo': titulo.trim(),
        'descripcion': descripcion.trim(),
        'tipo_operacion': tipoOperacion,
        'tipo_local': tipoLocal,
        'precio': precio,
        'departamento': departamento,
        'municipio': municipio.trim(),
        'direccion': direccion.trim(),
        'latitud': latitud,
        'longitud': longitud,
        'contacto_nombre': _nullable(contactoNombre),
        'contacto_telefono': _nullable(contactoTelefono),
        'contacto_whatsapp': _nullable(contactoWhatsapp),
        'contacto_correo': _nullable(contactoCorreo),
      }),
    );

    return _localDesdeRespuesta(
      response,
      'No fue posible actualizar el local',
    );
  }

  static Future<LocalComercial> cambiarDisponibilidad({
    required int id,
    required bool disponible,
  }) async {
    final response = await http.patch(
      Uri.parse(
        '${ApiConfig.baseUrl}/locales/$id/disponibilidad',
      ),
      headers: await _headers(),
      body: jsonEncode({
        'disponible': disponible,
      }),
    );

    return _localDesdeRespuesta(
      response,
      'No fue posible cambiar la disponibilidad',
    );
  }

  static Future<void> eliminar(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/locales/$id'),
      headers: await _headers(),
    );

    final body = _json(response.body);

    if (!_ok(response.statusCode)) {
      throw Exception(
        _mensajeError(
          body,
          'No fue posible eliminar el local',
        ),
      );
    }
  }

  static Future<List<ImagenLocalComercial>> subirImagenes({
    required int localId,
    required List<XFile> archivos,
  }) async {
    if (archivos.isEmpty) return [];

    if (archivos.length > 5) {
      throw Exception(
        'Solo puedes subir hasta 5 imágenes por vez',
      );
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(
        '${ApiConfig.baseUrl}/locales/$localId/imagenes',
      ),
    );

    request.headers.addAll(
      await _headers(json: false),
    );

    for (final archivo in archivos) {
      final bytes = await archivo.readAsBytes();

      request.files.add(
        http.MultipartFile.fromBytes(
          'imagenes',
          bytes,
          filename: archivo.name,
        ),
      );
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    final body = _json(response.body);

    if (!_ok(response.statusCode)) {
      throw Exception(
        _mensajeError(
          body,
          'No fue posible subir las imágenes',
        ),
      );
    }

    final data = body['data'];
    final resultado = <ImagenLocalComercial>[];

    if (data is List) {
      for (final item in data) {
        if (item is Map) {
          resultado.add(
            ImagenLocalComercial.fromJson(
              Map<String, dynamic>.from(item),
            ),
          );
        }
      }
    }

    return resultado;
  }

  static Future<void> establecerImagenPrincipal({
    required int localId,
    required int imagenId,
  }) async {
    final response = await http.patch(
      Uri.parse(
        '${ApiConfig.baseUrl}/locales/$localId/imagenes/$imagenId/principal',
      ),
      headers: await _headers(),
    );

    final body = _json(response.body);

    if (!_ok(response.statusCode)) {
      throw Exception(
        _mensajeError(
          body,
          'No fue posible cambiar la imagen principal',
        ),
      );
    }
  }

  static Future<void> eliminarImagen({
    required int localId,
    required int imagenId,
  }) async {
    final response = await http.delete(
      Uri.parse(
        '${ApiConfig.baseUrl}/locales/$localId/imagenes/$imagenId',
      ),
      headers: await _headers(),
    );

    final body = _json(response.body);

    if (!_ok(response.statusCode)) {
      throw Exception(
        _mensajeError(
          body,
          'No fue posible eliminar la imagen',
        ),
      );
    }
  }

  static Future<LocalComercial> _localDesdeRespuesta(
    http.Response response,
    String fallback,
  ) async {
    final body = _json(response.body);

    if (!_ok(response.statusCode)) {
      throw Exception(
        _mensajeError(body, fallback),
      );
    }

    final data = body['data'];

    if (data is! Map) {
      throw Exception('Respuesta inválida del servidor');
    }

    return LocalComercial.fromJson(
      Map<String, dynamic>.from(data),
    );
  }

  static List<LocalComercial> _listaLocales(dynamic data) {
    final resultado = <LocalComercial>[];

    if (data is List) {
      for (final item in data) {
        if (item is Map) {
          resultado.add(
            LocalComercial.fromJson(
              Map<String, dynamic>.from(item),
            ),
          );
        }
      }
    }

    return resultado;
  }

  static Map<String, dynamic> _json(String contenido) {
    if (contenido.trim().isEmpty) return {};

    try {
      final resultado = jsonDecode(contenido);

      if (resultado is Map) {
        return Map<String, dynamic>.from(resultado);
      }
    } catch (_) {}

    return {};
  }

  static bool _ok(int statusCode) {
    return statusCode >= 200 && statusCode < 300;
  }

  static String _mensajeError(
    Map<String, dynamic> body,
    String fallback,
  ) {
    final mensaje = body['message'] ?? body['mensaje'];
    return mensaje?.toString() ?? fallback;
  }

  static int _entero(dynamic valor, int fallback) {
    if (valor is int) return valor;
    return int.tryParse(valor?.toString() ?? '') ?? fallback;
  }

  static String? _nullable(String? valor) {
    final texto = valor?.trim() ?? '';
    return texto.isEmpty ? null : texto;
  }
}
