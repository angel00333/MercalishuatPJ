import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../helpers/chat_helper.dart';
import '../models/emprendimiento.dart';
import '../services/emprendimiento_service.dart';
import '../services/ruta_service.dart';

class MapaScreen extends StatefulWidget {
  const MapaScreen({
    super.key,
  });

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // ============================================================
  // MAPA
  // ============================================================

  MapLibreMapController? _mapController;

  bool _moviendoCamaraProgramaticamente = false;

  // ============================================================
  // EL SALVADOR
  // ============================================================

  static const LatLng _centroElSalvador = LatLng(
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

  // ============================================================
  // CÁMARA
  // ============================================================

  LatLng _centroCamaraActual =
      _centroElSalvador;

  double _zoomActual = 8.5;

  double _bearingActual = 0.0;

  double _tiltActual = 0.0;

  bool _primeraCargaEstilo = true;

  // ============================================================
  // ROTACIÓN / BRÚJULA
  // ============================================================

  /*
   * La rotación inicia ACTIVA.
   *
   * La brújula:
   * - siempre aparece desde que abre el mapa
   * - funciona mientras la rotación está activa
   * - se deshabilita cuando bloqueamos la rotación
   * - NO mueve el mapa al activar/desactivar rotación
   */
  bool _rotacionActiva = true;

  // ============================================================
  // EMPRENDIMIENTOS
  // ============================================================

  static const String _sourceEmprendimientos =
      'merc-emprendimientos-source';

  static const String _layerEmprendimientos =
      'merc-emprendimientos-layer';

  static const String _iconoTienda =
      'merc-marker-tienda';

  bool _iconoTiendaCargado = false;

  bool _capaEmprendimientosCargada = false;

  bool _cargandoEmprendimientos = false;

  List<Emprendimiento> _emprendimientos = [];

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

  static const Color _verdeRuta = Color(
    0xFF11C031,
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
  // GEOJSON
  // ============================================================

  Map<String, dynamic>? _admin0;
  Map<String, dynamic>? _admin1;
  Map<String, dynamic>? _admin2;
  Map<String, dynamic>? _admin3;
  Map<String, dynamic>? _mascara;

  bool _geoJsonCargado = false;
  bool _estiloCargado = false;
  bool _capasCargadas = false;

  String? _error;

  // ============================================================
  // GPS
  // ============================================================

  Position? _posicionUsuario;

  Circle? _marcadorUsuario;

  LatLng? _puntoGpsVisual;

  StreamSubscription<Position>? _streamPosicion;

  Timer? _timerAnimacionGps;

  bool _obteniendoUbicacion = false;

  bool _actualizacionContinua = false;

  bool _seguirUsuario = false;

  bool _actualizandoMarcadorGps = false;

  DateTime? _ultimaActualizacionCamara;

  static const int _duracionAnimacionGpsMs = 450;

  static const int _fpsMarcadorGps = 30;

  static const int _intervaloCamaraGpsMs = 350;

  // ============================================================
  // RUTA
  // ============================================================

  bool _rutaCreada = false;

  bool _calculandoRuta = false;

  Emprendimiento? _destinoActual;

  double? _distanciaRuta;

  double? _duracionRuta;

  Map<String, dynamic>? _geoJsonRutaActual;

  // ============================================================
  // TAPS
  // ============================================================

  bool _abriendoEmprendimiento = false;

  int? _ultimoEmprendimientoTocado;

  DateTime? _ultimoTapEmprendimiento;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _cargarGeoJson();
    _cargarEmprendimientos();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _streamPosicion?.cancel();
    _timerAnimacionGps?.cancel();

    super.dispose();
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

      _admin0 = jsonDecode(
        textos[0],
      );

      _admin1 = jsonDecode(
        textos[1],
      );

      _admin2 = jsonDecode(
        textos[2],
      );

      _admin3 = jsonDecode(
        textos[3],
      );

      _mascara = _crearMascara(
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
      debugPrint(
        'ERROR GEOJSON: $e',
      );

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

    final features = admin0['features'];

    if (features is List) {
      for (final feature in features) {
        final geometry =
            feature['geometry'];

        if (geometry == null) {
          continue;
        }

        final String tipo =
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
              exterior.reversed
                  .toList(),
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
  // EMPRENDIMIENTOS
  // ============================================================

  Future<void>
      _cargarEmprendimientos() async {
    if (_cargandoEmprendimientos) {
      return;
    }

    if (mounted) {
      setState(() {
        _cargandoEmprendimientos =
            true;
      });
    }

    try {
      final resultado =
          await EmprendimientoService
              .listar();

      if (!mounted) {
        return;
      }

      if (resultado['success'] == true) {
        final raw =
            resultado['emprendimientos'];

        if (raw is List) {
          final lista = raw
              .whereType<Emprendimiento>()
              .where(
                (e) =>
                    e.latitud != null &&
                    e.longitud != null,
              )
              .toList();

          setState(() {
            _emprendimientos =
                lista;
          });

          if (_estiloCargado &&
              _iconoTiendaCargado) {
            await _dibujarEmprendimientos();
          }
        }
      }
    } catch (e) {
      debugPrint(
        'ERROR CARGANDO EMPRENDIMIENTOS: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _cargandoEmprendimientos =
              false;
        });
      }
    }
  }

  // ============================================================
  // MAPA CREADO
  // ============================================================

  void _onMapCreated(
    MapLibreMapController controller,
  ) {
    _mapController = controller;

    controller.onFeatureTapped.add(
      _onFeatureTapped,
    );
  }

  // ============================================================
  // FEATURE TAP
  // ============================================================

  void _onFeatureTapped(
    Point<double> point,
    LatLng coordinates,
    String id,
    String layerId,
    Annotation? annotation,
  ) {
    if (layerId !=
        _layerEmprendimientos) {
      return;
    }

    final emprendimientoId =
        int.tryParse(
      id,
    );

    if (emprendimientoId == null) {
      return;
    }

    _abrirEmprendimientoPorId(
      emprendimientoId,
    );
  }

  // ============================================================
  // MAP CLICK
  // ============================================================

  Future<void> _onMapClick(
    Point<double> point,
    LatLng coordinates,
  ) async {
    final controller =
        _mapController;

    if (controller == null ||
        !_capaEmprendimientosCargada) {
      return;
    }

    try {
      final features =
          await controller
              .queryRenderedFeatures(
        point,
        const [
          _layerEmprendimientos,
        ],
        null,
      );

      for (final rawFeature in features) {
        if (rawFeature is! Map) {
          continue;
        }

        final feature =
            Map<String, dynamic>.from(
          rawFeature,
        );

        int? emprendimientoId;

        final id = feature['id'];

        if (id != null) {
          emprendimientoId =
              int.tryParse(
            id.toString(),
          );
        }

        if (emprendimientoId ==
            null) {
          final propiedades =
              feature['properties'];

          if (propiedades is Map) {
            final p =
                Map<String, dynamic>.from(
              propiedades,
            );

            emprendimientoId =
                int.tryParse(
              p['emprendimiento_id']
                      ?.toString() ??
                  '',
            );
          }
        }

        if (emprendimientoId !=
            null) {
          await _abrirEmprendimientoPorId(
            emprendimientoId,
          );

          return;
        }
      }
    } catch (e) {
      debugPrint(
        'ERROR TAP MAPA: $e',
      );
    }
  }

  // ============================================================
  // ABRIR EMPRENDIMIENTO
  // ============================================================

  Future<void>
      _abrirEmprendimientoPorId(
    int id,
  ) async {
    if (!mounted) {
      return;
    }

    final ahora =
        DateTime.now();

    if (_ultimoEmprendimientoTocado ==
            id &&
        _ultimoTapEmprendimiento !=
            null &&
        ahora
                .difference(
                  _ultimoTapEmprendimiento!,
                )
                .inMilliseconds <
            650) {
      return;
    }

    if (_abriendoEmprendimiento) {
      return;
    }

    Emprendimiento? seleccionado;

    for (final tienda
        in _emprendimientos) {
      if (tienda.id == id) {
        seleccionado = tienda;
        break;
      }
    }

    if (seleccionado == null) {
      return;
    }

    _ultimoEmprendimientoTocado =
        id;

    _ultimoTapEmprendimiento =
        ahora;

    _abriendoEmprendimiento =
        true;

    try {
      await _mostrarOpcionesEmprendimiento(
        seleccionado,
      );
    } finally {
      _abriendoEmprendimiento =
          false;
    }
  }

  // ============================================================
  // ESTILO CARGADO
  // ============================================================

  Future<void>
      _onStyleLoaded() async {
    _capasCargadas = false;

    _marcadorUsuario = null;

    _iconoTiendaCargado = false;

    _capaEmprendimientosCargada =
        false;

    _rutaCreada = false;

    if (!mounted) {
      return;
    }

    setState(() {
      _estiloCargado = true;
    });

    if (_geoJsonCargado) {
      await _agregarCapas();
    }

    await _cargarIconoTienda();

    await _dibujarEmprendimientos();

    if (_geoJsonRutaActual != null) {
      await _dibujarRuta(
        _geoJsonRutaActual!,
      );
    }

    if (_puntoGpsVisual != null) {
      await _actualizarMarcadorGps(
        _puntoGpsVisual!,
      );
    } else if (_posicionUsuario !=
        null) {
      final punto = LatLng(
        _posicionUsuario!.latitude,
        _posicionUsuario!.longitude,
      );

      _puntoGpsVisual = punto;

      await _actualizarMarcadorGps(
        punto,
      );
    }

    if (_primeraCargaEstilo) {
      _primeraCargaEstilo =
          false;
    } else {
      await _restaurarCamara();
    }
  }

  // ============================================================
  // CÁMARA PROGRAMÁTICA
  // ============================================================

  Future<void> _animarCamara(
    CameraUpdate update,
  ) async {
    final controller =
        _mapController;

    if (controller == null) {
      return;
    }

    _moviendoCamaraProgramaticamente =
        true;

    try {
      await controller.animateCamera(
        update,
      );

      await Future<void>.delayed(
        const Duration(
          milliseconds: 70,
        ),
      );
    } catch (e) {
      debugPrint(
        'ERROR MOVIENDO CÁMARA: $e',
      );
    } finally {
      _moviendoCamaraProgramaticamente =
          false;
    }
  }

  Future<void>
      _restaurarCamara() async {
    await _animarCamara(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target:
              _centroCamaraActual,
          zoom:
              _zoomActual,
          bearing:
              _bearingActual,
          tilt:
              _tiltActual,
        ),
      ),
    );
  }

  // ============================================================
  // ICONO TIENDA
  // ============================================================

  Future<void>
      _cargarIconoTienda() async {
    final controller =
        _mapController;

    if (controller == null ||
        _iconoTiendaCargado) {
      return;
    }

    ui.Codec? codec;
    ui.Image? imagen;

    try {
      final ByteData data =
          await rootBundle.load(
        'assets/mapas/marcador_tienda.png',
      );

      final Uint8List bytes =
          data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );

      codec =
          await ui.instantiateImageCodec(
        bytes,
        targetWidth: 96,
      );

      final frame =
          await codec.getNextFrame();

      imagen = frame.image;

      final pngData =
          await imagen.toByteData(
        format:
            ui.ImageByteFormat.png,
      );

      if (pngData == null) {
        return;
      }

      final bytesFinales =
          pngData.buffer.asUint8List(
        pngData.offsetInBytes,
        pngData.lengthInBytes,
      );

      await controller.addImage(
        _iconoTienda,
        bytesFinales,
      );

      _iconoTiendaCargado = true;
    } catch (e) {
      debugPrint(
        'ERROR ICONO: $e',
      );
    } finally {
      imagen?.dispose();
      codec?.dispose();
    }
  }

