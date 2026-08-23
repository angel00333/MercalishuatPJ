import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/categoria.dart';

class CategoriaService {
  static Future<
      Map<String, dynamic>>
      listar() async {
    try {
      final response =
          await http.get(
        Uri.parse(
          ApiConfig.categorias,
        ),
      );

      final data =
          jsonDecode(
        response.body,
      );

      if (response.statusCode == 200) {
        final categorias =
            (data['categorias']
                    as List)
                .map(
                  (item) =>
                      Categoria.fromJson(
                    item,
                  ),
                )
                .toList();

        return {
          'success': true,
          'categorias':
              categorias,
        };
      }

      return {
        'success': false,
        'message':
            data['message'] ??
                'No se pudieron cargar las categorías',
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