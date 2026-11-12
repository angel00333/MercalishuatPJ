class Conversacion {
  final int id;

  final int otroUsuarioId;

  // ============================================================
  // PROPIETARIO / USUARIO
  // ============================================================

  final String nombre;

  final String apellido;

  final String? correo;

  final String? imagenUsuarioUrl;

  // ============================================================
  // EMPRENDIMIENTO
  // ============================================================

  final int? emprendimientoId;

  final String? emprendimientoNombre;

  final String? emprendimientoImagenUrl;

  // ============================================================
  // CONVERSACIÓN
  // ============================================================

  final String? ultimoMensaje;

  final DateTime? ultimoMensajeFecha;

  final int mensajesNoLeidos;

  const Conversacion({
    required this.id,
    required this.otroUsuarioId,
    required this.nombre,
    required this.apellido,
    this.correo,
    this.imagenUsuarioUrl,
    this.emprendimientoId,
    this.emprendimientoNombre,
    this.emprendimientoImagenUrl,
    this.ultimoMensaje,
    this.ultimoMensajeFecha,
    required this.mensajesNoLeidos,
  });

  // ============================================================
  // NOMBRE DEL PROPIETARIO
  // ============================================================

  String get nombreCompleto {
    final partes = [
      nombre.trim(),
      apellido.trim(),
    ].where(
      (
        elemento,
      ) =>
          elemento.isNotEmpty,
    ).toList();

    return partes.join(' ');
  }

  // ============================================================
  // TIENE EMPRENDIMIENTO
  // ============================================================

  bool get tieneEmprendimiento {
    return emprendimientoNombre != null &&
        emprendimientoNombre!
            .trim()
            .isNotEmpty;
  }

  // ============================================================
  // TÍTULO DEL CHAT
  // ============================================================

  String get tituloChat {
    if (tieneEmprendimiento) {
      return emprendimientoNombre!.trim();
    }

    if (nombreCompleto.isNotEmpty) {
      return nombreCompleto;
    }

    return 'Conversación';
  }

  // ============================================================
  // SUBTÍTULO
  // ============================================================

  String? get subtituloChat {
    if (!tieneEmprendimiento) {
      return null;
    }

    if (nombreCompleto.isEmpty) {
      return null;
    }

    return nombreCompleto;
  }

  // ============================================================
  // IMAGEN QUE SE MOSTRARÁ
  // ============================================================

  String? get imagenChatUrl {
    final imagenTienda =
        emprendimientoImagenUrl?.trim();

    if (imagenTienda != null &&
        imagenTienda.isNotEmpty) {
      return imagenTienda;
    }

    final imagenUsuario =
        imagenUsuarioUrl?.trim();

    if (imagenUsuario != null &&
        imagenUsuario.isNotEmpty) {
      return imagenUsuario;
    }

    return null;
  }

  // ============================================================
  // FROM JSON
  // ============================================================

  factory Conversacion.fromJson(
    Map<String, dynamic> json,
  ) {
    return Conversacion(
      id:
          _toInt(
            json['id'],
          ) ??
          0,

      otroUsuarioId:
          _toInt(
            json['otro_usuario_id'],
          ) ??
          0,

      nombre:
          json['nombre']
              ?.toString() ??
          '',

      apellido:
          json['apellido']
              ?.toString() ??
          '',

      correo:
          json['correo']
              ?.toString(),

      imagenUsuarioUrl:
          json['imagen_usuario_url']
              ?.toString(),

      // ========================================================
      // EMPRENDIMIENTO
      // ========================================================

      emprendimientoId:
          _toInt(
        json['emprendimiento_id'],
      ),

      emprendimientoNombre:
          json['emprendimiento_nombre']
              ?.toString(),

      emprendimientoImagenUrl:
          json[
                  'emprendimiento_imagen_url']
              ?.toString(),

      // ========================================================
      // MENSAJES
      // ========================================================

      ultimoMensaje:
          json['ultimo_mensaje']
              ?.toString(),

      ultimoMensajeFecha:
          _toDateTime(
        json['ultimo_mensaje_fecha'],
      ),

      mensajesNoLeidos:
          _toInt(
            json['mensajes_no_leidos'],
          ) ??
          0,
    );
  }

  // ============================================================
  // UTILIDADES
  // ============================================================

  static int? _toInt(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    return int.tryParse(
      value.toString(),
    );
  }

  static DateTime? _toDateTime(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }
}