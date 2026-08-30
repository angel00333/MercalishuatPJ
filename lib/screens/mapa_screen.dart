import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class MapaScreen extends StatefulWidget {
  const MapaScreen({
    super.key,
  });

  @override
  State<MapaScreen> createState() =>
      _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  // ============================================================
  // CONTROLADOR
  // ============================================================

  MapLibreMapController? _mapController;

  Circle? _marcadorUsuario;

  // ============================================================
  // EL SALVADOR
  // ============================================================

  static const LatLng _centroElSalvador =
      LatLng(
    13.7942,
    -88.8965,
  );

  static final LatLngBounds _limitesElSalvador =
      LatLngBounds(
    southwest: const LatLng(
      13.00,
      -90.25,
    ),
    northeast: const LatLng(
      14.55,
      -87.55,
    ),
  );

  static const double _zoomMinimo = 7.4;
  static const double _zoomMaximo = 19.0;

  double _zoomActual = 8.5;

  // ============================================================
  // ESTILOS
  // ============================================================

  static const String _estiloClaro =
      'assets/mapas/openfreemap_mercali_light.json';

  static const String _estiloOscuro =
      'assets/mapas/openfreemap_mercali_dark.json';

  // ============================================================
  // COLORES
  // ============================================================

  static const Color _naranjaPrincipal =
      Color(0xFFFF7E01);

  static const Color _panelOscuro =
      Color(0xFF2A2045);

  static const Color _fondoOscuro =
      Color(0xFF171320);

  static const Color _fondoClaro =
      Color(0xFFFFF6ED);

  // ============================================================
  // GEOJSON
  // ============================================================

  Map<String, dynamic>? _admin0;
  Map<String, dynamic>? _admin1;
  Map<String, dynamic>? _admin2;
  Map<String, dynamic>? _admin3;

  Map<String, dynamic>? _mascara;

  // ============================================================
  // ESTADO MAPA
  // ============================================================

  bool _geoJsonCargado = false;
  bool _estiloCargado = false;
  bool _capasCargadas = false;

  String? _error;

  // ============================================================
  // GPS
  // ============================================================

  Position? _posicionUsuario;

  bool _obteniendoUbicacion = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _cargarGeoJson();
  }

  // ============================================================
  // GEOJSON
  // ============================================================

  Future<void> _cargarGeoJson() async {
    try {
      final textos = await Future.wait(
        [
          rootBundle.loadString(
            'assets/mapas/SV-Map-ADM0.geojson',
          ),
          rootBundle.loadString(
            'assets/mapas/SV-Map-ADM1.geojson',
          ),
          rootBundle.loadString(
            'assets/mapas/SV-Map-ADM2.geojson',
          ),
          rootBundle.loadString(
            'assets/mapas/SV-Map-ADM3.geojson',
          ),
        ],
      );

      _admin0 =
          jsonDecode(
        textos[0],
      );

      _admin1 =
          jsonDecode(
        textos[1],
      );

      _admin2 =
          jsonDecode(
        textos[2],
      );

      _admin3 =
          jsonDecode(
        textos[3],
      );

      _mascara =
          _crearMascara(
        _admin0!,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _geoJsonCargado = true;
        _error = null;
      });

      if (_estiloCargado) {
        await _agregarCapas();
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error =
            'Error cargando GeoJSON:\n$e';
      });
    }
  }

  // ============================================================
  // MÁSCARA
  // ============================================================

  Map<String, dynamic> _crearMascara(
    Map<String, dynamic> admin0,
  ) {
    final List<dynamic> huecos = [];

    final features =
        admin0['features'];

    if (features is List) {
      for (final feature in features) {
        final geometry =
            feature['geometry'];

        if (geometry == null) {
          continue;
        }

        final tipo =
            geometry['type']
                    ?.toString() ??
                '';

        final coordinates =
            geometry['coordinates'];

        if (tipo == 'Polygon' &&
            coordinates is List &&
            coordinates.isNotEmpty) {
          final exterior =
              coordinates[0];

          if (exterior is List) {
            huecos.add(
              exterior.reversed.toList(),
            );
          }
        }

        if (tipo == 'MultiPolygon' &&
            coordinates is List) {
          for (final polygon
              in coordinates) {
            if (polygon is List &&
                polygon.isNotEmpty &&
                polygon[0] is List) {
              huecos.add(
                (polygon[0] as List)
                    .reversed
                    .toList(),
              );
            }
          }
        }
      }
    }

    final exterior = [
      [-92.0, 12.0],
      [-85.5, 12.0],
      [-85.5, 16.0],
      [-92.0, 16.0],
      [-92.0, 12.0],
    ];

    return {
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'properties':
              <String, dynamic>{},
          'geometry': {
            'type': 'Polygon',
            'coordinates': [
              exterior,
              ...huecos,
            ],
          },
        },
      ],
    };
  }

  // ============================================================
  // MAPA CREADO
  // ============================================================

  void _onMapCreated(
    MapLibreMapController controller,
  ) {
    _mapController = controller;
  }

  // ============================================================
  // ESTILO CARGADO
  // ============================================================

  Future<void> _onStyleLoaded() async {
    _capasCargadas = false;
    _marcadorUsuario = null;

    if (!mounted) {
      return;
    }

    setState(() {
      _estiloCargado = true;
    });

    if (_geoJsonCargado) {
      await _agregarCapas();
    }

    await _centrarElSalvador();

    // Si el tema cambió y el mapa se reconstruyó,
    // volvemos a dibujar la ubicación conocida.
    if (_posicionUsuario != null) {
      await _dibujarUbicacion(
        _posicionUsuario!,
        centrar: false,
      );
    }
  }

  // ============================================================
  // CAPAS ADMINISTRATIVAS
  // ============================================================

  Future<void> _agregarCapas() async {
    final controller =
        _mapController;

    if (controller == null ||
        _capasCargadas ||
        !_geoJsonCargado) {
      return;
    }

    try {
      final esOscuro =
          Theme.of(context).brightness ==
              Brightness.dark;

      await controller.addGeoJsonSource(
        'merc-mask',
        _mascara!,
      );

      await controller.addGeoJsonSource(
        'merc-admin0',
        _admin0!,
      );

      await controller.addGeoJsonSource(
        'merc-admin1',
        _admin1!,
      );

      await controller.addGeoJsonSource(
        'merc-admin2',
        _admin2!,
      );

      await controller.addGeoJsonSource(
        'merc-admin3',
        _admin3!,
      );

      // ========================================================
      // OCULTAR EXTERIOR DE EL SALVADOR
      // ========================================================

      await controller.addFillLayer(
        'merc-mask',
        'merc-mask-layer',
        FillLayerProperties(
          fillColor:
              esOscuro
                  ? '#171320'
                  : '#FFF6ED',
          fillOpacity: 1.0,
          fillOutlineColor:
              esOscuro
                  ? '#171320'
                  : '#FFF6ED',
        ),
      );

      // ========================================================
      // TINTE NARANJA
      // ========================================================

      await controller.addFillLayer(
        'merc-admin0',
        'merc-orange-overlay',
        const FillLayerProperties(
          fillColor: '#FF7E01',
          fillOpacity: 0.035,
        ),
      );

      // ========================================================
      // ADMIN3
      // ========================================================

      await controller.addLineLayer(
        'merc-admin3',
        'merc-admin3-line',
        const LineLayerProperties(
          lineColor: '#FFC078',
          lineOpacity: 0.65,
          lineWidth: 0.65,
        ),
        minzoom: 13.0,
      );

      // ========================================================
      // ADMIN2
      // ========================================================

      await controller.addLineLayer(
        'merc-admin2',
        'merc-admin2-line',
        const LineLayerProperties(
          lineColor: '#FF9A3D',
          lineOpacity: 0.78,
          lineWidth: 1.0,
        ),
        minzoom: 10.0,
      );

      // ========================================================
      // ADMIN1
      // ========================================================

      await controller.addLineLayer(
        'merc-admin1',
        'merc-admin1-line',
        const LineLayerProperties(
          lineColor: '#FF7E01',
          lineOpacity: 0.90,
          lineWidth: 1.5,
        ),
        minzoom: 7.5,
      );

      // ========================================================
      // ADMIN0
      // ========================================================

      await controller.addLineLayer(
        'merc-admin0',
        'merc-admin0-line',
        const LineLayerProperties(
          lineColor: '#C95400',
          lineOpacity: 1.0,
          lineWidth: 3.0,
        ),
      );

      _capasCargadas = true;
    } catch (e) {
      debugPrint(
        'Error cargando capas: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _error =
            'Error agregando capas:\n$e';
      });
    }
  }

  // ============================================================
  // OBTENER UBICACIÓN
  // ============================================================

  Future<void> _obtenerMiUbicacion() async {
    if (_obteniendoUbicacion) {
      return;
    }

    setState(() {
      _obteniendoUbicacion = true;
    });

    try {
      // ========================================================
      // GPS / SERVICIO DE UBICACIÓN
      // ========================================================

      final bool servicioActivo =
          await Geolocator
              .isLocationServiceEnabled();

      if (!servicioActivo) {
        if (!mounted) {
          return;
        }

        _mostrarDialogoGpsDesactivado();

        return;
      }

      // ========================================================
      // PERMISOS
      // ========================================================

      LocationPermission permiso =
          await Geolocator.checkPermission();

      if (permiso ==
          LocationPermission.denied) {
        permiso =
            await Geolocator
                .requestPermission();
      }

      if (permiso ==
          LocationPermission.denied) {
        if (!mounted) {
          return;
        }

        _mostrarMensaje(
          'Permiso de ubicación denegado.',
        );

        return;
      }

      if (permiso ==
          LocationPermission.deniedForever) {
        if (!mounted) {
          return;
        }

        _mostrarDialogoPermisoPermanente();

        return;
      }

      // ========================================================
      // OBTENER POSICIÓN
      // ========================================================

      const LocationSettings settings =
          LocationSettings(
        accuracy:
            LocationAccuracy.high,
      );

      final Position posicion =
          await Geolocator
              .getCurrentPosition(
        locationSettings: settings,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _posicionUsuario = posicion;
      });

      await _dibujarUbicacion(
        posicion,
        centrar: true,
      );
    } catch (e) {
      debugPrint(
        'Error obteniendo ubicación: $e',
      );

      if (!mounted) {
        return;
      }

      _mostrarMensaje(
        'No se pudo obtener tu ubicación.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _obteniendoUbicacion = false;
        });
      }
    }
  }

  // ============================================================
  // DIBUJAR UBICACIÓN
  // ============================================================

  Future<void> _dibujarUbicacion(
    Position posicion, {
    required bool centrar,
  }) async {
    final controller =
        _mapController;

    if (controller == null ||
        !_estiloCargado) {
      return;
    }

    final LatLng punto =
        LatLng(
      posicion.latitude,
      posicion.longitude,
    );

    try {
      if (_marcadorUsuario == null) {
        _marcadorUsuario =
            await controller.addCircle(
          CircleOptions(
            geometry: punto,
            circleRadius: 9.0,
            circleColor: '#FF7E01',
            circleStrokeColor:
                '#FFFFFF',
            circleStrokeWidth: 3.0,
            circleOpacity: 1.0,
          ),
        );
      } else {
        await controller.updateCircle(
          _marcadorUsuario!,
          CircleOptions(
            geometry: punto,
          ),
        );
      }

      if (centrar) {
        await controller.animateCamera(
          CameraUpdate.newLatLngZoom(
            punto,
            15.0,
          ),
        );
      }
    } catch (e) {
      debugPrint(
        'Error dibujando ubicación: $e',
      );
    }
  }

  // ============================================================
  // GPS DESACTIVADO
  // ============================================================

  void _mostrarDialogoGpsDesactivado() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.location_off_outlined,
            color: _naranjaPrincipal,
            size: 38,
          ),
          title: const Text(
            'Ubicación desactivada',
          ),
          content: const Text(
            'Activa la ubicación del dispositivo para poder mostrar tu posición en el mapa.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child: const Text(
                'Cancelar',
              ),
            ),
            FilledButton(
              style:
                  FilledButton.styleFrom(
                backgroundColor:
                    _naranjaPrincipal,
                foregroundColor:
                    Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(
                  dialogContext,
                );

                await Geolocator
                    .openLocationSettings();
              },
              child: const Text(
                'Abrir ajustes',
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // PERMISO PERMANENTEMENTE DENEGADO
  // ============================================================

  void _mostrarDialogoPermisoPermanente() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.gps_off_outlined,
            color: _naranjaPrincipal,
            size: 38,
          ),
          title: const Text(
            'Permiso requerido',
          ),
          content: const Text(
            'El permiso de ubicación está bloqueado. Puedes habilitarlo desde los ajustes de la aplicación.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child: const Text(
                'Cancelar',
              ),
            ),
            FilledButton(
              style:
                  FilledButton.styleFrom(
                backgroundColor:
                    _naranjaPrincipal,
                foregroundColor:
                    Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(
                  dialogContext,
                );

                await Geolocator
                    .openAppSettings();
              },
              child: const Text(
                'Abrir ajustes',
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // MENSAJE
  // ============================================================

  void _mostrarMensaje(
    String mensaje,
  ) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          mensaje,
        ),
      ),
    );
  }

  // ============================================================
  // ZOOM +
  // ============================================================

  Future<void> _acercar() async {
    if (_mapController == null) {
      return;
    }

    final zoom =
        (_zoomActual + 1)
            .clamp(
              _zoomMinimo,
              _zoomMaximo,
            )
            .toDouble();

    await _mapController!
        .animateCamera(
      CameraUpdate.zoomTo(
        zoom,
      ),
    );
  }

  // ============================================================
  // ZOOM -
  // ============================================================

  Future<void> _alejar() async {
    if (_mapController == null) {
      return;
    }

    final zoom =
        (_zoomActual - 1)
            .clamp(
              _zoomMinimo,
              _zoomMaximo,
            )
            .toDouble();

    await _mapController!
        .animateCamera(
      CameraUpdate.zoomTo(
        zoom,
      ),
    );
  }

  // ============================================================
  // CENTRAR EL SALVADOR
  // ============================================================

  Future<void> _centrarElSalvador() async {
    if (_mapController == null) {
      return;
    }

    await _mapController!
        .animateCamera(
      CameraUpdate.newLatLngBounds(
        _limitesElSalvador,
        left: 25,
        top: 80,
        right: 25,
        bottom: 70,
      ),
    );
  }

  // ============================================================
  // NIVEL ACTUAL
  // ============================================================

  String _nivelActual() {
    if (_zoomActual < 8.5) {
      return 'ADMIN0';
    }

    if (_zoomActual < 10) {
      return 'ADMIN1';
    }

    if (_zoomActual < 13) {
      return 'ADMIN2';
    }

    return 'ADMIN3';
  }

  // ============================================================
  // BOTÓN
  // ============================================================

  Widget _boton({
    required String tag,
    required IconData icon,
    required VoidCallback onPressed,
    required bool oscuro,
    bool cargando = false,
  }) {
    return FloatingActionButton.small(
      heroTag: tag,
      elevation: 3,
      backgroundColor:
          oscuro
              ? _panelOscuro
              : Colors.white,
      foregroundColor:
          _naranjaPrincipal,
      onPressed:
          cargando
              ? null
              : onPressed,
      child:
          cargando
              ? const SizedBox(
                  width: 19,
                  height: 19,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,
                    color:
                        _naranjaPrincipal,
                  ),
                )
              : Icon(
                  icon,
                ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final oscuro =
        Theme.of(context).brightness ==
            Brightness.dark;

    final fondo =
        oscuro
            ? _fondoOscuro
            : _fondoClaro;

    final panel =
        oscuro
            ? _panelOscuro
            : Colors.white;

    final texto =
        oscuro
            ? Colors.white
            : const Color(
                0xFF512A12,
              );

    return Scaffold(
      backgroundColor: fondo,
      body: Stack(
        children: [
          // ====================================================
          // MAPA
          // ====================================================

          MapLibreMap(
            key: ValueKey(
              oscuro
                  ? 'map-dark'
                  : 'map-light',
            ),

            styleString:
                oscuro
                    ? _estiloOscuro
                    : _estiloClaro,

            initialCameraPosition:
                const CameraPosition(
              target:
                  _centroElSalvador,
              zoom: 8.5,
            ),

            cameraTargetBounds:
                CameraTargetBounds(
              _limitesElSalvador,
            ),

            minMaxZoomPreference:
                const MinMaxZoomPreference(
              _zoomMinimo,
              _zoomMaximo,
            ),

            rotateGesturesEnabled:
                false,

            tiltGesturesEnabled:
                false,

            compassEnabled:
                false,

            // No usamos la ubicación
            // automática de MapLibre.
            //
            // Nosotros la controlamos
            // con Geolocator.
            myLocationEnabled:
                false,

            myLocationTrackingMode:
                MyLocationTrackingMode.none,

            onMapCreated:
                _onMapCreated,

            onStyleLoadedCallback:
                _onStyleLoaded,

            onCameraMove:
                (position) {
              if ((position.zoom -
                          _zoomActual)
                      .abs() >
                  0.05) {
                setState(() {
                  _zoomActual =
                      position.zoom;
                });
              }
            },
          ),

          // ====================================================
          // CARGANDO MAPA
          // ====================================================

          if (!_estiloCargado ||
              !_geoJsonCargado)
            Container(
              color:
                  fondo.withValues(
                alpha: 0.80,
              ),
              alignment:
                  Alignment.center,
              child:
                  const CircularProgressIndicator(
                color:
                    _naranjaPrincipal,
              ),
            ),

          // ====================================================
          // CABECERA
          // ====================================================

          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                12,
                12,
                80,
                12,
              ),
              child: Container(
                height: 52,
                constraints:
                    const BoxConstraints(
                  maxWidth: 430,
                ),
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 15,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      panel.withValues(
                    alpha: 0.95,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    18,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black
                              .withValues(
                        alpha:
                            oscuro
                                ? 0.35
                                : 0.14,
                      ),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.map_outlined,
                      color:
                          _naranjaPrincipal,
                    ),

                    const SizedBox(
                      width: 9,
                    ),

                    Expanded(
                      child: Text(
                        'Mapa de El Salvador',
                        overflow:
                            TextOverflow.ellipsis,
                        style:
                            TextStyle(
                          color: texto,
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ====================================================
          // CONTROLES DERECHA
          // ====================================================

          Positioned(
            right: 15,
            top:
                MediaQuery.of(context)
                        .padding
                        .top +
                    12,
            child: Column(
              children: [
                _boton(
                  tag: 'zoomMas',
                  icon: Icons.add,
                  onPressed: _acercar,
                  oscuro: oscuro,
                ),

                const SizedBox(
                  height: 10,
                ),

                _boton(
                  tag: 'zoomMenos',
                  icon: Icons.remove,
                  onPressed: _alejar,
                  oscuro: oscuro,
                ),

                const SizedBox(
                  height: 10,
                ),

                _boton(
                  tag: 'centrar',
                  icon:
                      Icons.center_focus_strong,
                  onPressed:
                      _centrarElSalvador,
                  oscuro: oscuro,
                ),

                const SizedBox(
                  height: 10,
                ),

                // ===============================================
                // MI UBICACIÓN
                // ===============================================

                _boton(
                  tag: 'miUbicacion',
                  icon:
                      _posicionUsuario != null
                          ? Icons.my_location
                          : Icons
                              .location_searching,
                  onPressed:
                      _obtenerMiUbicacion,
                  oscuro: oscuro,
                  cargando:
                      _obteniendoUbicacion,
                ),
              ],
            ),
          ),

          // ====================================================
          // INDICADOR UBICACIÓN ACTIVA
          // ====================================================

          if (_posicionUsuario != null)
            Positioned(
              right: 15,
              bottom: 25,
              child: SafeArea(
                top: false,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        panel.withValues(
                      alpha: 0.95,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            Colors.black
                                .withValues(
                          alpha:
                              oscuro
                                  ? 0.35
                                  : 0.14,
                        ),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.my_location,
                        size: 16,
                        color:
                            _naranjaPrincipal,
                      ),
                      SizedBox(
                        width: 6,
                      ),
                      Text(
                        'Mi ubicación',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ====================================================
          // NIVEL
          // ====================================================

          Positioned(
            left: 15,
            bottom: 25,
            child: SafeArea(
              top: false,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      panel.withValues(
                    alpha: 0.95,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black
                              .withValues(
                        alpha:
                            oscuro
                                ? 0.35
                                : 0.14,
                      ),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.layers_outlined,
                      color:
                          _naranjaPrincipal,
                      size: 18,
                    ),

                    const SizedBox(
                      width: 6,
                    ),

                    Text(
                      '${_nivelActual()} · Zoom ${_zoomActual.toStringAsFixed(1)}',
                      style:
                          TextStyle(
                        color: texto,
                        fontWeight:
                            FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ====================================================
          // ERROR
          // ====================================================

          if (_error != null)
            Center(
              child: Container(
                margin:
                    const EdgeInsets.all(
                  25,
                ),
                padding:
                    const EdgeInsets.all(
                  20,
                ),
                decoration:
                    BoxDecoration(
                  color: panel,
                  borderRadius:
                      BorderRadius.circular(
                    18,
                  ),
                ),
                child: Text(
                  _error!,
                  textAlign:
                      TextAlign.center,
                  style:
                      TextStyle(
                    color: texto,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}