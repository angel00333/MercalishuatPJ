import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class SeleccionarUbicacionScreen
    extends StatefulWidget {
  final LatLng? ubicacionInicial;

  const SeleccionarUbicacionScreen({
    super.key,
    this.ubicacionInicial,
  });

  @override
  State<SeleccionarUbicacionScreen>
      createState() =>
          _SeleccionarUbicacionScreenState();
}

class _SeleccionarUbicacionScreenState
    extends State<
        SeleccionarUbicacionScreen> {
  // ============================================================
  // CONTROLADOR
  // ============================================================

  MapLibreMapController?
      _mapController;

  // ============================================================
  // EL SALVADOR
  // ============================================================

  static const LatLng
      _centroElSalvador =
      LatLng(
    13.7942,
    -88.8965,
  );

  static final LatLngBounds
      _limitesElSalvador =
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

  static const double
      _zoomMinimo = 7.4;

  static const double
      _zoomMaximo = 19.0;

  // ============================================================
  // ESTILOS
  // ============================================================

  static const String
      _estiloClaro =
      'assets/mapas/openfreemap_mercali_light.json';

  static const String
      _estiloOscuro =
      'assets/mapas/openfreemap_mercali_dark.json';

  // ============================================================
  // COLORES
  // ============================================================

  static const Color
      _naranjaPrincipal =
      Color(
    0xFFFF7E01,
  );

  static const Color
      _panelOscuro =
      Color(
    0xFF2A2045,
  );

  static const Color
      _fondoOscuro =
      Color(
    0xFF171320,
  );

  static const Color
      _fondoClaro =
      Color(
    0xFFFFF6ED,
  );

  // ============================================================
  // POSICIÓN
  // ============================================================

  late LatLng
      _centroActual;

  double _zoomActual =
      15.0;

  bool _mapaListo =
      false;

  bool _moviendoMapa =
      false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _centroActual =
        widget.ubicacionInicial ??
            _centroElSalvador;

    if (widget.ubicacionInicial ==
        null) {
      _zoomActual =
          8.5;
    }
  }

  // ============================================================
  // MAPA CREADO
  // ============================================================

  void _onMapCreated(
    MapLibreMapController controller,
  ) {
    _mapController =
        controller;
  }

  // ============================================================
  // ESTILO CARGADO
  // ============================================================

  void _onStyleLoaded() {
    if (!mounted) {
      return;
    }

    setState(() {
      _mapaListo =
          true;
    });
  }

  // ============================================================
  // MOVER CÁMARA
  // ============================================================

  void _onCameraMove(
    CameraPosition position,
  ) {
    _centroActual =
        position.target;

    _zoomActual =
        position.zoom;

    if (!_moviendoMapa &&
        mounted) {
      setState(() {
        _moviendoMapa =
            true;
      });
    }
  }

  // ============================================================
  // CÁMARA DETENIDA
  // ============================================================

  void _onCameraIdle() {
    if (!mounted) {
      return;
    }

    setState(() {
      _moviendoMapa =
          false;
    });
  }

  // ============================================================
  // CONFIRMAR
  // ============================================================

  void _confirmarUbicacion() {
    Navigator.pop(
      context,
      _centroActual,
    );
  }

  // ============================================================
  // CENTRAR EN UBICACIÓN INICIAL
  // ============================================================

  Future<void>
      _volverUbicacionInicial() async {
    final controller =
        _mapController;

    if (controller == null) {
      return;
    }

    final LatLng destino =
        widget.ubicacionInicial ??
            _centroElSalvador;

    await controller.animateCamera(
      CameraUpdate
          .newLatLngZoom(
        destino,
        widget.ubicacionInicial !=
                null
            ? 15.0
            : 8.5,
      ),
    );
  }

  // ============================================================
  // ZOOM +
  // ============================================================

  Future<void> _acercar() async {
    final controller =
        _mapController;

    if (controller == null) {
      return;
    }

    final zoom =
        (_zoomActual + 1)
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
  }

  // ============================================================
  // ZOOM -
  // ============================================================

  Future<void> _alejar() async {
    final controller =
        _mapController;

    if (controller == null) {
      return;
    }

    final zoom =
        (_zoomActual - 1)
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
  }

  // ============================================================
  // BOTÓN
  // ============================================================

  Widget _botonMapa({
    required String tag,
    required IconData icono,
    required VoidCallback onPressed,
    required bool oscuro,
  }) {
    return FloatingActionButton.small(
      heroTag:
          tag,
      elevation:
          3,
      backgroundColor:
          oscuro
              ? _panelOscuro
              : Colors.white,
      foregroundColor:
          _naranjaPrincipal,
      onPressed:
          onPressed,
      child:
          Icon(
        icono,
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
        Theme.of(context)
                .brightness ==
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
                  ? 'seleccionar-dark'
                  : 'seleccionar-light',
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
          // CARGANDO
          // ====================================================

          if (!_mapaListo)
            Container(
              color:
                  fondo.withValues(
                alpha:
                    0.80,
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
          // INSTRUCCIONES
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
                      10,
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

                  boxShadow:
                      [
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

                child:
                    Row(
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
                      child:
                          Text(
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

          // ====================================================
          // PIN FIJO CENTRAL
          // ====================================================

          IgnorePointer(
            child:
                Center(
              child:
                  Transform.translate(
                offset:
                    const Offset(
                  0,
                  -24,
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
                            160,
                      ),

                      scale:
                          _moviendoMapa
                              ? 1.15
                              : 1.0,

                      child:
                          Container(
                        width:
                            54,
                        height:
                            54,

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

                          boxShadow:
                              [
                            BoxShadow(
                              color:
                                  Colors.black
                                      .withValues(
                                alpha:
                                    0.28,
                              ),
                              blurRadius:
                                  9,
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
                          Icons.storefront,
                          color:
                              Colors.white,
                          size:
                              27,
                        ),
                      ),
                    ),

                    Container(
                      width:
                          4,
                      height:
                          26,

                      color:
                          _naranjaPrincipal,
                    ),

                    Container(
                      width:
                          12,
                      height:
                          6,

                      decoration:
                          BoxDecoration(
                        color:
                            Colors.black
                                .withValues(
                          alpha:
                              0.22,
                        ),
                        borderRadius:
                            BorderRadius.circular(
                          50,
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
                        'selectorZoomMas',
                    icono:
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
                        'selectorZoomMenos',
                    icono:
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
                        'selectorCentrar',
                    icono:
                        Icons
                            .center_focus_strong,
                    onPressed:
                        _volverUbicacionInicial,
                    oscuro:
                        oscuro,
                  ),
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

                  boxShadow:
                      [
                    BoxShadow(
                      color:
                          Colors.black
                              .withValues(
                        alpha:
                            oscuro
                                ? 0.35
                                : 0.18,
                      ),
                      blurRadius:
                          16,
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
                          Icons
                              .location_on,
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
                            _mapaListo
                                ? _confirmarUbicacion
                                : null,

                        icon:
                            const Icon(
                          Icons
                              .check_circle_outline,
                        ),

                        label:
                            const Text(
                          'Confirmar ubicación',
                          style:
                              TextStyle(
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