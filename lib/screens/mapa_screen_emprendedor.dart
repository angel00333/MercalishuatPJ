import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../models/emprendimiento.dart';
import '../services/emprendimiento_service.dart';
import '../services/ruta_service.dart';

class MapaScreenEmprendedor extends StatefulWidget {
  const MapaScreenEmprendedor({
    super.key,
  });

  @override
  State<MapaScreenEmprendedor> createState() =>
      _MapaScreenEmprendedorState();
}

class _MapaScreenEmprendedorState extends State<MapaScreenEmprendedor> {
  // ============================================================
  // CONTROLADOR
  // ============================================================

  MapLibreMapController? _mapController;

  Circle? _marcadorUsuario;

  // ============================================================
  // EMPRENDIMIENTOS
  // ============================================================

  static const String _sourceEmprendimientos =
      'merc-emprendimientos-source';

  static const String _layerEmprendimientos =
      'merc-emprendimientos-layer';

  static const String _iconoTienda =
      'merc-marker-tienda';

  bool _iconoTiendaCargado =
      false;

  bool _capaEmprendimientosCargada =
      false;

  List<Emprendimiento> _emprendimientos =
      [];

  bool _cargandoEmprendimientos =
      false;

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

  static const double _zoomMinimo =
      7.4;

  static const double _zoomMaximo =
      19.0;

  double _zoomActual =
      8.5;

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
      Color(
    0xFFFF7E01,
  );

  static const Color _verdeRuta =
      Color(
    0xFF11C031,
  );

  static const Color _panelOscuro =
      Color(
    0xFF2A2045,
  );

  static const Color _fondoOscuro =
      Color(
    0xFF171320,
  );

  static const Color _fondoClaro =
      Color(
    0xFFFFF6ED,
  );

  // ============================================================
  // ADMIN
  // ============================================================

  Map<String, dynamic>? _admin0;

  Map<String, dynamic>? _admin1;

  Map<String, dynamic>? _admin2;

  Map<String, dynamic>? _admin3;

  Map<String, dynamic>? _mascara;

  bool _geoJsonCargado =
      false;

  bool _estiloCargado =
      false;

  bool _capasCargadas =
      false;

  String? _error;

  // ============================================================
  // GPS
  // ============================================================

  Position? _posicionUsuario;

  bool _obteniendoUbicacion =
      false;

  // ============================================================
  // RUTA
  // ============================================================

  bool _rutaCreada =
      false;

  bool _calculandoRuta =
      false;

  Emprendimiento? _destinoActual;

  double? _distanciaRuta;

  double? _duracionRuta;

  // ============================================================
  // CONTROL DE TAPS EN MÓVIL
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
  // GEOJSON ADMIN
  // ============================================================

