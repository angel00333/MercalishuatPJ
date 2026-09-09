import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class SeleccionarUbicacionScreen extends StatefulWidget {
  final LatLng? ubicacionInicial;

  const SeleccionarUbicacionScreen({
    super.key,
    this.ubicacionInicial,
  });

  @override
  State<SeleccionarUbicacionScreen> createState() =>
      _SeleccionarUbicacionScreenState();
}

class _SeleccionarUbicacionScreenState
    extends State<SeleccionarUbicacionScreen> {
  MapLibreMapController? _mapController;

  // ============================================================
  // EL SALVADOR
  // ============================================================

  static const LatLng _centroElSalvador = LatLng(
    13.7942,
    -88.8965,
  );

  /*
   * IMPORTANTE:
   *
   * MapLibre utiliza un rectángulo para CameraTargetBounds.
   * El rectángulo por sí solo NO puede seguir la forma real
   * de El Salvador.
   *
   * Por eso además usamos el ADM0 para:
   *
   * 1. Ocultar Guatemala / Honduras.
   * 2. Saber si el pin está realmente dentro de El Salvador.
   * 3. Impedir confirmar coordenadas fuera del país.
   * 4. Regresar automáticamente a la última posición válida.
   */

  static final LatLngBounds _limitesElSalvador = LatLngBounds(
    southwest: const LatLng(
      13.12,
      -90.18,
    ),
    northeast: const LatLng(
      14.47,
      -87.66,
    ),
  );

  static const double _zoomMinimo = 8.3;
  static const double _zoomMaximo = 19.0;
  static const double _zoomInicial = 8.8;

  // ============================================================
  // GEOJSON
  // ============================================================

  Map<String, dynamic>? _admin0;
  Map<String, dynamic>? _mascara;

  bool _geoJsonCargado = false;
  bool _capasPaisCargadas = false;

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

  static const Color _naranjaPrincipal = Color(
    0xFFFF7E01,
  );

  static const Color _panelOscuro = Color(
    0xFF2A2045,
  );

  static const Color _fondoOscuro = Color(
    0xFF171320,
  );

  static const Color _fondoClaro = Color(
    0xFFFFF6ED,
  );

  // ============================================================
  // CÁMARA
  // ============================================================

  LatLng _centroActual = _centroElSalvador;

  LatLng _ultimaUbicacionValida = _centroElSalvador;

  double _zoomActual = _zoomInicial;

  bool _preparandoUbicacion = true;
  bool _mapaListo = false;
  bool _moviendoMapa = false;
  bool _confirmando = false;

  bool _movimientoProgramatico = false;
  bool _corrigiendoLimite = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _inicializar();
  }

  Future<void> _inicializar() async {
    await _cargarLimiteElSalvador();

    await _prepararUbicacionInicial();
  }

  // ============================================================
  // CARGAR ADM0
  //
  // Solo cargamos ADM0.
  // No necesitamos ADM1, ADM2 ni ADM3 en esta pantalla.
  //
  // Esto reduce:
  // - RAM
  // - JSON parsing
  // - capas
  // - tiempo de carga
  // ============================================================

  Future<void> _cargarLimiteElSalvador() async {
    try {
      final texto = await rootBundle.loadString(
        'assets/mapas/SV-Map-ADM0.geojson',
      );

      final Map<String, dynamic> geojson =
          Map<String, dynamic>.from(
        jsonDecode(
          texto,
        ),
      );

      _admin0 = geojson;

      _mascara = _crearMascara(
        geojson,
      );

      _geoJsonCargado = true;
    } catch (e) {
      debugPrint(
        'ERROR CARGANDO ADM0: $e',
      );

      _geoJsonCargado = false;
    }
  }

  // ============================================================
  // CREAR MÁSCARA
  //
  // Todo lo que está fuera de El Salvador queda cubierto.
  // ============================================================

  Map<String, dynamic> _crearMascara(
    Map<String, dynamic> admin0,
  ) {
    final List<dynamic> huecos = [];

    final features = admin0['features'];

    if (features is List) {
      for (final feature in features) {
        if (feature is! Map) {
          continue;
        }

        final geometry = feature['geometry'];

        if (geometry is! Map) {
          continue;
        }

        final String tipo =
            geometry['type']?.toString() ?? '';

        final coordinates =
            geometry['coordinates'];

        if (tipo == 'Polygon' &&
            coordinates is List &&
            coordinates.isNotEmpty) {
          final exterior = coordinates[0];

          if (exterior is List) {
            huecos.add(
              exterior.reversed.toList(),
            );
          }
        }

        if (tipo == 'MultiPolygon' &&
            coordinates is List) {
          for (final polygon in coordinates) {
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

    /*
     * Rectángulo externo.
     *
     * No tiene que cubrir el mundo entero porque la cámara
     * está restringida a la región de El Salvador.
     */

    final exterior = [
      [-91.0, 12.5],
      [-86.8, 12.5],
      [-86.8, 15.0],
      [-91.0, 15.0],
      [-91.0, 12.5],
    ];

    return {
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'properties': <String, dynamic>{},
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
  // PUNTO DENTRO DE EL SALVADOR
  // ============================================================

  bool _estaDentroDeElSalvador(
    LatLng punto,
  ) {
    final admin0 = _admin0;

    if (admin0 == null) {
      return false;
    }

    final features = admin0['features'];

    if (features is! List) {
      return false;
    }

    for (final feature in features) {
      if (feature is! Map) {
        continue;
      }

      final geometry =
          feature['geometry'];

      if (geometry is! Map) {
        continue;
      }

      final tipo =
          geometry['type']?.toString();

      final coordinates =
          geometry['coordinates'];

      // ========================================================
      // POLYGON
      // ========================================================

      if (tipo == 'Polygon' &&
          coordinates is List) {
        if (_puntoDentroDePolygon(
          punto,
          coordinates,
        )) {
          return true;
        }
      }

      // ========================================================
      // MULTIPOLYGON
      // ========================================================

      if (tipo == 'MultiPolygon' &&
          coordinates is List) {
        for (final polygon in coordinates) {
          if (polygon is List &&
              _puntoDentroDePolygon(
                punto,
                polygon,
              )) {
            return true;
          }
        }
      }
    }

    return false;
  }

  bool _puntoDentroDePolygon(
    LatLng punto,
    List<dynamic> polygon,
  ) {
    if (polygon.isEmpty) {
      return false;
    }

    final exterior =
        polygon[0];

    if (exterior is! List) {
      return false;
    }

    // Debe estar dentro del anillo exterior.
    if (!_puntoDentroDeAnillo(
      punto,
      exterior,
    )) {
      return false;
    }

    /*
     * Si el GeoJSON contiene huecos internos,
     * el punto no puede estar dentro de ellos.
     */

    for (int i = 1;
        i < polygon.length;
        i++) {
      final hueco =
          polygon[i];

      if (hueco is List &&
          _puntoDentroDeAnillo(
            punto,
            hueco,
          )) {
        return false;
      }
    }

    return true;
  }

  // ============================================================
  // RAY CASTING
  // ============================================================

  bool _puntoDentroDeAnillo(
    LatLng punto,
    List<dynamic> anillo,
  ) {
    bool dentro = false;

    final double x =
        punto.longitude;

    final double y =
        punto.latitude;

    int j =
        anillo.length - 1;

    for (int i = 0;
        i < anillo.length;
        i++) {
      final actual =
          anillo[i];

      final anterior =
          anillo[j];

      if (actual is! List ||
          actual.length < 2 ||
          anterior is! List ||
          anterior.length < 2) {
        j = i;
        continue;
      }

      final double xi =
          (actual[0] as num)
              .toDouble();

      final double yi =
          (actual[1] as num)
              .toDouble();

      final double xj =
          (anterior[0] as num)
              .toDouble();

      final double yj =
          (anterior[1] as num)
              .toDouble();

      final bool cruza =
          ((yi > y) != (yj > y)) &&
              (x <
                  ((xj - xi) *
                          (y - yi) /
                          ((yj - yi) == 0
                              ? 0.0000001
                              : (yj - yi)) +
                      xi));

      if (cruza) {
        dentro = !dentro;
      }

      j = i;
    }

    return dentro;
  }

  // ============================================================
  // PREPARAR UBICACIÓN
  // ============================================================

  Future<void> _prepararUbicacionInicial() async {
    /*
     * Si ya existe una ubicación guardada, únicamente
     * se utiliza si realmente pertenece a El Salvador.
     */

    if (widget.ubicacionInicial != null) {
      final inicial =
          widget.ubicacionInicial!;

      if (_estaDentroDeElSalvador(
        inicial,
      )) {
        _centroActual =
            inicial;

        _ultimaUbicacionValida =
            inicial;

        _zoomActual =
            16;

        if (mounted) {
          setState(() {
            _preparandoUbicacion =
                false;
          });
        }

        return;
      }
    }

    try {
      final bool servicio =
          await Geolocator
              .isLocationServiceEnabled();

      if (!servicio) {
        _usarCentroElSalvador();

        return;
      }

      LocationPermission permiso =
          await Geolocator
              .checkPermission();

      if (permiso ==
          LocationPermission.denied) {
        permiso =
            await Geolocator
                .requestPermission();
      }

      if (permiso ==
              LocationPermission.denied ||
          permiso ==
              LocationPermission.deniedForever) {
        _usarCentroElSalvador();

        return;
      }

      const settings =
          LocationSettings(
        accuracy:
            LocationAccuracy.high,
      );

      final Position posicion =
          await Geolocator
              .getCurrentPosition(
        locationSettings:
            settings,
      );

      final punto =
          LatLng(
        posicion.latitude,
        posicion.longitude,
      );

      /*
       * Si por cualquier razón el GPS devuelve una posición
       * fuera de El Salvador, no colocamos el selector ahí.
       */

      if (!_estaDentroDeElSalvador(
        punto,
      )) {
        _usarCentroElSalvador();

        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _centroActual =
            punto;

        _ultimaUbicacionValida =
            punto;

        _zoomActual =
            16;

        _preparandoUbicacion =
            false;
      });
    } catch (e) {
      debugPrint(
        'ERROR UBICACIÓN INICIAL: $e',
      );

      _usarCentroElSalvador();
    }
  }

  void _usarCentroElSalvador() {
    if (!mounted) {
      return;
    }

    setState(() {
      _centroActual =
          _centroElSalvador;

      _ultimaUbicacionValida =
          _centroElSalvador;

      _zoomActual =
          _zoomInicial;

      _preparandoUbicacion =
          false;
    });
  }

  // ============================================================
  // MAP CREATED
  // ============================================================

  void _onMapCreated(
    MapLibreMapController controller,
  ) {
    _mapController =
        controller;
  }

  // ============================================================
  // STYLE LOADED
  // ============================================================

  Future<void> _onStyleLoaded() async {
    if (_mapController == null) {
      return;
    }

    _capasPaisCargadas = false;

    await _dibujarLimitePais();

    if (!mounted) {
      return;
    }

    setState(() {
      _mapaListo =
          true;
    });
  }

  // ============================================================
  // DIBUJAR SOLO EL SALVADOR
  // ============================================================

  Future<void> _dibujarLimitePais() async {
    final controller =
        _mapController;

    if (controller == null ||
        !_geoJsonCargado ||
        _admin0 == null ||
        _mascara == null ||
        _capasPaisCargadas) {
      return;
    }

    try {
      final oscuro =
          Theme.of(context)
                  .brightness ==
              Brightness.dark;

      // ========================================================
      // MÁSCARA EXTERIOR
      // ========================================================

      await controller.addGeoJsonSource(
        'selector-mask',
        _mascara!,
      );

      await controller.addFillLayer(
        'selector-mask',
        'selector-mask-layer',
        FillLayerProperties(
          fillColor:
              oscuro
                  ? '#171320'
                  : '#FFF6ED',

          fillOpacity:
              1,

          fillOutlineColor:
              oscuro
                  ? '#171320'
                  : '#FFF6ED',
        ),
      );

      // ========================================================
      // FRONTERA REAL
      // ========================================================

      await controller.addGeoJsonSource(
        'selector-sv',
        _admin0!,
      );

      await controller.addLineLayer(
        'selector-sv',
        'selector-sv-border',
        const LineLayerProperties(
          lineColor:
              '#FF7E01',

          lineOpacity:
              1,

          lineWidth:
              2.5,
        ),
      );

      _capasPaisCargadas =
          true;
    } catch (e) {
      debugPrint(
        'ERROR CAPAS SELECTOR: $e',
      );
    }
  }

  // ============================================================
  // CAMERA MOVE
  //
  // Optimización:
  //
  // NO hacemos setState en cada frame.
  //
  // MapLibre puede enviar decenas de eventos por segundo.
  // ============================================================

  void _onCameraMove(
    CameraPosition position,
  ) {
    _centroActual =
        position.target;

    _zoomActual =
        position.zoom;

    /*
     * Solo hacemos un setState al comenzar el movimiento,
     * no 30/60 veces por segundo.
     */

    if (!_moviendoMapa &&
        !_movimientoProgramatico &&
        mounted) {
      setState(() {
        _moviendoMapa =
            true;
      });
    }
  }

  // ============================================================
  // CAMERA IDLE
  // ============================================================

  Future<void> _onCameraIdle() async {
    if (_corrigiendoLimite) {
      return;
    }

    final punto =
        _centroActual;

    // ==========================================================
    // POSICIÓN VÁLIDA
    // ==========================================================

    if (_estaDentroDeElSalvador(
      punto,
    )) {
      _ultimaUbicacionValida =
          punto;

      if (mounted) {
        setState(() {
          _moviendoMapa =
              false;
        });
      }

      return;
    }

    // ==========================================================
    // FUERA DE EL SALVADOR
    //
    // Volvemos a la última posición permitida.
    // ==========================================================

    await _volverAUltimaUbicacionValida();
  }

  // ============================================================
  // REGRESAR AL PAÍS
  // ============================================================

  Future<void>
      _volverAUltimaUbicacionValida() async {
    final controller =
        _mapController;

    if (controller == null) {
      return;
    }

    _corrigiendoLimite =
        true;

    _movimientoProgramatico =
        true;

    try {
      _centroActual =
          _ultimaUbicacionValida;

      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          _ultimaUbicacionValida,
          _zoomActual,
        ),
      );
    } catch (e) {
      debugPrint(
        'ERROR CORRIGIENDO LÍMITE: $e',
      );
    } finally {
      _movimientoProgramatico =
          false;

      _corrigiendoLimite =
          false;

      if (mounted) {
        setState(() {
          _moviendoMapa =
              false;
        });
      }
    }
  }

  // ============================================================
  // CONFIRMAR
  // ============================================================

  Future<void>
      _confirmarUbicacion() async {
    if (_confirmando) {
      return;
    }

    if (!_mapaListo) {
      _mostrarMensaje(
        'El mapa aún no está listo',
      );

      return;
    }

    final ubicacion =
        _centroActual;

    // ==========================================================
    // VALIDACIÓN REAL
    // ==========================================================

    if (!_estaDentroDeElSalvador(
      ubicacion,
    )) {
      _mostrarMensaje(
        'Solo puedes seleccionar una ubicación dentro de El Salvador.',
      );

      await _volverAUltimaUbicacionValida();

      return;
    }

    setState(() {
      _confirmando =
          true;
    });

    try {
      if (!mounted) {
        return;
      }

      Navigator.pop(
        context,
        ubicacion,
      );
    } finally {
      if (mounted) {
        setState(() {
          _confirmando =
              false;
        });
      }
    }
  }

  // ============================================================
  // GPS
  // ============================================================

  Future<void>
      _irAMiUbicacion() async {
    final controller =
        _mapController;

    if (controller == null) {
      return;
    }

    try {
      final bool servicio =
          await Geolocator
              .isLocationServiceEnabled();

      if (!servicio) {
        _mostrarMensaje(
          'Activa la ubicación del dispositivo',
        );

        return;
      }

      LocationPermission permiso =
          await Geolocator
              .checkPermission();

      if (permiso ==
          LocationPermission.denied) {
        permiso =
            await Geolocator
                .requestPermission();
      }

      if (permiso ==
              LocationPermission.denied ||
          permiso ==
              LocationPermission.deniedForever) {
        _mostrarMensaje(
          'No hay permiso de ubicación',
        );

        return;
      }

      const settings =
          LocationSettings(
        accuracy:
            LocationAccuracy.high,
      );

      final Position posicion =
          await Geolocator
              .getCurrentPosition(
        locationSettings:
            settings,
      );

      final punto =
          LatLng(
        posicion.latitude,
        posicion.longitude,
      );

      // ========================================================
      // GPS FUERA DEL PAÍS
      // ========================================================

      if (!_estaDentroDeElSalvador(
        punto,
      )) {
        _mostrarMensaje(
          'Tu ubicación actual está fuera de El Salvador.',
        );

        return;
      }

      _movimientoProgramatico =
          true;

      try {
        await controller.animateCamera(
          CameraUpdate.newLatLngZoom(
            punto,
            16,
          ),
        );

        _centroActual =
            punto;

        _ultimaUbicacionValida =
            punto;

        _zoomActual =
            16;
      } finally {
        _movimientoProgramatico =
            false;
      }

      if (mounted) {
        setState(() {
          _moviendoMapa =
              false;
        });
      }
    } catch (e) {
      debugPrint(
        'ERROR GPS: $e',
      );

      _mostrarMensaje(
        'No se pudo obtener tu ubicación',
      );
    }
  }

  // ============================================================
  // UBICACIÓN ORIGINAL
  // ============================================================

  Future<void>
      _volverUbicacionInicial() async {
    final controller =
        _mapController;

    if (controller == null) {
      return;
    }

    if (widget.ubicacionInicial != null &&
        _estaDentroDeElSalvador(
          widget.ubicacionInicial!,
        )) {
      final punto =
          widget.ubicacionInicial!;

      _movimientoProgramatico =
          true;

      try {
        await controller.animateCamera(
          CameraUpdate.newLatLngZoom(
            punto,
            16,
          ),
        );

        _centroActual =
            punto;

        _ultimaUbicacionValida =
            punto;

        _zoomActual =
            16;
      } finally {
        _movimientoProgramatico =
            false;
      }

      if (mounted) {
        setState(() {});
      }

      return;
    }

    await _irAMiUbicacion();
  }

  // ============================================================
  // ZOOM
  //
  // Optimización:
  // no usamos queryCameraPosition().
  //
  // _zoomActual ya se mantiene actualizado por onCameraMove.
  // ============================================================

  Future<void> _acercar() async {
    final controller =
        _mapController;

    if (controller == null) {
      return;
    }

    final double zoom =
        (_zoomActual + 1)
            .clamp(
              _zoomMinimo,
              _zoomMaximo,
            )
            .toDouble();

    _zoomActual =
        zoom;

    _movimientoProgramatico =
        true;

    try {
      await controller.animateCamera(
        CameraUpdate.zoomTo(
          zoom,
        ),
      );
    } finally {
      _movimientoProgramatico =
          false;
    }
  }

  Future<void> _alejar() async {
    final controller =
        _mapController;

    if (controller == null) {
      return;
    }

    final double zoom =
        (_zoomActual - 1)
            .clamp(
              _zoomMinimo,
              _zoomMaximo,
            )
            .toDouble();

    _zoomActual =
        zoom;

    _movimientoProgramatico =
        true;

    try {
      await controller.animateCamera(
        CameraUpdate.zoomTo(
          zoom,
        ),
      );
    } finally {
      _movimientoProgramatico =
          false;
    }
  }

  // ============================================================
  // MENSAJES
  // ============================================================

  void _mostrarMensaje(
    String mensaje,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    )
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration:
              const Duration(
            milliseconds:
                1600,
          ),
          content: Text(
            mensaje,
          ),
        ),
      );
  }

  // ============================================================
  // BOTÓN MAPA
  // ============================================================

  Widget _botonMapa({
    required String tag,
    required IconData icon,
    required VoidCallback onPressed,
    required bool oscuro,
  }) {
    return FloatingActionButton.small(
      heroTag:
          tag,

      elevation:
          2,

      backgroundColor:
          oscuro
              ? _panelOscuro
              : Colors.white,

      foregroundColor:
          _naranjaPrincipal,

      onPressed:
          onPressed,

      child: Icon(
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
    final bool oscuro =
        Theme.of(context).brightness ==
            Brightness.dark;

    final Color fondo =
        oscuro
            ? _fondoOscuro
            : _fondoClaro;

    final Color panel =
        oscuro
            ? _panelOscuro
            : Colors.white;

    final Color texto =
        oscuro
            ? Colors.white
            : const Color(
                0xFF512A12,
              );

    // ==========================================================
    // PREPARANDO
    // ==========================================================

    if (_preparandoUbicacion) {
      return Scaffold(
        backgroundColor:
            fondo,

        appBar:
            AppBar(
          title:
              const Text(
            'Ubicar emprendimiento',
          ),
        ),

        body:
            const Center(
          child:
              CircularProgressIndicator(
            color:
                _naranjaPrincipal,
          ),
        ),
      );
    }

    // ==========================================================
    // PANTALLA
    // ==========================================================

    return Scaffold(
      backgroundColor:
          fondo,

      appBar:
          AppBar(
        title:
            const Text(
          'Ubicar emprendimiento',
        ),
      ),

      body:
          Stack(
        children: [
          // ====================================================
          // MAPA
          // ====================================================

          MapLibreMap(
            key:
                ValueKey(
              oscuro
                  ? 'selector-dark'
                  : 'selector-light',
            ),

            styleString:
                oscuro
                    ? _estiloOscuro
                    : _estiloClaro,

            initialCameraPosition:
                CameraPosition(
              target:
                  _centroActual,

              zoom:
                  _zoomActual,
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

            // ==================================================
            // ESTA PANTALLA ES SOLO PARA ELEGIR UN PUNTO.
            //
            // Desactivar rotación e inclinación:
            //
            // - reduce trabajo de GPU
            // - hace más fácil colocar el pin
            // - evita movimientos accidentales
            // ==================================================

            rotateGesturesEnabled:
                false,

            tiltGesturesEnabled:
                false,

            compassEnabled:
                false,

            myLocationEnabled:
                false,

            myLocationTrackingMode:
                MyLocationTrackingMode.none,

            onMapCreated:
                _onMapCreated,

            onStyleLoadedCallback:
                _onStyleLoaded,

            onCameraMove:
                _onCameraMove,

            onCameraIdle:
                _onCameraIdle,
          ),

          // ====================================================
          // CARGANDO ESTILO
          // ====================================================

          if (!_mapaListo)
            Container(
              color:
                  fondo.withValues(
                alpha:
                    0.75,
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
          // INSTRUCCIÓN
          // ====================================================

          SafeArea(
            child:
                Align(
              alignment:
                  Alignment.topCenter,

              child:
                  Container(
                margin:
                    const EdgeInsets.fromLTRB(
                  16,
                  12,
                  80,
                  0,
                ),

                padding:
                    const EdgeInsets.symmetric(
                  horizontal:
                      14,

                  vertical:
                      11,
                ),

                decoration:
                    BoxDecoration(
                  color:
                      panel.withValues(
                    alpha:
                        0.95,
                  ),

                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                ),

                child:
                    Row(
                  children: [
                    const Icon(
                      Icons.touch_app_outlined,

                      color:
                          _naranjaPrincipal,
                    ),

                    const SizedBox(
                      width:
                          10,
                    ),

                    Expanded(
                      child:
                          Text(
                        'Mueve el mapa y coloca el pin dentro de El Salvador.',

                        style:
                            TextStyle(
                          color:
                              texto,

                          fontSize:
                              13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ====================================================
          // PIN CENTRAL
          // ====================================================

          IgnorePointer(
            child:
                Center(
              child:
                  Transform.translate(
                offset:
                    const Offset(
                  0,
                  -28,
                ),

                child:
                    Column(
                  mainAxisSize:
                      MainAxisSize.min,

                  children: [
                    AnimatedScale(
                      duration:
                          const Duration(
                        milliseconds:
                            100,
                      ),

                      scale:
                          _moviendoMapa
                              ? 1.07
                              : 1,

                      child:
                          Container(
                        width:
                            56,

                        height:
                            56,

                        decoration:
                            BoxDecoration(
                          color:
                              _naranjaPrincipal,

                          shape:
                              BoxShape.circle,

                          border:
                              Border.all(
                            color:
                                Colors.white,

                            width:
                                4,
                          ),

                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.black
                                      .withValues(
                                alpha:
                                    0.22,
                              ),

                              blurRadius:
                                  8,

                              offset:
                                  const Offset(
                                0,
                                3,
                              ),
                            ),
                          ],
                        ),

                        child:
                            const Icon(
                          Icons.storefront_outlined,

                          color:
                              Colors.white,

                          size:
                              28,
                        ),
                      ),
                    ),

                    Container(
                      width:
                          4,

                      height:
                          27,

                      color:
                          _naranjaPrincipal,
                    ),

                    Container(
                      width:
                          14,

                      height:
                          6,

                      decoration:
                          BoxDecoration(
                        color:
                            Colors.black.withValues(
                          alpha:
                              0.20,
                        ),

                        borderRadius:
                            BorderRadius.circular(
                          20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ====================================================
          // CONTROLES
          // ====================================================

          Positioned(
            right:
                15,

            top:
                14,

            child:
                SafeArea(
              child:
                  Column(
                children: [
                  _botonMapa(
                    tag:
                        'selectorMas',

                    icon:
                        Icons.add,

                    onPressed:
                        _acercar,

                    oscuro:
                        oscuro,
                  ),

                  const SizedBox(
                    height:
                        10,
                  ),

                  _botonMapa(
                    tag:
                        'selectorMenos',

                    icon:
                        Icons.remove,

                    onPressed:
                        _alejar,

                    oscuro:
                        oscuro,
                  ),

                  const SizedBox(
                    height:
                        10,
                  ),

                  _botonMapa(
                    tag:
                        'selectorGPS',

                    icon:
                        Icons.my_location,

                    onPressed:
                        _irAMiUbicacion,

                    oscuro:
                        oscuro,
                  ),

                  if (widget.ubicacionInicial !=
                      null) ...[
                    const SizedBox(
                      height:
                          10,
                    ),

                    _botonMapa(
                      tag:
                          'selectorOriginal',

                      icon:
                          Icons.history,

                      onPressed:
                          _volverUbicacionInicial,

                      oscuro:
                          oscuro,
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ====================================================
          // PANEL INFERIOR
          // ====================================================

          Positioned(
            left:
                15,

            right:
                15,

            bottom:
                15,

            child:
                SafeArea(
              top:
                  false,

              child:
                  Container(
                padding:
                    const EdgeInsets.all(
                  16,
                ),

                decoration:
                    BoxDecoration(
                  color:
                      panel.withValues(
                    alpha:
                        0.97,
                  ),

                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),

                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(
                        alpha:
                            0.14,
                      ),

                      blurRadius:
                          12,
                    ),
                  ],
                ),

                child:
                    Column(
                  mainAxisSize:
                      MainAxisSize.min,

                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,

                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,

                          color:
                              _naranjaPrincipal,
                        ),

                        const SizedBox(
                          width:
                              8,
                        ),

                        Expanded(
                          child:
                              Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,

                            children: [
                              Text(
                                'Ubicación seleccionada',

                                style:
                                    TextStyle(
                                  color:
                                      texto,

                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),

                              const SizedBox(
                                height:
                                    3,
                              ),

                              Text(
                                '${_centroActual.latitude.toStringAsFixed(6)}, '
                                '${_centroActual.longitude.toStringAsFixed(6)}',

                                style:
                                    TextStyle(
                                  color:
                                      texto.withValues(
                                    alpha:
                                        0.70,
                                  ),

                                  fontSize:
                                      12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height:
                          14,
                    ),

                    SizedBox(
                      height:
                          50,

                      child:
                          FilledButton.icon(
                        style:
                            FilledButton.styleFrom(
                          backgroundColor:
                              _naranjaPrincipal,

                          foregroundColor:
                              Colors.white,

                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              14,
                            ),
                          ),
                        ),

                        onPressed:
                            !_mapaListo ||
                                    _confirmando ||
                                    !_estaDentroDeElSalvador(
                                      _centroActual,
                                    )
                                ? null
                                : _confirmarUbicacion,

                        icon:
                            _confirmando
                                ? const SizedBox(
                                    width:
                                        19,

                                    height:
                                        19,

                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth:
                                          2,

                                      color:
                                          Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.check_circle_outline,
                                  ),

                        label:
                            Text(
                          _confirmando
                              ? 'Confirmando...'
                              : 'Confirmar ubicación',

                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}