class ImagenProducto {
  final int id;
  final int? productoId;

  final String url;
  final bool principal;

  final DateTime? fechaCreacion;

  ImagenProducto({
    required this.id,
    this.productoId,
    required this.url,
    required this.principal,
    this.fechaCreacion,
  });

  factory ImagenProducto.fromJson(
    Map<String, dynamic> json,
  ) {
    return ImagenProducto(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(
                json['id'].toString(),
              ) ??
              0,

      productoId:
          json['producto_id'] != null
              ? int.tryParse(
                  json['producto_id']
                      .toString(),
                )
              : null,

      url:
          json['url']?.toString() ?? '',

      principal:
          json['principal'] ?? false,

      fechaCreacion:
          json['fecha_creacion'] != null
              ? DateTime.tryParse(
                  json['fecha_creacion']
                      .toString(),
                )
              : null,
    );
  }
}