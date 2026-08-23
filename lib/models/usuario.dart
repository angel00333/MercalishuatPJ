class Usuario {
  final int? id;
  final String nombre;
  final String correo;
  final String rol;
  final String? token;
  final String? fotoPerfilUrl;

  Usuario({
    this.id,
    required this.nombre,
    required this.correo,
    required this.rol,
    this.token,
    this.fotoPerfilUrl,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'],
      nombre: json['nombre'] ?? '',
      fotoPerfilUrl: json['foto_perfil_url'] ?.toString(),
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