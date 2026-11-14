class Notificacion {
  final int id;
  final int usuarioId;
  final String tipo;
  final String titulo;
  final String mensaje;
  final int? referenciaId;
  final String? referenciaTipo;
  final bool leida;
  final DateTime? createdAt;

  const Notificacion({
    required this.id,
    required this.usuarioId,
    required this.tipo,
    required this.titulo,
    required this.mensaje,
    required this.referenciaId,
    required this.referenciaTipo,
    required this.leida,
    required this.createdAt,
  });

  String get tipoNormalizado =>
      tipo
          .trim()
          .toLowerCase();

  String get referenciaTipoNormalizado =>
      referenciaTipo
          ?.trim()
          .toLowerCase() ??
      '';

  bool get esMensaje =>
      tipoNormalizado ==
      'mensaje';

  bool get esNuevoEmprendimiento =>
      tipoNormalizado ==
      'nuevo_emprendimiento';

  bool get esNuevaPublicacion =>
      tipoNormalizado ==
      'nueva_publicacion';

  bool get esNuevoProducto =>
      tipoNormalizado ==
      'nuevo_producto';

  bool get tieneDestino =>
      referenciaId != null &&
      referenciaId! > 0 &&
      referenciaTipoNormalizado
          .isNotEmpty;

  factory Notificacion.fromJson(
    Map<String, dynamic> json,
  ) {
    return Notificacion(
      id:
          _toInt(
            json['id'],
          ) ??
          0,

      usuarioId:
          _toInt(
            json['usuario_id'],
          ) ??
          0,

      tipo:
          json['tipo']
                  ?.toString() ??
              '',

      titulo:
          json['titulo']
                  ?.toString() ??
              '',

      mensaje:
          json['mensaje']
                  ?.toString() ??
              '',

      referenciaId:
          _toInt(
            json['referencia_id'],
          ),

      referenciaTipo:
          json['referencia_tipo']
              ?.toString(),

      leida:
          _toBool(
            json['leida'],
          ),

      createdAt:
          _toDateTime(
            json['created_at'],
          ),
    );
  }

  Notificacion copyWith({
    bool? leida,
  }) {
    return Notificacion(
      id:
          id,

      usuarioId:
          usuarioId,

      tipo:
          tipo,

      titulo:
          titulo,

      mensaje:
          mensaje,

      referenciaId:
          referenciaId,

      referenciaTipo:
          referenciaTipo,

      leida:
          leida ??
          this.leida,

      createdAt:
          createdAt,
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

  static bool _toBool(
    dynamic value,
  ) {
    if (value is bool) {
      return value;
    }

    if (value is int) {
      return value == 1;
    }

    final texto =
        value
            ?.toString()
            .toLowerCase();

    return texto ==
            'true' ||
        texto ==
            '1';
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