import 'package:flutter/material.dart';
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

  static const LatLng _centroElSalvador = LatLng(
    13.7942,
    -88.8965,
  );

  static final LatLngBounds _limitesElSalvador = LatLngBounds(
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

  static const String _estiloClaro =
      'assets/mapas/openfreemap_mercali_light.json';

  static const String _estiloOscuro =
      'assets/mapas/openfreemap_mercali_dark.json';

  static const Color _naranjaPrincipal = Color(0xFFFF7E01);
  static const Color _panelOscuro = Color(0xFF2A2045);
  static const Color _fondoOscuro = Color(0xFF171320);
  static const Color _fondoClaro = Color(0xFFFFF6ED);

  LatLng _centroActual = _centroElSalvador;

  double _zoomActual = 8.5;

  bool _preparandoUbicacion = true;
  bool _mapaListo = false;
  bool _moviendoMapa = false;
  bool _confirmando = false;

  @override
  void initState() {
    super.initState();

    _prepararUbicacionInicial();
  }

  Future<void> _prepararUbicacionInicial() async {
    if (widget.ubicacionInicial != null) {
      _centroActual = widget.ubicacionInicial!;
      _zoomActual = 16;

      if (mounted) {
        setState(() {
          _preparandoUbicacion = false;
        });
      }

      return;
    }

    try {
      final bool servicio =
          await Geolocator.isLocationServiceEnabled();

      if (!servicio) {
        _usarCentroElSalvador();
        return;
      }

      LocationPermission permiso =
          await Geolocator.checkPermission();

      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }

      if (permiso == LocationPermission.denied ||
          permiso == LocationPermission.deniedForever) {
        _usarCentroElSalvador();
        return;
      }

      const settings = LocationSettings(
        accuracy: LocationAccuracy.high,
      );

      final Position posicion =
          await Geolocator.getCurrentPosition(
        locationSettings: settings,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _centroActual = LatLng(
          posicion.latitude,
          posicion.longitude,
        );

        _zoomActual = 16;

        _preparandoUbicacion = false;
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
      _centroActual = _centroElSalvador;
      _zoomActual = 8.5;
      _preparandoUbicacion = false;
    });
  }

  void _onMapCreated(
    MapLibreMapController controller,
  ) {
    _mapController = controller;
  }

  void _onStyleLoaded() {
    if (!mounted) {
      return;
    }

    setState(() {
      _mapaListo = true;
    });
  }

  void _onCameraMove(
    CameraPosition position,
  ) {
    _centroActual = position.target;
    _zoomActual = position.zoom;

    if (!_moviendoMapa && mounted) {
      setState(() {
        _moviendoMapa = true;
      });
    }
  }

  Future<void> _onCameraIdle() async {
    final controller = _mapController;

    if (controller != null) {
      try {
        final CameraPosition? posicion =
            await controller.queryCameraPosition();

        if (posicion != null) {
          _centroActual = posicion.target;
          _zoomActual = posicion.zoom;

          debugPrint(
            'CENTRO REAL: '
            '${_centroActual.latitude}, '
            '${_centroActual.longitude}',
          );
        }
      } catch (e) {
        debugPrint(
          'ERROR LEYENDO CÁMARA: $e',
        );
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _moviendoMapa = false;
    });
  }

  Future<void> _confirmarUbicacion() async {
    if (_confirmando) {
      return;
    }

    final controller = _mapController;

    if (controller == null) {
      _mostrarMensaje(
        'El mapa aún no está listo',
      );

      return;
    }

    setState(() {
      _confirmando = true;
    });

    try {
      final CameraPosition? posicion =
          await controller.queryCameraPosition();

      final LatLng ubicacionReal =
          posicion?.target ?? _centroActual;

      debugPrint(
        '================================',
      );

      debugPrint(
        'UBICACIÓN CONFIRMADA',
      );

      debugPrint(
        'LATITUD: ${ubicacionReal.latitude}',
      );

      debugPrint(
        'LONGITUD: ${ubicacionReal.longitude}',
      );

      debugPrint(
        '================================',
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(
        context,
        ubicacionReal,
      );
    } catch (e) {
      debugPrint(
        'ERROR CONFIRMANDO UBICACIÓN: $e',
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(
        context,
        _centroActual,
      );
    }
  }

  Future<void> _irAMiUbicacion() async {
    final controller = _mapController;

    if (controller == null) {
      return;
    }

    try {
      final bool servicio =
          await Geolocator.isLocationServiceEnabled();

      if (!servicio) {
        _mostrarMensaje(
          'Activa la ubicación del dispositivo',
        );

        return;
      }

      LocationPermission permiso =
          await Geolocator.checkPermission();

      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }

      if (permiso == LocationPermission.denied ||
          permiso == LocationPermission.deniedForever) {
        _mostrarMensaje(
          'No hay permiso de ubicación',
        );

        return;
      }

      const settings = LocationSettings(
        accuracy: LocationAccuracy.high,
      );

      final Position posicion =
          await Geolocator.getCurrentPosition(
        locationSettings: settings,
      );

      final LatLng punto = LatLng(
        posicion.latitude,
        posicion.longitude,
      );

      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          punto,
          16,
        ),
      );

      _centroActual = punto;
      _zoomActual = 16;

      if (mounted) {
        setState(() {});
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

  Future<void> _volverUbicacionInicial() async {
    final controller = _mapController;

    if (controller == null) {
      return;
    }

    if (widget.ubicacionInicial != null) {
      final LatLng punto =
          widget.ubicacionInicial!;

      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          punto,
          16,
        ),
      );

      _centroActual = punto;
      _zoomActual = 16;

      if (mounted) {
        setState(() {});
      }

      return;
    }

    await _irAMiUbicacion();
  }

  Future<void> _acercar() async {
    final controller = _mapController;

    if (controller == null) {
      return;
    }

    try {
      final CameraPosition? posicion =
          await controller.queryCameraPosition();

      final double zoomActual =
          posicion?.zoom ?? _zoomActual;

      final double zoom =
          (zoomActual + 1)
              .clamp(
                _zoomMinimo,
                _zoomMaximo,
              )
              .toDouble();

      await controller.animateCamera(
        CameraUpdate.zoomTo(
          zoom,
        ),
      );
    } catch (e) {
      debugPrint(
        'ERROR ZOOM +: $e',
      );
    }
  }

  Future<void> _alejar() async {
    final controller = _mapController;

    if (controller == null) {
      return;
    }

    try {
      final CameraPosition? posicion =
          await controller.queryCameraPosition();

      final double zoomActual =
          posicion?.zoom ?? _zoomActual;

      final double zoom =
          (zoomActual - 1)
              .clamp(
                _zoomMinimo,
                _zoomMaximo,
              )
              .toDouble();

      await controller.animateCamera(
        CameraUpdate.zoomTo(
          zoom,
        ),
      );
    } catch (e) {
      debugPrint(
        'ERROR ZOOM -: $e',
      );
    }
  }

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
          content: Text(
            mensaje,
          ),
        ),
      );
  }

  Widget _botonMapa({
    required String tag,
    required IconData icon,
    required VoidCallback onPressed,
    required bool oscuro,
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
      onPressed: onPressed,
      child: Icon(
        icon,
      ),
    );
  }

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

    if (_preparandoUbicacion) {
      return Scaffold(
        backgroundColor: fondo,
        appBar: AppBar(
          title: const Text(
            'Ubicar emprendimiento',
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: _naranjaPrincipal,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: fondo,
      appBar: AppBar(
        title: const Text(
          'Ubicar emprendimiento',
        ),
      ),
      body: Stack(
        children: [
          MapLibreMap(
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

          SafeArea(
            child: Align(
              alignment:
                  Alignment.topCenter,
              child: Container(
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
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black
                              .withValues(
                        alpha:
                            0.15,
                      ),
                      blurRadius:
                          10,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons
                          .touch_app_outlined,
                      color:
                          _naranjaPrincipal,
                    ),
                    const SizedBox(
                      width:
                          10,
                    ),
                    Expanded(
                      child: Text(
                        'Mueve el mapa y coloca el pin sobre la ubicación exacta del emprendimiento.',
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

          IgnorePointer(
            child: Center(
              child: Transform.translate(
                offset:
                    const Offset(
                  0,
                  -28,
                ),
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    AnimatedScale(
                      duration:
                          const Duration(
                        milliseconds:
                            120,
                      ),
                      scale:
                          _moviendoMapa
                              ? 1.10
                              : 1,
                      child: Container(
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
                                    0.28,
                              ),
                              blurRadius:
                                  10,
                              offset:
                                  const Offset(
                                0,
                                4,
                              ),
                            ),
                          ],
                        ),
                        child:
                            const Icon(
                          Icons
                              .storefront_outlined,
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
                            Colors.black
                                .withValues(
                          alpha:
                              0.23,
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

          Positioned(
            right:
                15,
            top:
                14,
            child: SafeArea(
              child: Column(
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

                  if (widget
                          .ubicacionInicial !=
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

          Positioned(
            left:
                15,
            right:
                15,
            bottom:
                15,
            child: SafeArea(
              top:
                  false,
              child: Container(
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
                          Colors.black
                              .withValues(
                        alpha:
                            0.18,
                      ),
                      blurRadius:
                          16,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .stretch,
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
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
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
                                    _confirmando
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
                                    Icons
                                        .check_circle_outline,
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