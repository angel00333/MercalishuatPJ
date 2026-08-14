import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const String _tokenKey = 'token';
  static const String _rolKey = 'rol';
  static const String _usuarioIdKey = 'usuario_id';
  static const String _nombreKey = 'nombre';
  static const String _correoKey = 'correo';

  static Future<void> guardarSesion({
    required String token,
    required int usuarioId  ,
    required String nombre,
    required String correo,
    required String rol,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_tokenKey, token);
    await prefs.setInt(_usuarioIdKey, usuarioId);
    await prefs.setString(_nombreKey, nombre);
    await prefs.setString(_correoKey, correo);
    await prefs.setString(_rolKey, rol);
  }

  static Future<String?> obtenerToken() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_tokenKey);
  }

  static Future<String?> obtenerRol() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_rolKey);
  }

  static Future<int?> obtenerUsuarioId() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getInt(_usuarioIdKey);
  }

  static Future<String?> obtenerNombre() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_nombreKey);
  }

  static Future<String?> obtenerCorreo() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_correoKey);
  }

  static Future<bool> existeSesion() async {
    final token = await obtenerToken();

    return token != null && token.isNotEmpty;
  }

  static Future<void> cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_tokenKey);
    await prefs.remove(_usuarioIdKey);
    await prefs.remove(_nombreKey);
    await prefs.remove(_correoKey);
    await prefs.remove(_rolKey);
  }
}