  Future<void> _cargarGeoJson() async {
    try {
      final textos =
          await Future.wait(
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
        _geoJsonCargado =
            true;

        _error =
            null;
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
    final List<dynamic> huecos =
        [];

    final features =
        admin0['features'];

    if (features is List) {
      for (final feature
          in features) {
        final geometry =
            feature['geometry'];

        if (geometry ==
            null) {
          continue;
        }

        final String tipo =
            geometry['type']
                    ?.toString() ??
                '';

        final coordinates =
            geometry[
                'coordinates'];

        if (tipo ==
                'Polygon' &&
            coordinates
                is List &&
            coordinates
                .isNotEmpty) {
          final exterior =
              coordinates[0];

          if (exterior
              is List) {
            huecos.add(
              exterior.reversed
                  .toList(),
            );
          }
        }

        if (tipo ==
                'MultiPolygon' &&
            coordinates
                is List) {
          for (final polygon
              in coordinates) {
            if (polygon
                    is List &&
                polygon
                    .isNotEmpty &&
                polygon[0]
                    is List) {
              huecos.add(
                (polygon[0]
                        as List)
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
      'type':
          'FeatureCollection',

      'features': [
        {
          'type':
              'Feature',

          'properties':
              <String, dynamic>{},

          'geometry': {
            'type':
                'Polygon',

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
  // CARGAR EMPRENDIMIENTOS
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

      if (resultado['success'] ==
          true) {
        final dynamic raw =
            resultado[
                'emprendimientos'];

        if (raw is List) {
          final lista =
              raw
                  .whereType<
                      Emprendimiento>()
                  .toList();

          setState(() {
            _emprendimientos =
                lista.where(
              (e) =>
                  e.latitud !=
                      null &&
                  e.longitud !=
                      null,
            ).toList();
          });

          debugPrint(
            '================================',
          );

          debugPrint(
            'EMPRENDIMIENTOS CON UBICACIÓN: '
            '${_emprendimientos.length}',
          );

          for (final tienda
              in _emprendimientos) {
            debugPrint(
              '${tienda.id} - '
              '${tienda.nombre} - '
              '${tienda.latitud}, '
              '${tienda.longitud}',
            );
          }

          debugPrint(
            '================================',
          );

          if (_estiloCargado &&
              _iconoTiendaCargado) {
            await _dibujarEmprendimientos();
          }
        }
      } else {
        debugPrint(
          'Error listando tiendas: '
          '${resultado['message']}',
        );
      }
    } catch (e) {
      debugPrint(
        'ERROR CARGANDO TIENDAS: $e',
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
    _mapController =
        controller;

    controller.onFeatureTapped.add(
      _onFeatureTapped,
    );
  }

  // ============================================================
  // TAP DIRECTO SOBRE EMPRENDIMIENTO
  // ============================================================

  void _onFeatureTapped(
    Point<double> point,
    LatLng coordinates,
    String id,
    String layerId,
    Annotation? annotation,
  ) {
    debugPrint(
      'FEATURE TAP -> id=$id layer=$layerId',
    );

    if (layerId != _layerEmprendimientos) {
      return;
    }

    final int? emprendimientoId =
        int.tryParse(id);

    if (emprendimientoId == null) {
      debugPrint(
        'ID inválido recibido desde onFeatureTapped: $id',
      );
      return;
    }

    _abrirEmprendimientoPorId(
      emprendimientoId,
    );
  }

  // ============================================================
  // TAP GENERAL DEL MAPA
  //
  // Respaldo para Android/iOS. Si el callback específico de
  // la capa no dispara, consultamos manualmente qué feature
  // quedó debajo del dedo.
  // ============================================================

  Future<void> _onMapClick(
    Point<double> point,
    LatLng coordinates,
  ) async {
    final controller = _mapController;

    if (controller == null ||
        !_capaEmprendimientosCargada) {
      return;
    }

    try {
      final List<dynamic> features =
          await controller.queryRenderedFeatures(
        point,
        const [
          _layerEmprendimientos,
        ],
        null,
      );

      if (features.isEmpty) {
        return;
      }

      for (final dynamic rawFeature in features) {
        if (rawFeature is! Map) {
          continue;
        }

        final Map<String, dynamic> feature =
            Map<String, dynamic>.from(
          rawFeature,
        );

        int? emprendimientoId;

        // En la mayoría de plataformas viene como Feature.id.
        final dynamic rawId =
            feature['id'];

        if (rawId != null) {
          emprendimientoId =
              int.tryParse(
            rawId.toString(),
          );
        }

        // Respaldo por si la plataforma devuelve solo properties.
        if (emprendimientoId == null) {
          final dynamic rawProperties =
              feature['properties'];

          if (rawProperties is Map) {
            final properties =
                Map<String, dynamic>.from(
              rawProperties,
            );

            final dynamic rawPropId =
                properties['emprendimiento_id'];

            if (rawPropId != null) {
              emprendimientoId =
                  int.tryParse(
                rawPropId.toString(),
              );
            }
          }
        }

        if (emprendimientoId != null) {
          await _abrirEmprendimientoPorId(
            emprendimientoId,
          );
          return;
        }
      }
    } catch (e) {
      debugPrint(
        'ERROR TAP RESPALDO MAPA: $e',
      );
    }
  }

  // ============================================================
  // ABRIR EMPRENDIMIENTO
  //
  // Evita que onFeatureTapped + onMapClick abran dos veces
  // el mismo BottomSheet.
  // ============================================================

  Future<void> _abrirEmprendimientoPorId(
    int id,
  ) async {
    if (!mounted) {
      return;
    }

    final DateTime ahora =
        DateTime.now();

    if (_ultimoEmprendimientoTocado == id &&
        _ultimoTapEmprendimiento != null &&
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

    for (final tienda in _emprendimientos) {
      if (tienda.id == id) {
        seleccionado = tienda;
        break;
      }
    }

    if (seleccionado == null) {
      debugPrint(
        'NO SE ENCONTRÓ EMPRENDIMIENTO ID $id',
      );
      return;
    }

    _ultimoEmprendimientoTocado = id;
    _ultimoTapEmprendimiento = ahora;
    _abriendoEmprendimiento = true;

    debugPrint(
      'TIENDA SELECCIONADA: ${seleccionado.nombre}',
    );

    try {
      await _mostrarOpcionesEmprendimiento(
        seleccionado,
      );
    } finally {
      _abriendoEmprendimiento = false;
    }
  }

  // ============================================================
  // ESTILO CARGADO
  // ============================================================

  Future<void>
      _onStyleLoaded() async {
    _capasCargadas =
        false;

    _rutaCreada =
        false;

    _marcadorUsuario =
        null;

    _iconoTiendaCargado =
        false;

    _capaEmprendimientosCargada =
        false;

    if (!mounted) {
      return;
    }

    setState(() {
      _estiloCargado =
          true;
    });

    if (_geoJsonCargado) {
      await _agregarCapas();
    }

    // Primero cargamos el icono.
    await _cargarIconoTienda();

    // Luego las tiendas.
    await _dibujarEmprendimientos();

    if (_posicionUsuario !=
        null) {
      await _dibujarUbicacion(
        _posicionUsuario!,
        centrar: false,
      );
    }

    await _centrarElSalvador();
  }

  // ============================================================
  // CARGAR ICONO TIENDA
  //
  // REDIMENSIONAMOS EL PNG ANTES DE ENTREGARLO A MAPLIBRE.
  // ESTO CORRIGE EL MARCADOR INVISIBLE EN WEB.
  // ============================================================

  Future<void>
      _cargarIconoTienda() async {
    final controller =
        _mapController;

    if (controller ==
            null ||
        _iconoTiendaCargado) {
      return;
    }

    ui.Codec? codec;
    ui.Image? imagen;

    try {
      // ========================================================
      // PNG ORIGINAL
      // ========================================================

      final ByteData data =
          await rootBundle.load(
        'assets/mapas/marcador_tienda.png',
      );

      final Uint8List
          bytesOriginales =
          data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );

      debugPrint(
        'Marcador original: '
        '${bytesOriginales.length} bytes',
      );

      // ========================================================
      // REDIMENSIONAR
      //
      // Dejamos el marcador en 96px de ancho.
      // La altura se calcula automáticamente.
      // ========================================================

      codec =
          await ui.instantiateImageCodec(
        bytesOriginales,
        targetWidth:
            96,
      );

      final ui.FrameInfo frame =
          await codec.getNextFrame();

      imagen =
          frame.image;

      debugPrint(
        'Marcador redimensionado: '
        '${imagen.width}x${imagen.height}',
      );

      // ========================================================
      // CONVERTIR A PNG
      // ========================================================

      final ByteData? pngData =
          await imagen.toByteData(
        format:
            ui.ImageByteFormat.png,
      );

      if (pngData ==
          null) {
        throw Exception(
          'No se pudo convertir el marcador a PNG',
        );
      }

      final Uint8List bytesFinales =
          pngData.buffer.asUint8List(
        pngData.offsetInBytes,
        pngData.lengthInBytes,
      );

      // ========================================================
      // REGISTRAR EN MAPLIBRE
      // ========================================================

      await controller.addImage(
        _iconoTienda,
        bytesFinales,
      );

      _iconoTiendaCargado =
          true;

      debugPrint(
        '✓ ICONO TIENDA REGISTRADO EN MAPLIBRE',
      );
    } catch (e) {
      _iconoTiendaCargado =
          false;

      debugPrint(
        'ERROR ICONO TIENDA: $e',
      );

      if (mounted) {
        _mostrarMensaje(
          'No se pudo cargar el marcador de las tiendas',
        );
      }
    } finally {
      imagen?.dispose();

      codec?.dispose();
    }
  }

  // ============================================================
  // CAPAS ADMIN
  // ============================================================

  Future<void> _agregarCapas() async {
    final controller =
        _mapController;

    if (controller ==
            null ||
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

      // ========================================================
      // MÁSCARA
      // ========================================================

      await controller.addFillLayer(
        'merc-mask',
        'merc-mask-layer',
        FillLayerProperties(
          fillColor:
              oscuro
                  ? '#171320'
                  : '#FFF6ED',

          fillOpacity:
              1.0,

          fillOutlineColor:
              oscuro
                  ? '#171320'
                  : '#FFF6ED',
        ),
      );

      // ========================================================
      // TINTE
      // ========================================================

      await controller.addFillLayer(
        'merc-admin0',
        'merc-orange-overlay',
        const FillLayerProperties(
          fillColor:
              '#FF7E01',

          fillOpacity:
              0.035,
        ),
      );

      // ========================================================
      // ADMIN3
      // ========================================================

      await controller.addLineLayer(
        'merc-admin3',
        'merc-admin3-line',
        const LineLayerProperties(
          lineColor:
              '#FFC078',

          lineOpacity:
              0.65,

          lineWidth:
              0.65,
        ),
        minzoom:
            13,
      );

      // ========================================================
      // ADMIN2
      // ========================================================

      await controller.addLineLayer(
        'merc-admin2',
        'merc-admin2-line',
        const LineLayerProperties(
          lineColor:
              '#FF9A3D',

          lineOpacity:
              0.78,

          lineWidth:
              1,
        ),
        minzoom:
            10,
      );

      // ========================================================
      // ADMIN1
      // ========================================================

      await controller.addLineLayer(
        'merc-admin1',
        'merc-admin1-line',
        const LineLayerProperties(
          lineColor:
              '#FF7E01',

          lineOpacity:
              0.9,

          lineWidth:
              1.5,
        ),
        minzoom:
            7.5,
      );

      // ========================================================
      // ADMIN0
      // ========================================================

      await controller.addLineLayer(
        'merc-admin0',
        'merc-admin0-line',
        const LineLayerProperties(
          lineColor:
              '#C95400',

          lineOpacity:
              1,

          lineWidth:
              3,
        ),
      );

      _capasCargadas =
          true;
    } catch (e) {
      debugPrint(
        'ERROR CAPAS ADMIN: $e',
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

    if (controller ==
            null ||
        !_estiloCargado ||
        !_iconoTiendaCargado) {
      return;
    }

    try {
      final features =
          <Map<String, dynamic>>[];

      for (final emprendimiento
          in _emprendimientos) {
        if (emprendimiento
                    .latitud ==
                null ||
            emprendimiento
                    .longitud ==
                null) {
          continue;
        }

        features.add({
          'type':
              'Feature',

          // Este ID es el que devuelve
          // onFeatureTapped.
          'id':
              emprendimiento.id
                  .toString(),

          'properties': {
            'tipo':
                'emprendimiento',

            'nombre':
                emprendimiento
                    .nombre,

            'emprendimiento_id':
                emprendimiento
                    .id,
          },

          'geometry': {
            'type':
                'Point',

            'coordinates': [
              emprendimiento
                  .longitud!,
              emprendimiento
                  .latitud!,
            ],
          },
        });
      }

      final Map<String, dynamic>
          geojson = {
        'type':
            'FeatureCollection',

        'features':
            features,
      };

      debugPrint(
        'FEATURES EMPRENDIMIENTOS: '
        '${features.length}',
      );

      // ========================================================
      // SI YA EXISTE, ACTUALIZAR
      // ========================================================

      if (_capaEmprendimientosCargada) {
        await controller
            .setGeoJsonSource(
          _sourceEmprendimientos,
          geojson,
        );

        debugPrint(
          '✓ SOURCE TIENDAS ACTUALIZADO',
        );

        return;
      }

      // ========================================================
      // SOURCE
      // ========================================================

      await controller
          .addGeoJsonSource(
        _sourceEmprendimientos,
        geojson,
      );

      // ========================================================
      // SYMBOL LAYER
      // ========================================================

      await controller
          .addSymbolLayer(
        _sourceEmprendimientos,
        _layerEmprendimientos,
        const SymbolLayerProperties(
          iconImage:
              _iconoTienda,

          // El PNG ya está reducido
          // a 96px.
          //
          // 0.85 deja un tamaño claro
          // y visible.
          iconSize:
              0.85,

          // La punta inferior del pin
          // coincide con la coordenada.
          iconAnchor:
              'bottom',

          // Nunca ocultar el marcador
          // por colisiones con textos.
          iconAllowOverlap:
              true,

          iconIgnorePlacement:
              true,

          iconOptional:
              false,

          iconOpacity:
              1.0,
        ),

        // Necesario para recibir taps.
        enableInteraction:
            true,
      );

      _capaEmprendimientosCargada =
          true;

      debugPrint(
        '✓ CAPA EMPRENDIMIENTOS CREADA',
      );
    } catch (e) {
      debugPrint(
        'ERROR DIBUJANDO TIENDAS: $e',
      );
    }
  }

  // ============================================================
  // OPCIONES DEL EMPRENDIMIENTO
  // ============================================================

  Future<void> _mostrarOpcionesEmprendimiento(
    Emprendimiento emprendimiento,
  ) async {
    if (!mounted) {
      return;
    }

    await showModalBottomSheet(
      context:
          context,

      showDragHandle:
          true,

      isScrollControlled:
          true,

      builder:
          (bottomContext) {
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
                  CrossAxisAlignment
                      .stretch,

              children: [
                Row(
                  children: [
                    Container(
                      width:
                          64,

                      height:
                          64,

                      decoration:
                          BoxDecoration(
                        color:
                            _naranjaPrincipal,

                        borderRadius:
                            BorderRadius
                                .circular(
                          18,
                        ),

                        image:
                            emprendimiento
                                            .imagenUrl !=
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
                          emprendimiento
                                          .imagenUrl ==
                                      null ||
                                  emprendimiento
                                      .imagenUrl!
                                      .isEmpty
                              ? const Icon(
                                  Icons.storefront,
                                  color:
                                      Colors.white,
                                  size:
                                      34,
                                )
                              : null,
                    ),

                    const SizedBox(
                      width:
                          14,
                    ),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,

                        children: [
                          Text(
                            emprendimiento
                                .nombre,

                            style:
                                const TextStyle(
                              fontSize:
                                  19,

                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          if (emprendimiento
                                      .descripcion !=
                                  null &&
                              emprendimiento
                                  .descripcion!
                                  .isNotEmpty) ...[
                            const SizedBox(
                              height:
                                  4,
                            ),

                            Text(
                              emprendimiento
                                  .descripcion!,

                              maxLines:
                                  2,

                              overflow:
                                  TextOverflow
                                      .ellipsis,
                            ),
                          ],

                          const SizedBox(
                            height:
                                6,
                          ),

                          const Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color:
                                    _naranjaPrincipal,
                                size:
                                    16,
                              ),

                              SizedBox(
                                width:
                                    4,
                              ),

                              Text(
                                'Ubicación disponible',

                                style:
                                    TextStyle(
                                  color:
                                      _naranjaPrincipal,

                                  fontSize:
                                      12,

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
                  height:
                      24,
                ),

                // =================================================
                // PERFIL
                // =================================================

                SizedBox(
                  height:
                      50,

                  child:
                      OutlinedButton.icon(
                    onPressed:
                        () {
                      Navigator.pop(
                        bottomContext,
                      );

                      _mostrarPerfilEmprendimiento(
                        emprendimiento,
                      );
                    },

                    icon:
                        const Icon(
                      Icons
                          .storefront_outlined,
                    ),

                    label:
                        const Text(
                      'Ver perfil del emprendimiento',
                    ),
                  ),
                ),

                const SizedBox(
                  height:
                      12,
                ),

                // =================================================
                // RUTA
                // =================================================

                SizedBox(
                  height:
                      50,

                  child:
                      FilledButton.icon(
                    style:
                        FilledButton
                            .styleFrom(
                      backgroundColor:
                          _verdeRuta,

                      foregroundColor:
                          Colors.white,
                    ),

                    onPressed:
                        () {
                      Navigator.pop(
                        bottomContext,
                      );

                      _marcarRuta(
                        emprendimiento,
                      );
                    },

                    icon:
                        const Icon(
                      Icons.route,
                    ),

                    label:
                        const Text(
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
      context:
          context,

      showDragHandle:
          true,

      isScrollControlled:
          true,

      builder:
          (perfilContext) {
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
                  radius:
                      52,

                  backgroundColor:
                      _naranjaPrincipal,

                  backgroundImage:
                      emprendimiento
                                  .imagenUrl !=
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
                      emprendimiento
                                  .imagenUrl ==
                              null ||
                          emprendimiento
                              .imagenUrl!
                              .isEmpty
                          ? const Icon(
                              Icons
                                  .storefront,

                              size:
                                  50,

                              color:
                                  Colors.white,
                            )
                          : null,
                ),

                const SizedBox(
                  height:
                      16,
                ),

                Text(
                  emprendimiento.nombre,

                  textAlign:
                      TextAlign.center,

                  style:
                      const TextStyle(
                    fontSize:
                        22,

                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                if (emprendimiento
                            .descripcion !=
                        null &&
                    emprendimiento
                        .descripcion!
                        .isNotEmpty) ...[
                  const SizedBox(
                    height:
                        12,
                  ),

                  Text(
                    emprendimiento
                        .descripcion!,

                    textAlign:
                        TextAlign.center,
                  ),
                ],

                if (emprendimiento
                            .telefono !=
                        null &&
                    emprendimiento
                        .telefono!
                        .isNotEmpty) ...[
                  const SizedBox(
                    height:
                        15,
                  ),

                  ListTile(
                    leading:
                        const Icon(
                      Icons
                          .phone_outlined,

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

                if (emprendimiento
                            .correoContacto !=
                        null &&
                    emprendimiento
                        .correoContacto!
                        .isNotEmpty)
                  ListTile(
                    leading:
                        const Icon(
                      Icons
                          .email_outlined,

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
                  height:
                      16,
                ),

                SizedBox(
                  width:
                      double.infinity,

                  height:
                      50,

                  child:
                      FilledButton.icon(
                    style:
                        FilledButton
                            .styleFrom(
                      backgroundColor:
                          _verdeRuta,

                      foregroundColor:
                          Colors.white,
                    ),

                    onPressed:
                        () {
                      Navigator.pop(
                        perfilContext,
                      );

                      _marcarRuta(
                        emprendimiento,
                      );
                    },

                    icon:
                        const Icon(
                      Icons.route,
                    ),

                    label:
                        const Text(
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
          LocationAccuracy.high,
    );

    return Geolocator
        .getCurrentPosition(
      locationSettings:
          settings,
    );
  }

  // ============================================================
  // MI UBICACIÓN
  // ============================================================

  Future<void>
      _obtenerMiUbicacion() async {
    if (_obteniendoUbicacion) {
      return;
    }

    setState(() {
      _obteniendoUbicacion =
          true;
    });

    try {
      final posicion =
          await _obtenerPosicionParaRuta();

      if (posicion ==
          null) {
        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _posicionUsuario =
            posicion;
      });

      await _dibujarUbicacion(
        posicion,
        centrar: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _obteniendoUbicacion =
              false;
        });
      }
    }
  }

  // ============================================================
  // DIBUJAR MI UBICACIÓN
  // ============================================================

  Future<void> _dibujarUbicacion(
    Position posicion, {
    required bool centrar,
  }) async {
    final controller =
        _mapController;

    if (controller ==
            null ||
        !_estiloCargado) {
      return;
    }

    final punto =
        LatLng(
      posicion.latitude,
      posicion.longitude,
    );

    try {
      if (_marcadorUsuario ==
          null) {
        _marcadorUsuario =
            await controller
                .addCircle(
          CircleOptions(
            geometry:
                punto,

            circleRadius:
                9,

            circleColor:
                '#FF7E01',

            circleStrokeColor:
                '#FFFFFF',

            circleStrokeWidth:
                3,

            circleOpacity:
                1,
          ),
        );
      } else {
        await controller
            .updateCircle(
          _marcadorUsuario!,
          CircleOptions(
            geometry:
                punto,
          ),
        );
      }

      if (centrar) {
        await controller
            .animateCamera(
          CameraUpdate
              .newLatLngZoom(
            punto,
            15,
          ),
        );
      }
    } catch (e) {
      debugPrint(
        'ERROR UBICACIÓN: $e',
      );
    }
  }

  // ============================================================
  // MARCAR RUTA
  // ============================================================

  Future<void> _marcarRuta(
    Emprendimiento emprendimiento,
  ) async {
    if (_calculandoRuta) {
      return;
    }

    if (emprendimiento
                .latitud ==
            null ||
        emprendimiento
                .longitud ==
            null) {
      _mostrarMensaje(
        'Este emprendimiento no tiene ubicación.',
      );

      return;
    }

    setState(() {
      _calculandoRuta =
          true;

      _destinoActual =
          emprendimiento;
    });

    try {
      final posicion =
          await _obtenerPosicionParaRuta();

      if (posicion ==
          null) {
        return;
      }

      _posicionUsuario =
          posicion;

      await _dibujarUbicacion(
        posicion,
        centrar: false,
      );

      final origen =
          LatLng(
        posicion.latitude,
        posicion.longitude,
      );

      final destino =
          LatLng(
        emprendimiento.latitud!,
        emprendimiento.longitud!,
      );

      final resultado =
          await RutaService
              .obtenerRuta(
        origen:
            origen,

        destino:
            destino,
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

      await _encuadrarRuta(
        origen,
        destino,
      );
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
          _calculandoRuta =
              false;
        });
      }
    }
  }

  // ============================================================
  // DIBUJAR RUTA
  // ============================================================

  Future<void> _dibujarRuta(
    Map<String, dynamic> geojson,
  ) async {
    final controller =
        _mapController;

    if (controller ==
        null) {
      return;
    }

    if (_rutaCreada) {
      await controller
          .setGeoJsonSource(
        'merc-ruta',
        geojson,
      );

      return;
    }

    await controller
        .addGeoJsonSource(
      'merc-ruta',
      geojson,
    );

    // Fondo blanco para que
    // destaque sobre el naranja.
    await controller
        .addLineLayer(
      'merc-ruta',
      'merc-ruta-borde',
      const LineLayerProperties(
        lineColor:
            '#FFFFFF',

        lineWidth:
            9,

        lineOpacity:
            0.85,
      ),
    );

    // Ruta verde Beta 4.4.
    await controller
        .addLineLayer(
      'merc-ruta',
      'merc-ruta-line',
      const LineLayerProperties(
        lineColor:
            '#11C031',

        lineWidth:
            6,

        lineOpacity:
            1,
      ),
    );

    _rutaCreada =
        true;

    if (mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // ENCUADRAR RUTA
  // ============================================================

  Future<void> _encuadrarRuta(
    LatLng origen,
    LatLng destino,
  ) async {
    final controller =
        _mapController;

    if (controller ==
        null) {
      return;
    }

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

    await controller
        .animateCamera(
      CameraUpdate
          .newLatLngBounds(
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

        left:
            55,

        top:
            100,

        right:
            55,

        bottom:
            150,
      ),
    );
  }

  // ============================================================
  // CANCELAR RUTA
  // ============================================================

  Future<void>
      _cancelarRuta() async {
    final controller =
        _mapController;

    if (controller !=
            null &&
        _rutaCreada) {
      try {
        await controller
            .removeLayer(
          'merc-ruta-line',
        );

        await controller
            .removeLayer(
          'merc-ruta-borde',
        );

        await controller
            .removeSource(
          'merc-ruta',
        );
      } catch (e) {
        debugPrint(
          'ERROR ELIMINANDO RUTA: $e',
        );
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _rutaCreada =
          false;

      _destinoActual =
          null;

      _distanciaRuta =
          null;

      _duracionRuta =
          null;
    });
  }

  // ============================================================
  // GPS DESACTIVADO
  // ============================================================

  void _mostrarDialogoGpsDesactivado() {
    showDialog(
      context:
          context,

      builder:
          (dialogContext) {
        return AlertDialog(
          icon:
              const Icon(
            Icons
                .location_off_outlined,

            color:
                _naranjaPrincipal,

            size:
                38,
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
              onPressed:
                  () {
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
                  FilledButton
                      .styleFrom(
                backgroundColor:
                    _naranjaPrincipal,

                foregroundColor:
                    Colors.white,
              ),

              onPressed:
                  () async {
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
  // PERMISO BLOQUEADO
  // ============================================================

  void _mostrarDialogoPermisoPermanente() {
    showDialog(
      context:
          context,

      builder:
          (dialogContext) {
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
              onPressed:
                  () {
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
                  FilledButton
                      .styleFrom(
                backgroundColor:
                    _naranjaPrincipal,

                foregroundColor:
                    Colors.white,
              ),

              onPressed:
                  () async {
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
    ScaffoldMessenger.of(
      context,
    )
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content:
              Text(
            mensaje,
          ),
        ),
      );
  }

  // ============================================================
  // ZOOM
  // ============================================================

  Future<void> _acercar() async {
    if (_mapController ==
        null) {
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

  Future<void> _alejar() async {
    if (_mapController ==
        null) {
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
  // CENTRAR
  // ============================================================

  Future<void>
      _centrarElSalvador() async {
    if (_mapController ==
        null) {
      return;
    }

    await _mapController!
        .animateCamera(
      CameraUpdate
          .newLatLngBounds(
        _limitesElSalvador,

        left:
            25,

        top:
            80,

        right:
            25,

        bottom:
            70,
      ),
    );
  }

  // ============================================================
  // NIVEL
  // ============================================================

  String _nivelActual() {
    if (_zoomActual <
        8.5) {
      return 'ADMIN0';
    }

    if (_zoomActual <
        10) {
      return 'ADMIN1';
    }

    if (_zoomActual <
        13) {
      return 'ADMIN2';
    }

    return 'ADMIN3';
  }

  // ============================================================
  // SELECTOR DE CONTENIDO - BETA 4.5
  //
  // Por ahora únicamente "Emprendimientos" está implementado.
  // "Locales en renta" aparece como opción preparada para la
  // siguiente etapa, pero todavía no cambia ninguna capa.
  // ============================================================

  void _mostrarSelectorContenidoMapa() {
    if (!mounted) {
      return;
    }

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (bottomContext) {
        final bool oscuro =
            Theme.of(bottomContext).brightness ==
                Brightness.dark;

        final Color textoSecundario =
            oscuro
                ? Colors.white70
                : Colors.black54;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              0,
              16,
              20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(
                    8,
                    4,
                    8,
                    14,
                  ),
                  child: Text(
                    'Mostrar en el mapa',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // =================================================
                // EMPRENDIMIENTOS
                // =================================================

                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                  tileColor:
                      _naranjaPrincipal.withValues(
                    alpha:
                        oscuro ? 0.16 : 0.09,
                  ),
                  leading: const CircleAvatar(
                    backgroundColor:
                        _naranjaPrincipal,
                    foregroundColor:
                        Colors.white,
                    child: Icon(
                      Icons.storefront_outlined,
                    ),
                  ),
                  title: const Text(
                    'Emprendimientos',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: const Text(
                    'Mostrar negocios registrados',
                  ),
                  trailing: const Icon(
                    Icons.check_circle,
                    color:
                        _naranjaPrincipal,
                  ),
                  onTap: () {
                    Navigator.pop(
                      bottomContext,
                    );
                  },
                ),

                const SizedBox(
                  height: 10,
                ),

                // =================================================
                // LOCALES EN RENTA
                // OPCIÓN VISIBLE, AÚN NO IMPLEMENTADA
                // =================================================

                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                  leading: const CircleAvatar(
                    child: Icon(
                      Icons.apartment_outlined,
                    ),
                  ),
                  title: const Text(
                    'Locales en renta',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    'Disponible próximamente',
                    style: TextStyle(
                      color:
                          textoSecundario,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.schedule_outlined,
                  ),
                  onTap: () {
                    Navigator.pop(
                      bottomContext,
                    );

                    _mostrarMensaje(
                      'Locales en renta estará disponible próximamente.',
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
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
    return FloatingActionButton
        .small(
      heroTag:
          tag,

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
                  width:
                      19,

                  height:
                      19,

                  child:
                      CircularProgressIndicator(
                    strokeWidth:
                        2,

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
    if (_distanciaRuta ==
        null) {
      return '';
    }

    if (_distanciaRuta! <
        1000) {
      return '${_distanciaRuta!.round()} m';
    }

    return '${(_distanciaRuta! / 1000).toStringAsFixed(1)} km';
  }

  String _formatearDuracion() {
    if (_duracionRuta ==
        null) {
      return '';
    }

    final minutos =
        (_duracionRuta! / 60)
            .round();

    if (minutos <
        60) {
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
      backgroundColor:
          fondo,

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
                const CameraPosition(
              target:
                  _centroElSalvador,

              zoom:
                  8.5,
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

            // ==================================================
            // TAP ROBUSTO EN MÓVIL
            //
            // La capa interactiva dispara onFeatureTapped y,
            // además, este callback consulta manualmente la capa
            // cuando el toque específico falla en Android/iOS.
            // ==================================================

            onMapClick:
                _onMapClick,

            featureTapsTriggersMapClick:
                true,

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
          // CARGANDO
          // ====================================================

          if (!_estiloCargado ||
              !_geoJsonCargado)
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
                height:
                    52,

                padding:
                    const EdgeInsets.symmetric(
                  horizontal:
                      15,
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
                    18,
                  ),
                ),

                child: Row(
                  children: [
                    const Icon(
                      Icons
                          .map_outlined,

                      color:
                          _naranjaPrincipal,
                    ),

                    const SizedBox(
                      width:
                          8,
                    ),

                    Expanded(
                      child: Text(
                        'Mapa de El Salvador',

                        style:
                            TextStyle(
                          color:
                              texto,

                          fontWeight:
                              FontWeight.bold,
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
                MediaQuery.of(
                      context,
                    ).padding.top +
                    12,

            child: Column(
              children: [
                _boton(
                  tag:
                      'zoomMas',

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

                _boton(
                  tag:
                      'zoomMenos',

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

                _boton(
                  tag:
                      'centrar',

                  icon:
                      Icons
                          .center_focus_strong,

                  onPressed:
                      _centrarElSalvador,

                  oscuro:
                      oscuro,
                ),

                const SizedBox(
                  height:
                      10,
                ),

                _boton(
                  tag:
                      'gps',

                  icon:
                      _posicionUsuario ==
                              null
                          ? Icons
                              .location_searching
                          : Icons
                              .my_location,

                  onPressed:
                      _obtenerMiUbicacion,

                  oscuro:
                      oscuro,

                  cargando:
                      _obteniendoUbicacion,
                ),

                const SizedBox(
                  height:
                      10,
                ),

                // =================================================
                // BETA 4.5 - SELECTOR DE CONTENIDO
                // =================================================

                _boton(
                  tag:
                      'contenidoMapaEmprendedor',

                  icon:
                      Icons.layers_outlined,

                  onPressed:
                      _mostrarSelectorContenidoMapa,

                  oscuro:
                      oscuro,
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
                        width:
                            15,
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
              _destinoActual !=
                  null)
            Positioned(
              left:
                  15,

              right:
                  15,

              bottom:
                  20,

              child: SafeArea(
                top:
                    false,

                child: Container(
                  padding:
                      const EdgeInsets.all(
                    15,
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
                      18,
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
                            12,
                      ),
                    ],
                  ),

                  child: Row(
                    children: [
                      Container(
                        width:
                            45,

                        height:
                            45,

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
                        width:
                            12,
                      ),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,

                          children: [
                            Text(
                              _destinoActual!
                                  .nombre,

                              maxLines:
                                  1,

                              overflow:
                                  TextOverflow
                                      .ellipsis,

                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            const SizedBox(
                              height:
                                  3,
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
              left:
                  15,

              bottom:
                  25,

              child: SafeArea(
                top:
                    false,

                child: Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal:
                        14,

                    vertical:
                        9,
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
                      20,
                    ),
                  ),

                  child: Row(
                    mainAxisSize:
                        MainAxisSize.min,

                    children: [
                      const Icon(
                        Icons
                            .layers_outlined,

                        color:
                            _naranjaPrincipal,

                        size:
                            17,
                      ),

                      const SizedBox(
                        width:
                            6,
                      ),

                      Text(
                        '${_nivelActual()} · '
                        'Zoom ${_zoomActual.toStringAsFixed(1)}',

                        style:
                            TextStyle(
                          color:
                              texto,

                          fontWeight:
                              FontWeight.bold,

                          fontSize:
                              12,
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

          if (_error !=
              null)
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
                  color:
                      panel,

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