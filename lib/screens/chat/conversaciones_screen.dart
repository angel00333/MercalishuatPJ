import 'package:flutter/material.dart';

import '../../config/app_theme.dart';

import '../../models/conversacion.dart';

import '../../services/chat_service.dart';
import '../../services/chat_socket_service.dart';

import 'chat_screen.dart';

class ConversacionesScreen extends StatefulWidget {
  const ConversacionesScreen({
    super.key,
  });

  @override
  State<ConversacionesScreen> createState() =>
      _ConversacionesScreenState();
}

class _ConversacionesScreenState extends State<ConversacionesScreen> {
  // ============================================================
  // DATOS
  // ============================================================

  List<Conversacion> conversaciones = [];

  bool cargando = true;

  String? error;

  bool _socketPreparado = false;

  // ============================================================
  // BÚSQUEDA
  // ============================================================

  final TextEditingController buscarController =
      TextEditingController();

  String _consulta = '';

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _iniciar();
  }

  // ============================================================
  // INICIAR
  // ============================================================

  Future<void> _iniciar() async {
    await _prepararSocket();

    await _cargar();
  }

  // ============================================================
  // SOCKET
  // ============================================================

  Future<void> _prepararSocket() async {
    if (_socketPreparado) {
      return;
    }

    await ChatSocketService.instance.conectar();

    if (!mounted) {
      return;
    }

    ChatSocketService.instance.escucharConversacionActualizada(
      (
        data,
      ) {
        if (!mounted) {
          return;
        }

        debugPrint(
          'CONVERSACIÓN ACTUALIZADA: $data',
        );

        _cargar(
          mostrarCarga: false,
        );
      },
    );

    _socketPreparado = true;
  }

  // ============================================================
  // CARGAR CONVERSACIONES
  // ============================================================

  Future<void> _cargar({
    bool mostrarCarga = true,
  }) async {
    if (!mounted) {
      return;
    }

    if (mostrarCarga) {
      setState(() {
        cargando = true;
        error = null;
      });
    }

    try {
      final resultado =
          await ChatService.listarConversaciones();

      if (!mounted) {
        return;
      }

      if (resultado['success'] == true) {
        final dynamic raw =
            resultado['conversaciones'];

        final List<Conversacion> lista = [];

        if (raw is List) {
          for (final item in raw) {
            if (item is Conversacion) {
              lista.add(
                item,
              );
            } else if (item is Map) {
              try {
                lista.add(
                  Conversacion.fromJson(
                    Map<String, dynamic>.from(
                      item,
                    ),
                  ),
                );
              } catch (e) {
                debugPrint(
                  'ERROR PARSEANDO CONVERSACIÓN: $e',
                );
              }
            }
          }
        }

        setState(() {
          conversaciones = lista;
          cargando = false;
          error = null;
        });

        return;
      }

      setState(() {
        cargando = false;

        error =
            resultado['message']?.toString() ??
                'No se pudieron cargar las conversaciones';
      });
    } catch (e) {
      debugPrint(
        'ERROR CONVERSACIONES: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        cargando = false;
        error =
            'Error cargando conversaciones';
      });
    }
  }

  // ============================================================
  // FILTRADO
  // ============================================================

  List<Conversacion> get _conversacionesFiltradas {
    final consulta =
        _consulta.trim().toLowerCase();

    if (consulta.isEmpty) {
      return conversaciones;
    }

    return conversaciones.where(
      (
        conversacion,
      ) {
        final tienda =
            conversacion.tituloChat
                .toLowerCase();

        final propietario =
            conversacion.nombreCompleto
                .toLowerCase();

        final mensaje =
            (conversacion.ultimoMensaje ?? '')
                .toLowerCase();

        return tienda.contains(
              consulta,
            ) ||
            propietario.contains(
              consulta,
            ) ||
            mensaje.contains(
              consulta,
            );
      },
    ).toList();
  }

  // ============================================================
  // ABRIR CHAT
  // ============================================================

  Future<void> _abrir(
    Conversacion conversacion,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) {
          return ChatScreen(
            conversacionId:
                conversacion.id,

            // ==================================================
            // PROPIETARIO
            // ==================================================

            nombreUsuario:
                conversacion.nombreCompleto,

            imagenUsuarioUrl:
                conversacion.imagenUsuarioUrl,

            // ==================================================
            // EMPRENDIMIENTO
            // ==================================================

            nombreEmprendimiento:
                conversacion.emprendimientoNombre,

            imagenEmprendimientoUrl:
                conversacion.emprendimientoImagenUrl,
          );
        },
      ),
    );

    if (!mounted) {
      return;
    }

    await _cargar(
      mostrarCarga: false,
    );
  }

  // ============================================================
  // AVATAR
  // ============================================================

  Widget _avatar(
    Conversacion conversacion,
  ) {
    final String? url =
        conversacion.imagenChatUrl;

    final bool tieneImagen =
        url != null &&
        url.trim().isNotEmpty;

    final String titulo =
        conversacion.tituloChat.trim();

    final String inicial =
        titulo.isNotEmpty
            ? titulo[0].toUpperCase()
            : '?';

    return Container(
      width: 60,
      height: 60,

      padding:
          const EdgeInsets.all(
        3,
      ),

      decoration:
          BoxDecoration(
        shape:
            BoxShape.circle,

        gradient:
            const LinearGradient(
          begin:
              Alignment.topLeft,

          end:
              Alignment.bottomRight,

          colors: [
            AppColors.naranja,
            AppColors.naranjaClaro,
          ],
        ),

        boxShadow: [
          BoxShadow(
            color:
                AppColors.naranja.withValues(
              alpha:
                  0.20,
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
          ClipOval(
        child:
            tieneImagen
                ? Image.network(
                    url,

                    fit:
                        BoxFit.cover,

                    errorBuilder:
                        (
                      context,
                      error,
                      stackTrace,
                    ) {
                      return _avatarFallback(
                        inicial,
                      );
                    },
                  )
                : _avatarFallback(
                    inicial,
                  ),
      ),
    );
  }

  Widget _avatarFallback(
    String inicial,
  ) {
    return Container(
      color:
          AppColors.morado,

      alignment:
          Alignment.center,

      child:
          Text(
        inicial,

        style:
            const TextStyle(
          color:
              Colors.white,

          fontSize:
              21,

          fontWeight:
              FontWeight.w900,
        ),
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    buscarController.dispose();

    ChatSocketService
        .instance
        .dejarDeEscucharConversacionActualizada();

    super.dispose();
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
      // ========================================================
      // APP BAR
      // ========================================================

      appBar:
          AppBar(
        automaticallyImplyLeading:
            false,

        backgroundColor:
            oscuro
                ? AppColors.moradoOscuro
                : AppColors.naranja,

        foregroundColor:
            Colors.white,

        elevation:
            0,

        surfaceTintColor:
            Colors.transparent,

        titleSpacing:
            20,

        title:
            const Align(
          alignment:
              Alignment.centerLeft,

          child:
              Text(
            'Mensajes',

            style:
                TextStyle(
              fontSize:
                  24,

              fontWeight:
                  FontWeight.w900,
            ),
          ),
        ),

        actions: [
          IconButton(
            tooltip:
                'Actualizar',

            onPressed:
                () {
              _cargar(
                mostrarCarga:
                    false,
              );
            },

            icon:
                const Icon(
              Icons.refresh_rounded,
            ),
          ),

          const SizedBox(
            width:
                6,
          ),
        ],
      ),

      // ========================================================
      // BODY
      // ========================================================

      body:
          Column(
        children: [
          // ====================================================
          // BUSCADOR
          // ====================================================

          Padding(
            padding:
                const EdgeInsets.fromLTRB(
              16,
              14,
              16,
              10,
            ),

            child:
                TextField(
              controller:
                  buscarController,

              onChanged:
                  (
                valor,
              ) {
                setState(() {
                  _consulta =
                      valor;
                });
              },

              decoration:
                  InputDecoration(
                hintText:
                    'Buscar tienda o conversación...',

                prefixIcon:
                    const Icon(
                  Icons.search_rounded,
                ),

                suffixIcon:
                    _consulta.isNotEmpty
                        ? IconButton(
                            tooltip:
                                'Limpiar',

                            onPressed:
                                () {
                              buscarController
                                  .clear();

                              setState(() {
                                _consulta =
                                    '';
                              });
                            },

                            icon:
                                const Icon(
                              Icons.close_rounded,
                            ),
                          )
                        : null,
              ),
            ),
          ),

          // ====================================================
          // TÍTULO SECUNDARIO
          // ====================================================

          if (!cargando &&
              error == null &&
              conversaciones.isNotEmpty)
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                18,
                4,
                18,
                10,
              ),

              child:
                  Row(
                children: [
                  const Icon(
                    Icons.storefront_outlined,

                    color:
                        AppColors.naranja,

                    size:
                        19,
                  ),

                  const SizedBox(
                    width:
                        7,
                  ),

                  Text(
                    'Conversaciones con emprendimientos',

                    style:
                        Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

          // ====================================================
          // CONTENIDO
          // ====================================================

          Expanded(
            child:
                _contenido(
              oscuro,
            ),
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
    if (cargando) {
      return const Center(
        child:
            CircularProgressIndicator(),
      );
    }

    // ==========================================================
    // ERROR
    // ==========================================================

    if (error != null) {
      return RefreshIndicator(
        onRefresh:
            _cargar,

        child:
            ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),

          padding:
              const EdgeInsets.symmetric(
            horizontal:
                30,
          ),

          children: [
            const SizedBox(
              height:
                  120,
            ),

            Center(
              child:
                  Container(
                width:
                    80,

                height:
                    80,

                decoration:
                    BoxDecoration(
                  color:
                      AppColors.naranja.withValues(
                    alpha:
                        0.10,
                  ),

                  shape:
                      BoxShape.circle,
                ),

                child:
                    const Icon(
                  Icons.cloud_off_outlined,

                  color:
                      AppColors.naranja,

                  size:
                      38,
                ),
              ),
            ),

            const SizedBox(
              height:
                  18,
            ),

            Text(
              error!,

              textAlign:
                  TextAlign.center,

              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.w700,
              ),
            ),

            const SizedBox(
              height:
                  14,
            ),

            Center(
              child:
                  FilledButton.icon(
                onPressed:
                    _cargar,

                icon:
                    const Icon(
                  Icons.refresh_rounded,
                ),

                label:
                    const Text(
                  'Reintentar',
                ),
              ),
            ),
          ],
        ),
      );
    }

    final lista =
        _conversacionesFiltradas;

    // ==========================================================
    // VACÍO
    // ==========================================================

    if (lista.isEmpty) {
      return RefreshIndicator(
        onRefresh:
            _cargar,

        child:
            ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),

          padding:
              const EdgeInsets.symmetric(
            horizontal:
                30,
          ),

          children: [
            const SizedBox(
              height:
                  120,
            ),

            Center(
              child:
                  Container(
                width:
                    84,

                height:
                    84,

                decoration:
                    BoxDecoration(
                  color:
                      AppColors.naranja.withValues(
                    alpha:
                        0.10,
                  ),

                  shape:
                      BoxShape.circle,
                ),

                child:
                    const Icon(
                  Icons.chat_bubble_outline_rounded,

                  color:
                      AppColors.naranja,

                  size:
                      40,
                ),
              ),
            ),

            const SizedBox(
              height:
                  18,
            ),

            Text(
              _consulta.isNotEmpty
                  ? 'No encontramos conversaciones'
                  : 'Todavía no tienes conversaciones',

              textAlign:
                  TextAlign.center,

              style:
                  const TextStyle(
                fontSize:
                    18,

                fontWeight:
                    FontWeight.w800,
              ),
            ),

            const SizedBox(
              height:
                  7,
            ),

            Text(
              _consulta.isNotEmpty
                  ? 'Prueba buscando el nombre de otra tienda.'
                  : 'Cuando escribas a un emprendimiento aparecerá aquí.',

              textAlign:
                  TextAlign.center,

              style:
                  Theme.of(context)
                      .textTheme
                      .bodySmall,
            ),
          ],
        ),
      );
    }

    // ==========================================================
    // LISTA
    // ==========================================================

    return RefreshIndicator(
      onRefresh:
          _cargar,

      child:
          ListView.builder(
        padding:
            const EdgeInsets.fromLTRB(
          12,
          6,
          12,
          24,
        ),

        itemCount:
            lista.length,

        itemBuilder:
            (
          context,
          index,
        ) {
          final conversacion =
              lista[index];

          return _tarjetaConversacion(
            conversacion,
            oscuro,
          );
        },
      ),
    );
  }

  // ============================================================
  // TARJETA
  // ============================================================

  Widget _tarjetaConversacion(
    Conversacion conversacion,
    bool oscuro,
  ) {
    final int noLeidos =
        conversacion.mensajesNoLeidos;

    final bool tieneNoLeidos =
        noLeidos > 0;

    return Padding(
      padding:
          const EdgeInsets.only(
        bottom:
            8,
      ),

      child:
          Material(
        color:
            oscuro
                ? AppColors.tarjetaOscura
                : Colors.white,

        borderRadius:
            BorderRadius.circular(
          20,
        ),

        child:
            InkWell(
          onTap:
              () {
            _abrir(
              conversacion,
            );
          },

          borderRadius:
              BorderRadius.circular(
            20,
          ),

          child:
              Container(
            padding:
                const EdgeInsets.fromLTRB(
              12,
              12,
              12,
              12,
            ),

            decoration:
                BoxDecoration(
              borderRadius:
                  BorderRadius.circular(
                20,
              ),

              border:
                  Border.all(
                color:
                    tieneNoLeidos
                        ? AppColors.naranja.withValues(
                            alpha:
                                0.40,
                          )
                        : oscuro
                            ? AppColors.bordeOscuro
                            : AppColors.bordeClaro,

                width:
                    tieneNoLeidos
                        ? 1.3
                        : 1,
              ),
            ),

            child:
                Row(
              children: [
                // ==============================================
                // LOGO DEL EMPRENDIMIENTO
                // ==============================================

                _avatar(
                  conversacion,
                ),

                const SizedBox(
                  width:
                      13,
                ),

                // ==============================================
                // INFORMACIÓN
                // ==============================================

                Expanded(
                  child:
                      Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      // ========================================
                      // NOMBRE EMPRENDIMIENTO
                      // ========================================

                      Text(
                        conversacion.tituloChat,

                        maxLines:
                            1,

                        overflow:
                            TextOverflow.ellipsis,

                        style:
                            TextStyle(
                          fontSize:
                              16,

                          fontWeight:
                              tieneNoLeidos
                                  ? FontWeight.w900
                                  : FontWeight.w800,
                        ),
                      ),

                      // ========================================
                      // PROPIETARIO
                      // ========================================

                      if (conversacion.subtituloChat !=
                          null) ...[
                        const SizedBox(
                          height:
                              2,
                        ),

                        Row(
                          children: [
                            Icon(
                              Icons.person_outline_rounded,

                              size:
                                  13,

                              color:
                                  Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(
                                        alpha:
                                            0.52,
                                      ),
                            ),

                            const SizedBox(
                              width:
                                  4,
                            ),

                            Expanded(
                              child:
                                  Text(
                                conversacion.subtituloChat!,

                                maxLines:
                                    1,

                                overflow:
                                    TextOverflow.ellipsis,

                                style:
                                    TextStyle(
                                  fontSize:
                                      11.5,

                                  color:
                                      Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(
                                            alpha:
                                                0.56,
                                          ),

                                  fontWeight:
                                      FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(
                        height:
                            5,
                      ),

                      // ========================================
                      // ÚLTIMO MENSAJE
                      // ========================================

                      Text(
                        conversacion.ultimoMensaje ??
                            'Nueva conversación',

                        maxLines:
                            1,

                        overflow:
                            TextOverflow.ellipsis,

                        style:
                            TextStyle(
                          fontSize:
                              13,

                          color:
                              tieneNoLeidos
                                  ? Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(
                                        alpha:
                                            0.52,
                                      ),

                          fontWeight:
                              tieneNoLeidos
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  width:
                      10,
                ),

                // ==============================================
                // BADGE
                // ==============================================

                if (tieneNoLeidos)
                  Container(
                    constraints:
                        const BoxConstraints(
                      minWidth:
                          27,

                      minHeight:
                          27,
                    ),

                    padding:
                        const EdgeInsets.symmetric(
                      horizontal:
                          7,
                    ),

                    alignment:
                        Alignment.center,

                    decoration:
                        const BoxDecoration(
                      color:
                          AppColors.naranja,

                      shape:
                          BoxShape.circle,
                    ),

                    child:
                        Text(
                      noLeidos > 99
                          ? '99+'
                          : '$noLeidos',

                      style:
                          const TextStyle(
                        color:
                            Colors.white,

                        fontSize:
                            11,

                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                  )
                else
                  Container(
                    width:
                        34,

                    height:
                        34,

                    decoration:
                        BoxDecoration(
                      color:
                          AppColors.naranja.withValues(
                        alpha:
                            0.10,
                      ),

                      shape:
                          BoxShape.circle,
                    ),

                    child:
                        const Icon(
                      Icons.chevron_right_rounded,

                      color:
                          AppColors.naranja,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}