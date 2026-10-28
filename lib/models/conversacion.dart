class Conversacion {
  final int id;

  final int otroUsuarioId;

  final String nombre;

  final String apellido;

  final String? correo;

  final String? imagenUsuarioUrl;

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
    this.ultimoMensaje,
    this.ultimoMensajeFecha,
    required this.mensajesNoLeidos,
  });

  String get nombreCompleto {
    final partes = [
      nombre.trim(),
      apellido.trim(),
    ].where(
      (e) => e.isNotEmpty,
    ).toList();

    return partes.join(' ');
  }

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

      ultimoMensaje:
          json['ultimo_mensaje']
              ?.toString(),

      ultimoMensajeFecha:
          _toDateTime(
            json[
                'ultimo_mensaje_fecha'],
          ),

      mensajesNoLeidos:
          _toInt(
            json[
                'mensajes_no_leidos'],
          ) ??
          0,
    );
  }

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