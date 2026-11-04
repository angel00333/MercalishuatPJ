import 'package:shared_preferences/shared_preferences.dart';
import '../screens/admin/admin_dashboard_screen.dart';

class SessionService {
  static const String _tokenKey = 'token';
  static const String _nombreKey = 'nombre';
  static const String _correoKey = 'correo';
  static const String _rolKey = 'rol';

  // =========================================
  // GUARDAR SESIÓN
  // =========================================

  static Future<void> guardarSesion({
    required String token,
    required String nombre,
    required String correo,
    required String rol,
  }) async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      _tokenKey,
      token,
    );

    await prefs.setString(
      _nombreKey,
      nombre,
    );

    await prefs.setString(
      _correoKey,
      correo,
    );

    await prefs.setString(
      _rolKey,
      rol,
    );
  }

  // =========================================
  // OBTENER TOKEN
  // =========================================

  static Future<String?> obtenerToken() async {
    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getString(
      _tokenKey,
    );
  }

  // =========================================
  // OBTENER NOMBRE
  // =========================================

  static Future<String?> obtenerNombre() async {
    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getString(
      _nombreKey,
    );
  }

  // =========================================
  // OBTENER CORREO
  // =========================================

  static Future<String?> obtenerCorreo() async {
    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getString(
      _correoKey,
    );
  }

  // =========================================
  // OBTENER ROL
  // =========================================

  static Future<String?> obtenerRol() async {
    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getString(
      _rolKey,
    );
  }

  // =========================================
  // COMPROBAR SESIÓN
  // =========================================

  static Future<bool> haySesion() async {
    final token =
        await obtenerToken();

    return token != null &&
        token.isNotEmpty;
  }

  // =========================================
  // ACTUALIZAR DATOS
  // =========================================

  static Future<void> actualizarDatos({
    required String nombre,
    required String correo,
  }) async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      _nombreKey,
      nombre,
    );

    await prefs.setString(
      _correoKey,
      correo,
    );
  }

  // =========================================
  // CERRAR SESIÓN LOCAL
  // =========================================

  static Future<void> cerrarSesion() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove(
      _tokenKey,
    );

    await prefs.remove(
      _nombreKey,
    );

    await prefs.remove(
      _correoKey,
    );

    await prefs.remove(
      _rolKey,
    );
  }
}