import 'dart:async';

import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../models/local_comercial.dart';
import '/../services/admin_locales.service.dart';

class AdminLocalesScreen
    extends StatefulWidget {
  const AdminLocalesScreen({
    super.key,
  });

  @override
  State<AdminLocalesScreen> createState() =>
      _AdminLocalesScreenState();
}

class _AdminLocalesScreenState
    extends State<AdminLocalesScreen> {
  final TextEditingController
      _buscarController =
      TextEditingController();

  Timer? _debounce;

  List<LocalComercial> _locales =
      [];

  AdminLocalesResumen _resumen =
      const AdminLocalesResumen(
    total: 0,
    activos: 0,
    ocultos: 0,
    disponibles: 0,
    noDisponibles: 0,
  );

  bool _cargando = true;

  String? _error;

  String _estado = 'todos';

  String? _operacion;

  int _pagina = 1;

  int _paginas = 1;

  final Set<int> _procesando =
      {};

  @override
  void initState() {
    super.initState();

    _cargar();
  }

  @override
  void dispose() {
    _debounce?.cancel();

    _buscarController.dispose();

    super.dispose();
  }

  // ==========================================================
  // CARGAR
  // ==========================================================

  Future<void> _cargar({
    int? pagina,
  }) async {
    final paginaNueva =
        pagina ?? _pagina;

    if (mounted) {
      setState(() {
        _cargando = true;

        _error = null;
      });
    }

    try {
      final resultado =
          await AdminLocalesService
              .listar(
        pagina:
            paginaNueva,

        buscar:
            _buscarController.text,

        estado:
            _estado,

        tipoOperacion:
            _operacion,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _locales =
            resultado.locales;

        _resumen =
            resultado.resumen;

        _pagina =
            resultado.pagina;

        _paginas =
            resultado.paginas;

        _cargando = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _cargando = false;

        _error =
            e
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

    _debounce =
        Timer(
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
  // ESTADO
  // ==========================================================

  void _cambiarFiltroEstado(
    String estado,
  ) {
    if (
      _estado == estado
    ) {
      return;
    }

    setState(() {
      _estado =
          estado;

      _pagina =
          1;
    });

    _cargar(
      pagina: 1,
    );
  }

  // ==========================================================
  // CAMBIAR ACTIVO
  // ==========================================================

  Future<void> _cambiarEstado(
    LocalComercial local,
  ) async {
    final nuevoActivo =
        !local.activo;

    final confirmar =
        await showDialog<bool>(
      context:
          context,

      builder:
          (context) {
        return AlertDialog(
          title:
              Text(
            nuevoActivo
                ? 'Reactivar local'
                : 'Ocultar local',
          ),

          content:
              Text(
            nuevoActivo
                ? 'El local volverá a mostrarse en Mercalishuat cuando esté disponible.'
                : 'El local dejará de mostrarse en el catálogo público.',
          ),

          actions: [
            TextButton(
              onPressed:
                  () =>
                      Navigator.pop(
                context,
                false,
              ),

              child:
                  const Text(
                'Cancelar',
              ),
            ),

            FilledButton(
              onPressed:
                  () =>
                      Navigator.pop(
                context,
                true,
              ),

              style:
                  FilledButton.styleFrom(
                backgroundColor:
                    nuevoActivo
                        ? AppColors.naranja
                        : Colors.red,
              ),

              child:
                  Text(
                nuevoActivo
                    ? 'Reactivar'
                    : 'Ocultar',
              ),
            ),
          ],
        );
      },
    );

    if (
      confirmar != true
    ) {
      return;
    }

    setState(() {
      _procesando.add(
        local.id,
      );
    });

    try {
      await AdminLocalesService
          .cambiarEstado(
        id:
            local.id,

        activo:
            nuevoActivo,
      );

      if (!mounted) {
        return;
      }

      _mensaje(
        nuevoActivo
            ? 'Local reactivado correctamente'
            : 'Local ocultado correctamente',
      );

      await _cargar();
    } catch (e) {
      if (!mounted) {
        return;
      }

      _mensaje(
        e
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _procesando.remove(
            local.id,
          );
        });
      }
    }
  }

  // ==========================================================
  // DISPONIBILIDAD
  // ==========================================================

  Future<void>
      _cambiarDisponibilidad(
    LocalComercial local,
  ) async {
    final nuevoEstado =
        !local.disponible;

    setState(() {
      _procesando.add(
        local.id,
      );
    });

    try {
      await AdminLocalesService
          .cambiarDisponibilidad(
        id:
            local.id,

        disponible:
            nuevoEstado,
      );

      if (!mounted) {
        return;
      }

      _mensaje(
        nuevoEstado
            ? 'Local marcado como disponible'
            : 'Local marcado como no disponible',
      );

      await _cargar();
    } catch (e) {
      if (!mounted) {
        return;
      }

      _mensaje(
        e
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _procesando.remove(
            local.id,
          );
        });
      }
    }
  }

  // ==========================================================
  // DETALLE ADMIN
  // ==========================================================

  Future<void> _verDetalle(
    LocalComercial local,
  ) async {
    try {
      final completo =
          await AdminLocalesService
              .obtener(
        local.id,
      );

      if (!mounted) {
        return;
      }

      showModalBottomSheet(
        context:
            context,

        isScrollControlled:
            true,

        useSafeArea:
            true,

        builder:
            (context) {
          final oscuro =
              Theme.of(context)
                      .brightness ==
                  Brightness.dark;

          return DraggableScrollableSheet(
            expand:
                false,

            initialChildSize:
                0.85,

            minChildSize:
                0.55,

            maxChildSize:
                0.95,

            builder:
                (
              context,
              scrollController,
            ) {
              return Container(
                color:
                    oscuro
                        ? const Color(
                            0xFF171320,
                          )
                        : Colors.white,

                child:
                    ListView(
                  controller:
                      scrollController,

                  padding:
                      const EdgeInsets.all(
                    20,
                  ),

                  children: [
                    Row(
                      children: [
                        Expanded(
                          child:
                              Text(
                            completo
                                .titulo,

                            style:
                                const TextStyle(
                              fontSize:
                                  22,

                              fontWeight:
                                  FontWeight
                                      .w800,
                            ),
                          ),
                        ),

                        IconButton(
                          onPressed:
                              () =>
                                  Navigator.pop(
                            context,
                          ),

                          icon:
                              const Icon(
                            Icons
                                .close_rounded,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    if (completo
                        .imagenes
                        .isNotEmpty)
                      SizedBox(
                        height:
                            220,

                        child:
                            PageView.builder(
                          itemCount:
                              completo
                                  .imagenes
                                  .length,

                          itemBuilder:
                              (
                            context,
                            index,
                          ) {
                            return ClipRRect(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                16,
                              ),

                              child:
                                  Image.network(
                                completo
                                    .imagenes[
                                        index]
                                    .url,

                                fit:
                                    BoxFit
                                        .cover,

                                errorBuilder:
                                    (
                                  _,
                                  __,
                                  ___,
                                ) =>
                                        _sinImagen(),
                              ),
                            );
                          },
                        ),
                      )
                    else
                      SizedBox(
                        height:
                            180,

                        child:
                            _sinImagen(),
                      ),

                    const SizedBox(
                      height: 20,
                    ),

                    _filaDetalle(
                      'Propietario',
                      completo
                              .propietarioNombre
                              .isNotEmpty
                          ? completo
                              .propietarioNombre
                          : 'Usuario #${completo.usuarioId}',
                    ),

                    _filaDetalle(
                      'Operación',
                      completo
                          .operacionTexto,
                    ),

                    _filaDetalle(
                      'Tipo',
                      completo
                          .tipoLocal,
                    ),

                    _filaDetalle(
                      'Precio',
                      completo
                          .precioTexto,
                    ),

                    _filaDetalle(
                      'Ubicación',
                      completo
                          .ubicacionTexto,
                    ),

                    _filaDetalle(
                      'Dirección',
                      completo
                          .direccion,
                    ),

                    _filaDetalle(
                      'Estado',
                      completo.activo
                          ? 'Activo'
                          : 'Oculto',
                    ),

                    _filaDetalle(
                      'Disponibilidad',
                      completo
                              .disponible
                          ? 'Disponible'
                          : 'No disponible',
                    ),

                    const Divider(
                      height: 32,
                    ),

                    const Text(
                      'Descripción',

                      style:
                          TextStyle(
                        fontWeight:
                            FontWeight.w800,

                        fontSize:
                            17,
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Text(
                      completo
                          .descripcion,
                    ),

                    const Divider(
                      height: 32,
                    ),

                    const Text(
                      'Contacto',

                      style:
                          TextStyle(
                        fontWeight:
                            FontWeight.w800,

                        fontSize:
                            17,
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    if (completo
                            .contactoNombre !=
                        null)
                      _filaDetalle(
                        'Nombre',
                        completo
                            .contactoNombre!,
                      ),

                    if (completo
                            .contactoTelefono !=
                        null)
                      _filaDetalle(
                        'Teléfono',
                        completo
                            .contactoTelefono!,
                      ),

                    if (completo
                            .contactoWhatsapp !=
                        null)
                      _filaDetalle(
                        'WhatsApp',
                        completo
                            .contactoWhatsapp!,
                      ),

                    if (completo
                            .contactoCorreo !=
                        null)
                      _filaDetalle(
                        'Correo',
                        completo
                            .contactoCorreo!,
                      ),
                  ],
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _mensaje(
        e
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            ),
      );
    }
  }

  // ==========================================================
  // MENSAJE
  // ==========================================================

  void _mensaje(
    String mensaje,
  ) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content:
            Text(
          mensaje,
        ),
      ),
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
        Theme.of(context)
                .brightness ==
            Brightness.dark;

    final fondo =
        oscuro
            ? const Color(
                0xFF171320,
              )
            : const Color(
                0xFFF7F7F8,
              );

    return Scaffold(
      backgroundColor:
          fondo,

      appBar:
          AppBar(
        backgroundColor:
            oscuro
                ? fondo
                : AppColors
                    .naranja,

        surfaceTintColor:
            Colors.transparent,

        elevation:
            0,

        leading:
            IconButton(
          onPressed:
              () =>
                  Navigator.pop(
            context,
          ),

          icon:
              const Icon(
            Icons
                .arrow_back_ios_new_rounded,

            color:
                Colors.white,
          ),
        ),

        title:
            const Text(
          'Locales comerciales',

          style:
              TextStyle(
            color:
                Colors.white,

            fontWeight:
                FontWeight.w800,
          ),
        ),

        centerTitle:
            true,

        actions: [
          IconButton(
            tooltip:
                'Actualizar',

            onPressed:
                _cargar,

            icon:
                const Icon(
              Icons
                  .refresh_rounded,

              color:
                  Colors.white,
            ),
          ),
        ],
      ),

      body:
          RefreshIndicator(
        color:
            AppColors.naranja,

        onRefresh:
            _cargar,

        child:
            _contenido(
          oscuro,
        ),
      ),
    );
  }

  // ==========================================================
  // CONTENIDO
  // ==========================================================

  Widget _contenido(
    bool oscuro,
  ) {
    if (_cargando) {
      return ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),

        children:
            const [
          SizedBox(
            height:
                180,
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
            height:
                100,
          ),

          const Icon(
            Icons
                .apartment_outlined,

            size:
                70,

            color:
                AppColors.naranja,
          ),

          const SizedBox(
            height:
                20,
          ),

          Text(
            _error!,

            textAlign:
                TextAlign.center,
          ),

          const SizedBox(
            height:
                20,
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

    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),

      padding:
          const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        40,
      ),

      children: [
        // ====================================================
        // RESUMEN
        // ====================================================

        _resumenWidget(
          oscuro,
        ),

        const SizedBox(
          height: 20,
        ),

        // ====================================================
        // BUSCADOR
        // ====================================================

        TextField(
          controller:
              _buscarController,

          onChanged:
              _buscar,

          decoration:
              InputDecoration(
            hintText:
                'Buscar local o propietario',

            prefixIcon:
                const Icon(
              Icons
                  .search_rounded,
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
          height: 14,
        ),

        // ====================================================
        // ESTADOS
        // ====================================================

        SingleChildScrollView(
          scrollDirection:
              Axis.horizontal,

          child:
              Row(
            children: [
              _filtro(
                'Todos',
                'todos',
              ),

              const SizedBox(
                width: 8,
              ),

              _filtro(
                'Activos',
                'activos',
              ),

              const SizedBox(
                width: 8,
              ),

              _filtro(
                'Ocultos',
                'ocultos',
              ),

              const SizedBox(
                width: 8,
              ),

              _filtro(
                'Disponibles',
                'disponibles',
              ),

              const SizedBox(
                width: 8,
              ),

              _filtro(
                'No disponibles',
                'no_disponibles',
              ),
            ],
          ),
        ),

        const SizedBox(
          height: 12,
        ),

        // ====================================================
        // VENTA / ALQUILER
        // ====================================================

        Row(
          children: [
            ChoiceChip(
              selected:
                  _operacion ==
                      null,

              label:
                  const Text(
                'Todas',
              ),

              onSelected:
                  (_) {
                setState(() {
                  _operacion =
                      null;
                });

                _cargar(
                  pagina: 1,
                );
              },
            ),

            const SizedBox(
              width: 8,
            ),

            ChoiceChip(
              selected:
                  _operacion ==
                      'venta',

              label:
                  const Text(
                'Venta',
              ),

              onSelected:
                  (_) {
                setState(() {
                  _operacion =
                      'venta';
                });

                _cargar(
                  pagina: 1,
                );
              },
            ),

            const SizedBox(
              width: 8,
            ),

            ChoiceChip(
              selected:
                  _operacion ==
                      'alquiler',

              label:
                  const Text(
                'Alquiler',
              ),

              onSelected:
                  (_) {
                setState(() {
                  _operacion =
                      'alquiler';
                });

                _cargar(
                  pagina: 1,
                );
              },
            ),
          ],
        ),

        const SizedBox(
          height: 20,
        ),

        if (_locales.isEmpty)
          const Padding(
            padding:
                EdgeInsets.symmetric(
              vertical:
                  70,
            ),

            child:
                Column(
              children: [
                Icon(
                  Icons
                      .apartment_outlined,

                  size:
                      70,

                  color:
                      AppColors.naranja,
                ),

                SizedBox(
                  height:
                      16,
                ),

                Text(
                  'No se encontraron locales comerciales',
                ),
              ],
            ),
          )
        else
          ..._locales.map(
            (
              local,
            ) =>
                _tarjetaLocal(
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
  // RESUMEN
  // ==========================================================

  Widget _resumenWidget(
    bool oscuro,
  ) {
    return Wrap(
      spacing:
          10,

      runSpacing:
          10,

      children: [
        _datoResumen(
          'Total',
          _resumen.total,
          Icons
              .apartment_outlined,
          oscuro,
        ),

        _datoResumen(
          'Activos',
          _resumen.activos,
          Icons
              .check_circle_outline,
          oscuro,
        ),

        _datoResumen(
          'Ocultos',
          _resumen.ocultos,
          Icons
              .visibility_off_outlined,
          oscuro,
        ),

        _datoResumen(
          'Disponibles',
          _resumen.disponibles,
          Icons
              .storefront_outlined,
          oscuro,
        ),
      ],
    );
  }

  Widget _datoResumen(
    String titulo,
    int cantidad,
    IconData icono,
    bool oscuro,
  ) {
    return Container(
      width:
          145,

      padding:
          const EdgeInsets.all(
        14,
      ),

      decoration:
          BoxDecoration(
        color:
            oscuro
                ? const Color(
                    0xFF2A2045,
                  )
                : Colors.white,

        borderRadius:
            BorderRadius.circular(
          16,
        ),
      ),

      child:
          Row(
        children: [
          Icon(
            icono,

            color:
                AppColors.naranja,
          ),

          const SizedBox(
            width:
                10,
          ),

          Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Text(
                '$cantidad',

                style:
                    const TextStyle(
                  fontSize:
                      20,

                  fontWeight:
                      FontWeight.w800,
                ),
              ),

              Text(
                titulo,

                style:
                    TextStyle(
                  fontSize:
                      11,

                  color:
                      Colors
                          .grey
                          .shade500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // FILTRO
  // ==========================================================

  Widget _filtro(
    String texto,
    String valor,
  ) {
    final seleccionado =
        _estado ==
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
                ? Colors.white
                : null,
      ),

      label:
          Text(
        texto,
      ),

      onSelected:
          (_) =>
              _cambiarFiltroEstado(
        valor,
      ),
    );
  }

  // ==========================================================
  // TARJETA
  // ==========================================================

  Widget _tarjetaLocal(
    LocalComercial local,
    bool oscuro,
  ) {
    final imagen =
        local
            .imagenPrincipal
            ?.url;

    final procesando =
        _procesando.contains(
      local.id,
    );

    return Container(
      margin:
          const EdgeInsets.only(
        bottom:
            14,
      ),

      decoration:
          BoxDecoration(
        color:
            oscuro
                ? const Color(
                    0xFF2A2045,
                  )
                : Colors.white,

        borderRadius:
            BorderRadius.circular(
          18,
        ),
      ),

      clipBehavior:
          Clip.antiAlias,

      child:
          Column(
        children: [
          ListTile(
            contentPadding:
                const EdgeInsets.all(
              12,
            ),

            leading:
                ClipRRect(
              borderRadius:
                  BorderRadius.circular(
                12,
              ),

              child:
                  SizedBox(
                width:
                    68,

                height:
                    68,

                child:
                    imagen != null &&
                            imagen
                                .isNotEmpty
                        ? Image.network(
                            imagen,

                            fit:
                                BoxFit
                                    .cover,

                            errorBuilder:
                                (
                              _,
                              __,
                              ___,
                            ) =>
                                    _sinImagen(),
                          )
                        : _sinImagen(),
              ),
            ),

            title:
                Text(
              local.titulo,

              maxLines:
                  1,

              overflow:
                  TextOverflow.ellipsis,

              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.w800,
              ),
            ),

            subtitle:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                const SizedBox(
                  height:
                      4,
                ),

                Text(
                  local
                          .propietarioNombre
                          .isNotEmpty
                      ? local
                          .propietarioNombre
                      : 'Usuario #${local.usuarioId}',
                ),

                Text(
                  local
                      .ubicacionTexto,
                ),

                const SizedBox(
                  height:
                      6,
                ),

                Wrap(
                  spacing:
                      5,

                  runSpacing:
                      5,

                  children: [
                    _badge(
                      local
                          .operacionTexto,

                      AppColors.naranja,
                    ),

                    _badge(
                      local.activo
                          ? 'Activo'
                          : 'Oculto',

                      local.activo
                          ? Colors.green
                          : Colors.red,
                    ),

                    _badge(
                      local.disponible
                          ? 'Disponible'
                          : 'No disponible',

                      local.disponible
                          ? Colors.blue
                          : Colors.grey,
                    ),
                  ],
                ),
              ],
            ),

            trailing:
                PopupMenuButton<String>(
              enabled:
                  !procesando,

              onSelected:
                  (
                value,
              ) {
                if (
                  value ==
                      'detalle'
                ) {
                  _verDetalle(
                    local,
                  );
                }

                if (
                  value ==
                      'estado'
                ) {
                  _cambiarEstado(
                    local,
                  );
                }

                if (
                  value ==
                      'disponibilidad'
                ) {
                  _cambiarDisponibilidad(
                    local,
                  );
                }
              },

              itemBuilder:
                  (_) => [
                const PopupMenuItem(
                  value:
                      'detalle',

                  child:
                      Row(
                    children: [
                      Icon(
                        Icons
                            .visibility_outlined,
                      ),

                      SizedBox(
                        width:
                            10,
                      ),

                      Text(
                        'Ver detalle',
                      ),
                    ],
                  ),
                ),

                PopupMenuItem(
                  value:
                      'estado',

                  child:
                      Row(
                    children: [
                      Icon(
                        local.activo
                            ? Icons
                                .visibility_off_outlined
                            : Icons
                                .visibility_outlined,
                      ),

                      const SizedBox(
                        width:
                            10,
                      ),

                      Text(
                        local.activo
                            ? 'Ocultar'
                            : 'Reactivar',
                      ),
                    ],
                  ),
                ),

                PopupMenuItem(
                  value:
                      'disponibilidad',

                  child:
                      Row(
                    children: [
                      Icon(
                        local.disponible
                            ? Icons
                                .do_not_disturb_alt_outlined
                            : Icons
                                .check_circle_outline,
                      ),

                      const SizedBox(
                        width:
                            10,
                      ),

                      Text(
                        local.disponible
                            ? 'Marcar no disponible'
                            : 'Marcar disponible',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (procesando)
            const LinearProgressIndicator(
              color:
                  AppColors.naranja,
            ),
        ],
      ),
    );
  }

  Widget _sinImagen() {
    return Container(
      color:
          AppColors.naranja
              .withValues(
        alpha:
            0.10,
      ),

      child:
          const Center(
        child:
            Icon(
          Icons
              .apartment_outlined,

          color:
              AppColors.naranja,

          size:
              34,
        ),
      ),
    );
  }

  Widget _badge(
    String texto,
    Color color,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal:
            8,

        vertical:
            3,
      ),

      decoration:
          BoxDecoration(
        color:
            color.withValues(
          alpha:
              0.12,
        ),

        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),

      child:
          Text(
        texto,

        style:
            TextStyle(
          color:
              color,

          fontSize:
              10,

          fontWeight:
              FontWeight.w700,
        ),
      ),
    );
  }

  Widget _filaDetalle(
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
          SizedBox(
            width:
                115,

            child:
                Text(
              titulo,

              style:
                  TextStyle(
                color:
                    Colors
                        .grey
                        .shade500,

                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),

          Expanded(
            child:
                Text(
              valor,

              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        ],
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
        top:
            15,
      ),

      child:
          Row(
        mainAxisAlignment:
            MainAxisAlignment.center,

        children: [
          IconButton(
            onPressed:
                _pagina > 1
                    ? () =>
                        _cargar(
                          pagina:
                              _pagina -
                                  1,
                        )
                    : null,

            icon:
                const Icon(
              Icons
                  .chevron_left_rounded,
            ),
          ),

          Text(
            'Página $_pagina de $_paginas',

            style:
                const TextStyle(
              fontWeight:
                  FontWeight.w600,
            ),
          ),

          IconButton(
            onPressed:
                _pagina <
                        _paginas
                    ? () =>
                        _cargar(
                          pagina:
                              _pagina +
                                  1,
                        )
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