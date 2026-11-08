import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../models/emprendimiento.dart';
import '../../models/local_comercial.dart';
import '../../services/admin_mapa_service.dart';

class AdminMapaScreen extends StatefulWidget {
  const AdminMapaScreen({
    super.key,
  });

  @override
  State<AdminMapaScreen> createState() =>
      _AdminMapaScreenState();
}

class _AdminMapaScreenState
    extends State<AdminMapaScreen> {
  // ============================================================
  // MAPA
  // ============================================================

  MapLibreMapController? _mapController;

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

  LatLng _centroCamaraActual =
      _centroElSalvador;

  double _zoomActual =
      8.5;

  double _bearingActual =
      0;

  double _tiltActual =
      0;

  bool _rotacionActiva =
      true;

  // ============================================================
  // BLOQUEO DE INTERACCIÓN
  //
  // IMPORTANTE:
  //
  // Mientras cualquier BottomSheet esté abierto:
  //
  // - no se mueve el mapa
  // - no hace zoom
  // - no rota
  // - no abre departamentos
  // - no activa marcadores
  //
  // Usamos contador y no bool porque puede abrirse un modal
  // inmediatamente después de cerrar otro.
  // ============================================================

  int _bloqueosInteraccionMapa =
      0;

  bool get _mapaBloqueado =>
      _bloqueosInteraccionMapa >
      0;

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

  static const Color _naranjaOscuro =
      Color(
    0xFFC95400,
  );

  static const Color _verde =
      Color(
    0xFF11C031,
  );

  static const Color _rojo =
      Color(
    0xFFE53935,
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
  // GEOJSON
  // ============================================================

  Map<String, dynamic>? _admin0;

  Map<String, dynamic>? _admin1;

  Map<String, dynamic>? _mascara;

  bool _geoJsonCargado =
      false;

  bool _estiloCargado =
      false;

  bool _capasBaseCargadas =
      false;

  bool _capasConcentracionCargadas =
      false;

  // ============================================================
  // DATOS
  // ============================================================

  bool _cargandoDatos =
      true;

  String? _error;

  List<Emprendimiento>
      _emprendimientos =
      [];

  List<LocalComercial> _locales =
      [];

  // ============================================================
  // VISIBILIDAD
  // ============================================================

  bool _mostrarEmprendimientos =
      true;

  bool _mostrarLocales =
      true;

  bool _mostrarConcentracion =
      true;

  // ============================================================
  // MARCADORES
  //
  // tienda.png = EMPRENDIMIENTOS
  // local.png  = LOCALES COMERCIALES
  // ============================================================

  static const String _sourceEmprendimientos =
      'admin-emprendimientos-source';

  static const String _layerEmprendimientos =
      'admin-emprendimientos-layer';

  static const String _iconoEmprendimiento =
      'admin-marker-emprendimiento';

  static const String _sourceLocales =
      'admin-locales-source';

  static const String _layerLocales =
      'admin-locales-layer';

  static const String _iconoLocal =
      'admin-marker-local';

  bool _iconoEmprendimientoCargado =
      false;

  bool _iconoLocalCargado =
      false;

  bool _capaEmprendimientosCargada =
      false;

  bool _capaLocalesCargada =
      false;

  // ============================================================
  // CONCENTRACIÓN
  // ============================================================

  static const List<String>
      _sourcesConcentracion = [
    'admin1-conc-sin',
    'admin1-conc-baja',
    'admin1-conc-media',
    'admin1-conc-alta',
    'admin1-conc-muy-alta',
  ];

  static const List<String>
      _layersConcentracion = [
    'admin1-conc-sin-layer',
    'admin1-conc-baja-layer',
    'admin1-conc-media-layer',
    'admin1-conc-alta-layer',
    'admin1-conc-muy-alta-layer',
  ];

  final Map<int, String>
      _departamentoPorFeatureId =
      {};

  final Map<String,
          _MetricaDepartamento>
      _metricas =
      {};

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _cargarGeoJson();

    _cargarDatos();
  }

  // ============================================================
  // BLOQUEAR MAPA
  // ============================================================

  void _bloquearMapa() {
    _bloqueosInteraccionMapa++;

    if (mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // LIBERAR MAPA
  // ============================================================

  Future<void> _liberarMapa() async {
    // Evita que el último pointer-up del BottomSheet
    // caiga inmediatamente sobre MapLibre.

    await Future<void>.delayed(
      const Duration(
        milliseconds: 220,
      ),
    );

    if (_bloqueosInteraccionMapa >
        0) {
      _bloqueosInteraccionMapa--;
    }

    if (mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // BOTTOM SHEET PROTEGIDO
  // ============================================================

  Future<T?> _mostrarModalMapa<T>({
    required WidgetBuilder builder,
    bool isScrollControlled = false,
  }) async {
    _bloquearMapa();

    try {
      return await showModalBottomSheet<T>(
        context: context,
        showDragHandle: true,
        isScrollControlled:
            isScrollControlled,
        builder: builder,
      );
    } finally {
      await _liberarMapa();
    }
  }

  // ============================================================
  // CARGAR GEOJSON
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
        ],
      );

      final admin0Decoded =
          jsonDecode(
        textos[0],
      );

      final admin1Decoded =
          jsonDecode(
        textos[1],
      );

      if (admin0Decoded is! Map ||
          admin1Decoded is! Map) {
        throw Exception(
          'Los archivos GeoJSON no tienen una estructura válida.',
        );
      }

      _admin0 =
          Map<String, dynamic>.from(
        admin0Decoded,
      );

      _admin1 =
          Map<String, dynamic>.from(
        admin1Decoded,
      );

      _mascara =
          _crearMascara(
        _admin0!,
      );

      _prepararDepartamentos();

      if (!mounted) {
        return;
      }

      setState(() {
        _geoJsonCargado =
            true;

        _error =
            null;
      });

      _recalcularMetricas();

      await _sincronizarMapa();
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error =
            'No se pudo cargar el mapa administrativo.\n$e';
      });
    }
  }

  // ============================================================
  // CARGAR DATOS
  // ============================================================

  Future<void> _cargarDatos() async {
    if (mounted) {
      setState(() {
        _cargandoDatos =
            true;

        _error =
            null;
      });
    }

    try {
      final datos =
          await AdminMapaService
              .cargar();

      if (!mounted) {
        return;
      }

      setState(() {
        _emprendimientos =
            datos.emprendimientos;

        _locales =
            datos.locales;

        _cargandoDatos =
            false;

        _error =
            null;
      });

      _recalcularMetricas();

      await _sincronizarMapa();
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _cargandoDatos =
            false;

        _error = e
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            );
      });
    }
  }

  // ============================================================
  // ACTUALIZAR TODO
  // ============================================================

  Future<void>
      _actualizarTodo() async {
    await _cargarDatos();

    if (!mounted) {
      return;
    }

    _mostrarMensaje(
      'Mapa administrativo actualizado',
    );
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
      for (final rawFeature
          in features) {
        if (rawFeature is! Map) {
          continue;
        }

        final geometry =
            rawFeature['geometry'];

        if (geometry is! Map) {
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
              exterior.reversed
                  .toList(),
            );
          }
        }

        if (tipo ==
                'MultiPolygon' &&
            coordinates is List) {
          for (final polygon
              in coordinates) {
            if (polygon is List &&
                polygon.isNotEmpty &&
                polygon[0] is List) {
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
  // PREPARAR DEPARTAMENTOS
  // ============================================================

  void _prepararDepartamentos() {
    final features =
        _admin1?['features'];

    _departamentoPorFeatureId
        .clear();

    _metricas.clear();

    if (features is! List) {
      return;
    }

    for (int i = 0;
        i < features.length;
        i++) {
      final raw =
          features[i];

      if (raw is! Map) {
        continue;
      }

      final properties =
          raw['properties'];

      if (properties is! Map) {
        continue;
      }

      final nombre =
          _obtenerNombreDepartamento(
        Map<String, dynamic>.from(
          properties,
        ),
      );

      if (nombre.isEmpty) {
        continue;
      }

      final id =
          i + 1;

      _departamentoPorFeatureId[
          id] = nombre;

      _metricas[nombre] =
          _MetricaDepartamento(
        nombre:
            nombre,
      );
    }
  }

  // ============================================================
  // NOMBRE DEPARTAMENTO
  // ============================================================

  String _obtenerNombreDepartamento(
    Map<String, dynamic> properties,
  ) {
    const posiblesCampos = [
      'shapeName',
      'NAME_1',
      'NAME',
      'name',
      'ADM1_ES',
      'ADM1',
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

  // ============================================================
  // RECALCULAR MÉTRICAS
  // ============================================================

  void _recalcularMetricas() {
    if (!_geoJsonCargado ||
        _admin1 == null) {
      return;
    }

    for (final metrica
        in _metricas.values) {
      metrica.emprendimientos =
          0;

      metrica.locales =
          0;

      metrica.nivel =
          0;
    }

    // ==========================================================
    // EMPRENDIMIENTOS
    // ==========================================================

    for (final emprendimiento
        in _emprendimientos) {
      final lat =
          emprendimiento.latitud;

      final lon =
          emprendimiento.longitud;

      if (lat == null ||
          lon == null) {
        continue;
      }

      final departamento =
          _departamentoParaPunto(
        lat,
        lon,
      );

      if (departamento !=
          null) {
        _metricas[departamento]
            ?.emprendimientos++;
      }
    }

    // ==========================================================
    // LOCALES
    // ==========================================================

    for (final local
        in _locales) {
      final lat =
          local.latitud;

      final lon =
          local.longitud;

      if (lat == null ||
          lon == null) {
        continue;
      }

      final departamento =
          _departamentoParaPunto(
        lat,
        lon,
      );

      if (departamento !=
          null) {
        _metricas[departamento]
            ?.locales++;
      }
    }

    int maximo =
        0;

    for (final metrica
        in _metricas.values) {
      maximo =
          max(
        maximo,
        metrica.emprendimientos,
      );
    }

    for (final metrica
        in _metricas.values) {
      metrica.nivel =
          _nivelConcentracion(
        metrica.emprendimientos,
        maximo,
      );
    }
  }

  // ============================================================
  // NIVEL CONCENTRACIÓN
  // ============================================================

  int _nivelConcentracion(
    int cantidad,
    int maximo,
  ) {
    if (cantidad <= 0 ||
        maximo <= 0) {
      return 0;
    }

    final proporcion =
        cantidad /
            maximo;

    if (proporcion <=
        0.25) {
      return 1;
    }

    if (proporcion <=
        0.50) {
      return 2;
    }

    if (proporcion <=
        0.75) {
      return 3;
    }

    return 4;
  }

  // ============================================================
  // DEPARTAMENTO PARA PUNTO
  // ============================================================

  String? _departamentoParaPunto(
    double latitud,
    double longitud,
  ) {
    final features =
        _admin1?['features'];

    if (features is! List) {
      return null;
    }

    for (final raw
        in features) {
      if (raw is! Map) {
        continue;
      }

      final properties =
          raw['properties'];

      final geometry =
          raw['geometry'];

      if (properties is! Map ||
          geometry is! Map) {
        continue;
      }

      final dentro =
          _puntoDentroGeometry(
        longitud,
        latitud,
        Map<String, dynamic>.from(
          geometry,
        ),
      );

      if (!dentro) {
        continue;
      }

      final nombre =
          _obtenerNombreDepartamento(
        Map<String, dynamic>.from(
          properties,
        ),
      );

      if (nombre.isEmpty) {
        return null;
      }

      return nombre;
    }

    return null;
  }

  // ============================================================
  // PUNTO DENTRO GEOMETRY
  // ============================================================

  bool _puntoDentroGeometry(
    double longitud,
    double latitud,
    Map<String, dynamic> geometry,
  ) {
    final tipo =
        geometry['type']
            ?.toString();

    final coordinates =
        geometry['coordinates'];

    if (tipo == 'Polygon' &&
        coordinates is List) {
      return _puntoDentroPolygon(
        longitud,
        latitud,
        coordinates,
      );
    }

    if (tipo ==
            'MultiPolygon' &&
        coordinates is List) {
      for (final polygon
          in coordinates) {
        if (polygon is List &&
            _puntoDentroPolygon(
              longitud,
              latitud,
              polygon,
            )) {
          return true;
        }
      }
    }

    return false;
  }

  // ============================================================
  // PUNTO DENTRO POLYGON
  // ============================================================

  bool _puntoDentroPolygon(
    double longitud,
    double latitud,
    List<dynamic> polygon,
  ) {
    if (polygon.isEmpty ||
        polygon.first is! List) {
      return false;
    }

    final exterior =
        polygon.first as List;

    if (!_puntoDentroRing(
      longitud,
      latitud,
      exterior,
    )) {
      return false;
    }

    for (int i = 1;
        i < polygon.length;
        i++) {
      final hueco =
          polygon[i];

      if (hueco is List &&
          _puntoDentroRing(
            longitud,
            latitud,
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

  bool _puntoDentroRing(
    double x,
    double y,
    List<dynamic> ring,
  ) {
    if (ring.length <
        3) {
      return false;
    }

    bool dentro =
        false;

    int j =
        ring.length - 1;

    for (int i = 0;
        i < ring.length;
        i++) {
      final puntoA =
          ring[i];

      final puntoB =
          ring[j];

      if (puntoA is! List ||
          puntoB is! List ||
          puntoA.length < 2 ||
          puntoB.length < 2) {
        j = i;

        continue;
      }

      final xi =
          (puntoA[0] as num)
              .toDouble();

      final yi =
          (puntoA[1] as num)
              .toDouble();

      final xj =
          (puntoB[0] as num)
              .toDouble();

      final yj =
          (puntoB[1] as num)
              .toDouble();

      final denominador =
          (yj - yi).abs() <
                  0.0000000001
              ? 0.0000000001
              : yj - yi;

      final intersecta =
          ((yi > y) !=
                  (yj > y)) &&
              (x <
                  ((xj - xi) *
                          (y - yi) /
                          denominador) +
                      xi);

      if (intersecta) {
        dentro =
            !dentro;
      }

      j =
          i;
    }

    return dentro;
  }

  // ============================================================
  // MAP CREATED
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
  // STYLE LOADED
  // ============================================================

  Future<void>
      _onStyleLoaded() async {
    _estiloCargado =
        true;

    _capasBaseCargadas =
        false;

    _capasConcentracionCargadas =
        false;

    _iconoEmprendimientoCargado =
        false;

    _iconoLocalCargado =
        false;

    _capaEmprendimientosCargada =
        false;

    _capaLocalesCargada =
        false;

    if (mounted) {
      setState(() {});
    }

    await _sincronizarMapa();
  }

  // ============================================================
  // SINCRONIZAR
  // ============================================================

  Future<void>
      _sincronizarMapa() async {
    if (!_estiloCargado ||
        !_geoJsonCargado ||
        _mapController ==
            null) {
      return;
    }

    await _agregarCapasBase();

    await _cargarIconosMapa();

    await _actualizarConcentracion();

    await _dibujarEmprendimientos();

    await _dibujarLocales();
  }

  // ============================================================
  // CAPAS BASE
  // ============================================================

  Future<void>
      _agregarCapasBase() async {
    final controller =
        _mapController;

    if (controller == null ||
        _capasBaseCargadas ||
        _admin0 == null ||
        _admin1 == null ||
        _mascara == null) {
      return;
    }

    final oscuro =
        Theme.of(context)
                .brightness ==
            Brightness.dark;

    try {
      await controller.addGeoJsonSource(
        'admin-map-mask',
        _mascara!,
      );

      await controller.addGeoJsonSource(
        'admin-map-admin0',
        _admin0!,
      );

      await controller.addGeoJsonSource(
        'admin-map-admin1',
        _admin1!,
      );

      await controller.addFillLayer(
        'admin-map-mask',
        'admin-map-mask-layer',
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

      await controller.addLineLayer(
        'admin-map-admin1',
        'admin-map-admin1-line',
        const LineLayerProperties(
          lineColor:
              '#FF7E01',

          lineOpacity:
              0.95,

          lineWidth:
              1.6,
        ),
        minzoom:
            7.4,
      );

      await controller.addLineLayer(
        'admin-map-admin0',
        'admin-map-admin0-line',
        const LineLayerProperties(
          lineColor:
              '#C95400',

          lineOpacity:
              1,

          lineWidth:
              3,
        ),
      );

      _capasBaseCargadas =
          true;
    } catch (e) {
      debugPrint(
        'ERROR CAPAS BASE ADMIN: $e',
      );
    }
  }

  // ============================================================
  // CONCENTRACIÓN
  // ============================================================

  Future<void>
      _actualizarConcentracion() async {
    final controller =
        _mapController;

    if (controller == null ||
        !_estiloCargado ||
        !_geoJsonCargado) {
      return;
    }

    final grupos =
        List.generate(
      5,
      (_) =>
          <Map<String, dynamic>>[],
    );

    _departamentoPorFeatureId
        .clear();

    final features =
        _admin1?['features'];

    if (features is List) {
      for (int i = 0;
          i < features.length;
          i++) {
        final raw =
            features[i];

        if (raw is! Map) {
          continue;
        }

        final properties =
            raw['properties'];

        if (properties is! Map) {
          continue;
        }

        final nombre =
            _obtenerNombreDepartamento(
          Map<String, dynamic>.from(
            properties,
          ),
        );

        if (nombre.isEmpty) {
          continue;
        }

        final metrica =
            _metricas[nombre] ??
                _MetricaDepartamento(
                  nombre:
                      nombre,
                );

        final id =
            i + 1;

        _departamentoPorFeatureId[
            id] = nombre;

        final feature =
            Map<String, dynamic>.from(
          raw,
        );

        feature['id'] =
            id.toString();

        feature['properties'] = {
          ...Map<String, dynamic>.from(
            properties,
          ),
          'departamento':
              nombre,
          'emprendimientos':
              metrica.emprendimientos,
          'locales':
              metrica.locales,
          'total':
              metrica.total,
          'nivel_concentracion':
              metrica.nivel,
        };

        grupos[metrica.nivel]
            .add(
          feature,
        );
      }
    }

    final colecciones =
        grupos
            .map(
              (grupo) =>
                  <String, dynamic>{
                'type':
                    'FeatureCollection',
                'features':
                    grupo,
              },
            )
            .toList();

    if (_capasConcentracionCargadas) {
      for (int i = 0;
          i < 5;
          i++) {
        await controller
            .setGeoJsonSource(
          _sourcesConcentracion[i],
          colecciones[i],
        );
      }

      await _cambiarVisibilidadConcentracion();

      return;
    }

    const colores = [
      '#FFF3E6',
      '#FFD4A3',
      '#FFAE66',
      '#FF7E01',
      '#C95400',
    ];

    const opacidades = [
      0.10,
      0.30,
      0.42,
      0.52,
      0.64,
    ];

    for (int i = 0;
        i < 5;
        i++) {
      await controller.addGeoJsonSource(
        _sourcesConcentracion[i],
        colecciones[i],
      );

      await controller.addFillLayer(
        _sourcesConcentracion[i],
        _layersConcentracion[i],
        FillLayerProperties(
          fillColor:
              colores[i],

          fillOpacity:
              _mostrarConcentracion
                  ? opacidades[i]
                  : 0,

          fillOutlineColor:
              '#FF7E01',
        ),
        enableInteraction:
            true,
      );
    }

    _capasConcentracionCargadas =
        true;
  }

  // ============================================================
  // VISIBILIDAD CONCENTRACIÓN
  // ============================================================

  Future<void>
      _cambiarVisibilidadConcentracion() async {
    final controller =
        _mapController;

    if (controller == null ||
        !_capasConcentracionCargadas) {
      return;
    }

    const opacidades = [
      0.10,
      0.30,
      0.42,
      0.52,
      0.64,
    ];

    for (int i = 0;
        i < 5;
        i++) {
      try {
        await controller
            .setLayerProperties(
          _layersConcentracion[i],
          FillLayerProperties(
            fillOpacity:
                _mostrarConcentracion
                    ? opacidades[i]
                    : 0,
          ),
        );
      } catch (e) {
        debugPrint(
          'ERROR VISIBILIDAD CONCENTRACIÓN: $e',
        );
      }
    }
  }

  // ============================================================
  // ICONOS
  // ============================================================

  Future<void>
      _cargarIconosMapa() async {
    if (!_iconoEmprendimientoCargado) {
      _iconoEmprendimientoCargado =
          await _registrarIcono(
        asset:
            'assets/mapas/tienda.png',

        nombre:
            _iconoEmprendimiento,
      );
    }

    if (!_iconoLocalCargado) {
      _iconoLocalCargado =
          await _registrarIcono(
        asset:
            'assets/mapas/local.png',

        nombre:
            _iconoLocal,
      );
    }
  }

  Future<bool> _registrarIcono({
    required String asset,
    required String nombre,
  }) async {
    final controller =
        _mapController;

    if (controller == null) {
      return false;
    }

    ui.Codec? codec;

    ui.Image? imagen;

    try {
      final data =
          await rootBundle.load(
        asset,
      );

      final Uint8List bytesOriginales =
          data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );

      codec =
          await ui.instantiateImageCodec(
        bytesOriginales,
        targetWidth:
            96,
      );

      final frame =
          await codec.getNextFrame();

      imagen =
          frame.image;

      final pngData =
          await imagen.toByteData(
        format:
            ui.ImageByteFormat.png,
      );

      if (pngData == null) {
        return false;
      }

      final bytesFinales =
          pngData.buffer.asUint8List(
        pngData.offsetInBytes,
        pngData.lengthInBytes,
      );

      await controller.addImage(
        nombre,
        Uint8List.fromList(
          bytesFinales,
        ),
      );

      return true;
    } catch (e) {
      debugPrint(
        'ERROR CARGANDO ICONO $asset: $e',
      );

      return false;
    } finally {
      imagen?.dispose();

      codec?.dispose();
    }
  }

  // ============================================================
  // EMPRENDIMIENTOS
  // ============================================================

  Future<void>
      _dibujarEmprendimientos() async {
    final controller =
        _mapController;

    if (controller == null ||
        !_estiloCargado ||
        !_iconoEmprendimientoCargado) {
      return;
    }

    final features =
        <Map<String, dynamic>>[];

    if (_mostrarEmprendimientos) {
      for (final emprendimiento
          in _emprendimientos) {
        if (emprendimiento.latitud ==
                null ||
            emprendimiento.longitud ==
                null) {
          continue;
        }

        features.add({
          'type':
              'Feature',

          'id':
              emprendimiento.id
                  .toString(),

          'properties': {
            'tipo':
                'emprendimiento',

            'emprendimiento_id':
                emprendimiento.id,

            'nombre':
                emprendimiento.nombre,
          },

          'geometry': {
            'type':
                'Point',

            'coordinates': [
              emprendimiento.longitud!,
              emprendimiento.latitud!,
            ],
          },
        });
      }
    }

    final geojson =
        <String, dynamic>{
      'type':
          'FeatureCollection',

      'features':
          features,
    };

    try {
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
              _iconoEmprendimiento,

          iconSize:
              0.55,

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
        'ERROR EMPRENDIMIENTOS ADMIN: $e',
      );
    }
  }

  // ============================================================
  // LOCALES
  // ============================================================

  Future<void> _dibujarLocales() async {
    final controller =
        _mapController;

    if (controller == null ||
        !_estiloCargado ||
        !_iconoLocalCargado) {
      return;
    }

    final features =
        <Map<String, dynamic>>[];

    if (_mostrarLocales) {
      for (final local
          in _locales) {
        if (local.latitud ==
                null ||
            local.longitud ==
                null) {
          continue;
        }

        features.add({
          'type':
              'Feature',

          'id':
              local.id
                  .toString(),

          'properties': {
            'tipo':
                'local_comercial',

            'local_id':
                local.id,

            'nombre':
                local.titulo,
          },

          'geometry': {
            'type':
                'Point',

            'coordinates': [
              local.longitud!,
              local.latitud!,
            ],
          },
        });
      }
    }

    final geojson =
        <String, dynamic>{
      'type':
          'FeatureCollection',

      'features':
          features,
    };

    try {
      if (_capaLocalesCargada) {
        await controller
            .setGeoJsonSource(
          _sourceLocales,
          geojson,
        );

        return;
      }

      await controller.addGeoJsonSource(
        _sourceLocales,
        geojson,
      );

      await controller.addSymbolLayer(
        _sourceLocales,
        _layerLocales,
        const SymbolLayerProperties(
          iconImage:
              _iconoLocal,

          iconSize:
              0.55,

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

      _capaLocalesCargada =
          true;
    } catch (e) {
      debugPrint(
        'ERROR LOCALES ADMIN: $e',
      );
    }
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
    // ==========================================================
    // IMPORTANTE
    // ==========================================================

    if (_mapaBloqueado) {
      return;
    }

    final elementoId =
        int.tryParse(
      id,
    );

    if (elementoId == null) {
      return;
    }

    // ==========================================================
    // EMPRENDIMIENTO
    // ==========================================================

    if (layerId ==
        _layerEmprendimientos) {
      _mostrarEmprendimiento(
        elementoId,
      );

      return;
    }

    // ==========================================================
    // LOCAL
    // ==========================================================

    if (layerId ==
        _layerLocales) {
      _mostrarLocal(
        elementoId,
      );

      return;
    }

    // ==========================================================
    // DEPARTAMENTO
    // ==========================================================

    final indice =
        _layersConcentracion
            .indexOf(
      layerId,
    );

    if (indice >= 0) {
      final departamento =
          _departamentoPorFeatureId[
              elementoId];

      if (departamento != null) {
        _mostrarDepartamento(
          departamento,
        );
      }
    }
  }

  // ============================================================
  // MODAL EMPRENDIMIENTO
  // ============================================================

  void _mostrarEmprendimiento(
    int id,
  ) {
    Emprendimiento? seleccionado;

    for (final emprendimiento
        in _emprendimientos) {
      if (emprendimiento.id ==
          id) {
        seleccionado =
            emprendimiento;

        break;
      }
    }

    if (seleccionado == null) {
      return;
    }

    final emprendimiento =
        seleccionado;

    _mostrarModalMapa(
      isScrollControlled:
          true,

      builder:
          (bottomContext) {
        return SafeArea(
          child:
              SingleChildScrollView(
            padding:
                const EdgeInsets.fromLTRB(
              20,
              0,
              20,
              24,
            ),

            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              mainAxisSize:
                  MainAxisSize.min,

              children: [
                Row(
                  children: [
                    SizedBox(
                      width:
                          52,

                      height:
                          52,

                      child:
                          Image.asset(
                        'assets/mapas/tienda.png',

                        fit:
                            BoxFit.contain,
                      ),
                    ),

                    const SizedBox(
                      width:
                          14,
                    ),

                    Expanded(
                      child:
                          Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [
                          Text(
                            emprendimiento.nombre,

                            style:
                                const TextStyle(
                              fontSize:
                                  20,

                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),

                          const SizedBox(
                            height:
                                3,
                          ),

                          const Text(
                            'Emprendimiento',

                            style:
                                TextStyle(
                              color:
                                  _verde,

                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (emprendimiento.descripcion !=
                        null &&
                    emprendimiento
                        .descripcion!
                        .trim()
                        .isNotEmpty) ...[
                  const SizedBox(
                    height:
                        18,
                  ),

                  Text(
                    emprendimiento
                        .descripcion!,
                  ),
                ],

                const SizedBox(
                  height:
                      18,
                ),

                _detalleFila(
                  Icons.location_on_outlined,
                  'Coordenadas',
                  '${emprendimiento.latitud?.toStringAsFixed(5)}, '
                      '${emprendimiento.longitud?.toStringAsFixed(5)}',
                ),

                if (emprendimiento.telefono !=
                        null &&
                    emprendimiento
                        .telefono!
                        .trim()
                        .isNotEmpty)
                  _detalleFila(
                    Icons.phone_outlined,
                    'Teléfono',
                    emprendimiento
                        .telefono!,
                  ),

                if (emprendimiento.correoContacto !=
                        null &&
                    emprendimiento
                        .correoContacto!
                        .trim()
                        .isNotEmpty)
                  _detalleFila(
                    Icons.email_outlined,
                    'Correo',
                    emprendimiento
                        .correoContacto!,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // MODAL LOCAL
  // ============================================================

  void _mostrarLocal(
    int id,
  ) {
    LocalComercial? seleccionado;

    for (final local
        in _locales) {
      if (local.id ==
          id) {
        seleccionado =
            local;

        break;
      }
    }

    if (seleccionado == null) {
      return;
    }

    final local =
        seleccionado;

    _mostrarModalMapa(
      isScrollControlled:
          true,

      builder:
          (bottomContext) {
        return SafeArea(
          child:
              SingleChildScrollView(
            padding:
                const EdgeInsets.fromLTRB(
              20,
              0,
              20,
              24,
            ),

            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              mainAxisSize:
                  MainAxisSize.min,

              children: [
                Row(
                  children: [
                    SizedBox(
                      width:
                          52,

                      height:
                          52,

                      child:
                          Image.asset(
                        'assets/mapas/local.png',

                        fit:
                            BoxFit.contain,
                      ),
                    ),

                    const SizedBox(
                      width:
                          14,
                    ),

                    Expanded(
                      child:
                          Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [
                          Text(
                            local.titulo,

                            style:
                                const TextStyle(
                              fontSize:
                                  20,

                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),

                          const SizedBox(
                            height:
                                3,
                          ),

                          const Text(
                            'Local comercial',

                            style:
                                TextStyle(
                              color:
                                  _rojo,

                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height:
                      18,
                ),

                _detalleFila(
                  Icons.sell_outlined,
                  'Operación',
                  local.tipoOperacion ==
                          'venta'
                      ? 'Venta'
                      : 'Alquiler',
                ),

                _detalleFila(
                  Icons.apartment_outlined,
                  'Tipo',
                  local.tipoLocal,
                ),

                _detalleFila(
                  Icons.payments_outlined,
                  'Precio',
                  local.precioTexto,
                ),

                _detalleFila(
                  Icons.location_city_outlined,
                  'Departamento',
                  local.departamento,
                ),

                _detalleFila(
                  Icons.location_on_outlined,
                  'Municipio',
                  local.municipio,
                ),

                _detalleFila(
                  Icons.map_outlined,
                  'Dirección',
                  local.direccion,
                ),

                _detalleFila(
                  Icons.visibility_outlined,
                  'Estado',
                  local.activo
                      ? 'Activo'
                      : 'Oculto',
                ),

                _detalleFila(
                  Icons.event_available_outlined,
                  'Disponibilidad',
                  local.disponible
                      ? 'Disponible'
                      : 'No disponible',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // MODAL DEPARTAMENTO
  // ============================================================

  void _mostrarDepartamento(
    String nombre,
  ) {
    final metrica =
        _metricas[nombre];

    if (metrica == null) {
      return;
    }

    _mostrarModalMapa(
      builder:
          (bottomContext) {
        return SafeArea(
          child:
              Padding(
            padding:
                const EdgeInsets.fromLTRB(
              20,
              0,
              20,
              24,
            ),

            child:
                Column(
              mainAxisSize:
                  MainAxisSize.min,

              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Row(
                  children: [
                    Container(
                      width:
                          50,

                      height:
                          50,

                      decoration:
                          BoxDecoration(
                        color:
                            _colorNivel(
                                  metrica.nivel,
                                )
                                .withValues(
                          alpha:
                              0.16,
                        ),

                        borderRadius:
                            BorderRadius.circular(
                          15,
                        ),
                      ),

                      child:
                          Icon(
                        Icons.map_outlined,

                        color:
                            _colorNivel(
                          metrica.nivel,
                        ),
                      ),
                    ),

                    const SizedBox(
                      width:
                          14,
                    ),

                    Expanded(
                      child:
                          Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [
                          Text(
                            nombre,

                            style:
                                const TextStyle(
                              fontSize:
                                  21,

                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),

                          Text(
                            _textoNivel(
                              metrica.nivel,
                            ),

                            style:
                                TextStyle(
                              color:
                                  _colorNivel(
                                metrica.nivel,
                              ),

                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height:
                      20,
                ),

                Row(
                  children: [
                    Expanded(
                      child:
                          _tarjetaMetrica(
                        titulo:
                            'Emprendimientos',

                        cantidad:
                            metrica.emprendimientos,

                        icono:
                            Icons.storefront_outlined,

                        color:
                            _verde,
                      ),
                    ),

                    const SizedBox(
                      width:
                          10,
                    ),

                    Expanded(
                      child:
                          _tarjetaMetrica(
                        titulo:
                            'Locales',

                        cantidad:
                            metrica.locales,

                        icono:
                            Icons.apartment_outlined,

                        color:
                            _rojo,
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height:
                      10,
                ),

                _tarjetaMetrica(
                  titulo:
                      'Total de ubicaciones comerciales',

                  cantidad:
                      metrica.total,

                  icono:
                      Icons.place_outlined,

                  color:
                      _naranjaPrincipal,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // FILA DETALLE
  // ============================================================

  Widget _detalleFila(
    IconData icono,
    String titulo,
    String valor,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom:
            12,
      ),

      child:
          Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Container(
            width:
                38,

            height:
                38,

            decoration:
                BoxDecoration(
              color:
                  _naranjaPrincipal
                      .withValues(
                alpha:
                    0.10,
              ),

              borderRadius:
                  BorderRadius.circular(
                11,
              ),
            ),

            child:
                Icon(
              icono,

              size:
                  20,

              color:
                  _naranjaPrincipal,
            ),
          ),

          const SizedBox(
            width:
                12,
          ),

          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  titulo,

                  style:
                      TextStyle(
                    fontSize:
                        12,

                    color:
                        Colors.grey.shade600,

                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                const SizedBox(
                  height:
                      2,
                ),

                Text(
                  valor,

                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TARJETA MÉTRICA
  // ============================================================

  Widget _tarjetaMetrica({
    required String titulo,
    required int cantidad,
    required IconData icono,
    required Color color,
  }) {
    return Container(
      padding:
          const EdgeInsets.all(
        14,
      ),

      decoration:
          BoxDecoration(
        color:
            color.withValues(
          alpha:
              0.08,
        ),

        borderRadius:
            BorderRadius.circular(
          14,
        ),

        border:
            Border.all(
          color:
              color.withValues(
            alpha:
                0.18,
          ),
        ),
      ),

      child:
          Row(
        children: [
          Icon(
            icono,

            color:
                color,
          ),

          const SizedBox(
            width:
                10,
          ),

          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  '$cantidad',

                  style:
                      TextStyle(
                    fontSize:
                        20,

                    color:
                        color,

                    fontWeight:
                        FontWeight.w900,
                  ),
                ),

                Text(
                  titulo,

                  maxLines:
                      2,

                  overflow:
                      TextOverflow.ellipsis,

                  style:
                      const TextStyle(
                    fontSize:
                        11,

                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COLOR NIVEL
  // ============================================================

  Color _colorNivel(
    int nivel,
  ) {
    switch (nivel) {
      case 1:
        return const Color(
          0xFFFFC27A,
        );

      case 2:
        return const Color(
          0xFFFFA347,
        );

      case 3:
        return _naranjaPrincipal;

      case 4:
        return _naranjaOscuro;

      default:
        return Colors.grey;
    }
  }

  // ============================================================
  // TEXTO NIVEL
  // ============================================================

  String _textoNivel(
    int nivel,
  ) {
    switch (nivel) {
      case 1:
        return 'Concentración baja';

      case 2:
        return 'Concentración media';

      case 3:
        return 'Concentración alta';

      case 4:
        return 'Concentración muy alta';

      default:
        return 'Sin emprendimientos registrados';
    }
  }

  // ============================================================
  // SELECTOR CAPAS
  // ============================================================

  void _mostrarSelectorCapas() {
    _mostrarModalMapa(
      builder:
          (bottomContext) {
        return StatefulBuilder(
          builder:
              (
            context,
            setModalState,
          ) {
            return SafeArea(
              child:
                  Padding(
                padding:
                    const EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  22,
                ),

                child:
                    Column(
                  mainAxisSize:
                      MainAxisSize.min,

                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,

                  children: [
                    const Padding(
                      padding:
                          EdgeInsets.fromLTRB(
                        8,
                        0,
                        8,
                        14,
                      ),

                      child:
                          Text(
                        'Capas del mapa',

                        style:
                            TextStyle(
                          fontSize:
                              20,

                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                    ),

                    SwitchListTile(
                      secondary:
                          const Icon(
                        Icons.gradient_outlined,

                        color:
                            _naranjaPrincipal,
                      ),

                      title:
                          const Text(
                        'Concentración territorial',

                        style:
                            TextStyle(
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),

                      subtitle:
                          const Text(
                        'Intensidad de emprendimientos por departamento',
                      ),

                      value:
                          _mostrarConcentracion,

                      activeThumbColor:
                          _naranjaPrincipal,

                      onChanged:
                          (value) async {
                        setState(() {
                          _mostrarConcentracion =
                              value;
                        });

                        setModalState(
                          () {},
                        );

                        await _cambiarVisibilidadConcentracion();
                      },
                    ),

                    const Divider(),

                    SwitchListTile(
                      secondary:
                          SizedBox(
                        width:
                            38,

                        height:
                            38,

                        child:
                            Image.asset(
                          'assets/mapas/tienda.png',
                        ),
                      ),

                      title:
                          const Text(
                        'Emprendimientos',

                        style:
                            TextStyle(
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),

                      subtitle:
                          Text(
                        '${_emprendimientos.length} con ubicación',
                      ),

                      value:
                          _mostrarEmprendimientos,

                      activeThumbColor:
                          _verde,

                      onChanged:
                          (value) async {
                        setState(() {
                          _mostrarEmprendimientos =
                              value;
                        });

                        setModalState(
                          () {},
                        );

                        await _dibujarEmprendimientos();
                      },
                    ),

                    SwitchListTile(
                      secondary:
                          SizedBox(
                        width:
                            38,

                        height:
                            38,

                        child:
                            Image.asset(
                          'assets/mapas/local.png',
                        ),
                      ),

                      title:
                          const Text(
                        'Locales comerciales',

                        style:
                            TextStyle(
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),

                      subtitle:
                          Text(
                        '${_locales.length} con ubicación',
                      ),

                      value:
                          _mostrarLocales,

                      activeThumbColor:
                          _rojo,

                      onChanged:
                          (value) async {
                        setState(() {
                          _mostrarLocales =
                              value;
                        });

                        setModalState(
                          () {},
                        );

                        await _dibujarLocales();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // ACTIVIDAD TERRITORIAL
  // ============================================================

  void _mostrarListadoDepartamentos() {
    final lista =
        _metricas.values
            .toList()
          ..sort(
            (
              a,
              b,
            ) =>
                b.emprendimientos
                    .compareTo(
              a.emprendimientos,
            ),
          );

    _mostrarModalMapa(
      isScrollControlled:
          true,

      builder:
          (bottomContext) {
        return SafeArea(
          child:
              DraggableScrollableSheet(
            expand:
                false,

            initialChildSize:
                0.72,

            minChildSize:
                0.40,

            maxChildSize:
                0.92,

            builder:
                (
              context,
              scrollController,
            ) {
              return Column(
                children: [
                  const Padding(
                    padding:
                        EdgeInsets.fromLTRB(
                      20,
                      0,
                      20,
                      14,
                    ),

                    child:
                        Row(
                      children: [
                        Icon(
                          Icons.bar_chart_rounded,

                          color:
                              _naranjaPrincipal,
                        ),

                        SizedBox(
                          width:
                              10,
                        ),

                        Expanded(
                          child:
                              Text(
                            'Actividad territorial',

                            style:
                                TextStyle(
                              fontSize:
                                  20,

                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child:
                        ListView.separated(
                      controller:
                          scrollController,

                      physics:
                          const ClampingScrollPhysics(),

                      padding:
                          const EdgeInsets.fromLTRB(
                        16,
                        0,
                        16,
                        24,
                      ),

                      itemCount:
                          lista.length,

                      separatorBuilder:
                          (
                        context,
                        index,
                      ) =>
                              const SizedBox(
                        height:
                            8,
                      ),

                      itemBuilder:
                          (
                        context,
                        index,
                      ) {
                        final metrica =
                            lista[index];

                        return Material(
                          color:
                              Theme.of(
                                        context,
                                      ).brightness ==
                                      Brightness.dark
                                  ? _panelOscuro
                                  : Colors.white,

                          borderRadius:
                              BorderRadius.circular(
                            14,
                          ),

                          child:
                              ListTile(
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                14,
                              ),
                            ),

                            leading:
                                CircleAvatar(
                              backgroundColor:
                                  _colorNivel(
                                        metrica.nivel,
                                      )
                                      .withValues(
                                alpha:
                                    0.15,
                              ),

                              foregroundColor:
                                  _colorNivel(
                                metrica.nivel,
                              ),

                              child:
                                  Text(
                                '${index + 1}',

                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight.w800,
                                ),
                              ),
                            ),

                            title:
                                Text(
                              metrica.nombre,

                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight.w700,
                              ),
                            ),

                            subtitle:
                                Text(
                              '${metrica.emprendimientos} emprendimientos · '
                              '${metrica.locales} locales',
                            ),

                            trailing:
                                const Icon(
                              Icons.chevron_right_rounded,
                            ),

                            onTap:
                                () {
                              Navigator.pop(
                                bottomContext,
                              );

                              _mostrarDepartamento(
                                metrica.nombre,
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  // ============================================================
  // CÁMARA
  // ============================================================

  Future<void> _animarCamara(
    CameraUpdate update,
  ) async {
    if (_mapaBloqueado) {
      return;
    }

    final controller =
        _mapController;

    if (controller == null) {
      return;
    }

    try {
      await controller.animateCamera(
        update,
      );
    } catch (e) {
      debugPrint(
        'ERROR MOVIENDO CÁMARA ADMIN: $e',
      );
    }
  }

  Future<void>
      _centrarElSalvador() async {
    if (_mapaBloqueado) {
      return;
    }

    _centroCamaraActual =
        _centroElSalvador;

    _zoomActual =
        8.5;

    _bearingActual =
        0;

    _tiltActual =
        0;

    await _animarCamara(
      CameraUpdate.newCameraPosition(
        const CameraPosition(
          target:
              _centroElSalvador,

          zoom:
              8.5,

          bearing:
              0,

          tilt:
              0,
        ),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _acercar() async {
    if (_mapaBloqueado) {
      return;
    }

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
    if (_mapaBloqueado) {
      return;
    }

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

  void _alternarRotacion() {
    if (_mapaBloqueado) {
      return;
    }

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

  Future<void>
      _restablecerAngulo() async {
    if (_mapaBloqueado ||
        !_rotacionActiva) {
      return;
    }

    _bearingActual =
        0;

    _tiltActual =
        0;

    await _animarCamara(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target:
              _centroCamaraActual,

          zoom:
              _zoomActual,

          bearing:
              0,

          tilt:
              0,
        ),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  String _nivelActual() {
    if (_zoomActual <
        8.5) {
      return 'ADMIN0';
    }

    if (_zoomActual <
        10) {
      return 'ADMIN1';
    }

    return 'DETALLE';
  }

  int get _departamentosConActividad {
    return _metricas.values
        .where(
          (metrica) =>
              metrica.total >
              0,
        )
        .length;
  }

  // ============================================================
  // BOTÓN MAPA
  // ============================================================

  Widget _botonMapa({
    required String tag,
    required IconData icono,
    required VoidCallback? onPressed,
    required bool oscuro,
    Color? color,
  }) {
    return FloatingActionButton.small(
      heroTag:
          tag,

      backgroundColor:
          oscuro
              ? _panelOscuro
              : Colors.white,

      foregroundColor:
          color ??
              _naranjaPrincipal,

      onPressed:
          _mapaBloqueado
              ? null
              : onPressed,

      child:
          Icon(
        icono,
      ),
    );
  }

  // ============================================================
  // PANEL ESTADÍSTICAS
  // ============================================================

  Widget _panelEstadisticas(
    bool oscuro,
  ) {
    final panel =
        oscuro
            ? _panelOscuro
            : Colors.white;

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal:
            12,
        vertical:
            10,
      ),

      decoration:
          BoxDecoration(
        color:
            panel.withValues(
          alpha:
              0.96,
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
                  0.12,
            ),

            blurRadius:
                12,

            offset:
                const Offset(
              0,
              4,
            ),
          ),
        ],
      ),

      child:
          Row(
        children: [
          Expanded(
            child:
                _indicadorSuperior(
              icono:
                  Icons.storefront_outlined,

              valor:
                  '${_emprendimientos.length}',

              etiqueta:
                  'Emprend.',

              color:
                  _verde,
            ),
          ),

          _separadorVertical(),

          Expanded(
            child:
                _indicadorSuperior(
              icono:
                  Icons.apartment_outlined,

              valor:
                  '${_locales.length}',

              etiqueta:
                  'Locales',

              color:
                  _rojo,
            ),
          ),

          _separadorVertical(),

          Expanded(
            child:
                _indicadorSuperior(
              icono:
                  Icons.map_outlined,

              valor:
                  '$_departamentosConActividad',

              etiqueta:
                  'Deptos.',

              color:
                  _naranjaPrincipal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _separadorVertical() {
    return Container(
      width:
          1,

      height:
          34,

      margin:
          const EdgeInsets.symmetric(
        horizontal:
            5,
      ),

      color:
          Colors.grey.withValues(
        alpha:
            0.25,
      ),
    );
  }

  Widget _indicadorSuperior({
    required IconData icono,
    required String valor,
    required String etiqueta,
    required Color color,
  }) {
    return Column(
      mainAxisSize:
          MainAxisSize.min,

      children: [
        Row(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            Icon(
              icono,

              size:
                  16,

              color:
                  color,
            ),

            const SizedBox(
              width:
                  4,
            ),

            Text(
              valor,

              style:
                  TextStyle(
                color:
                    color,

                fontSize:
                    16,

                fontWeight:
                    FontWeight.w900,
              ),
            ),
          ],
        ),

        const SizedBox(
          height:
              2,
        ),

        Text(
          etiqueta,

          maxLines:
              1,

          style:
              const TextStyle(
            fontSize:
                10,

            fontWeight:
                FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // LEYENDA
  // ============================================================

  Widget _leyenda(
    bool oscuro,
  ) {
    final panel =
        oscuro
            ? _panelOscuro
            : Colors.white;

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal:
            10,

        vertical:
            8,
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
          14,
        ),
      ),

      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        mainAxisSize:
            MainAxisSize.min,

        children: [
          const Text(
            'Concentración',

            style:
                TextStyle(
              fontSize:
                  11,

              fontWeight:
                  FontWeight.w800,
            ),
          ),

          const SizedBox(
            height:
                5,
          ),

          _itemLeyenda(
            const Color(
              0xFFFFD4A3,
            ),
            'Baja',
          ),

          _itemLeyenda(
            const Color(
              0xFFFFAE66,
            ),
            'Media',
          ),

          _itemLeyenda(
            _naranjaPrincipal,
            'Alta',
          ),

          _itemLeyenda(
            _naranjaOscuro,
            'Muy alta',
          ),
        ],
      ),
    );
  }

  Widget _itemLeyenda(
    Color color,
    String texto,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom:
            3,
      ),

      child:
          Row(
        mainAxisSize:
            MainAxisSize.min,

        children: [
          Container(
            width:
                10,

            height:
                10,

            decoration:
                BoxDecoration(
              color:
                  color,

              borderRadius:
                  BorderRadius.circular(
                3,
              ),
            ),
          ),

          const SizedBox(
            width:
                5,
          ),

          Text(
            texto,

            style:
                const TextStyle(
              fontSize:
                  10,

              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MENSAJE
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
                1500,
          ),

          content:
              Text(
            mensaje,
          ),
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

      appBar:
          AppBar(
        title:
            const Text(
          'Mapa administrativo',

          style:
              TextStyle(
            fontWeight:
                FontWeight.w800,

            color:
                Colors.white,
          ),
        ),

        centerTitle:
            true,

        backgroundColor:
            oscuro
                ? _panelOscuro
                : _naranjaPrincipal,

        foregroundColor:
            Colors.white,

        surfaceTintColor:
            Colors.transparent,

        actions: [
          IconButton(
            tooltip:
                'Actualizar',

            onPressed:
                _cargandoDatos ||
                        _mapaBloqueado
                    ? null
                    : _actualizarTodo,

            icon:
                _cargandoDatos
                    ? const SizedBox(
                        width:
                            20,

                        height:
                            20,

                        child:
                            CircularProgressIndicator(
                          strokeWidth:
                              2,

                          color:
                              Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.refresh_rounded,
                      ),
          ),
        ],
      ),

      body:
          Stack(
        children: [
          // ====================================================
          // MAPA
          //
          // AbsorbPointer impide que Android/Web pasen los
          // eventos de los BottomSheet a MapLibre.
          // ====================================================

          AbsorbPointer(
            absorbing:
                _mapaBloqueado,

            child:
                MapLibreMap(
              key:
                  ValueKey(
                oscuro
                    ? 'admin-map-dark'
                    : 'admin-map-light',
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

              // ================================================
              // BLOQUEO REAL DE GESTOS
              // ================================================

              scrollGesturesEnabled:
                  !_mapaBloqueado,

              zoomGesturesEnabled:
                  !_mapaBloqueado,

              rotateGesturesEnabled:
                  !_mapaBloqueado &&
                      _rotacionActiva,

              tiltGesturesEnabled:
                  !_mapaBloqueado &&
                      _rotacionActiva,

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

              // Evita que un FeatureTap genere además MapClick.
              featureTapsTriggersMapClick:
                  false,

              onCameraMove:
                  (position) {
                if (_mapaBloqueado) {
                  return;
                }

                _centroCamaraActual =
                    position.target;

                _zoomActual =
                    position.zoom;

                _bearingActual =
                    position.bearing;

                _tiltActual =
                    position.tilt;
              },

              onCameraIdle:
                  () {
                if (mounted &&
                    !_mapaBloqueado) {
                  setState(() {});
                }
              },
            ),
          ),

          // ====================================================
          // CARGANDO MAPA
          // ====================================================

          if (!_geoJsonCargado ||
              !_estiloCargado)
            Container(
              color:
                  fondo.withValues(
                alpha:
                    0.82,
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
          // ESTADÍSTICAS
          // ====================================================

          Positioned(
            left:
                12,

            right:
                70,

            top:
                12,

            child:
                _panelEstadisticas(
              oscuro,
            ),
          ),

          // ====================================================
          // BRÚJULA
          // ====================================================

          Positioned(
            left:
                14,

            top:
                88,

            child:
                FloatingActionButton.small(
              heroTag:
                  'brujulaAdminMapa',

              backgroundColor:
                  panel,

              foregroundColor:
                  _rotacionActiva
                      ? _naranjaPrincipal
                      : Colors.grey,

              onPressed:
                  _mapaBloqueado ||
                          !_rotacionActiva
                      ? null
                      : _restablecerAngulo,

              child:
                  Transform.rotate(
                angle:
                    -_bearingActual *
                        pi /
                        180,

                child:
                    const Icon(
                  Icons.navigation,
                ),
              ),
            ),
          ),

          // ====================================================
          // CONTROLES DERECHA
          // ====================================================

          Positioned(
            right:
                14,

            top:
                12,

            child:
                Column(
              children: [
                _botonMapa(
                  tag:
                      'adminZoomMas',

                  icono:
                      Icons.add,

                  onPressed:
                      _acercar,

                  oscuro:
                      oscuro,
                ),

                const SizedBox(
                  height:
                      9,
                ),

                _botonMapa(
                  tag:
                      'adminZoomMenos',

                  icono:
                      Icons.remove,

                  onPressed:
                      _alejar,

                  oscuro:
                      oscuro,
                ),

                const SizedBox(
                  height:
                      9,
                ),

                _botonMapa(
                  tag:
                      'adminCentrar',

                  icono:
                      Icons.center_focus_strong,

                  onPressed:
                      _centrarElSalvador,

                  oscuro:
                      oscuro,
                ),

                const SizedBox(
                  height:
                      9,
                ),

                _botonMapa(
                  tag:
                      'adminRotacion',

                  icono:
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

                const SizedBox(
                  height:
                      9,
                ),

                _botonMapa(
                  tag:
                      'adminCapas',

                  icono:
                      Icons.layers_outlined,

                  onPressed:
                      _mostrarSelectorCapas,

                  oscuro:
                      oscuro,
                ),

                const SizedBox(
                  height:
                      9,
                ),

                _botonMapa(
                  tag:
                      'adminMetricas',

                  icono:
                      Icons.bar_chart_rounded,

                  onPressed:
                      _mostrarListadoDepartamentos,

                  oscuro:
                      oscuro,
                ),
              ],
            ),
          ),

          // ====================================================
          // LEYENDA
          // ====================================================

          if (_mostrarConcentracion &&
              _geoJsonCargado)
            Positioned(
              left:
                  14,

              bottom:
                  64,

              child:
                  _leyenda(
                oscuro,
              ),
            ),

          // ====================================================
          // NIVEL / ZOOM
          // ====================================================

          Positioned(
            left:
                14,

            bottom:
                14,

            child:
                Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal:
                    12,

                vertical:
                    8,
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
                  14,
                ),
              ),

              child:
                  Row(
                mainAxisSize:
                    MainAxisSize.min,

                children: [
                  const Icon(
                    Icons.layers_outlined,

                    size:
                        16,

                    color:
                        _naranjaPrincipal,
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

                      fontSize:
                          11,

                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ====================================================
          // CARGANDO DATOS
          // ====================================================

          if (_cargandoDatos &&
              _estiloCargado)
            Positioned(
              left:
                  0,

              right:
                  0,

              bottom:
                  20,

              child:
                  Center(
                child:
                    Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal:
                        16,

                    vertical:
                        10,
                  ),

                  decoration:
                      BoxDecoration(
                    color:
                        panel,

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
                              0.12,
                        ),

                        blurRadius:
                            10,
                      ),
                    ],
                  ),

                  child:
                      const Row(
                    mainAxisSize:
                        MainAxisSize.min,

                    children: [
                      SizedBox(
                        width:
                            18,

                        height:
                            18,

                        child:
                            CircularProgressIndicator(
                          strokeWidth:
                              2,

                          color:
                              _naranjaPrincipal,
                        ),
                      ),

                      SizedBox(
                        width:
                            10,
                      ),

                      Text(
                        'Actualizando datos...',
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
              child:
                  Container(
                constraints:
                    const BoxConstraints(
                  maxWidth:
                      380,
                ),

                margin:
                    const EdgeInsets.all(
                  24,
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

                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black
                              .withValues(
                        alpha:
                            0.15,
                      ),

                      blurRadius:
                          14,
                    ),
                  ],
                ),

                child:
                    Column(
                  mainAxisSize:
                      MainAxisSize.min,

                  children: [
                    const Icon(
                      Icons.error_outline_rounded,

                      size:
                          46,

                      color:
                          Colors.red,
                    ),

                    const SizedBox(
                      height:
                          12,
                    ),

                    Text(
                      _error!,

                      textAlign:
                          TextAlign.center,
                    ),

                    const SizedBox(
                      height:
                          16,
                    ),

                    FilledButton.icon(
                      style:
                          FilledButton.styleFrom(
                        backgroundColor:
                            _naranjaPrincipal,

                        foregroundColor:
                            Colors.white,
                      ),

                      onPressed:
                          _cargarDatos,

                      icon:
                          const Icon(
                        Icons.refresh_rounded,
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
        ],
      ),
    );
  }
}

// ============================================================
// MÉTRICA DEPARTAMENTO
// ============================================================

class _MetricaDepartamento {
  final String nombre;

  int emprendimientos =
      0;

  int locales =
      0;

  int nivel =
      0;

  _MetricaDepartamento({
    required this.nombre,
  });

  int get total =>
      emprendimientos +
      locales;
}