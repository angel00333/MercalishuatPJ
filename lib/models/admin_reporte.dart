class AdminReporte {
  final int id;

  final int reportanteId;
  final String reportanteNombre;
  final String reportanteCorreo;

  final int? publicacionId;
  final int? comentarioId;

  final String tipo;

  final String motivo;
  final String? descripcion;

  final String estado;
  final String? accion;

  final DateTime? fechaCreacion;
  final DateTime? fechaResolucion;

  final int? resueltoPor;
  final String? administradorNombre;

  final String? publicacionTexto;
  final bool? publicacionActiva;

  final String? comentarioTexto;
  final bool? comentarioActivo;

  final int? comentarioAutorId;
  final String? comentarioAutorNombre;

  final int? publicacionAutorId;
  final String? publicacionAutorNombre;

  const AdminReporte({
    required this.id,
    required this.reportanteId,
    required this.reportanteNombre,
    required this.reportanteCorreo,
    required this.publicacionId,
    required this.comentarioId,
    required this.tipo,
    required this.motivo,
    required this.descripcion,
    required this.estado,
    required this.accion,
    required this.fechaCreacion,
    required this.fechaResolucion,
    required this.resueltoPor,
    required this.administradorNombre,
    required this.publicacionTexto,
    required this.publicacionActiva,
    required this.comentarioTexto,
    required this.comentarioActivo,
    required this.comentarioAutorId,
    required this.comentarioAutorNombre,
    required this.publicacionAutorId,
    required this.publicacionAutorNombre,
  });

  factory AdminReporte.fromJson(
    Map<String, dynamic> json,
  ) {
    return AdminReporte(
      id: _toInt(
        json['id'],
      ),
      reportanteId: _toInt(
        json['reportante_id'],
      ),
      reportanteNombre:
          json['reportante_nombre']
                  ?.toString() ??
              '',
      reportanteCorreo:
          json['reportante_correo']
                  ?.toString() ??
              '',
      publicacionId: _toNullableInt(
        json['publicacion_id'],
      ),
      comentarioId: _toNullableInt(
        json['comentario_id'],
      ),
      tipo:
          json['tipo']?.toString() ?? '',
      motivo:
          json['motivo']?.toString() ?? '',
      descripcion:
          json['descripcion']?.toString(),
      estado:
          json['estado']?.toString() ??
              'pendiente',
      accion:
          json['accion']?.toString(),
      fechaCreacion: _toDateTime(
        json['fecha_creacion'],
      ),
      fechaResolucion: _toDateTime(
        json['fecha_resolucion'],
      ),
      resueltoPor: _toNullableInt(
        json['resuelto_por'],
      ),
      administradorNombre:
          json['administrador_nombre']
              ?.toString(),
      publicacionTexto:
          json['publicacion_texto']
              ?.toString(),
      publicacionActiva: _toNullableBool(
        json['publicacion_activa'],
      ),
      comentarioTexto:
          json['comentario_texto']
              ?.toString(),
      comentarioActivo: _toNullableBool(
        json['comentario_activo'],
      ),
      comentarioAutorId:
          _toNullableInt(
        json['comentario_autor_id'],
      ),
      comentarioAutorNombre:
          json['comentario_autor_nombre']
              ?.toString(),
      publicacionAutorId:
          _toNullableInt(
        json['publicacion_autor_id'],
      ),
      publicacionAutorNombre:
          json['publicacion_autor_nombre']
              ?.toString(),
    );
  }

  String get contenido {
    if (tipo == 'comentario') {
      return comentarioTexto?.trim().isNotEmpty ==
              true
          ? comentarioTexto!
          : 'Comentario no disponible';
    }

    return publicacionTexto?.trim().isNotEmpty ==
            true
        ? publicacionTexto!
        : 'Publicación no disponible';
  }

  String get autorContenido {
    if (tipo == 'comentario') {
      return comentarioAutorNombre ??
          'Usuario desconocido';
    }

    return publicacionAutorNombre ??
        'Usuario desconocido';
  }

  bool? get contenidoActivo {
    if (tipo == 'comentario') {
      return comentarioActivo;
    }

    return publicacionActiva;
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

  static int? _toNullableInt(
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

  static bool? _toNullableBool(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is bool) {
      return value;
    }

    final texto =
        value.toString().toLowerCase();

    if (texto == 'true') {
      return true;
    }

    if (texto == 'false') {
      return false;
    }

    return null;
  }

  static DateTime? _toDateTime(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }
}

class AdminReportesRespuesta {
  final List<AdminReporte> reportes;

  final int pagina;
  final int limite;
  final int total;
  final int paginas;

  const AdminReportesRespuesta({
    required this.reportes,
    required this.pagina,
    required this.limite,
    required this.total,
    required this.paginas,
  });
}