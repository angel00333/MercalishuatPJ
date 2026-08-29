class Comentario {
  final int id;
  final int publicacionId;
  final int usuarioId;

  final String texto;

  final String? usuarioNombre;
  final String? usuarioImagen;
  final String? usuarioRol;

  final int? comentarioPadreId;

  final DateTime? fechaCreacion;

  final bool puedeEliminar;

  Comentario({
    required this.id,
    required this.publicacionId,
    required this.usuarioId,
    required this.texto,
    this.usuarioNombre,
    this.usuarioImagen,
    this.usuarioRol,
    this.comentarioPadreId,
    this.fechaCreacion,
    this.puedeEliminar = false,
  });

  factory Comentario.fromJson(
    Map<String, dynamic> json,
  ) {
    return Comentario(
      id: int.parse(
        json['id'].toString(),
      ),

      publicacionId: int.parse(
        json['publicacion_id'].toString(),
      ),

      usuarioId: int.parse(
        json['usuario_id'].toString(),
      ),

      texto:
          json['texto']?.toString() ?? '',

      usuarioNombre:
          json['usuario_nombre']
              ?.toString(),

      usuarioImagen:
          json['usuario_imagen']
              ?.toString(),

      usuarioRol:
          json['usuario_rol']
              ?.toString(),

      comentarioPadreId:
          json['comentario_padre_id'] ==
                  null
              ? null
              : int.tryParse(
                  json['comentario_padre_id']
                      .toString(),
                ),

      fechaCreacion:
          json['fecha_creacion'] ==
                  null
              ? null
              : DateTime.tryParse(
                  json['fecha_creacion']
                      .toString(),
                ),

                puedeEliminar:
          json['puede_eliminar'] == true ||
              json['puede_eliminar']
                      ?.toString()
                      .toLowerCase() ==
                  'true',
    );
  }
}