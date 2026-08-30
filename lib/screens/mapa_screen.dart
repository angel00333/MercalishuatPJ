import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapaScreen extends StatefulWidget {
  const MapaScreen({
    super.key,
  });

  @override
  State<MapaScreen> createState() =>
      _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  // ============================================
  // CONTROLADOR DEL MAPA
  // ============================================

  final MapController mapController =
      MapController();

  // ============================================
  // CENTRO DE EL SALVADOR
  // ============================================

  static const LatLng centroElSalvador =
      LatLng(
    13.7942,
    -88.8965,
  );

  // ============================================
  // PALETA MERCALISHUAT
  // ============================================

  static const Color naranjaPrincipal =
      Color(0xFFFF7E01);

  static const Color naranjaOscuro =
      Color(0xFFE86600);

  static const Color naranjaMedio =
      Color(0xFFFF9A3D);

  static const Color naranjaClaro =
      Color(0xFFFFC078);

  static const Color moradoOscuro =
      Color(0xFF2A2045);

  static const Color fondoOscuro =
      Color(0xFF171320);

  static const Color fondoClaro =
      Color(0xFFF7F7F7);

  // ============================================
  // POLÍGONOS ADMINISTRATIVOS
  // ============================================

  List<Polygon> admin0Poligonos = [];
  List<Polygon> admin1Poligonos = [];
  List<Polygon> admin2Poligonos = [];

  // ADM3 queda preparado para el futuro.
  List<Polygon> admin3Poligonos = [];

  // ============================================
  // ETIQUETAS
  // ============================================

  final List<_EtiquetaMapa>
      admin1Etiquetas = [];

  final List<_EtiquetaMapa>
      admin2Etiquetas = [];

  final List<_EtiquetaMapa>
      admin3Etiquetas = [];

  // ============================================
  // ESTADO
  // ============================================

  bool cargando = true;

  String? error;

  double zoomActual = 8.0;

  @override
  void initState() {
    super.initState();

    cargarGeoJson();
  }

  // ============================================
  // CARGAR GEOJSON
  // ============================================

  Future<void> cargarGeoJson() async {
    try {
      final admin0Texto =
          await rootBundle.loadString(
        'assets/mapas/SV-Map-ADM0.geojson',
      );

      final admin1Texto =
          await rootBundle.loadString(
        'assets/mapas/SV-Map-ADM1.geojson',
      );

      final admin2Texto =
          await rootBundle.loadString(
        'assets/mapas/SV-Map-ADM2.geojson',
      );

      final Map<String, dynamic> admin0 =
          jsonDecode(
        admin0Texto,
      );

      final Map<String, dynamic> admin1 =
          jsonDecode(
        admin1Texto,
      );

      final Map<String, dynamic> admin2 =
          jsonDecode(
        admin2Texto,
      );

      procesarAdmin0(
        admin0,
      );

      procesarAdmin1(
        admin1,
      );

      procesarAdmin2(
        admin2,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        cargando = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        cargando = false;

        error =
            'No se pudieron cargar los archivos GeoJSON.\n$e';
      });
    }
  }

  // ============================================
  // ADMIN0
  // ============================================

  void procesarAdmin0(
    Map<String, dynamic> geojson,
  ) {
    final features =
        geojson['features'];

    if (features is! List) {
      return;
    }

    final nuevosPoligonos =
        <Polygon>[];

    for (final feature in features) {
      final geometry =
          feature['geometry'];

      if (geometry == null) {
        continue;
      }

      final tipo =
          geometry['type'];

      final coordinates =
          geometry['coordinates'];

      if (tipo == 'Polygon') {
        nuevosPoligonos.addAll(
          crearPoligonosDesdePolygon(
            coordinates,
            nivel: 0,
          ),
        );
      }

      if (tipo == 'MultiPolygon') {
        nuevosPoligonos.addAll(
          crearPoligonosDesdeMultiPolygon(
            coordinates,
            nivel: 0,
          ),
        );
      }
    }

    admin0Poligonos =
        nuevosPoligonos;
  }

  // ============================================
  // ADMIN1
  // ============================================

  void procesarAdmin1(
    Map<String, dynamic> geojson,
  ) {
    final features =
        geojson['features'];

    if (features is! List) {
      return;
    }

    final nuevosPoligonos =
        <Polygon>[];

    final nuevasEtiquetas =
        <_EtiquetaMapa>[];

    for (final feature in features) {
      final geometry =
          feature['geometry'];

      if (geometry == null) {
        continue;
      }

      final properties =
          Map<String, dynamic>.from(
        feature['properties'] ?? {},
      );

      final nombre =
          limpiarNombre(
        obtenerNombre(
          properties,
        ),
      );

      final tipo =
          geometry['type'];

      final coordinates =
          geometry['coordinates'];

      final puntosFeature =
          <LatLng>[];

      if (tipo == 'Polygon') {
        final poligonos =
            crearPoligonosDesdePolygon(
          coordinates,
          nivel: 1,
        );

        nuevosPoligonos.addAll(
          poligonos,
        );

        for (final poligono
            in poligonos) {
          puntosFeature.addAll(
            poligono.points,
          );
        }
      }

      if (tipo == 'MultiPolygon') {
        final poligonos =
            crearPoligonosDesdeMultiPolygon(
          coordinates,
          nivel: 1,
        );

        nuevosPoligonos.addAll(
          poligonos,
        );

        for (final poligono
            in poligonos) {
          puntosFeature.addAll(
            poligono.points,
          );
        }
      }

      if (puntosFeature.isNotEmpty &&
          nombre.isNotEmpty) {
        nuevasEtiquetas.add(
          _EtiquetaMapa(
            nombre: nombre,
            posicion:
                calcularCentro(
              puntosFeature,
            ),
          ),
        );
      }
    }

    admin1Poligonos =
        nuevosPoligonos;

    admin1Etiquetas
      ..clear()
      ..addAll(
        nuevasEtiquetas,
      );
  }

  // ============================================
  // ADMIN2
  // ============================================

  void procesarAdmin2(
    Map<String, dynamic> geojson,
  ) {
    final features =
        geojson['features'];

    if (features is! List) {
      return;
    }

    final nuevosPoligonos =
        <Polygon>[];

    final nuevasEtiquetas =
        <_EtiquetaMapa>[];

    for (final feature in features) {
      final geometry =
          feature['geometry'];

      if (geometry == null) {
        continue;
      }

      final properties =
          Map<String, dynamic>.from(
        feature['properties'] ?? {},
      );

      final nombre =
          limpiarNombre(
        obtenerNombre(
          properties,
        ),
      );

      final tipo =
          geometry['type'];

      final coordinates =
          geometry['coordinates'];

      final puntosFeature =
          <LatLng>[];

      if (tipo == 'Polygon') {
        final poligonos =
            crearPoligonosDesdePolygon(
          coordinates,
          nivel: 2,
        );

        nuevosPoligonos.addAll(
          poligonos,
        );

        for (final poligono
            in poligonos) {
          puntosFeature.addAll(
            poligono.points,
          );
        }
      }

      if (tipo == 'MultiPolygon') {
        final poligonos =
            crearPoligonosDesdeMultiPolygon(
          coordinates,
          nivel: 2,
        );

        nuevosPoligonos.addAll(
          poligonos,
        );

        for (final poligono
            in poligonos) {
          puntosFeature.addAll(
            poligono.points,
          );
        }
      }

      if (puntosFeature.isNotEmpty &&
          nombre.isNotEmpty) {
        nuevasEtiquetas.add(
          _EtiquetaMapa(
            nombre: nombre,
            posicion:
                calcularCentro(
              puntosFeature,
            ),
          ),
        );
      }
    }

    admin2Poligonos =
        nuevosPoligonos;

    admin2Etiquetas
      ..clear()
      ..addAll(
        nuevasEtiquetas,
      );
  }

  // ============================================
  // OBTENER NOMBRE
  // ============================================

  String obtenerNombre(
    Map<String, dynamic> properties,
  ) {
    final posiblesCampos = [
      'shapeName',
      'NAME_3',
      'NAME_2',
      'NAME_1',
      'NAME',
      'name',
      'ADM3_ES',
      'ADM3',
      'ADM2_ES',
      'ADM2',
      'ADM1_ES',
      'ADM1',
      'Distrito',
      'distrito',
      'Municipio',
      'municipio',
      'Departamento',
      'departamento',
    ];

    for (final campo
        in posiblesCampos) {
      final valor =
          properties[campo];

      if (valor != null &&
          valor
              .toString()
              .trim()
              .isNotEmpty) {
        return valor
            .toString()
            .trim();
      }
    }

    return '';
  }

  // ============================================
  // LIMPIAR NOMBRES
  // ============================================

  String limpiarNombre(
    String nombre,
  ) {
    return nombre
        .replaceFirst(
          RegExp(
            r'^Departamento de\s+',
            caseSensitive: false,
          ),
          '',
        )
        .replaceFirst(
          RegExp(
            r'^Municipio de\s+',
            caseSensitive: false,
          ),
          '',
        )
        .replaceFirst(
          RegExp(
            r'^Distrito de\s+',
            caseSensitive: false,
          ),
          '',
        )
        .trim();
  }

  // ============================================
  // POLYGON
  // ============================================

  List<Polygon>
      crearPoligonosDesdePolygon(
    dynamic coordinates, {
    required int nivel,
  }) {
    final resultado =
        <Polygon>[];

    if (coordinates is! List ||
        coordinates.isEmpty) {
      return resultado;
    }

    final exterior =
        coordinates.first;

    if (exterior is! List) {
      return resultado;
    }

    final puntos =
        convertirCoordenadas(
      exterior,
    );

    if (puntos.length < 3) {
      return resultado;
    }

    Color colorRelleno =
        Colors.transparent;

    Color colorBorde =
        naranjaOscuro;

    double anchoBorde =
        3.5;

    // ========================================
    // ADMIN0
    // BORDE NACIONAL GRUESO
    // ========================================

    if (nivel == 0) {
      colorRelleno =
          Colors.transparent;

      colorBorde =
          naranjaOscuro;

      anchoBorde =
          3.5;
    }

    // ========================================
    // ADMIN1
    // NARANJA PRINCIPAL
    // ========================================

    if (nivel == 1) {
      colorRelleno =
          naranjaPrincipal.withValues(
        alpha: 0.16,
      );

      colorBorde =
          naranjaPrincipal;

      anchoBorde =
          2.0;
    }

    // ========================================
    // ADMIN2
    // BORDE MÁS FINO
    // ========================================

    if (nivel == 2) {
      colorRelleno =
          naranjaMedio.withValues(
        alpha: 0.08,
      );

      colorBorde =
          naranjaMedio;

      anchoBorde =
          1.1;
    }

    // ========================================
    // ADMIN3
    // BORDE TODAVÍA MÁS FINO
    // ========================================

    if (nivel == 3) {
      colorRelleno =
          naranjaClaro.withValues(
        alpha: 0.05,
      );

      colorBorde =
          naranjaClaro;

      anchoBorde =
          0.7;
    }

    resultado.add(
      Polygon(
        points:
            puntos,

        color:
            colorRelleno,

        borderColor:
            colorBorde,

        borderStrokeWidth:
            anchoBorde,
      ),
    );

    return resultado;
  }

  // ============================================
  // MULTIPOLYGON
  // ============================================

  List<Polygon>
      crearPoligonosDesdeMultiPolygon(
    dynamic coordinates, {
    required int nivel,
  }) {
    final resultado =
        <Polygon>[];

    if (coordinates is! List) {
      return resultado;
    }

    for (final polygonCoordinates
        in coordinates) {
      resultado.addAll(
        crearPoligonosDesdePolygon(
          polygonCoordinates,
          nivel: nivel,
        ),
      );
    }

    return resultado;
  }

  // ============================================
  // COORDENADAS
  // GEOJSON = LONGITUD, LATITUD
  // FLUTTER = LATITUD, LONGITUD
  // ============================================

  List<LatLng> convertirCoordenadas(
    dynamic coordinates,
  ) {
    final puntos =
        <LatLng>[];

    if (coordinates is! List) {
      return puntos;
    }

    for (final coordinate
        in coordinates) {
      if (coordinate is! List ||
          coordinate.length < 2) {
        continue;
      }

      final longitud =
          (coordinate[0] as num)
              .toDouble();

      final latitud =
          (coordinate[1] as num)
              .toDouble();

      puntos.add(
        LatLng(
          latitud,
          longitud,
        ),
      );
    }

    return puntos;
  }

  // ============================================
  // CENTRO APROXIMADO
  // ============================================

  LatLng calcularCentro(
    List<LatLng> puntos,
  ) {
    double latitud = 0;
    double longitud = 0;

    for (final punto in puntos) {
      latitud +=
          punto.latitude;

      longitud +=
          punto.longitude;
    }

    return LatLng(
      latitud /
          puntos.length,

      longitud /
          puntos.length,
    );
  }

  // ============================================
  // CENTRAR EL SALVADOR
  // ============================================

  void centrarElSalvador() {
    mapController.move(
      centroElSalvador,
      8.0,
    );
  }

  // ============================================
  // NIVEL ACTUAL
  // ============================================

  String obtenerNivelActual() {
    if (zoomActual < 8.2) {
      return 'ADMIN0';
    }

    if (zoomActual < 9.5) {
      return 'ADMIN1';
    }

    if (zoomActual < 12.5) {
      return 'ADMIN2';
    }

    return 'ADMIN3';
  }

  // ============================================
  // BUILD
  // ============================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final bool esOscuro =
        Theme.of(context).brightness ==
            Brightness.dark;

    final Color colorTexto =
        esOscuro
            ? Colors.white
            : const Color(
                0xFF202020,
              );

    final Color colorFondo =
        esOscuro
            ? fondoOscuro
            : fondoClaro;

    // ============================================
    // CARGANDO
    // ============================================

    if (cargando) {
      return Scaffold(
        backgroundColor:
            colorFondo,

        body: const Center(
          child:
              CircularProgressIndicator(
            color:
                naranjaPrincipal,
          ),
        ),
      );
    }

    // ============================================
    // ERROR
    // ============================================

    if (error != null) {
      return Scaffold(
        backgroundColor:
            colorFondo,

        body: Center(
          child: Padding(
            padding:
                const EdgeInsets.all(
              25,
            ),

            child: Column(
              mainAxisSize:
                  MainAxisSize.min,

              children: [
                const Icon(
                  Icons.map_outlined,
                  size: 80,
                  color:
                      naranjaPrincipal,
                ),

                const SizedBox(
                  height: 20,
                ),

                Text(
                  error!,
                  textAlign:
                      TextAlign.center,
                ),

                const SizedBox(
                  height: 20,
                ),

                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      cargando = true;
                      error = null;
                    });

                    cargarGeoJson();
                  },

                  icon:
                      const Icon(
                    Icons.refresh,
                  ),

                  label:
                      const Text(
                    'Reintentar',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
          colorFondo,

      body: Stack(
        children: [
          // ========================================
          // MAPA
          // ========================================

          FlutterMap(
            mapController:
                mapController,

            options: MapOptions(
              initialCenter:
                  centroElSalvador,

              initialZoom:
                  8.0,

              minZoom:
                  7.0,

              maxZoom:
                  16.0,

              backgroundColor:
                  colorFondo,

              onPositionChanged:
                  (
                position,
                hasGesture,
              ) {
                final nuevoZoom =
                    position.zoom;

                if ((nuevoZoom -
                            zoomActual)
                        .abs() >
                    0.1) {
                  setState(() {
                    zoomActual =
                        nuevoZoom;
                  });
                }
              },
            ),

            children: [
              // ====================================
              // NO HAY TILELAYER
              // ====================================
              //
              // Sin OpenStreetMap.
              // Así evitamos nombres, carreteras
              // y ruido visual.
              //

              // ====================================
              // ADMIN3
              // PREPARADO PARA EL FUTURO
              // ====================================

              if (zoomActual >= 12.5 &&
                  admin3Poligonos.isNotEmpty)
                PolygonLayer(
                  polygons:
                      admin3Poligonos,
                ),

              // ====================================
              // ADMIN2
              // ====================================

              if (zoomActual >= 9.5)
                PolygonLayer(
                  polygons:
                      admin2Poligonos,
                ),

              // ====================================
              // ADMIN1
              // ====================================

              PolygonLayer(
                polygons:
                    admin1Poligonos,
              ),

              // ====================================
              // ADMIN0
              // SIEMPRE ENCIMA
              // ====================================

              PolygonLayer(
                polygons:
                    admin0Poligonos,
              ),

              // ====================================
              // NOMBRES ADMIN1
              // ====================================

              if (zoomActual >= 8.0 &&
                  zoomActual < 11.5)
                MarkerLayer(
                  markers:
                      admin1Etiquetas
                          .map(
                    (etiqueta) {
                      return Marker(
                        point:
                            etiqueta.posicion,

                        width:
                            120,

                        height:
                            42,

                        child:
                            IgnorePointer(
                          child:
                              Center(
                            child:
                                Text(
                              etiqueta.nombre,

                              textAlign:
                                  TextAlign.center,

                              maxLines:
                                  2,

                              overflow:
                                  TextOverflow.ellipsis,

                              style:
                                  TextStyle(
                                color:
                                    colorTexto,

                                fontSize:
                                    11,

                                fontWeight:
                                    FontWeight.bold,

                                shadows:
                                    [
                                  Shadow(
                                    color:
                                        esOscuro
                                            ? Colors.black
                                            : Colors.white,

                                    blurRadius:
                                        4,
                                  ),

                                  Shadow(
                                    color:
                                        esOscuro
                                            ? Colors.black
                                            : Colors.white,

                                    blurRadius:
                                        4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ).toList(),
                ),

              // ====================================
              // NOMBRES ADMIN2
              // ====================================

              if (zoomActual >= 11.5 &&
                  zoomActual < 14.0)
                MarkerLayer(
                  markers:
                      admin2Etiquetas
                          .map(
                    (etiqueta) {
                      return Marker(
                        point:
                            etiqueta.posicion,

                        width:
                            100,

                        height:
                            35,

                        child:
                            IgnorePointer(
                          child:
                              Center(
                            child:
                                Text(
                              etiqueta.nombre,

                              textAlign:
                                  TextAlign.center,

                              maxLines:
                                  2,

                              overflow:
                                  TextOverflow.ellipsis,

                              style:
                                  TextStyle(
                                color:
                                    colorTexto,

                                fontSize:
                                    9,

                                fontWeight:
                                    FontWeight.w600,

                                shadows:
                                    [
                                  Shadow(
                                    color:
                                        esOscuro
                                            ? Colors.black
                                            : Colors.white,

                                    blurRadius:
                                        3,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ).toList(),
                ),

              // ====================================
              // NOMBRES ADMIN3
              // FUTURO
              // ====================================

              if (zoomActual >= 14.0 &&
                  admin3Etiquetas.isNotEmpty)
                MarkerLayer(
                  markers:
                      admin3Etiquetas
                          .map(
                    (etiqueta) {
                      return Marker(
                        point:
                            etiqueta.posicion,

                        width:
                            90,

                        height:
                            30,

                        child:
                            IgnorePointer(
                          child:
                              Center(
                            child:
                                Text(
                              etiqueta.nombre,

                              textAlign:
                                  TextAlign.center,

                              style:
                                  TextStyle(
                                color:
                                    colorTexto,

                                fontSize:
                                    8,

                                fontWeight:
                                    FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ).toList(),
                ),
            ],
          ),

          // ========================================
          // CABECERA
          // ========================================

          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.all(
                12,
              ),

              child: Container(
                height: 52,

                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 16,
                ),

                decoration:
                    BoxDecoration(
                  color:
                      esOscuro
                          ? moradoOscuro.withValues(
                              alpha: 0.94,
                            )
                          : Colors.white.withValues(
                              alpha: 0.95,
                            ),

                  borderRadius:
                      BorderRadius.circular(
                    18,
                  ),

                  boxShadow: [
                    BoxShadow(
                      blurRadius: 12,

                      color:
                          Colors.black.withValues(
                        alpha: 0.12,
                      ),
                    ),
                  ],
                ),

                child: Row(
                  children: [
                    const Icon(
                      Icons.map,
                      color:
                          naranjaPrincipal,
                    ),

                    const SizedBox(
                      width: 10,
                    ),

                    Expanded(
                      child: Text(
                        'Mapa de El Salvador',

                        style:
                            TextStyle(
                          color:
                              colorTexto,

                          fontWeight:
                              FontWeight.bold,

                          fontSize:
                              17,
                        ),
                      ),
                    ),

                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),

                      decoration:
                          BoxDecoration(
                        color:
                            naranjaPrincipal.withValues(
                          alpha: 0.12,
                        ),

                        borderRadius:
                            BorderRadius.circular(
                          10,
                        ),
                      ),

                      child:
                          Text(
                        'Z ${zoomActual.toStringAsFixed(1)}',

                        style:
                            const TextStyle(
                          color:
                              naranjaPrincipal,

                          fontWeight:
                              FontWeight.bold,

                          fontSize:
                              11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ========================================
          // BOTÓN CENTRAR
          // ========================================

          Positioned(
            right: 16,
            bottom: 25,

            child:
                FloatingActionButton(
              heroTag:
                  'centrarMapa',

              backgroundColor:
                  naranjaPrincipal,

              foregroundColor:
                  Colors.white,

              onPressed:
                  centrarElSalvador,

              child:
                  const Icon(
                Icons
                    .center_focus_strong,
              ),
            ),
          ),

          // ========================================
          // NIVEL ADMINISTRATIVO
          // ========================================

          Positioned(
            left: 16,
            bottom: 25,

            child:
                Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 9,
              ),

              decoration:
                  BoxDecoration(
                color:
                    esOscuro
                        ? moradoOscuro.withValues(
                            alpha: 0.94,
                          )
                        : Colors.white.withValues(
                            alpha: 0.95,
                          ),

                borderRadius:
                    BorderRadius.circular(
                  14,
                ),

                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.black.withValues(
                      alpha: 0.12,
                    ),

                    blurRadius:
                        10,
                  ),
                ],
              ),

              child:
                  Row(
                mainAxisSize:
                    MainAxisSize.min,

                children: [
                  const Icon(
                    Icons.layers_outlined,

                    size: 18,

                    color:
                        naranjaPrincipal,
                  ),

                  const SizedBox(
                    width: 6,
                  ),

                  Text(
                    obtenerNivelActual(),

                    style:
                        TextStyle(
                      color:
                          colorTexto,

                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// ETIQUETA DEL MAPA
// ============================================

class _EtiquetaMapa {
  final String nombre;
  final LatLng posicion;

  const _EtiquetaMapa({
    required this.nombre,
    required this.posicion,
  });
}