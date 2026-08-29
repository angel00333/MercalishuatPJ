class ApiConfig {
  static const String baseUrl =
      'https://mercalishuatbackend-production.up.railway.app/api';

  // =========================
  // AUTENTICACIÓN
  // =========================

  static const String login =
      '$baseUrl/auth/login';

  static const String register =
      '$baseUrl/auth/register';

  static const String profile =
      '$baseUrl/auth/profile';

  // =========================
  // EMPRENDIMIENTOS
  // =========================

  static const String emprendimientos =
      '$baseUrl/emprendimientos';

  static const String miTienda =
      '$baseUrl/emprendimientos/mi-tienda';

  static String emprendimientoDetalle(int id) {
    return '$baseUrl/emprendimientos/detalle/$id';
  }

  // =========================
  // CATEGORÍAS
  // =========================

  static const String categorias =
      '$baseUrl/categorias';

  // =========================
  // PRODUCTOS
  // =========================

  static const String productos =
      '$baseUrl/productos';

  static const String misProductos =
      '$baseUrl/productos/mis-productos';

  static String productoDetalle(int id) {
    return '$baseUrl/productos/detalle/$id';
  }

  static String productosEmprendimiento(
    int emprendimientoId,
  ) {
    return '$baseUrl/productos/emprendimiento/$emprendimientoId';
  }

  static String producto(int id) {
    return '$baseUrl/productos/$id';
  }

  // =========================
  // IMÁGENES
  // =========================

  static String imagenesProducto(int productoId) {
    return '$baseUrl/imagenes/producto/$productoId';
  }
  static const String fotoPerfil =
      '$baseUrl/perfil/foto';

  static const String imagenEmprendimiento =
      '$baseUrl/emprendimientos/imagen';


  static String imagenPrincipal({
    required int productoId,
    required int imagenId,
  }) {
    return '$baseUrl/imagenes/producto/$productoId/principal/$imagenId';
  }

  static String eliminarImagen({
    required int productoId,
    required int imagenId,
  }) {
    return '$baseUrl/imagenes/producto/$productoId/$imagenId';
  }

  // =========================
  // PUBLICACIONES
  // =========================
static const String publicaciones =
    '$baseUrl/publicaciones';

static const String feed =
    '$publicaciones/feed';

static const String misPublicaciones =
    '$publicaciones/mis-publicaciones';

static const String guardados =
    '$publicaciones/guardados';

static String publicacion(
  int id,
) =>
    '$publicaciones/$id';

static String imagenesPublicacion(
  int id,
) =>
    '$publicaciones/$id/imagenes';

static String meGusta(
  int id,
) =>
    '$publicaciones/$id/me-gusta';

static String guardarPublicacion(
  int id,
) =>
    '$publicaciones/$id/guardar';

static String comentarios(
  int id,
) =>
    '$publicaciones/$id/comentarios';

static String eliminarComentario(
  int comentarioId,
) =>
    '$publicaciones/comentarios/$comentarioId';

static String responderComentario(
  int comentarioId,
) =>
    '$publicaciones/comentarios/$comentarioId/responder';
}

  