import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'session_service.dart';

class AuthService {
  // =========================================
  // LOGIN
  // =========================================

  static Future<Map<String, dynamic>> login({
    required String correo,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.login),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'correo': correo,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final usuario = data['usuario'];

        await SessionService.guardarSesion(
          token: data['token'],
          nombre: usuario['nombre'] ?? '',
          correo: usuario['correo'] ?? correo,
          rol: usuario['rol'] ?? 'usuario',
        );

        return {
          'success': true,
          'message': 'Inicio de sesión correcto',
          'rol': usuario['rol'],
          'usuario': usuario,
        };
      }

      return {
        'success': false,
        'message':
            data['message'] ??
            'Correo o contraseña incorrectos',
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
  // REGISTRO
  // =========================================

  static Future<Map<String, dynamic>> registro({
    required String nombre,
    required String correo,
    required String password,
    required String rol,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.register),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'nombre': nombre,
          'correo': correo,
          'password': password,
          'rol': rol,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        return {
          'success': true,
          'message':
              data['message'] ??
              'Usuario registrado correctamente',
          'usuario': data['usuario'],
        };
      }

      return {
        'success': false,
        'message':
            data['message'] ??
            'No se pudo registrar el usuario',
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
  // OBTENER PERFIL
  // =========================================

  static Future<Map<String, dynamic>>
      obtenerPerfil() async {
    try {
      final token =
          await SessionService.obtenerToken();

      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': 'Sesión no encontrada',
        };
      }

      final response = await http.get(
        Uri.parse(ApiConfig.profile),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'usuario': data['usuario'],
        };
      }

      return {
        'success': false,
        'message':
            data['message'] ??
            'No se pudo cargar el perfil',
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
  // EDITAR PERFIL
  // =========================================

  static Future<Map<String, dynamic>>
      editarPerfil({
    required String nombre,
    required String correo,
  }) async {
    try {
      final token =
          await SessionService.obtenerToken();

      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': 'Sesión no encontrada',
        };
      }

      final response = await http.put(
        Uri.parse(ApiConfig.profile),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'nombre': nombre,
          'correo': correo,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final usuario = data['usuario'];

        await SessionService.actualizarDatos(
          nombre: usuario['nombre'] ?? nombre,
          correo: usuario['correo'] ?? correo,
        );

        return {
          'success': true,
          'message':
              data['message'] ??
              'Perfil actualizado correctamente',
          'usuario': usuario,
        };
      }

      return {
        'success': false,
        'message':
            data['message'] ??
            'No se pudo actualizar el perfil',
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