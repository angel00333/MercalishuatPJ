class Publicacion {
  final int id;

  final int emprendimientoId;

  final int? productoId;

  final String texto;

  final String? emprendimientoNombre;

  final String? emprendimientoImagen;

  final String? productoNombre;

  final double? productoPrecio;

  final String? imagenPrincipal;

  int totalMeGusta;

  int totalComentarios;

  bool meGusta;

  bool guardado;

  final DateTime? fechaCreacion;

  Publicacion({
    required this.id,
    required this.emprendimientoId,
    required this.texto,

    this.productoId,

    this.emprendimientoNombre,
    this.emprendimientoImagen,

    this.productoNombre,
    this.productoPrecio,

    this.imagenPrincipal,

    this.totalMeGusta = 0,
    this.totalComentarios = 0,

    this.meGusta = false,
    this.guardado = false,

    this.fechaCreacion,
  });

  factory Publicacion.fromJson(
    Map<String, dynamic> json,
  ) {
    double? precio;

    if (
      json['producto_precio'] !=
          null
    ) {
      precio = double.tryParse(
        json['producto_precio']
            .toString(),
      );
    }

    return Publicacion(
      id:
          int.parse(
        json['id'].toString(),
      ),

      emprendimientoId:
          int.parse(
        json['emprendimiento_id']
            .toString(),
      ),

      productoId:
          json['producto_id'] ==
                  null
              ? null
              : int.tryParse(
                  json['producto_id']
                      .toString(),
                ),

      texto:
          json['texto'] ?? '',

      emprendimientoNombre:
          json[
              'emprendimiento_nombre'],

      emprendimientoImagen:
          json[
              'emprendimiento_imagen'],

      productoNombre:
          json['producto_nombre'],

      productoPrecio:
          precio,

      imagenPrincipal:
          json['imagen_principal'],

      totalMeGusta:
          int.tryParse(
            json['total_me_gusta']
                    ?.toString() ??
                '0',
          ) ??
          0,

      totalComentarios:
          int.tryParse(
            json['total_comentarios']
                    ?.toString() ??
                '0',
          ) ??
          0,

      meGusta:
          json['me_gusta'] == true,

      guardado:
          json['guardado'] == true,

      fechaCreacion:
          json['fecha_creacion'] ==
                  null
              ? null
              : DateTime.tryParse(
                  json[
                          'fecha_creacion']
                      .toString(),
                ),
    );
  }
}