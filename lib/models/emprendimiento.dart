class Emprendimiento {
  final int id;
  final int? usuarioId;

  final String nombre;
  final String? descripcion;
  final String? telefono;
  final String? correoContacto;
  final String? imagenUrl;

  final bool activo;

  final String? propietario;
  final DateTime? fechaCreacion;

  Emprendimiento({
    required this.id,
    this.usuarioId,
    required this.nombre,
    this.descripcion,
    this.imagenUrl,
    this.telefono,
    this.correoContacto,
    this.activo = true,
    this.propietario,
    this.fechaCreacion,
  });

  factory Emprendimiento.fromJson(
    Map<String, dynamic> json,
  ) {
    return Emprendimiento(
      id: _toInt(json['id']) ?? 0,

      usuarioId:
          _toInt(json['usuario_id']),

      nombre:
          json['nombre']?.toString() ?? '',

      descripcion:
          json['descripcion']?.toString(),
          
      imagenUrl:
          json['imagen_url']?.toString(),

      telefono:
          json['telefono']?.toString(),

      correoContacto:
          json['correo_contacto']?.toString(),

      activo:
          json['activo'] ?? true,

      propietario:
          json['propietario']?.toString(),

      fechaCreacion:
          json['fecha_creacion'] != null
              ? DateTime.tryParse(
                  json['fecha_creacion']
                      .toString(),
                )
              : null,
    );
  }

  static int? _toInt(dynamic valor) {
    if (valor == null) {
      return null;
    }

    if (valor is int) {
      return valor;
    }

    return int.tryParse(
      valor.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'nombre': nombre,
      'descripcion': descripcion,
      'telefono': telefono,
      'correo_contacto':
          correoContacto,
      'activo': activo,
      'propietario': propietario,
      'fecha_creacion':
          fechaCreacion?.toIso8601String(),
    };
  }
}