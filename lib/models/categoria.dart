class Categoria {
  final int id;
  final String nombre;
  final bool activo;

  Categoria({
    required this.id,
    required this.nombre,
    this.activo = true,
  });

  factory Categoria.fromJson(
    Map<String, dynamic> json,
  ) {
    return Categoria(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(
                json['id'].toString(),
              ) ??
              0,

      nombre:
          json['nombre']?.toString() ?? '',

      activo:
          json['activo'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'activo': activo,
    };
  }
}