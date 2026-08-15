class Usuario {
  final int? id;
  final String nombre;
  final String correo;
  final String rol;
  final String? token;

  Usuario({
    this.id,
    required this.nombre,
    required this.correo,
    required this.rol,
    this.token,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'],
      nombre: json['nombre'] ?? '',
      correo: json['correo'] ?? '',
      rol: json['rol'] ?? 'usuario',
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'correo': correo,
      'rol': rol,
      'token': token,
    };
  }
}