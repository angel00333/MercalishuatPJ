class AdminUsuario {
  final int id;
  final String nombre;
  final String correo;
  final int rolId;
  final String rol;
  final bool activo;

  const AdminUsuario({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.rolId,
    required this.rol,
    required this.activo,
  });

  factory AdminUsuario.fromJson(
    Map<String, dynamic> json,
  ) {
    return AdminUsuario(
      id: _toInt(json['id']),
      nombre:
          json['nombre']?.toString() ?? '',
      correo:
          json['correo']?.toString() ?? '',
      rolId:
          _toInt(json['rol_id']),
      rol:
          json['rol']?.toString() ?? '',
      activo:
          json['activo'] == true,
    );
  }

  static int _toInt(
    dynamic value,
  ) {
    if (value is int) {
      return value;
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }
}

class AdminUsuariosRespuesta {
  final List<AdminUsuario> usuarios;
  final int pagina;
  final int limite;
  final int total;
  final int paginas;

  const AdminUsuariosRespuesta({
    required this.usuarios,
    required this.pagina,
    required this.limite,
    required this.total,
    required this.paginas,
  });
}