  // ============================================================
  // CAPAS
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
      final oscuro =
          Theme.of(context)
                  .brightness ==
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

      await controller.addFillLayer(
        'merc-mask',
        'merc-mask-layer',
        FillLayerProperties(
          fillColor:
              oscuro
                  ? '#171320'
                  : '#FFF6ED',
          fillOpacity: 1,
          fillOutlineColor:
              oscuro
                  ? '#171320'
                  : '#FFF6ED',
        ),
      );

      await controller.addFillLayer(
        'merc-admin0',
        'merc-orange-overlay',
        const FillLayerProperties(
          fillColor: '#FF7E01',
          fillOpacity: 0.035,
        ),
      );

      await controller.addLineLayer(
        'merc-admin3',
        'merc-admin3-line',
        const LineLayerProperties(
          lineColor: '#FFC078',
          lineOpacity: 0.65,
          lineWidth: 0.65,
        ),
        minzoom: 13,
      );

      await controller.addLineLayer(
        'merc-admin2',
        'merc-admin2-line',
        const LineLayerProperties(
          lineColor: '#FF9A3D',
          lineOpacity: 0.78,
          lineWidth: 1,
        ),
        minzoom: 10,
      );

      await controller.addLineLayer(
        'merc-admin1',
        'merc-admin1-line',
        const LineLayerProperties(
          lineColor: '#FF7E01',
          lineOpacity: 0.9,
          lineWidth: 1.5,
        ),
        minzoom: 7.5,
      );

