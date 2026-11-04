class AdminDashboard {
  final int totalUsuarios;
  final int usuarios;
  final int emprendedores;
  final int administradores;
  final int emprendimientos;
  final int publicaciones;
  final int comentarios;

  const AdminDashboard({
    required this.totalUsuarios,
    required this.usuarios,
    required this.emprendedores,
    required this.administradores,
    required this.emprendimientos,
    required this.publicaciones,
    required this.comentarios,
  });

  factory AdminDashboard.fromJson(
    Map<String, dynamic> json,
  ) {
    return AdminDashboard(
      totalUsuarios:
          _toInt(json['total_usuarios']),
      usuarios:
          _toInt(json['usuarios']),
      emprendedores:
          _toInt(json['emprendedores']),
      administradores:
          _toInt(json['administradores']),
      emprendimientos:
          _toInt(json['emprendimientos']),
      publicaciones:
          _toInt(json['publicaciones']),
      comentarios:
          _toInt(json['comentarios']),
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