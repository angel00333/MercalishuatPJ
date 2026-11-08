import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/local_comercial.dart';
import '../../services/local_comercial_service.dart';
import '../../config/app_theme.dart';

import 'detalle_local_comercial_screen.dart';
import 'mis_locales_screen.dart';
import 'publicar_local_screen.dart';

class LocalesComercialesScreen extends StatefulWidget {
  /// true  = Emprendedor
  /// false = Usuario normal
  final bool puedePublicar;

  const LocalesComercialesScreen({
    super.key,
    this.puedePublicar = false,
  });

  @override
  State<LocalesComercialesScreen> createState() =>
      _LocalesComercialesScreenState();
}

class _LocalesComercialesScreenState
    extends State<LocalesComercialesScreen> {
  final TextEditingController _buscarController =
      TextEditingController();

  Timer? _debounce;

  List<LocalComercial> _locales = [];

  bool _cargando = true;

  String? _error;

  String? _operacion;

  int _pagina = 1;

  int _paginas = 1;

  int _total = 0;

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _cargar();
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _debounce?.cancel();

    _buscarController.dispose();

    super.dispose();
  }

  // ==========================================================
  // CARGAR LOCALES
  // ==========================================================

  Future<void> _cargar({
    int? pagina,
  }) async {
    final paginaSolicitada =
        pagina ?? _pagina;

    if (mounted) {
      setState(() {
        _cargando = true;

        _error = null;
      });
    }

    try {
      final resultado =
          await LocalComercialService.listar(
        pagina: paginaSolicitada,
        buscar: _buscarController.text,
        tipoOperacion: _operacion,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _locales = resultado.locales;

        _pagina = resultado.pagina;

        _paginas = resultado.paginas;

        _total = resultado.total;

        _cargando = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _cargando = false;

        _error = e
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            );
      });
    }
  }

  // ==========================================================
  // BUSCAR
  // ==========================================================

  void _buscar(
    String value,
  ) {
    setState(() {});

    _debounce?.cancel();

    _debounce = Timer(
      const Duration(
        milliseconds: 450,
      ),
      () {
        _pagina = 1;

        _cargar(
          pagina: 1,
        );
      },
    );
  }

  // ==========================================================
  // FILTRO OPERACIÓN
  // ==========================================================

  void _cambiarOperacion(
    String? valor,
  ) {
    setState(() {
      _operacion = valor;

      _pagina = 1;
    });

    _cargar(
      pagina: 1,
    );
  }

  // ==========================================================
  // PUBLICAR
  // ==========================================================

  Future<void> _publicar() async {
    if (!widget.puedePublicar) {
      return;
    }

    final cambiado =
        await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            const PublicarLocalScreen(),
      ),
    );

    if (cambiado == true) {
      _cargar(
        pagina: 1,
      );
    }
  }

  // ==========================================================
  // MIS LOCALES
  // ==========================================================

  Future<void> _misLocales() async {
    if (!widget.puedePublicar) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            const MisLocalesScreen(),
      ),
    );

    _cargar(
      pagina: 1,
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final oscuro =
        Theme.of(context).brightness ==
            Brightness.dark;

    return Scaffold(
      backgroundColor:
          oscuro
              ? AppColors.fondoOscuro
              : AppColors.fondoClaro,

      // ======================================================
      // APP BAR
      // ======================================================

      appBar: AppBar(
        title: const Text(
          'Locales comerciales',
          style: TextStyle(
            fontWeight:
                FontWeight.w700,
          ),
        ),

        actions: [
          // Solo el emprendedor ve este menú.
          if (widget.puedePublicar)
            PopupMenuButton<String>(
              onSelected: (
                value,
              ) {
                if (value == 'mios') {
                  _misLocales();
                }

                if (value ==
                    'publicar') {
                  _publicar();
                }
              },

              itemBuilder: (_) =>
                  const [
                PopupMenuItem(
                  value: 'mios',
                  child: Row(
                    children: [
                      Icon(
                        Icons
                            .business_center_outlined,
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Text(
                        'Mis locales',
                      ),
                    ],
                  ),
                ),

                PopupMenuItem(
                  value: 'publicar',
                  child: Row(
                    children: [
                      Icon(
                        Icons
                            .add_business_outlined,
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Text(
                        'Publicar local',
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),

      // ======================================================
      // BOTÓN PUBLICAR
      //
      // Solo aparece para emprendedor.
      // ======================================================

      floatingActionButton:
          widget.puedePublicar
              ? FloatingActionButton(
                  tooltip:
                      'Publicar local',

                  onPressed:
                      _publicar,

                  backgroundColor:
                      AppColors.naranja,

                  foregroundColor:
                      AppColors
                          .textoSobreNaranja,

                  child: const Icon(
                    Icons
                        .add_business_outlined,
                  ),
                )
              : null,

      // ======================================================
      // BODY
      // ======================================================

      body: RefreshIndicator(
        color:
            AppColors.naranja,

        onRefresh:
            _cargar,

        child: Column(
          children: [
            _filtros(
              oscuro,
            ),

            Expanded(
              child:
                  _contenido(
                oscuro,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // FILTROS
  // ==========================================================

  Widget _filtros(
    bool oscuro,
  ) {
    return Container(
      width:
          double.infinity,

      padding:
          const EdgeInsets.fromLTRB(
        16,
        14,
        16,
        12,
      ),

      color:
          oscuro
              ? AppColors.fondoOscuro
              : AppColors.fondoClaro,

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          // ==================================================
          // BUSCADOR
          // ==================================================

          TextField(
            controller:
                _buscarController,

            onChanged:
                _buscar,

            decoration:
                InputDecoration(
              hintText:
                  'Buscar local, municipio o departamento',

              prefixIcon:
                  const Icon(
                Icons.search_rounded,
              ),

              suffixIcon:
                  _buscarController
                          .text
                          .isNotEmpty
                      ? IconButton(
                          onPressed:
                              () {
                            _buscarController
                                .clear();

                            setState(
                              () {},
                            );

                            _pagina =
                                1;

                            _cargar(
                              pagina:
                                  1,
                            );
                          },

                          icon:
                              const Icon(
                            Icons
                                .close_rounded,
                          ),
                        )
                      : null,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          // ==================================================
          // FILTROS VENTA / ALQUILER
          // ==================================================

          SingleChildScrollView(
            scrollDirection:
                Axis.horizontal,

            child: Row(
              children: [
                _chipOperacion(
                  texto:
                      'Todos',

                  valor:
                      null,
                ),

                const SizedBox(
                  width: 8,
                ),

                _chipOperacion(
                  texto:
                      'Venta',

                  valor:
                      'venta',
                ),

                const SizedBox(
                  width: 8,
                ),

                _chipOperacion(
                  texto:
                      'Alquiler',

                  valor:
                      'alquiler',
                ),

                const SizedBox(
                  width: 14,
                ),

                Text(
                  '$_total local${_total == 1 ? '' : 'es'}',

                  style:
                      TextStyle(
                    color:
                        Colors
                            .grey
                            .shade500,

                    fontWeight:
                        FontWeight
                            .w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // CHIP OPERACIÓN
  // ==========================================================

  Widget _chipOperacion({
    required String texto,
    required String? valor,
  }) {
    final seleccionado =
        _operacion ==
            valor;

    return ChoiceChip(
      selected:
          seleccionado,

      selectedColor:
          AppColors.naranja,

      labelStyle:
          TextStyle(
        color:
            seleccionado
                ? AppColors
                    .textoSobreNaranja
                : null,

        fontWeight:
            FontWeight.w600,
      ),

      side:
          BorderSide.none,

      label:
          Text(
        texto,
      ),

      onSelected:
          (_) {
        _cambiarOperacion(
          valor,
        );
      },
    );
  }

  // ==========================================================
  // CONTENIDO
  // ==========================================================

  Widget _contenido(
    bool oscuro,
  ) {
    // ========================================================
    // CARGANDO
    // ========================================================

    if (_cargando) {
      return ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),

        children:
            const [
          SizedBox(
            height: 180,
          ),

          Center(
            child:
                CircularProgressIndicator(
              color:
                  AppColors.naranja,
            ),
          ),
        ],
      );
    }

    // ========================================================
    // ERROR
    // ========================================================

    if (_error != null) {
      return ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),

        padding:
            const EdgeInsets.all(
          24,
        ),

        children: [
          const SizedBox(
            height: 100,
          ),

          const Icon(
            Icons
                .store_mall_directory_outlined,

            size:
                68,

            color:
                AppColors.naranja,
          ),

          const SizedBox(
            height: 16,
          ),

          Text(
            _error!,

            textAlign:
                TextAlign.center,
          ),

          const SizedBox(
            height: 18,
          ),

          FilledButton.icon(
            onPressed:
                _cargar,

            icon:
                const Icon(
              Icons
                  .refresh_rounded,
            ),

            label:
                const Text(
              'Reintentar',
            ),
          ),
        ],
      );
    }

    // ========================================================
    // SIN LOCALES
    // ========================================================

    if (_locales.isEmpty) {
      return ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),

        children: [
          const SizedBox(
            height: 150,
          ),

          const Icon(
            Icons
                .storefront_outlined,

            size:
                72,

            color:
                AppColors.naranja,
          ),

          const SizedBox(
            height: 16,
          ),

          const Center(
            child:
                Text(
              'No se encontraron locales comerciales',

              style:
                  TextStyle(
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),

          // Solo emprendedor.
          if (widget.puedePublicar)
            ...[
              const SizedBox(
                height: 18,
              ),

              Center(
                child:
                    FilledButton.icon(
                  onPressed:
                      _publicar,

                  icon:
                      const Icon(
                    Icons
                        .add_business_outlined,
                  ),

                  label:
                      const Text(
                    'Publicar un local',
                  ),
                ),
              ),
            ],
        ],
      );
    }

    // ========================================================
    // LISTADO
    // ========================================================

    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),

      padding:
          const EdgeInsets.fromLTRB(
        16,
        10,
        16,
        100,
      ),

      children: [
        ..._locales.map(
          (
            local,
          ) =>
              _tarjeta(
            local,
            oscuro,
          ),
        ),

        if (_paginas > 1)
          _paginacion(),
      ],
    );
  }

  // ==========================================================
  // TARJETA LOCAL
  // ==========================================================

  Widget _tarjeta(
    LocalComercial local,
    bool oscuro,
  ) {
    final imagen =
        local
            .imagenPrincipal
            ?.url;

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 14,
      ),

      decoration:
          BoxDecoration(
        color:
            oscuro
                ? const Color(
                    0xFF352951,
                  )
                : Colors.white,

        borderRadius:
            BorderRadius.circular(
          18,
        ),

        boxShadow:
            oscuro
                ? null
                : [
                    BoxShadow(
                      color:
                          Colors
                              .black
                              .withValues(
                        alpha:
                            0.05,
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

      clipBehavior:
          Clip.antiAlias,

      child:
          InkWell(
        // Tanto usuario como emprendedor pueden abrir el local.
        onTap:
            () {
          Navigator.of(
            context,
          ).push(
            MaterialPageRoute(
              builder:
                  (_) =>
                      DetalleLocalComercialScreen(
                localId:
                    local.id,
              ),
            ),
          );
        },

        child:
            Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            // ================================================
            // IMAGEN
            // ================================================

            AspectRatio(
              aspectRatio:
                  16 / 9,

              child:
                  imagen != null &&
                          imagen
                              .isNotEmpty
                      ? Image.network(
                          imagen,

                          fit:
                              BoxFit.cover,

                          errorBuilder:
                              (
                            _,
                            __,
                            ___,
                          ) =>
                                  _placeholderImagen(
                            oscuro,
                          ),
                        )
                      : _placeholderImagen(
                          oscuro,
                        ),
            ),

            // ================================================
            // DATOS
            // ================================================

            Padding(
              padding:
                  const EdgeInsets.all(
                16,
              ),

              child:
                  Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Row(
                    children: [
                      _badgeOperacion(
                        local,
                      ),

                      const Spacer(),

                      Text(
                        local
                            .precioTexto,

                        style:
                            const TextStyle(
                          color:
                              AppColors
                                  .naranja,

                          fontSize:
                              19,

                          fontWeight:
                              FontWeight
                                  .w800,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height:
                        10,
                  ),

                  Text(
                    local
                        .titulo,

                    maxLines:
                        2,

                    overflow:
                        TextOverflow
                            .ellipsis,

                    style:
                        const TextStyle(
                      fontSize:
                          18,

                      fontWeight:
                          FontWeight
                              .w800,
                    ),
                  ),

                  const SizedBox(
                    height:
                        7,
                  ),

                  Row(
                    children: [
                      const Icon(
                        Icons
                            .location_on_outlined,

                        size:
                            18,

                        color:
                            AppColors
                                .naranja,
                      ),

                      const SizedBox(
                        width:
                            5,
                      ),

                      Expanded(
                        child:
                            Text(
                          local
                              .ubicacionTexto,

                          maxLines:
                              1,

                          overflow:
                              TextOverflow
                                  .ellipsis,

                          style:
                              TextStyle(
                            color:
                                Colors
                                    .grey
                                    .shade500,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height:
                        7,
                  ),

                  Text(
                    local
                        .tipoLocal,

                    style:
                        TextStyle(
                      color:
                          Colors
                              .grey
                              .shade500,

                      fontSize:
                          13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // PLACEHOLDER
  // ==========================================================

  Widget _placeholderImagen(
    bool oscuro,
  ) {
    return Container(
      color:
          AppColors.naranja.withValues(
        alpha:
            oscuro
                ? 0.12
                : 0.08,
      ),

      child:
          const Center(
        child:
            Icon(
          Icons
              .storefront_rounded,

          size:
              60,

          color:
              AppColors.naranja,
        ),
      ),
    );
  }

  // ==========================================================
  // BADGE
  // ==========================================================

  Widget _badgeOperacion(
    LocalComercial local,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal:
            10,

        vertical:
            5,
      ),

      decoration:
          BoxDecoration(
        color:
            AppColors.naranja.withValues(
          alpha:
              0.13,
        ),

        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),

      child:
          Text(
        local
            .operacionTexto,

        style:
            const TextStyle(
          color:
              AppColors.naranja,

          fontWeight:
              FontWeight.w700,

          fontSize:
              12,
        ),
      ),
    );
  }

  // ==========================================================
  // PAGINACIÓN
  // ==========================================================

  Widget _paginacion() {
    return Padding(
      padding:
          const EdgeInsets.only(
        top: 12,
      ),

      child:
          Row(
        mainAxisAlignment:
            MainAxisAlignment.center,

        children: [
          IconButton(
            onPressed:
                _pagina > 1
                    ? () {
                        _cargar(
                          pagina:
                              _pagina -
                                  1,
                        );
                      }
                    : null,

            icon:
                const Icon(
              Icons
                  .chevron_left_rounded,
            ),
          ),

          Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal:
                  16,
            ),

            child:
                Text(
              'Página $_pagina de $_paginas',

              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),

          IconButton(
            onPressed:
                _pagina <
                        _paginas
                    ? () {
                        _cargar(
                          pagina:
                              _pagina +
                                  1,
                        );
                      }
                    : null,

            icon:
                const Icon(
              Icons
                  .chevron_right_rounded,
            ),
          ),
        ],
      ),
    );
  }
}