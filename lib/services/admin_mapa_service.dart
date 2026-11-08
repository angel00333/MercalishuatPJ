import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/emprendimiento.dart';
import '../models/local_comercial.dart';
import 'emprendimiento_service.dart';
import 'session_service.dart';

class AdminMapaDatos {
  final List<Emprendimiento> emprendimientos;
  final List<LocalComercial> locales;

  const AdminMapaDatos({
    required this.emprendimientos,
    required this.locales,
  });
}

class AdminMapaService {
  // ============================================================
  // CARGAR TODOS LOS DATOS DEL MAPA ADMINISTRATIVO
  // ============================================================

  static Future<AdminMapaDatos> cargar() async {
    final resultados = await Future.wait([
      _cargarEmprendimientos(),
      _cargarTodosLosLocales(),
    ]);

    return AdminMapaDatos(
      emprendimientos:
          resultados[0] as List<Emprendimiento>,
      locales:
          resultados[1] as List<LocalComercial>,
    );
  }

  // ============================================================
  // EMPRENDIMIENTOS
  // ============================================================

  static Future<List<Emprendimiento>>
      _cargarEmprendimientos() async {
    final resultado =
        await EmprendimientoService.listar();

    if (resultado['success'] != true) {
      throw Exception(
        resultado['message']?.toString() ??
            'No fue posible cargar los emprendimientos',
      );
    }

    final raw =
        resultado['emprendimientos'];

    if (raw is! List) {
      return [];
    }

    return raw
        .whereType<Emprendimiento>()
        .where(
          (emprendimiento) =>
              emprendimiento.latitud != null &&
              emprendimiento.longitud != null,
        )
        .toList();
  }

  // ============================================================
  // LOCALES COMERCIALES
  //
  // Se utiliza la ruta administrativa porque el administrador
  // debe poder consultar también locales ocultos/no disponibles.
  // ============================================================

  static Future<List<LocalComercial>>
      _cargarTodosLosLocales() async {
    final token =
        await SessionService.obtenerToken();

    if (token == null ||
        token.trim().isEmpty) {
      throw Exception(
        'Sesión administrativa no válida',
      );
    }

    final locales =
        <LocalComercial>[];

    int pagina = 1;
    int paginas = 1;

    do {
      final uri =
          Uri.parse(
        '${ApiConfig.baseUrl}/admin/locales',
      ).replace(
        queryParameters: {
          'pagina':
              pagina.toString(),
          'limite':
              '100',
          'estado':
              'todos',
        },
      );

      final response =
          await http.get(
        uri,
        headers: {
          'Accept':
              'application/json',
          'Content-Type':
              'application/json',
          'Authorization':
              'Bearer $token',
        },
      );

      final body =
          _decodificarJson(
        response.body,
      );

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        throw Exception(
          body['message']?.toString() ??
              body['mensaje']?.toString() ??
              'No fue posible cargar los locales comerciales',
        );
      }

      final data =
          body['data'];

      if (data is List) {
        for (final item in data) {
          if (item is! Map) {
            continue;
          }

          try {
            final local =
                LocalComercial.fromJson(
              Map<String, dynamic>.from(
                item,
              ),
            );

            if (local.latitud != null &&
                local.longitud != null) {
              locales.add(
                local,
              );
            }
          } catch (_) {
            // Si un registro individual es inválido,
            // no bloqueamos la carga completa del mapa.
          }
        }
      }

      final paginacion =
          body['paginacion'];

      if (paginacion is Map) {
        paginas =
            _entero(
          paginacion['paginas'],
          1,
        );
      } else {
        paginas = 1;
      }

      pagina++;
    } while (pagina <= paginas);

    return locales;
  }

  // ============================================================
  // JSON
  // ============================================================

  static Map<String, dynamic>
      _decodificarJson(
    String value,
  ) {
    if (value.trim().isEmpty) {
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
    } catch (_) {
      // Respuesta no JSON.
    }

    return {};
  }

  // ============================================================
  // ENTERO
  // ============================================================

  static int _entero(
    dynamic value,
    int fallback,
  ) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        fallback;
  }
}