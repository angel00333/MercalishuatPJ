import 'dart:convert';
import 'dart:io';

const String libertyUrl =
    'https://tiles.openfreemap.org/styles/liberty';

Future<void> main() async {
  final client = HttpClient();

  try {
    print('Descargando estilo Liberty...');

    final request =
        await client.getUrl(
      Uri.parse(libertyUrl),
    );

    request.headers.set(
      HttpHeaders.userAgentHeader,
      'Mercalishuat Map Style Generator',
    );

    final response =
        await request.close();

    if (response.statusCode != 200) {
      throw Exception(
        'OpenFreeMap respondió ${response.statusCode}',
      );
    }

    final contenido =
        await response
            .transform(
              utf8.decoder,
            )
            .join();

    final Map<String, dynamic> original =
        jsonDecode(contenido);

    final claro =
        _crearEstilo(
      original,
      oscuro: false,
    );

    final oscuro =
        _crearEstilo(
      original,
      oscuro: true,
    );

    final directorio =
        Directory(
      'assets/mapas',
    );

    if (!directorio.existsSync()) {
      directorio.createSync(
        recursive: true,
      );
    }

    final archivoClaro =
        File(
      'assets/mapas/openfreemap_mercali_light.json',
    );

    final archivoOscuro =
        File(
      'assets/mapas/openfreemap_mercali_dark.json',
    );

    const encoder =
        JsonEncoder.withIndent(
      '  ',
    );

    await archivoClaro.writeAsString(
      encoder.convert(claro),
    );

    await archivoOscuro.writeAsString(
      encoder.convert(oscuro),
    );

    print('');
    print('ESTILOS GENERADOS CORRECTAMENTE');
    print('');
    print(
      'assets/mapas/openfreemap_mercali_light.json',
    );
    print(
      'assets/mapas/openfreemap_mercali_dark.json',
    );
  } finally {
    client.close();
  }
}

