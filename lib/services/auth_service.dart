import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'session_service.dart';

class AuthService {
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
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Correo o contraseña incorrectos',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'No se pudo conectar con el servidor',
      };
    }
  }

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
          'message': data['message'] ?? 'Usuario registrado correctamente',
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'No se pudo registrar el usuario',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'No se pudo conectar con el servidor',
      };
    }
  }
}