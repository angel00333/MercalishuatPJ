import 'package:flutter/material.dart';

import '../../models/admin_reporte.dart';
import '../../services/admin_reporte_service.dart';
import '/../widgets/admin/admin_top_bar.dart';

class AdminReportesScreen
    extends StatefulWidget {
  const AdminReportesScreen({
    super.key,
  });

  @override
  State<AdminReportesScreen>
      createState() =>
          _AdminReportesScreenState();
}

class _AdminReportesScreenState
    extends State<AdminReportesScreen> {
  List<AdminReporte> _reportes =
      [];

  String _estado =
      'pendiente';

  bool _cargando =
      true;

  String? _error;

  int _pagina =
      1;

  int _paginas =
      1;

  int _total =
      0;

  final Set<int> _procesando =
      {};

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _cargar();
  }

  // ============================================================
  // CARGAR
  // ============================================================

  Future<void> _cargar({
    int? pagina,
  }) async {
    final paginaSolicitada =
        pagina ?? _pagina;

    if (mounted) {
      setState(() {
        _cargando =
            true;

        _error =
            null;
      });
    }

    try {
      final resultado =
          await AdminReporteService
              .obtenerReportes(
        pagina:
            paginaSolicitada,
        estado:
            _estado,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _reportes =
            resultado.reportes;

        _pagina =
            resultado.pagina;

        _paginas =
            resultado.paginas;

        _total =
            resultado.total;

        _cargando =
            false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error =
            e
                .toString()
                .replaceFirst(
                  'Exception: ',
                  '',
                );

        _cargando =
            false;
      });
    }
  }

  // ============================================================
  // CAMBIAR FILTRO
  // ============================================================

  void _cambiarFiltro(
    String estado,
  ) {
    if (_estado ==
        estado) {
      return;
    }

    setState(() {
      _estado =
          estado;

      _pagina =
          1;
    });

    _cargar(
      pagina:
          1,
    );
  }

  // ============================================================
  // RESOLVER
  // ============================================================

  Future<void> _resolver(
    AdminReporte reporte,
    String accion,
  ) async {
    final ocultar =
        accion ==
            'ocultar';

    final confirmado =
        await showDialog<bool>(
      context:
          context,
      builder:
          (context) {
        return AlertDialog(
          title:
              Text(
            ocultar
                ? 'Ocultar contenido'
                : 'Descartar reporte',
          ),
          content:
              Text(
            ocultar
                ? '¿Deseas ocultar este ${_nombreTipo(reporte.tipo).toLowerCase()}? El contenido dejará de estar visible, pero podrá restaurarse posteriormente.'
                : '¿Deseas descartar este reporte? El contenido permanecerá activo.',
          ),
          actions: [
            TextButton(
              onPressed:
                  () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child:
                  const Text(
                'Cancelar',
              ),
            ),
            FilledButton(
              onPressed:
                  () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              style:
                  FilledButton
                      .styleFrom(
                backgroundColor:
                    ocultar
                        ? Colors.red
                        : Colors
                            .blueGrey,
                foregroundColor:
                    Colors.white,
              ),
              child:
                  Text(
                ocultar
                    ? 'Ocultar'
                    : 'Descartar',
              ),
            ),
          ],
        );
      },
    );

    if (confirmado !=
        true) {
      return;
    }

    setState(() {
      _procesando.add(
        reporte.id,
      );
    });

    try {
      await AdminReporteService
          .resolverReporte(
        reporteId:
            reporte.id,
        accion:
            accion,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content:
              Text(
            ocultar
                ? 'Contenido ocultado correctamente'
                : 'Reporte descartado correctamente',
          ),
        ),
      );

      await _cargar(
        pagina:
            _pagina,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content:
              Text(
            e
                .toString()
                .replaceFirst(
                  'Exception: ',
                  '',
                ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _procesando.remove(
            reporte.id,
          );
        });
      }
    }
  }

  // ============================================================
  // RESTAURAR
  // ============================================================

  Future<void> _restaurar(
    AdminReporte reporte,
  ) async {
    if (reporte.contenidoActivo ==
        true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content:
              Text(
            'Este contenido ya está activo',
          ),
        ),
      );

      return;
    }

    final confirmado =
        await showDialog<bool>(
      context:
          context,
      builder:
          (context) {
        return AlertDialog(
          title:
              const Text(
            'Restaurar contenido',
          ),
          content:
              Text(
            '¿Deseas volver a mostrar este ${_nombreTipo(reporte.tipo).toLowerCase()}?',
          ),
          actions: [
            TextButton(
              onPressed:
                  () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child:
                  const Text(
                'Cancelar',
              ),
            ),
            FilledButton(
              onPressed:
                  () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              style:
                  FilledButton
                      .styleFrom(
                backgroundColor:
                    Colors.green,
                foregroundColor:
                    Colors.white,
              ),
              child:
                  const Text(
                'Restaurar',
              ),
            ),
          ],
        );
      },
    );

    if (confirmado !=
        true) {
      return;
    }

    setState(() {
      _procesando.add(
        reporte.id,
      );
    });

    try {
      await AdminReporteService
          .restaurarContenido(
        reporte,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content:
              Text(
            'Contenido restaurado correctamente',
          ),
        ),
      );

      await _cargar();
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content:
              Text(
            e
                .toString()
                .replaceFirst(
                  'Exception: ',
                  '',
                ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _procesando.remove(
            reporte.id,
          );
        });
      }
    }
  }

  // ============================================================
  // DETALLE
  // ============================================================

  void _detalle(
    AdminReporte reporte,
  ) {
    final oscuro =
        Theme.of(context)
                .brightness ==
            Brightness.dark;

    showModalBottomSheet(
      context:
          context,
      showDragHandle:
          true,
      isScrollControlled:
          true,
      builder:
          (context) {
        return Container(
          width:
              double.infinity,
          constraints:
              BoxConstraints(
            maxHeight:
                MediaQuery.of(
                      context,
                    ).size.height *
                    0.82,
          ),
          padding:
              const EdgeInsets
                  .fromLTRB(
            22,
            8,
            22,
            30,
          ),
          decoration:
              BoxDecoration(
            color:
                oscuro
                    ? const Color(
                        0xFF211A32,
                      )
                    : Colors.white,
            borderRadius:
                const BorderRadius
                    .vertical(
              top:
                  Radius.circular(
                24,
              ),
            ),
          ),
          child:
              SingleChildScrollView(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  reporte.motivo,
                  style:
                      const TextStyle(
                    fontSize:
                        20,
                    fontWeight:
                        FontWeight
                            .w800,
                  ),
                ),

                const SizedBox(
                  height:
                      16,
                ),

                _filaDetalle(
                  'Reporte',
                  '#${reporte.id}',
                ),

                _filaDetalle(
                  'Estado',
                  _nombreEstado(
                    reporte.estado,
                  ),
                ),

                _filaDetalle(
                  'Tipo',
                  _nombreTipo(
                    reporte.tipo,
                  ),
                ),

                _filaDetalle(
                  'Reportado por',
                  reporte
                      .reportanteNombre,
                ),

                _filaDetalle(
                  'Correo',
                  reporte
                      .reportanteCorreo,
                ),

                _filaDetalle(
                  'Autor',
                  reporte
                      .autorContenido,
                ),

                _filaDetalle(
                  'Fecha',
                  _fecha(
                    reporte
                        .fechaCreacion,
                  ),
                ),

                const SizedBox(
                  height:
                      18,
                ),

                const Text(
                  'Contenido reportado',
                  style:
                      TextStyle(
                    fontWeight:
                        FontWeight
                            .w800,
                  ),
                ),

                const SizedBox(
                  height:
                      8,
                ),

                Container(
                  width:
                      double.infinity,
                  padding:
                      const EdgeInsets
                          .all(
                    14,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        const Color(
                          0xFFFF7E01,
                        ).withValues(
                      alpha:
                          0.09,
                    ),
                    borderRadius:
                        BorderRadius
                            .circular(
                      14,
                    ),
                  ),
                  child:
                      Text(
                    reporte
                        .contenido,
                  ),
                ),

                if (reporte
                            .descripcion !=
                        null &&
                    reporte
                        .descripcion!
                        .trim()
                        .isNotEmpty) ...[
                  const SizedBox(
                    height:
                        18,
                  ),
                  const Text(
                    'Descripción del reporte',
                    style:
                        TextStyle(
                      fontWeight:
                          FontWeight
                              .w800,
                    ),
                  ),
                  const SizedBox(
                    height:
                        6,
                  ),
                  Text(
                    reporte
                        .descripcion!,
                  ),
                ],

                if (reporte
                        .estado !=
                    'pendiente') ...[
                  const SizedBox(
                    height:
                        18,
                  ),
                  _filaDetalle(
                    'Acción',
                    reporte
                            .accion ??
                        'Sin acción',
                  ),
                  _filaDetalle(
                    'Administrador',
                    reporte
                            .administradorNombre ??
                        '-',
                  ),
                  _filaDetalle(
                    'Resolución',
                    _fecha(
                      reporte
                          .fechaResolucion,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
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

    return Scaffold(
      backgroundColor:
          oscuro
              ? const Color(
                  0xFF171320,
                )
              : const Color(
                  0xFFF7F7F8,
                ),
      appBar: buildAdminTopBar(
        context: context,
        title: 'Reportes y moderación',
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: () {
              _cargar();
            },
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),
      body:
          Column(
        children: [
          _filtros(
            oscuro,
          ),
          Expanded(
            child:
                RefreshIndicator(
              onRefresh:
                  _cargar,
              child:
                  _contenido(
                oscuro,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FILTROS
  // ============================================================

  Widget _filtros(
    bool oscuro,
  ) {
    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets
              .fromLTRB(
        14,
        12,
        14,
        12,
      ),
      color:
          oscuro
              ? const Color(
                  0xFF171320,
                )
              : Colors.white,
      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment
                .start,
        children: [
          Wrap(
            spacing:
                8,
            runSpacing:
                8,
            children: [
              _filtro(
                valor:
                    'pendiente',
                texto:
                    'Pendientes',
                icono:
                    Icons
                        .flag_outlined,
              ),
              _filtro(
                valor:
                    'resuelto',
                texto:
                    'Resueltos',
                icono:
                    Icons
                        .check_circle_outline,
              ),
              _filtro(
                valor:
                    'descartado',
                texto:
                    'Descartados',
                icono:
                    Icons
                        .delete_outline_rounded,
              ),
            ],
          ),

          const SizedBox(
            height:
                10,
          ),

          Text(
            '$_total reporte${_total == 1 ? '' : 's'}',
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
    );
  }

  Widget _filtro({
    required String valor,
    required String texto,
    required IconData icono,
  }) {
    final seleccionado =
        _estado ==
            valor;

    return ChoiceChip(
      selected:
          seleccionado,
      onSelected:
          (_) {
        _cambiarFiltro(
          valor,
        );
      },
      avatar:
          Icon(
        icono,
        size:
            17,
        color:
            seleccionado
                ? Colors.white
                : null,
      ),
      label:
          Text(
        texto,
      ),
      selectedColor:
          const Color(
        0xFFFF7E01,
      ),
      labelStyle:
          TextStyle(
        color:
            seleccionado
                ? Colors.white
                : null,
        fontWeight:
            FontWeight
                .w600,
      ),
      side:
          BorderSide.none,
    );
  }

  // ============================================================
  // CONTENIDO
  // ============================================================

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
                  Color(
                0xFFFF7E01,
              ),
            ),
          ),
        ],
      );
    }

    if (_error !=
        null) {
      return ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding:
            const EdgeInsets
                .all(
          24,
        ),
        children: [
          const SizedBox(
            height:
                100,
          ),
          const Icon(
            Icons
                .error_outline_rounded,
            size:
                64,
          ),
          const SizedBox(
            height:
                14,
          ),
          Text(
            _error!,
            textAlign:
                TextAlign.center,
          ),
          const SizedBox(
            height:
                18,
          ),
          FilledButton(
            onPressed:
                _cargar,
            style:
                FilledButton
                    .styleFrom(
              backgroundColor:
                  const Color(
                0xFFFF7E01,
              ),
            ),
            child:
                const Text(
              'Reintentar',
            ),
          ),
        ],
      );
    }

    if (_reportes
        .isEmpty) {
      return ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(
            height:
                130,
          ),
          Icon(
            _estado ==
                    'pendiente'
                ? Icons
                    .verified_outlined
                : Icons
                    .inbox_outlined,
            size:
                68,
            color:
                Colors
                    .grey
                    .shade500,
          ),
          const SizedBox(
            height:
                14,
          ),
          Center(
            child:
                Text(
              _estado ==
                      'pendiente'
                  ? 'No hay reportes pendientes'
                  : 'No hay reportes en esta sección',
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight
                        .w600,
              ),
            ),
          ),
        ],
      );
    }

    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      padding:
          const EdgeInsets
              .fromLTRB(
        14,
        10,
        14,
        28,
      ),
      children: [
        ..._reportes.map(
          (
            reporte,
          ) =>
              _tarjeta(
            reporte,
            oscuro,
          ),
        ),

        if (_paginas >
            1)
          _paginacion(),
      ],
    );
  }

  // ============================================================
  // TARJETA
  // ============================================================

  Widget _tarjeta(
    AdminReporte reporte,
    bool oscuro,
  ) {
    final procesando =
        _procesando
            .contains(
      reporte.id,
    );

    return Container(
      margin:
          const EdgeInsets
              .only(
        bottom:
            12,
      ),
      padding:
          const EdgeInsets
              .all(
        15,
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
            BorderRadius
                .circular(
          17,
        ),
      ),
      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment
                .start,
        children: [
          Row(
            children: [
              Container(
                width:
                    42,
                height:
                    42,
                decoration:
                    BoxDecoration(
                  color:
                      _colorEstado(
                        reporte
                            .estado,
                      ).withValues(
                    alpha:
                        0.12,
                  ),
                  borderRadius:
                      BorderRadius
                          .circular(
                    12,
                  ),
                ),
                child:
                    Icon(
                  reporte.tipo ==
                          'comentario'
                      ? Icons
                          .comment_outlined
                      : Icons
                          .article_outlined,
                  color:
                      _colorEstado(
                    reporte
                        .estado,
                  ),
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
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      reporte
                          .motivo,
                      maxLines:
                          1,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight
                                .w800,
                      ),
                    ),
                    const SizedBox(
                      height:
                          3,
                    ),
                    Text(
                      '${_nombreTipo(reporte.tipo)} · ${_fecha(reporte.fechaCreacion)}',
                      style:
                          TextStyle(
                        color:
                            Colors
                                .grey
                                .shade500,
                        fontSize:
                            12,
                      ),
                    ),
                  ],
                ),
              ),

              _badgeEstado(
                reporte.estado,
              ),
            ],
          ),

          const SizedBox(
            height:
                14,
          ),

          Text(
            reporte
                .contenido,
            maxLines:
                3,
            overflow:
                TextOverflow
                    .ellipsis,
          ),

          const SizedBox(
            height:
                10,
          ),

          Text(
            'Reportado por: ${reporte.reportanteNombre}',
            style:
                TextStyle(
              color:
                  Colors
                      .grey
                      .shade500,
              fontSize:
                  12,
            ),
          ),

          const SizedBox(
            height:
                12,
          ),

          if (procesando)
            const LinearProgressIndicator(
              color:
                  Color(
                0xFFFF7E01,
              ),
            ),

          if (!procesando &&
              reporte.estado ==
                  'pendiente')
            Row(
              children: [
                Expanded(
                  child:
                      OutlinedButton(
                    onPressed:
                        () {
                      _resolver(
                        reporte,
                        'descartar',
                      );
                    },
                    child:
                        const Text(
                      'Descartar',
                    ),
                  ),
                ),

                const SizedBox(
                  width:
                      9,
                ),

                Expanded(
                  child:
                      FilledButton(
                    onPressed:
                        () {
                      _resolver(
                        reporte,
                        'ocultar',
                      );
                    },
                    style:
                        FilledButton
                            .styleFrom(
                      backgroundColor:
                          Colors.red,
                      foregroundColor:
                          Colors.white,
                    ),
                    child:
                        const Text(
                      'Ocultar',
                    ),
                  ),
                ),
              ],
            ),

          if (!procesando &&
              reporte.estado ==
                  'resuelto' &&
              reporte
                      .contenidoActivo ==
                  false)
            SizedBox(
              width:
                  double.infinity,
              child:
                  OutlinedButton.icon(
                onPressed:
                    () {
                  _restaurar(
                    reporte,
                  );
                },
                icon:
                    const Icon(
                  Icons
                      .restore_rounded,
                ),
                label:
                    const Text(
                  'Restaurar contenido',
                ),
              ),
            ),

          const SizedBox(
            height:
                4,
          ),

          SizedBox(
            width:
                double.infinity,
            child:
                TextButton.icon(
              onPressed:
                  () {
                _detalle(
                  reporte,
                );
              },
              icon:
                  const Icon(
                Icons
                    .visibility_outlined,
              ),
              label:
                  const Text(
                'Ver detalle',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BADGE ESTADO
  // ============================================================

  Widget _badgeEstado(
    String estado,
  ) {
    final color =
        _colorEstado(
      estado,
    );

    return Container(
      padding:
          const EdgeInsets
              .symmetric(
        horizontal:
            8,
        vertical:
            4,
      ),
      decoration:
          BoxDecoration(
        color:
            color.withValues(
          alpha:
              0.12,
        ),
        borderRadius:
            BorderRadius
                .circular(
          20,
        ),
      ),
      child:
          Text(
        _nombreEstado(
          estado,
        ),
        style:
            TextStyle(
          color:
              color,
          fontSize:
              10,
          fontWeight:
              FontWeight
                  .w800,
        ),
      ),
    );
  }

  // ============================================================
  // PAGINACIÓN
  // ============================================================

  Widget _paginacion() {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment
              .center,
      children: [
        IconButton(
          onPressed:
              _pagina >
                      1
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
        Text(
          'Página $_pagina de $_paginas',
          style:
              const TextStyle(
            fontWeight:
                FontWeight
                    .w600,
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
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  Color _colorEstado(
    String estado,
  ) {
    switch (estado) {
      case 'resuelto':
        return Colors.green;

      case 'descartado':
        return Colors.blueGrey;

      default:
        return Colors.orange;
    }
  }

  String _nombreEstado(
    String estado,
  ) {
    switch (estado) {
      case 'resuelto':
        return 'Resuelto';

      case 'descartado':
        return 'Descartado';

      default:
        return 'Pendiente';
    }
  }

  String _nombreTipo(
    String tipo,
  ) {
    return tipo ==
            'comentario'
        ? 'Comentario'
        : 'Publicación';
  }

  String _fecha(
    DateTime? fecha,
  ) {
    if (fecha ==
        null) {
      return '-';
    }

    final local =
        fecha.toLocal();

    final dia =
        local.day
            .toString()
            .padLeft(
              2,
              '0',
            );

    final mes =
        local.month
            .toString()
            .padLeft(
              2,
              '0',
            );

    final hora =
        local.hour
            .toString()
            .padLeft(
              2,
              '0',
            );

    final minuto =
        local.minute
            .toString()
            .padLeft(
              2,
              '0',
            );

    return '$dia/$mes/${local.year} $hora:$minuto';
  }

  Widget _filaDetalle(
    String titulo,
    String valor,
  ) {
    return Padding(
      padding:
          const EdgeInsets
              .symmetric(
        vertical:
            6,
      ),
      child:
          Row(
        crossAxisAlignment:
            CrossAxisAlignment
                .start,
        children: [
          SizedBox(
            width:
                105,
            child:
                Text(
              titulo,
              style:
                  TextStyle(
                color:
                    Colors
                        .grey
                        .shade500,
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
                    FontWeight
                        .w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}