Map<String, dynamic> _crearEstilo(
  Map<String, dynamic> original, {
  required bool oscuro,
}) {
  final estilo =
      jsonDecode(
    jsonEncode(original),
  ) as Map<String, dynamic>;

  estilo['name'] =
      oscuro
          ? 'Mercalishuat Orange Dark'
          : 'Mercalishuat Orange Light';

  final List<dynamic> layers =
      estilo['layers'] ?? [];

  // ============================================================
  // PALETA CLARA
  // ============================================================

  final String fondo =
      oscuro
          ? '#171320'
          : '#FFF6ED';

  final String tierra =
      oscuro
          ? '#241B18'
          : '#FFEBD8';

  final String tierraSecundaria =
      oscuro
          ? '#30221A'
          : '#FFE1C4';

  final String agua =
      oscuro
          ? '#211A19'
          : '#F4D1B1';

  final String aguaLinea =
      oscuro
          ? '#5A3520'
          : '#E5A66E';

  final String parque =
      oscuro
          ? '#34271D'
          : '#F7D8A8';

  final String bosque =
      oscuro
          ? '#3A2A1C'
          : '#F2CE95';

  final String edificio =
      oscuro
          ? '#4B3425'
          : '#EDC49A';

  final String carreteraPrincipal =
      oscuro
          ? '#FF7E01'
          : '#F97800';

  final String carreteraSecundaria =
      oscuro
          ? '#D86512'
          : '#FF9B42';

  final String carreteraLocal =
      oscuro
          ? '#744326'
          : '#F6B87C';

  final String bordeCarretera =
      oscuro
          ? '#351F17'
          : '#D97928';

  final String limites =
      oscuro
          ? '#E36D18'
          : '#D96100';

  final String texto =
      oscuro
          ? '#FFE9D6'
          : '#512A12';

  final String textoSecundario =
      oscuro
          ? '#D8BBA5'
          : '#795037';

  final String haloTexto =
      oscuro
          ? '#171320'
          : '#FFF4E8';

  final String poi =
      oscuro
          ? '#FF9A3D'
          : '#D95F00';

  for (final dynamic rawLayer
      in layers) {
    if (rawLayer
        is! Map<String, dynamic>) {
      continue;
    }

    final layer =
        rawLayer;

    final String id =
        layer['id']
                ?.toString()
                .toLowerCase() ??
            '';

    final String type =
        layer['type']
                ?.toString()
                .toLowerCase() ??
            '';

    final String sourceLayer =
        layer['source-layer']
                ?.toString()
                .toLowerCase() ??
            '';

    final String identificador =
        '$id $sourceLayer';

    final paint =
        Map<String, dynamic>.from(
      layer['paint'] ?? {},
    );

    // ==========================================================
    // BACKGROUND
    // ==========================================================

    if (type == 'background') {
      paint['background-color'] =
          fondo;

      layer['paint'] =
          paint;

      continue;
    }

    // ==========================================================
    // FILL
    // ==========================================================

    if (type == 'fill') {
      if (_contiene(
        identificador,
        [
          'water',
          'ocean',
          'lake',
          'river',
        ],
      )) {
        paint['fill-color'] =
            agua;

        paint['fill-outline-color'] =
            aguaLinea;
      } else if (_contiene(
        identificador,
        [
          'park',
          'garden',
          'grass',
          'recreation',
          'playground',
        ],
      )) {
        paint['fill-color'] =
            parque;
      } else if (_contiene(
        identificador,
        [
          'forest',
          'wood',
          'vegetation',
          'landcover',
        ],
      )) {
        paint['fill-color'] =
            bosque;
      } else if (_contiene(
        identificador,
        [
          'building',
        ],
      )) {
        paint['fill-color'] =
            edificio;

        paint['fill-outline-color'] =
            oscuro
                ? '#65452F'
                : '#DFA972';
      } else if (_contiene(
        identificador,
        [
          'landuse',
          'residential',
          'industrial',
          'commercial',
          'pedestrian',
        ],
      )) {
        paint['fill-color'] =
            tierraSecundaria;
      } else {
        paint['fill-color'] =
            tierra;
      }

      // Conservamos opacidades existentes cuando
      // Liberty usa expresiones.
      if (paint['fill-opacity']
          is num) {
        final opacity =
            (paint['fill-opacity']
                    as num)
                .toDouble();

        paint['fill-opacity'] =
            opacity.clamp(
          0.15,
          1.0,
        );
      }

      layer['paint'] =
          paint;

      continue;
    }

    // ==========================================================
    // LINE
    // ==========================================================

    if (type == 'line') {
      if (_contiene(
        identificador,
        [
          'waterway',
          'river',
          'stream',
          'canal',
        ],
      )) {
        paint['line-color'] =
            aguaLinea;
      } else if (_contiene(
        identificador,
        [
          'boundary',
          'admin',
          'border',
        ],
      )) {
        paint['line-color'] =
            limites;
      } else if (_contiene(
        identificador,
        [
          'motorway',
          'trunk',
          'primary',
        ],
      )) {
        paint['line-color'] =
            id.contains('casing')
                ? bordeCarretera
                : carreteraPrincipal;
      } else if (_contiene(
        identificador,
        [
          'secondary',
          'tertiary',
        ],
      )) {
        paint['line-color'] =
            id.contains('casing')
                ? bordeCarretera
                : carreteraSecundaria;
      } else if (_contiene(
        identificador,
        [
          'road',
          'street',
          'transportation',
          'path',
          'track',
          'service',
          'living',
        ],
      )) {
        paint['line-color'] =
            id.contains('casing')
                ? bordeCarretera
                : carreteraLocal;
      } else {
        paint['line-color'] =
            oscuro
                ? '#704A32'
                : '#DFA56F';
      }

      layer['paint'] =
          paint;

      continue;
    }

    // ==========================================================
    // SYMBOL
    //
    // Aquí conservamos text-field, icon-image, filtros,
    // fuentes, tamaños, etc.
    //
    // Por eso siguen apareciendo:
    // comunidades, tiendas, parques, escuelas,
    // restaurantes, iglesias, calles, ciudades...
    // ==========================================================

    if (type == 'symbol') {
      if (_contiene(
        identificador,
        [
          'poi',
          'shop',
          'amenity',
          'restaurant',
          'park',
        ],
      )) {
        paint['text-color'] =
            poi;
      } else if (_contiene(
        identificador,
        [
          'road',
          'street',
          'transportation',
        ],
      )) {
        paint['text-color'] =
            textoSecundario;
      } else {
        paint['text-color'] =
            texto;
      }

      paint['text-halo-color'] =
          haloTexto;

      paint['text-halo-width'] =
          1.2;

      paint['text-halo-blur'] =
          0.3;

      layer['paint'] =
          paint;

      continue;
    }

    // ==========================================================
    // FILL EXTRUSION
    // ==========================================================

    if (type ==
        'fill-extrusion') {
      paint['fill-extrusion-color'] =
          edificio;

      layer['paint'] =
          paint;

      continue;
    }

    // ==========================================================
    // CIRCLE
    // ==========================================================

    if (type == 'circle') {
      paint['circle-color'] =
          poi;

      paint['circle-stroke-color'] =
          haloTexto;

      layer['paint'] =
          paint;

      continue;
    }

    // ==========================================================
    // HILLSHADE
    // ==========================================================

    if (type == 'hillshade') {
      paint['hillshade-highlight-color'] =
          oscuro
              ? '#704524'
              : '#FFD6AB';

      paint['hillshade-shadow-color'] =
          oscuro
              ? '#100C0A'
              : '#AD5D27';

      paint['hillshade-accent-color'] =
          '#FF7E01';

      layer['paint'] =
          paint;

      continue;
    }
  }

  return estilo;
}

bool _contiene(
  String texto,
  List<String> palabras,
) {
  for (final palabra
      in palabras) {
    if (texto.contains(
      palabra,
    )) {
      return true;
    }
  }

  return false;
}