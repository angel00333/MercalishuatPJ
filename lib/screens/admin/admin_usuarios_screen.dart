import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/admin_usuario.dart';
import '../../services/admin_service.dart';

class AdminUsuariosScreen
    extends StatefulWidget {
  const AdminUsuariosScreen({
    super.key,
  });

  @override
  State<AdminUsuariosScreen>
      createState() =>
          _AdminUsuariosScreenState();
}

class _AdminUsuariosScreenState
    extends State<AdminUsuariosScreen> {
  final TextEditingController
      _buscarController =
      TextEditingController();

  Timer? _debounce;

  List<AdminUsuario> _usuarios =
      [];

  bool _cargando =
      true;

  String? _error;

  int _pagina =
      1;

  int _paginas =
      1;

  int _total =
      0;

  int? _rolSeleccionado;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _cargarUsuarios();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _debounce?.cancel();

    _buscarController.dispose();

    super.dispose();
  }

  // ============================================================
  // CARGAR
  // ============================================================

  Future<void> _cargarUsuarios({
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
          await AdminService.obtenerUsuarios(
        pagina:
            paginaSolicitada,

        limite:
            20,

        buscar:
            _buscarController.text,

        rolId:
            _rolSeleccionado,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _usuarios =
            resultado.usuarios;

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
  // BUSCAR
  // ============================================================

  void _onBuscar(
    String value,
  ) {
    _debounce?.cancel();

    _debounce =
        Timer(
      const Duration(
        milliseconds:
            450,
      ),
      () {
        _pagina =
            1;

        _cargarUsuarios(
          pagina:
              1,
        );
      },
    );
  }

  // ============================================================
  // DETALLE
  // ============================================================

  Future<void> _mostrarDetalle(
    AdminUsuario usuario,
  ) async {
    try {
      final completo =
          await AdminService.obtenerUsuario(
        usuario.id,
      );

      if (!mounted) {
        return;
      }

      showModalBottomSheet(
        context:
            context,

        showDragHandle:
            true,

        isScrollControlled:
            true,

        builder:
            (
          context,
        ) {
          final oscuro =
              Theme.of(context).brightness ==
                  Brightness.dark;

          return Container(
            width:
                double.infinity,

            padding:
                const EdgeInsets.fromLTRB(
              24,
              10,
              24,
              32,
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
                  const BorderRadius.vertical(
                top:
                    Radius.circular(
                  24,
                ),
              ),
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
                    CircleAvatar(
                      radius:
                          28,

                      backgroundColor:
                          const Color(
                            0xFFFF7E01,
                          ).withValues(
                        alpha:
                            0.15,
                      ),

                      child:
                          Text(
                        _iniciales(
                          completo.nombre,
                        ),
                        style:
                            const TextStyle(
                          color:
                              Color(
                            0xFFFF7E01,
                          ),

                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                    ),

                    const SizedBox(
                      width:
                          16,
                    ),

                    Expanded(
                      child:
                          Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [
                          Text(
                            completo.nombre,
                            style:
                                const TextStyle(
                              fontSize:
                                  19,
                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),

                          const SizedBox(
                            height:
                                4,
                          ),

                          Text(
                            completo.correo,
                            style:
                                TextStyle(
                              color:
                                  Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height:
                      26,
                ),

                _filaDetalle(
                  titulo:
                      'ID',

                  valor:
                      '${completo.id}',
                ),

                _filaDetalle(
                  titulo:
                      'Rol',

                  valor:
                      _nombreRol(
                    completo,
                  ),
                ),

                _filaDetalle(
                  titulo:
                      'Rol ID',

                  valor:
                      '${completo.rolId}',
                ),

                const SizedBox(
                  height:
                      20,
                ),

                SizedBox(
                  width:
                      double.infinity,

                  child:
                      FilledButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                      );
                    },

                    style:
                        FilledButton.styleFrom(
                      backgroundColor:
                          const Color(
                        0xFFFF7E01,
                      ),

                      foregroundColor:
                          Colors.white,
                    ),

                    child:
                        const Text(
                      'Cerrar',
                    ),
                  ),
                ),
              ],
            ),
          );
        },
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
    }
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

    return Scaffold(
      backgroundColor:
          oscuro
              ? const Color(
                  0xFF171320,
                )
              : const Color(
                  0xFFF7F7F8,
                ),

      appBar:
          AppBar(
        backgroundColor:
            oscuro
                ? const Color(
                    0xFF171320,
                  )
                : Colors.white,

        surfaceTintColor:
            Colors.transparent,

        title:
            const Text(
          'Gestionar usuarios',
          style:
              TextStyle(
            fontWeight:
                FontWeight.w700,
          ),
        ),

        actions: [
          IconButton(
            tooltip:
                'Actualizar',

            onPressed: () {
              _cargarUsuarios();
            },

            icon:
                const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),

      body:
          RefreshIndicator(
        onRefresh:
            _cargarUsuarios,

        child:
            Column(
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

  // ============================================================
  // FILTROS
  // ============================================================

  Widget _filtros(
    bool oscuro,
  ) {
    return Container(
      padding:
          const EdgeInsets.fromLTRB(
        16,
        14,
        16,
        14,
      ),

      color:
          oscuro
              ? const Color(
                  0xFF171320,
                )
              : Colors.white,

      child:
          Column(
        children: [
          TextField(
            controller:
                _buscarController,

            onChanged:
                _onBuscar,

            decoration:
                InputDecoration(
              hintText:
                  'Buscar por nombre o correo',

              prefixIcon:
                  const Icon(
                Icons.search_rounded,
              ),

              suffixIcon:
                  _buscarController
                          .text
                          .isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _buscarController
                                .clear();

                            _pagina =
                                1;

                            _cargarUsuarios(
                              pagina:
                                  1,
                            );
                          },

                          icon:
                              const Icon(
                            Icons.close_rounded,
                          ),
                        )
                      : null,

              filled:
                  true,

              fillColor:
                  oscuro
                      ? const Color(
                          0xFF2A2045,
                        )
                      : const Color(
                          0xFFF2F2F4,
                        ),

              border:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  15,
                ),

                borderSide:
                    BorderSide.none,
              ),
            ),
          ),

          const SizedBox(
            height:
                12,
          ),

          Row(
            children: [
              Expanded(
                child:
                    DropdownButtonFormField<int?>(
                  initialValue:
                      _rolSeleccionado,

                  decoration:
                      InputDecoration(
                    labelText:
                        'Rol',

                    filled:
                        true,

                    fillColor:
                        oscuro
                            ? const Color(
                                0xFF2A2045,
                              )
                            : const Color(
                                0xFFF2F2F4,
                              ),

                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        15,
                      ),

                      borderSide:
                          BorderSide.none,
                    ),
                  ),

                  items:
                      const [
                    DropdownMenuItem<int?>(
                      value:
                          null,
                      child:
                          Text(
                        'Todos',
                      ),
                    ),

                    DropdownMenuItem<int?>(
                      value:
                          1,
                      child:
                          Text(
                        'Usuarios',
                      ),
                    ),

                    DropdownMenuItem<int?>(
                      value:
                          2,
                      child:
                          Text(
                        'Emprendedores',
                      ),
                    ),

                    DropdownMenuItem<int?>(
                      value:
                          3,
                      child:
                          Text(
                        'Administradores',
                      ),
                    ),
                  ],

                  onChanged: (
                    value,
                  ) {
                    setState(() {
                      _rolSeleccionado =
                          value;

                      _pagina =
                          1;
                    });

                    _cargarUsuarios(
                      pagina:
                          1,
                    );
                  },
                ),
              ),

              const SizedBox(
                width:
                    12,
              ),

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal:
                      14,

                  vertical:
                      16,
                ),

                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                        0xFFFF7E01,
                      ).withValues(
                    alpha:
                        0.12,
                  ),

                  borderRadius:
                      BorderRadius.circular(
                    15,
                  ),
                ),

                child:
                    Text(
                  '$_total',
                  style:
                      const TextStyle(
                    color:
                        Color(
                      0xFFFF7E01,
                    ),
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CONTENIDO
  // ============================================================

  Widget _contenido(
    bool oscuro,
  ) {
    if (_cargando) {
      return const Center(
        child:
            CircularProgressIndicator(
          color:
              Color(
            0xFFFF7E01,
          ),
        ),
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
            Icons.error_outline_rounded,
            size:
                60,
          ),

          const SizedBox(
            height:
                16,
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
                _cargarUsuarios,

            style:
                FilledButton.styleFrom(
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

    if (_usuarios.isEmpty) {
      return ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),

        children: const [
          SizedBox(
            height:
                150,
          ),

          Icon(
            Icons.person_search_outlined,
            size:
                64,
          ),

          SizedBox(
            height:
                14,
          ),

          Center(
            child:
                Text(
              'No se encontraron usuarios',
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
        10,
        16,
        26,
      ),

      children: [
        ..._usuarios.map(
          (
            usuario,
          ) =>
              _tarjetaUsuario(
            usuario,
            oscuro,
          ),
        ),

        if (_paginas > 1)
          _paginacion(),
      ],
    );
  }

  // ============================================================
  // TARJETA USUARIO
  // ============================================================

  Widget _tarjetaUsuario(
    AdminUsuario usuario,
    bool oscuro,
  ) {
    return Container(
      margin:
          const EdgeInsets.only(
        bottom:
            10,
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
          ListTile(
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal:
              16,

          vertical:
              6,
        ),

        onTap: () {
          _mostrarDetalle(
            usuario,
          );
        },

        leading:
            CircleAvatar(
          backgroundColor:
              const Color(
                0xFFFF7E01,
              ).withValues(
            alpha:
                0.14,
          ),

          child:
              Text(
            _iniciales(
              usuario.nombre,
            ),

            style:
                const TextStyle(
              color:
                  Color(
                0xFFFF7E01,
              ),

              fontWeight:
                  FontWeight.w800,
            ),
          ),
        ),

        title:
            Text(
          usuario.nombre,
          style:
              const TextStyle(
            fontWeight:
                FontWeight.w700,
          ),
        ),

        subtitle:
            Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            const SizedBox(
              height:
                  3,
            ),

            Text(
              usuario.correo,
              maxLines:
                  1,
              overflow:
                  TextOverflow.ellipsis,
            ),

            const SizedBox(
              height:
                  5,
            ),

            _badgeRol(
              usuario,
            ),
          ],
        ),

        trailing:
            const Icon(
          Icons.chevron_right_rounded,
        ),
      ),
    );
  }

  // ============================================================
  // BADGE ROL
  // ============================================================

  Widget _badgeRol(
    AdminUsuario usuario,
  ) {
    final nombre =
        _nombreRol(
      usuario,
    );

    return Align(
      alignment:
          Alignment.centerLeft,

      child:
          Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal:
              9,

          vertical:
              4,
        ),

        decoration:
            BoxDecoration(
          color:
              const Color(
                0xFFFF7E01,
              ).withValues(
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
          nombre,

          style:
              const TextStyle(
            color:
                Color(
              0xFFFF7E01,
            ),

            fontSize:
                11,

            fontWeight:
                FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PAGINACIÓN
  // ============================================================

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
                    ? () {
                        _cargarUsuarios(
                          pagina:
                              _pagina -
                                  1,
                        );
                      }
                    : null,

            icon:
                const Icon(
              Icons.chevron_left_rounded,
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
                        _cargarUsuarios(
                          pagina:
                              _pagina +
                                  1,
                        );
                      }
                    : null,

            icon:
                const Icon(
              Icons.chevron_right_rounded,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _nombreRol(
    AdminUsuario usuario,
  ) {
    if (usuario.rol.trim().isNotEmpty) {
      final texto =
          usuario.rol.trim();

      return '${texto[0].toUpperCase()}${texto.substring(1)}';
    }

    switch (usuario.rolId) {
      case 1:
        return 'Usuario';

      case 2:
        return 'Emprendedor';

      case 3:
        return 'Administrador';

      default:
        return 'Rol ${usuario.rolId}';
    }
  }

  String _iniciales(
    String nombre,
  ) {
    final partes =
        nombre
            .trim()
            .split(
              RegExp(
                r'\s+',
              ),
            )
            .where(
              (
                item,
              ) =>
                  item.isNotEmpty,
            )
            .toList();

    if (partes.isEmpty) {
      return '?';
    }

    if (partes.length == 1) {
      return partes.first[0]
          .toUpperCase();
    }

    return (
      partes[0][0] +
      partes[1][0]
    ).toUpperCase();
  }

  Widget _filaDetalle({
    required String titulo,
    required String valor,
  }) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical:
            8,
      ),

      child:
          Row(
        children: [
          SizedBox(
            width:
                85,

            child:
                Text(
              titulo,
              style:
                  TextStyle(
                color:
                    Colors.grey.shade500,
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
}