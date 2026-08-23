import 'imagen_producto.dart';

class Producto {
  final int id;

  final int? emprendimientoId;
  final int categoriaId;

  final String nombre;
  final String? descripcion;

  final double precio;

  final bool disponible;

  final String? categoria;
  final String? emprendimiento;

  final String? imagenPrincipal;

  final DateTime? fechaCreacion;
  final DateTime? fechaActualizacion;

  final List<ImagenProducto> imagenes;

  Producto({
    required this.id,
    this.emprendimientoId,
    required this.categoriaId,
    required this.nombre,
    this.descripcion,
    required this.precio,
    this.disponible = true,
    this.categoria,
    this.emprendimiento,
    this.imagenPrincipal,
    this.fechaCreacion,
    this.fechaActualizacion,
    this.imagenes = const [],
  });

  factory Producto.fromJson(
    Map<String, dynamic> json,
  ) {
    final imagenesJson =
        json['imagenes'];

    List<ImagenProducto> listaImagenes =
        [];

    if (imagenesJson is List) {
      listaImagenes = imagenesJson
          .map(
            (imagen) =>
                ImagenProducto.fromJson(
              Map<String, dynamic>.from(
                imagen,
              ),
            ),
          )
          .toList();
    }

    return Producto(
      id: _toInt(json['id']) ?? 0,

      emprendimientoId:
          _toInt(
        json['emprendimiento_id'],
      ),

      categoriaId:
          _toInt(
            json['categoria_id'],
          ) ??
          0,

      nombre:
          json['nombre']?.toString() ?? '',

      descripcion:
          json['descripcion']?.toString(),

      precio:
          _toDouble(
            json['precio'],
          ) ??
          0,

      disponible:
          json['disponible'] ?? true,

      categoria:
          json['categoria']?.toString(),

      emprendimiento:
          json['emprendimiento']
              ?.toString(),

      imagenPrincipal:
          json['imagen_principal']
              ?.toString(),

      fechaCreacion:
          json['fecha_creacion'] != null
              ? DateTime.tryParse(
                  json['fecha_creacion']
                      .toString(),
                )
              : null,

      fechaActualizacion:
          json['fecha_actualizacion'] !=
                  null
              ? DateTime.tryParse(
                  json['fecha_actualizacion']
                      .toString(),
                )
              : null,

      imagenes: listaImagenes,
    );
  }

  static int? _toInt(dynamic valor) {
    if (valor == null) {
      return null;
    }

    if (valor is int) {
      return valor;
    }

    return int.tryParse(
      valor.toString(),
    );
  }

  static double? _toDouble(
    dynamic valor,
  ) {
    if (valor == null) {
      return null;
    }

    if (valor is double) {
      return valor;
    }

    if (valor is int) {
      return valor.toDouble();
    }

    return double.tryParse(
      valor.toString(),
    );
  }
}