      await controller.addLineLayer(
        'merc-admin0',
        'merc-admin0-line',
        const LineLayerProperties(
          lineColor: '#C95400',
          lineOpacity: 1,
          lineWidth: 3,
        ),
      );

      _capasCargadas = true;
    } catch (e) {
      debugPrint(
        'ERROR CAPAS: $e',
      );
    }
  }

  // ============================================================
  // DIBUJAR EMPRENDIMIENTOS
  // ============================================================

  Future<void>
      _dibujarEmprendimientos() async {
    final controller =
        _mapController;

    if (controller == null ||
        !_estiloCargado ||
        !_iconoTiendaCargado) {
      return;
    }

    try {
      final features =
          <Map<String, dynamic>>[];

      for (final emprendimiento
          in _emprendimientos) {
        if (emprendimiento.latitud ==
                null ||
            emprendimiento.longitud ==
                null) {
          continue;
        }

        features.add({
          'type': 'Feature',
          'id':
              emprendimiento.id.toString(),
          'properties': {
            'tipo': 'emprendimiento',
            'nombre':
                emprendimiento.nombre,
            'emprendimiento_id':
                emprendimiento.id,
          },
          'geometry': {
            'type': 'Point',
            'coordinates': [
              emprendimiento.longitud!,
              emprendimiento.latitud!,
            ],
          },
        });
      }

      final geojson =
          <String, dynamic>{
        'type':
            'FeatureCollection',
        'features':
            features,
      };

      if (_capaEmprendimientosCargada) {
        await controller
            .setGeoJsonSource(
          _sourceEmprendimientos,
          geojson,
        );

        return;
      }

      await controller.addGeoJsonSource(
        _sourceEmprendimientos,
        geojson,
      );

      await controller.addSymbolLayer(
        _sourceEmprendimientos,
        _layerEmprendimientos,
        const SymbolLayerProperties(
          iconImage:
              _iconoTienda,
          iconSize:
              0.85,
          iconAnchor:
              'bottom',
          iconAllowOverlap:
              true,
          iconIgnorePlacement:
              true,
          iconOptional:
              false,
          iconOpacity:
              1,
        ),
        enableInteraction:
            true,
      );

      _capaEmprendimientosCargada =
          true;
    } catch (e) {
      debugPrint(
        'ERROR TIENDAS: $e',
      );
    }
  }

  // ============================================================
  // MODAL EMPRENDIMIENTO
  // ============================================================

  Future<void>
      _mostrarOpcionesEmprendimiento(
    Emprendimiento emprendimiento,
  ) async {
    if (!mounted) {
      return;
    }

    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (bottomContext) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.fromLTRB(
              20,
              4,
              20,
              24,
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration:
                          BoxDecoration(
                        color:
                            _naranjaPrincipal,
                        borderRadius:
                            BorderRadius.circular(
                          18,
                        ),
                        image:
                            emprendimiento.imagenUrl !=
                                        null &&
                                    emprendimiento
                                        .imagenUrl!
                                        .isNotEmpty
                                ? DecorationImage(
                                    image:
                                        NetworkImage(
                                      emprendimiento
                                          .imagenUrl!,
                                    ),
                                    fit:
                                        BoxFit.cover,
                                  )
                                : null,
                      ),
                      child:
                          emprendimiento.imagenUrl ==
                                      null ||
                                  emprendimiento
                                      .imagenUrl!
                                      .isEmpty
                              ? const Icon(
                                  Icons.storefront,
                                  color:
                                      Colors.white,
                                  size: 34,
                                )
                              : null,
                    ),
                    const SizedBox(
                      width: 14,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            emprendimiento.nombre,
                            style:
                                const TextStyle(
                              fontSize: 19,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          if (emprendimiento.descripcion !=
                                  null &&
                              emprendimiento
                                  .descripcion!
                                  .isNotEmpty) ...[
                            const SizedBox(
                              height: 4,
                            ),
                            Text(
                              emprendimiento
                                  .descripcion!,
                              maxLines: 2,
                              overflow:
                                  TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(
                            height: 6,
                          ),
                          const Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color:
                                    _naranjaPrincipal,
                                size: 16,
                              ),
                              SizedBox(
                                width: 4,
                              ),
                              Text(
                                'Ubicación disponible',
                                style:
                                    TextStyle(
                                  color:
                                      _naranjaPrincipal,
                                  fontSize: 12,
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 24,
                ),
                SizedBox(
                  height: 50,
                  child:
                      OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(
                        bottomContext,
                      );

                      _mostrarPerfilEmprendimiento(
                        emprendimiento,
                      );
                    },
                    icon: const Icon(
                      Icons
                          .storefront_outlined,
                    ),
                    label: const Text(
                      'Ver perfil del emprendimiento',
                    ),
                  ),
                ),
                const SizedBox(
                  height: 12,
                ),

                // =================================================
                // ENVIAR MENSAJE
                // =================================================

                SizedBox(
                  height: 50,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          _naranjaPrincipal,
                      foregroundColor:
                          Colors.white,
                    ),
                    onPressed:
                        emprendimiento.usuarioId ==
                                null
                            ? null
                            : () {
                                Navigator.pop(
                                  bottomContext,
                                );

                                ChatHelper.abrirChat(
                                  context:
                                      context,
                                  usuarioDestinoId:
                                      emprendimiento
                                          .usuarioId!,
                                  nombreDestino:
                                      emprendimiento
                                          .nombre,
                                );
                              },
                    icon: const Icon(
                      Icons.chat_bubble_outline,
                    ),
                    label: const Text(
                      'Enviar mensaje',
                    ),
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                SizedBox(
                  height: 50,
                  child:
                      FilledButton.icon(
                    style:
                        FilledButton.styleFrom(
                      backgroundColor:
                          _verdeRuta,
                      foregroundColor:
                          Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pop(
                        bottomContext,
                      );

                      _marcarRuta(
                        emprendimiento,
                      );
                    },
                    icon: const Icon(
                      Icons.route,
                    ),
                    label: const Text(
                      'Marcar ruta',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // PERFIL EMPRENDIMIENTO
  // ============================================================

  void _mostrarPerfilEmprendimiento(
    Emprendimiento emprendimiento,
  ) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (perfilContext) {
        return SafeArea(
          child:
              SingleChildScrollView(
            padding:
                const EdgeInsets.all(
              24,
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 52,
                  backgroundColor:
                      _naranjaPrincipal,
                  backgroundImage:
                      emprendimiento.imagenUrl !=
                                  null &&
                              emprendimiento
                                  .imagenUrl!
                                  .isNotEmpty
                          ? NetworkImage(
                              emprendimiento
                                  .imagenUrl!,
                            )
                          : null,
                  child:
                      emprendimiento.imagenUrl ==
                                  null ||
                              emprendimiento
                                  .imagenUrl!
                                  .isEmpty
                          ? const Icon(
                              Icons.storefront,
                              size: 50,
                              color:
                                  Colors.white,
                            )
                          : null,
                ),
                const SizedBox(
                  height: 16,
                ),
                Text(
                  emprendimiento.nombre,
                  textAlign:
                      TextAlign.center,
                  style:
                      const TextStyle(
                    fontSize: 22,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                if (emprendimiento.descripcion !=
                        null &&
                    emprendimiento
                        .descripcion!
                        .isNotEmpty) ...[
                  const SizedBox(
                    height: 12,
                  ),
                  Text(
                    emprendimiento
                        .descripcion!,
                    textAlign:
                        TextAlign.center,
                  ),
                ],
                if (emprendimiento.telefono !=
                        null &&
                    emprendimiento
                        .telefono!
                        .isNotEmpty) ...[
                  const SizedBox(
                    height: 15,
                  ),
                  ListTile(
                    leading:
                        const Icon(
                      Icons.phone_outlined,
                      color:
                          _naranjaPrincipal,
                    ),
                    title:
                        const Text(
                      'Teléfono',
                    ),
                    subtitle:
                        Text(
                      emprendimiento
                          .telefono!,
                    ),
                  ),
                ],
                if (emprendimiento.correoContacto !=
                        null &&
                    emprendimiento
                        .correoContacto!
                        .isNotEmpty)
                  ListTile(
                    leading:
                        const Icon(
                      Icons.email_outlined,
                      color:
                          _naranjaPrincipal,
                    ),
                    title:
                        const Text(
                      'Correo de contacto',
                    ),
                    subtitle:
                        Text(
                      emprendimiento
                          .correoContacto!,
                    ),
                  ),
                const SizedBox(
                  height: 16,
                ),

                // =================================================
                // ENVIAR MENSAJE DESDE PERFIL
                // =================================================

                SizedBox(
                  width:
                      double.infinity,
                  height: 50,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          _naranjaPrincipal,
                      foregroundColor:
                          Colors.white,
                    ),
                    onPressed:
                        emprendimiento.usuarioId ==
                                null
                            ? null
                            : () {
                                Navigator.pop(
                                  perfilContext,
                                );

                                ChatHelper.abrirChat(
                                  context:
                                      context,
                                  usuarioDestinoId:
                                      emprendimiento
                                          .usuarioId!,
                                  nombreDestino:
                                      emprendimiento
                                          .nombre,
                                );
                              },
                    icon: const Icon(
                      Icons.chat_bubble_outline,
                    ),
                    label: const Text(
                      'Enviar mensaje',
                    ),
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                SizedBox(
                  width:
                      double.infinity,
                  height: 50,
                  child:
                      FilledButton.icon(
                    style:
                        FilledButton.styleFrom(
                      backgroundColor:
                          _verdeRuta,
                      foregroundColor:
                          Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pop(
                        perfilContext,
                      );

                      _marcarRuta(
                        emprendimiento,
                      );
                    },
                    icon: const Icon(
                      Icons.route,
                    ),
                    label: const Text(
                      'Cómo llegar',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // GPS / PERMISOS
  // ============================================================

  Future<Position?>
      _obtenerPosicionParaRuta() async {
    final servicio =
        await Geolocator
            .isLocationServiceEnabled();

    if (!servicio) {
      if (mounted) {
        _mostrarDialogoGpsDesactivado();
      }

      return null;
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
        LocationPermission.denied) {
      if (mounted) {
        _mostrarMensaje(
          'Permiso de ubicación denegado.',
        );
      }

      return null;
    }

    if (permiso ==
        LocationPermission
            .deniedForever) {
      if (mounted) {
        _mostrarDialogoPermisoPermanente();
      }

      return null;
    }

    const settings =
        LocationSettings(
      accuracy:
          LocationAccuracy
              .bestForNavigation,
    );

    return Geolocator
        .getCurrentPosition(
      locationSettings:
          settings,
    );
  }

  // ============================================================
  // GPS
  // ============================================================

  Future<void>
      _obtenerMiUbicacion() async {
    if (_obteniendoUbicacion) {
      return;
    }

    /*
     * GPS activo pero el usuario movió el mapa:
     * vuelve a seguirlo.
     */
    if (_actualizacionContinua &&
        !_seguirUsuario) {
      final posicion =
          _posicionUsuario;

      if (posicion != null) {
        _seguirUsuario = true;

        await _centrarEnUsuario(
          LatLng(
            posicion.latitude,
            posicion.longitude,
          ),
          zoom: max(
            _zoomActual,
            16,
          ),
        );

        if (mounted) {
          setState(() {});
        }
      }

      return;
    }

    /*
     * GPS activo y siguiendo:
     * apagar.
     */
    if (_actualizacionContinua &&
        _seguirUsuario) {
      await _detenerActualizacionContinua();

      _mostrarMensaje(
        'Seguimiento GPS detenido',
      );

      return;
    }

    setState(() {
      _obteniendoUbicacion =
          true;
    });

    try {
      final posicion =
          await _obtenerPosicionParaRuta();

      if (posicion == null ||
          !mounted) {
        return;
      }

      _posicionUsuario =
          posicion;

      final punto = LatLng(
        posicion.latitude,
        posicion.longitude,
      );

      _puntoGpsVisual =
          punto;

      await _actualizarMarcadorGps(
        punto,
      );

      _seguirUsuario = true;

      await _centrarEnUsuario(
        punto,
        zoom: 17,
      );

      await _iniciarActualizacionContinua();

      if (mounted) {
        setState(() {});
      }
    } finally {
      if (mounted) {
        setState(() {
          _obteniendoUbicacion =
              false;
        });
      }
    }
  }

  Future<void> _centrarEnUsuario(
    LatLng punto, {
    required double zoom,
  }) async {
    _centroCamaraActual = punto;

    _zoomActual =
        zoom
            .clamp(
              _zoomMinimo,
              _zoomMaximo,
            )
            .toDouble();

    await _animarCamara(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: punto,
          zoom: _zoomActual,
          bearing: _bearingActual,
          tilt: _tiltActual,
        ),
      ),
    );
  }

  Future<void>
      _iniciarActualizacionContinua() async {
    if (_actualizacionContinua) {
      return;
    }

    _actualizacionContinua = true;

    await _iniciarStreamPosicion();

    if (mounted) {
      setState(() {});
    }
  }

  Future<void>
      _iniciarStreamPosicion() async {
    final servicio =
        await Geolocator
            .isLocationServiceEnabled();

    if (!servicio) {
      _actualizacionContinua = false;

      if (mounted) {
        setState(() {});

        _mostrarDialogoGpsDesactivado();
      }

      return;
    }

    await _streamPosicion?.cancel();

    const settings =
        LocationSettings(
      accuracy:
          LocationAccuracy
              .bestForNavigation,
      distanceFilter: 1,
    );

    _streamPosicion =
        Geolocator
            .getPositionStream(
      locationSettings:
          settings,
    ).listen(
      (Position posicion) async {
        if (!mounted ||
            !_actualizacionContinua) {
          return;
        }

        if (posicion.accuracy >
            80) {
          return;
        }

        _posicionUsuario =
            posicion;

        await _animarGpsHasta(
          LatLng(
            posicion.latitude,
            posicion.longitude,
          ),
        );
      },
      onError: (error) {
        debugPrint(
          'ERROR GPS STREAM: $error',
        );
      },
      cancelOnError: false,
    );
  }

  // ============================================================
  // ANIMAR GPS
  // ============================================================

  Future<void> _animarGpsHasta(
    LatLng destino,
  ) async {
    if (!_actualizacionContinua ||
        !_estiloCargado) {
      return;
    }

    if (_puntoGpsVisual == null) {
      _puntoGpsVisual = destino;

      await _actualizarMarcadorGps(
        destino,
      );

      await _actualizarCamaraGps(
        destino,
      );

      return;
    }

    final origen =
        _puntoGpsVisual!;

    final distancia =
        Geolocator.distanceBetween(
      origen.latitude,
      origen.longitude,
      destino.latitude,
      destino.longitude,
    );

    if (distancia < 0.5) {
      _puntoGpsVisual = destino;

      await _actualizarMarcadorGps(
        destino,
      );

      await _actualizarCamaraGps(
        destino,
      );

      return;
    }

    _timerAnimacionGps?.cancel();

    const int intervaloMs =
        1000 ~/ _fpsMarcadorGps;

    int transcurrido = 0;

    _timerAnimacionGps =
        Timer.periodic(
      const Duration(
        milliseconds:
            intervaloMs,
      ),
      (timer) async {
        if (!mounted ||
            !_actualizacionContinua) {
          timer.cancel();
          return;
        }

        transcurrido +=
            intervaloMs;

        double t =
            transcurrido /
                _duracionAnimacionGpsMs;

        if (t > 1) {
          t = 1;
        }

        final suavizado =
            _easeInOutCubic(
          t,
        );

        final punto = LatLng(
          origen.latitude +
              ((destino.latitude -
                      origen.latitude) *
                  suavizado),
          origen.longitude +
              ((destino.longitude -
                      origen.longitude) *
                  suavizado),
        );

        _puntoGpsVisual = punto;

        if (!_actualizandoMarcadorGps) {
          _actualizandoMarcadorGps =
              true;

          try {
            await _actualizarMarcadorGps(
              punto,
            );

            await _actualizarCamaraGps(
              punto,
            );
          } finally {
            _actualizandoMarcadorGps =
                false;
          }
        }

        if (t >= 1) {
          timer.cancel();

          _puntoGpsVisual = destino;

          if (!_actualizandoMarcadorGps) {
            _actualizandoMarcadorGps =
                true;

            try {
              await _actualizarMarcadorGps(
                destino,
              );

              await _actualizarCamaraGps(
                destino,
              );
            } finally {
              _actualizandoMarcadorGps =
                  false;
            }
          }
        }
      },
    );
  }

  double _easeInOutCubic(
    double t,
  ) {
    if (t < 0.5) {
      return 4 * t * t * t;
    }

    return 1 -
        pow(
              -2 * t + 2,
              3,
            ) /
            2;
  }

  // ============================================================
  // MARCADOR GPS
  // ============================================================

  Future<void>
      _actualizarMarcadorGps(
    LatLng punto,
  ) async {
    final controller =
        _mapController;

    if (controller == null ||
        !_estiloCargado) {
      return;
    }

    try {
      if (_marcadorUsuario == null) {
        _marcadorUsuario =
            await controller.addCircle(
          CircleOptions(
            geometry: punto,
            circleRadius: 9,
            circleColor: '#FF7E01',
            circleStrokeColor: '#FFFFFF',
            circleStrokeWidth: 3,
            circleOpacity: 1,
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
    } catch (e) {
      debugPrint(
        'ERROR MARCADOR GPS: $e',
      );
    }
  }

  // ============================================================
  // SEGUIR GPS
  // ============================================================

  Future<void> _actualizarCamaraGps(
    LatLng punto,
  ) async {
    if (!_seguirUsuario) {
      return;
    }

    final ahora =
        DateTime.now();

    if (_ultimaActualizacionCamara !=
            null &&
        ahora
                .difference(
                  _ultimaActualizacionCamara!,
                )
                .inMilliseconds <
            _intervaloCamaraGpsMs) {
      return;
    }

    _ultimaActualizacionCamara =
        ahora;

    _centroCamaraActual =
        punto;

    await _animarCamara(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: punto,
          zoom: _zoomActual,
          bearing: _bearingActual,
          tilt: _tiltActual,
        ),
      ),
    );
  }

  Future<void>
      _detenerActualizacionContinua() async {
    _actualizacionContinua = false;
    _seguirUsuario = false;

    await _streamPosicion?.cancel();

    _streamPosicion = null;

    _timerAnimacionGps?.cancel();

    _timerAnimacionGps = null;

    _ultimaActualizacionCamara = null;

    if (mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // RUTA
  // ============================================================

  Future<void> _marcarRuta(
    Emprendimiento emprendimiento,
  ) async {
    if (_calculandoRuta) {
      return;
    }

    if (emprendimiento.latitud ==
            null ||
        emprendimiento.longitud ==
            null) {
      _mostrarMensaje(
        'Este emprendimiento no tiene ubicación.',
      );

      return;
    }

    setState(() {
      _calculandoRuta = true;
      _destinoActual = emprendimiento;
    });

    try {
      final posicion =
          await _obtenerPosicionParaRuta();

      if (posicion == null) {
        return;
      }

      _posicionUsuario = posicion;

      final origen = LatLng(
        posicion.latitude,
        posicion.longitude,
      );

      final destino = LatLng(
        emprendimiento.latitud!,
        emprendimiento.longitud!,
      );

      _puntoGpsVisual = origen;

      await _actualizarMarcadorGps(
        origen,
      );

      final resultado =
          await RutaService
              .obtenerRuta(
        origen: origen,
        destino: destino,
      );

      if (resultado['success'] !=
          true) {
        if (mounted) {
          _mostrarMensaje(
            resultado['message'] ??
                'No se pudo calcular la ruta',
          );
        }

        return;
      }

      final geojson =
          Map<String, dynamic>.from(
        resultado['geojson'],
      );

      _geoJsonRutaActual =
          geojson;

      await _dibujarRuta(
        geojson,
      );

      _distanciaRuta =
          (resultado['distancia']
                  as num?)
              ?.toDouble();

      _duracionRuta =
          (resultado['duracion']
                  as num?)
              ?.toDouble();

      if (mounted) {
        setState(() {});
      }

      _seguirUsuario = false;

      await _encuadrarRuta(
        origen,
        destino,
      );

      if (!_actualizacionContinua) {
        await _iniciarActualizacionContinua();
      }
    } catch (e) {
      debugPrint(
        'ERROR RUTA: $e',
      );

      if (mounted) {
        _mostrarMensaje(
          'No se pudo calcular la ruta',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _calculandoRuta = false;
        });
      }
    }
  }

  Future<void> _dibujarRuta(
    Map<String, dynamic> geojson,
  ) async {
    final controller =
        _mapController;

    if (controller == null ||
        !_estiloCargado) {
      return;
    }

    try {
      if (_rutaCreada) {
        await controller
            .setGeoJsonSource(
          'merc-ruta',
          geojson,
        );

        return;
      }

      await controller.addGeoJsonSource(
        'merc-ruta',
        geojson,
      );

      await controller.addLineLayer(
        'merc-ruta',
        'merc-ruta-borde',
        const LineLayerProperties(
          lineColor: '#FFFFFF',
          lineWidth: 9,
          lineOpacity: 0.85,
        ),
      );

      await controller.addLineLayer(
        'merc-ruta',
        'merc-ruta-line',
        const LineLayerProperties(
          lineColor: '#11C031',
          lineWidth: 6,
          lineOpacity: 1,
        ),
      );

      _rutaCreada = true;
    } catch (e) {
      debugPrint(
        'ERROR DIBUJANDO RUTA: $e',
      );
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _encuadrarRuta(
    LatLng origen,
    LatLng destino,
  ) async {
    final south =
        min(
      origen.latitude,
      destino.latitude,
    );

    final north =
        max(
      origen.latitude,
      destino.latitude,
    );

    final west =
        min(
      origen.longitude,
      destino.longitude,
    );

    final east =
        max(
      origen.longitude,
      destino.longitude,
    );

    await _animarCamara(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest:
              LatLng(
            south,
            west,
          ),
          northeast:
              LatLng(
            north,
            east,
          ),
        ),
        left: 55,
        top: 100,
        right: 55,
        bottom: 150,
      ),
    );
  }

  Future<void>
      _cancelarRuta() async {
    final controller =
        _mapController;

    if (controller != null &&
        _rutaCreada) {
      try {
        await controller.removeLayer(
          'merc-ruta-line',
        );

        await controller.removeLayer(
          'merc-ruta-borde',
        );

        await controller.removeSource(
          'merc-ruta',
        );
      } catch (e) {
        debugPrint(
          'ERROR ELIMINANDO RUTA: $e',
        );
      }
    }

    _rutaCreada = false;

    _geoJsonRutaActual = null;

    _destinoActual = null;

    _distanciaRuta = null;

    _duracionRuta = null;

    _seguirUsuario = false;

    if (mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // CENTRAR EL SALVADOR
  // ============================================================

  Future<void>
      _centrarElSalvador() async {
    _seguirUsuario = false;

    _centroCamaraActual =
        _centroElSalvador;

    _zoomActual = 8.5;

    _bearingActual = 0;

    _tiltActual = 0;

    await _animarCamara(
      CameraUpdate.newCameraPosition(
        const CameraPosition(
          target:
              _centroElSalvador,
          zoom: 8.5,
          bearing: 0,
          tilt: 0,
        ),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // BRÚJULA
  //
  // SIEMPRE VISIBLE.
  //
  // Solo funciona si la rotación está activa.
  //
  // NO cambia:
  // - centro
  // - zoom
  //
  // Solo estabiliza:
  // - bearing = 0
  // - tilt = 0
  // ============================================================

  Future<void>
      _restablecerAnguloMapa() async {
    if (!_rotacionActiva) {
      return;
    }

    final centro =
        _centroCamaraActual;

    final zoom =
        _zoomActual;

    _bearingActual = 0;

    _tiltActual = 0;

    await _animarCamara(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: centro,
          zoom: zoom,
          bearing: 0,
          tilt: 0,
        ),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // ROTACIÓN
  //
  // IMPORTANTE:
  //
  // NO mueve cámara.
  // NO cambia zoom.
  // NO cambia bearing.
  // NO centra El Salvador.
  //
  // Solo bloquea/desbloquea el gesto.
  // ============================================================

  void _alternarRotacion() {
    setState(() {
      _rotacionActiva =
          !_rotacionActiva;
    });

    _mostrarMensaje(
      _rotacionActiva
          ? 'Rotación activada'
          : 'Rotación bloqueada',
    );
  }

  // ============================================================
  // ZOOM
  // ============================================================

  Future<void> _acercar() async {
    final nuevoZoom =
        (_zoomActual + 1)
            .clamp(
              _zoomMinimo,
              _zoomMaximo,
            )
            .toDouble();

    _zoomActual =
        nuevoZoom;

    await _animarCamara(
      CameraUpdate.zoomTo(
        nuevoZoom,
      ),
    );
  }

  Future<void> _alejar() async {
    final nuevoZoom =
        (_zoomActual - 1)
            .clamp(
              _zoomMinimo,
              _zoomMaximo,
            )
            .toDouble();

    _zoomActual =
        nuevoZoom;

    await _animarCamara(
      CameraUpdate.zoomTo(
        nuevoZoom,
      ),
    );
  }

  // ============================================================
  // NIVEL ADMIN
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
  // GPS DESACTIVADO
  // ============================================================

  void _mostrarDialogoGpsDesactivado() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon:
              const Icon(
            Icons.location_off_outlined,
            color:
                _naranjaPrincipal,
            size: 38,
          ),
          title:
              const Text(
            'Ubicación desactivada',
          ),
          content:
              const Text(
            'Activa la ubicación del dispositivo para poder usar el GPS o calcular una ruta.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child:
                  const Text(
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
              child:
                  const Text(
                'Abrir ajustes',
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // PERMISO
  // ============================================================

  void _mostrarDialogoPermisoPermanente() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon:
              const Icon(
            Icons.gps_off,
            color:
                _naranjaPrincipal,
          ),
          title:
              const Text(
            'Permiso requerido',
          ),
          content:
              const Text(
            'El permiso de ubicación está bloqueado. Actívalo desde los ajustes de la aplicación.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child:
                  const Text(
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
              child:
                  const Text(
                'Abrir ajustes',
              ),
            ),
          ],
        );
      },
    );
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
            milliseconds: 1300,
          ),
          content:
              Text(
            mensaje,
          ),
        ),
      );
  }

  // ============================================================
  // BOTÓN
  // ============================================================

  Widget _boton({
    required String tag,
    required IconData icon,
    required VoidCallback? onPressed,
    required bool oscuro,
    bool cargando = false,
    Color? color,
  }) {
    return FloatingActionButton.small(
      heroTag: tag,
      backgroundColor:
          oscuro
              ? _panelOscuro
              : Colors.white,
      foregroundColor:
          color ??
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
  // FORMATEAR RUTA
  // ============================================================

  String _formatearDistancia() {
    if (_distanciaRuta == null) {
      return '';
    }

    if (_distanciaRuta! < 1000) {
      return '${_distanciaRuta!.round()} m';
    }

    return '${(_distanciaRuta! / 1000).toStringAsFixed(1)} km';
  }

  String _formatearDuracion() {
    if (_duracionRuta == null) {
      return '';
    }

    final minutos =
        (_duracionRuta! / 60)
            .round();

    if (minutos < 60) {
      return '$minutos min';
    }

    final horas =
        minutos ~/ 60;

    final resto =
        minutos % 60;

    return '${horas}h ${resto}min';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    super.build(
      context,
    );

    final oscuro =
        Theme.of(context)
                .brightness ==
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
            key:
                ValueKey(
              oscuro
                  ? 'map-dark'
                  : 'map-light',
            ),

            styleString:
                oscuro
                    ? _estiloOscuro
                    : _estiloClaro,

            initialCameraPosition:
                CameraPosition(
              target:
                  _centroCamaraActual,
              zoom:
                  _zoomActual,
              bearing:
                  _bearingActual,
              tilt:
                  _tiltActual,
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

            scrollGesturesEnabled:
                true,

            zoomGesturesEnabled:
                true,

            rotateGesturesEnabled:
                _rotacionActiva,

            tiltGesturesEnabled:
                _rotacionActiva,

            /*
             * Desactivamos la brújula nativa porque usamos
             * nuestra brújula personalizada.
             */
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

            onMapClick:
                _onMapClick,

            featureTapsTriggersMapClick:
                true,

            // ==================================================
            // CAMERA MOVE
            //
            // NO SETSTATE AQUÍ.
            //
            // Esto es importante para rendimiento.
            // ==================================================

            onCameraMove:
                (position) {
              _centroCamaraActual =
                  position.target;

              _zoomActual =
                  position.zoom;

              _bearingActual =
                  position.bearing;

              _tiltActual =
                  position.tilt;

              /*
               * Si el usuario toca/mueve/gira el mapa
               * mientras está siguiendo el GPS,
               * liberamos la cámara.
               *
               * El punto GPS sigue actualizándose.
               */
              if (!_moviendoCamaraProgramaticamente &&
                  _seguirUsuario) {
                _seguirUsuario =
                    false;
              }
            },

            /*
             * Solo reconstruimos UI cuando termina
             * el movimiento del mapa.
             */
            onCameraIdle:
                () {
              if (mounted) {
                setState(() {});
              }
            },
          ),

          // ====================================================
          // CARGANDO
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
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.map_outlined,
                      color:
                          _naranjaPrincipal,
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    Expanded(
                      child: Text(
                        'Mapa de El Salvador',
                        style:
                            TextStyle(
                          color: texto,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                    if (_actualizacionContinua)
                      Row(
                        children: [
                          const Icon(
                            Icons.gps_fixed,
                            color:
                                _verdeRuta,
                            size: 17,
                          ),
                          const SizedBox(
                            width: 4,
                          ),
                          Text(
                            _seguirUsuario
                                ? 'GPS'
                                : 'GPS',
                            style:
                                const TextStyle(
                              color:
                                  _verdeRuta,
                              fontSize:
                                  11,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),

          // ====================================================
          // BRÚJULA
          //
          // SIEMPRE VISIBLE.
          //
          // Se desactiva cuando se bloquea la rotación.
          // ====================================================

          Positioned(
            left:
                15,

            top:
                MediaQuery.of(
                      context,
                    ).padding.top +
                    78,

            child:
                FloatingActionButton.small(
              heroTag:
                  'brujulaUsuario',

              backgroundColor:
                  oscuro
                      ? _panelOscuro
                      : Colors.white,

              foregroundColor:
                  _rotacionActiva
                      ? _naranjaPrincipal
                      : Colors.grey,

              /*
               * Si rotación está desactivada,
               * la brújula queda realmente deshabilitada.
               */
              onPressed:
                  _rotacionActiva
                      ? _restablecerAnguloMapa
                      : null,

              child:
                  Transform.rotate(
                angle:
                    -_bearingActual *
                        pi /
                        180,

                child:
                    Icon(
                  _rotacionActiva
                      ? Icons.navigation
                      : Icons.navigation_outlined,
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
                MediaQuery.of(
                      context,
                    ).padding.top +
                    12,

            child:
                Column(
              children: [
                _boton(
                  tag:
                      'zoomMasUsuario',
                  icon:
                      Icons.add,
                  onPressed:
                      _acercar,
                  oscuro:
                      oscuro,
                ),

                const SizedBox(
                  height: 10,
                ),

                _boton(
                  tag:
                      'zoomMenosUsuario',
                  icon:
                      Icons.remove,
                  onPressed:
                      _alejar,
                  oscuro:
                      oscuro,
                ),

                const SizedBox(
                  height: 10,
                ),

                _boton(
                  tag:
                      'centrarUsuario',
                  icon:
                      Icons.center_focus_strong,
                  onPressed:
                      _centrarElSalvador,
                  oscuro:
                      oscuro,
                ),

                const SizedBox(
                  height: 10,
                ),

                // =================================================
                // GPS
                // =================================================

                _boton(
                  tag:
                      'gpsUsuario',

                  icon:
                      _actualizacionContinua
                          ? (_seguirUsuario
                              ? Icons.gps_fixed
                              : Icons.my_location)
                          : (_posicionUsuario ==
                                  null
                              ? Icons.location_searching
                              : Icons.my_location),

                  onPressed:
                      _obtenerMiUbicacion,

                  oscuro:
                      oscuro,

                  cargando:
                      _obteniendoUbicacion,

                  color:
                      _actualizacionContinua
                          ? _verdeRuta
                          : _naranjaPrincipal,
                ),

                const SizedBox(
                  height: 10,
                ),

                // =================================================
                // ROTACIÓN
                // =================================================

                _boton(
                  tag:
                      'rotacionUsuario',

                  icon:
                      _rotacionActiva
                          ? Icons.screen_rotation_alt
                          : Icons.screen_lock_rotation,

                  onPressed:
                      _alternarRotacion,

                  oscuro:
                      oscuro,

                  color:
                      _rotacionActiva
                          ? _naranjaPrincipal
                          : Colors.grey,
                ),
              ],
            ),
          ),

          // ====================================================
          // CALCULANDO RUTA
          // ====================================================

          if (_calculandoRuta)
            const Center(
              child: Card(
                child: Padding(
                  padding:
                      EdgeInsets.all(
                    18,
                  ),
                  child: Row(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color:
                            _verdeRuta,
                      ),
                      SizedBox(
                        width: 15,
                      ),
                      Text(
                        'Calculando ruta...',
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ====================================================
          // PANEL RUTA
          // ====================================================

          if (_rutaCreada &&
              _destinoActual != null)
            Positioned(
              left: 15,
              right: 15,
              bottom: 20,
              child: SafeArea(
                top: false,
                child: Container(
                  padding:
                      const EdgeInsets.all(
                    15,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        panel.withValues(
                      alpha: 0.97,
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
                          alpha: 0.15,
                        ),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 45,
                        height: 45,
                        decoration:
                            const BoxDecoration(
                          color:
                              _verdeRuta,
                          shape:
                              BoxShape.circle,
                        ),
                        child:
                            const Icon(
                          Icons.route,
                          color:
                              Colors.white,
                        ),
                      ),
                      const SizedBox(
                        width: 12,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              _destinoActual!
                                  .nombre,
                              maxLines: 1,
                              overflow:
                                  TextOverflow.ellipsis,
                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                            const SizedBox(
                              height: 3,
                            ),
                            Text(
                              '${_formatearDistancia()} · '
                              '${_formatearDuracion()}',
                              style:
                                  const TextStyle(
                                color:
                                    _verdeRuta,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip:
                            'Cancelar ruta',
                        onPressed:
                            _cancelarRuta,
                        icon:
                            const Icon(
                          Icons.close,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
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
                  ),
                  child: Row(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.layers_outlined,
                        color:
                            _naranjaPrincipal,
                        size: 17,
                      ),
                      const SizedBox(
                        width: 6,
                      ),
                      Text(
                        '${_nivelActual()} · '
                        'Zoom ${_zoomActual.toStringAsFixed(1)}',
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
                  30,
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
                ),
              ),
            ),
        ],
      ),
    );
  }
}