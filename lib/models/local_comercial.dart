class ImagenLocalComercial {
  final int id;
  final String url;
  final String? publicId;
  final int orden;
  final bool principal;

  const ImagenLocalComercial({
    required this.id,
    required this.url,
    this.publicId,
    required this.orden,
    required this.principal,
  });

  factory ImagenLocalComercial.fromJson(Map<String, dynamic> json) {
    return ImagenLocalComercial(
      id: _entero(json['id']),
      url: json['url']?.toString() ?? '',
      publicId: json['public_id']?.toString(),
      orden: _entero(json['orden']),
      principal: json['principal'] == true,
    );
  }

  static int _entero(dynamic valor) {
    if (valor is int) return valor;
    return int.tryParse(valor?.toString() ?? '') ?? 0;
  }
}

class LocalComercial {
  final int id;
  final int usuarioId;
  final String titulo;
  final String descripcion;
  final String tipoOperacion;
  final String tipoLocal;
  final double precio;
  final String moneda;
  final String departamento;
  final String municipio;
  final String direccion;
  final double? latitud;
  final double? longitud;
  final String? contactoNombre;
  final String? contactoTelefono;
  final String? contactoWhatsapp;
  final String? contactoCorreo;
  final bool disponible;
  final bool activo;
  final String propietarioNombre;
  final DateTime? fechaCreacion;
  final DateTime? fechaActualizacion;
  final List<ImagenLocalComercial> imagenes;

  const LocalComercial({
    required this.id,
    required this.usuarioId,
    required this.titulo,
    required this.descripcion,
    required this.tipoOperacion,
    required this.tipoLocal,
    required this.precio,
    required this.moneda,
    required this.departamento,
    required this.municipio,
    required this.direccion,
    this.latitud,
    this.longitud,
    this.contactoNombre,
    this.contactoTelefono,
    this.contactoWhatsapp,
    this.contactoCorreo,
    required this.disponible,
    required this.activo,
    required this.propietarioNombre,
    this.fechaCreacion,
    this.fechaActualizacion,
    required this.imagenes,
  });

  factory LocalComercial.fromJson(Map<String, dynamic> json) {
    final lista = <ImagenLocalComercial>[];
    final imagenesJson = json['imagenes'];

    if (imagenesJson is List) {
      for (final item in imagenesJson) {
        if (item is Map) {
          lista.add(
            ImagenLocalComercial.fromJson(
              Map<String, dynamic>.from(item),
            ),
          );
        }
      }
    }

    lista.sort((a, b) {
      if (a.principal && !b.principal) return -1;
      if (!a.principal && b.principal) return 1;
      return a.orden.compareTo(b.orden);
    });

    return LocalComercial(
      id: _entero(json['id']),
      usuarioId: _entero(json['usuario_id']),
      titulo: json['titulo']?.toString() ?? '',
      descripcion: json['descripcion']?.toString() ?? '',
      tipoOperacion: json['tipo_operacion']?.toString() ?? '',
      tipoLocal: json['tipo_local']?.toString() ?? '',
      precio: _decimal(json['precio']),
      moneda: json['moneda']?.toString() ?? 'USD',
      departamento: json['departamento']?.toString() ?? '',
      municipio: json['municipio']?.toString() ?? '',
      direccion: json['direccion']?.toString() ?? '',
      latitud: _decimalNullable(json['latitud']),
      longitud: _decimalNullable(json['longitud']),
      contactoNombre: _textoNullable(json['contacto_nombre']),
      contactoTelefono: _textoNullable(json['contacto_telefono']),
      contactoWhatsapp: _textoNullable(json['contacto_whatsapp']),
      contactoCorreo: _textoNullable(json['contacto_correo']),
      disponible: json['disponible'] == true,
      activo: json['activo'] == true,
      propietarioNombre: json['propietario_nombre']?.toString() ?? '',
      fechaCreacion: _fecha(json['fecha_creacion']),
      fechaActualizacion: _fecha(json['fecha_actualizacion']),
      imagenes: lista,
    );
  }

  ImagenLocalComercial? get imagenPrincipal {
    if (imagenes.isEmpty) return null;
    for (final imagen in imagenes) {
      if (imagen.principal) return imagen;
    }
    return imagenes.first;
  }

  String get operacionTexto =>
      tipoOperacion == 'alquiler' ? 'Alquiler' : 'Venta';

  String get precioTexto {
    final valor = precio.toStringAsFixed(2);
    return tipoOperacion == 'alquiler' ? '\$$valor / mes' : '\$$valor';
  }

  String get ubicacionTexto {
    if (municipio.trim().isEmpty) return departamento;
    return '$municipio, $departamento';
  }

  static int _entero(dynamic valor) {
    if (valor is int) return valor;
    return int.tryParse(valor?.toString() ?? '') ?? 0;
  }

  static double _decimal(dynamic valor) {
    if (valor is num) return valor.toDouble();
    return double.tryParse(valor?.toString() ?? '') ?? 0;
  }

  static double? _decimalNullable(dynamic valor) {
    if (valor == null || valor.toString().trim().isEmpty) return null;
    if (valor is num) return valor.toDouble();
    return double.tryParse(valor.toString());
  }

  static String? _textoNullable(dynamic valor) {
    if (valor == null) return null;
    final texto = valor.toString().trim();
    return texto.isEmpty ? null : texto;
  }

  static DateTime? _fecha(dynamic valor) {
    if (valor == null) return null;
    return DateTime.tryParse(valor.toString());
  }
}

class LocalesComercialesResultado {
  final List<LocalComercial> locales;
  final int pagina;
  final int limite;
  final int total;
  final int paginas;

  const LocalesComercialesResultado({
    required this.locales,
    required this.pagina,
    required this.limite,
    required this.total,
    required this.paginas,
  });
}
