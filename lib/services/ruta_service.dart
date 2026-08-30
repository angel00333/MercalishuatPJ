import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:maplibre_gl/maplibre_gl.dart';

class RutaService {
  static const String _baseUrl =
      'https://router.project-osrm.org';

  static Future<Map<String, dynamic>>
      obtenerRuta({
    required LatLng origen,
    required LatLng destino,
  }) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/route/v1/driving/'
        '${origen.longitude},${origen.latitude};'
        '${destino.longitude},${destino.latitude}'
        '?overview=full'
        '&geometries=geojson'
        '&steps=false',
      );

      final response =
          await http.get(
        uri,
        headers: {
          'Accept':
              'application/json',
        },
      );

      if (response.statusCode != 200) {
        return {
          'success': false,
          'message':
              'No se pudo calcular la ruta',
        };
      }

      final data =
          jsonDecode(
        response.body,
      );

      if (data['code'] != 'Ok') {
        return {
          'success': false,
          'message':
              'No se encontró una ruta hasta este emprendimiento',
        };
      }

      final rutas =
          data['routes'];

      if (rutas is! List ||
          rutas.isEmpty) {
        return {
          'success': false,
          'message':
              'No se encontró una ruta',
        };
      }

      final ruta =
          rutas.first;

      final geometry =
          ruta['geometry'];

      if (geometry == null) {
        return {
          'success': false,
          'message':
              'La ruta no contiene geometría',
        };
      }

      final geojson = {
        'type':
            'FeatureCollection',
        'features': [
          {
            'type':
                'Feature',
            'properties': {
              'distance':
                  ruta['distance'],
              'duration':
                  ruta['duration'],
            },
            'geometry':
                geometry,
          },
        ],
      };

      return {
        'success':
            true,
        'geojson':
            geojson,
        'distancia':
            (ruta['distance'] as num?)
                ?.toDouble(),
        'duracion':
            (ruta['duration'] as num?)
                ?.toDouble(),
      };
    } catch (e) {
      return {
        'success': false,
        'message':
            'No se pudo conectar con el servicio de rutas',
      };
    }
  }
}