import 'package:flutter/material.dart';

import '../../models/mensaje.dart';
import '../../services/chat_service.dart';

class ChatScreen
    extends StatefulWidget {
  final int conversacionId;
  final String nombreUsuario;

  const ChatScreen({
    super.key,
    required this.conversacionId,
    required this.nombreUsuario,
  });

  @override
  State<ChatScreen>
      createState() =>
          _ChatScreenState();
}

class _ChatScreenState
    extends State<ChatScreen> {
  static const Color naranja =
      Color(0xFFFF7E01);

  final TextEditingController
      mensajeController =
      TextEditingController();

  final ScrollController
      scrollController =
      ScrollController();

  List<Mensaje> mensajes =
      [];

  bool cargando =
      true;

  bool enviando =
      false;

  String? error;

  @override
  void initState() {
    super.initState();

    _cargarMensajes();
  }

  Future<void>
      _cargarMensajes() async {
    final resultado =
        await ChatService
            .obtenerMensajes(
      conversacionId:
          widget.conversacionId,
    );

    if (!mounted) {
      return;
    }

    if (resultado['success'] ==
        true) {
      setState(() {
        mensajes =
            resultado[
                'mensajes'];

        cargando =
            false;

        error =
            null;
      });

      await ChatService
          .marcarComoLeidos(
        conversacionId:
            widget.conversacionId,
      );

      _bajar();

      return;
    }

    setState(() {
      cargando =
          false;

      error =
          resultado['message'] ??
              'No se pudieron cargar los mensajes';
    });
  }

  void _bajar() {
    WidgetsBinding.instance
        .addPostFrameCallback(
      (_) {
        if (!scrollController
            .hasClients) {
          return;
        }

        scrollController
            .animateTo(
          scrollController
              .position
              .maxScrollExtent,
          duration:
              const Duration(
            milliseconds:
                250,
          ),
          curve:
              Curves.easeOut,
        );
      },
    );
  }

  Future<void>
      _enviarMensaje() async {
    final contenido =
        mensajeController.text
            .trim();

    if (contenido.isEmpty ||
        enviando) {
      return;
    }

    setState(() {
      enviando =
          true;
    });

    final resultado =
        await ChatService
            .enviarMensaje(
      conversacionId:
          widget.conversacionId,
      contenido:
          contenido,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      enviando =
          false;
    });

    if (resultado['success'] !=
        true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content:
              Text(
            resultado['message'] ??
                'No se pudo enviar el mensaje',
          ),
        ),
      );

      return;
    }

    mensajeController.clear();

    // El endpoint de envío no incluye
    // "es_mio", por eso refrescamos
    // desde el servidor.
    await _cargarMensajes();
  }

  String _hora(
    DateTime fecha,
  ) {
    final local =
        fecha.toLocal();

    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    mensajeController.dispose();
    scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final oscuro =
        Theme.of(context)
                .brightness ==
            Brightness.dark;

    return Scaffold(
      appBar:
          AppBar(
        title:
            Row(
          children: [
            const CircleAvatar(
              radius:
                  18,
              backgroundColor:
                  naranja,
              foregroundColor:
                  Colors.white,
              child:
                  Icon(
                Icons.person,
              ),
            ),

            const SizedBox(
              width:
                  10,
            ),

            Expanded(
              child:
                  Text(
                widget
                    .nombreUsuario,
                overflow:
                    TextOverflow
                        .ellipsis,
              ),
            ),
          ],
        ),
      ),

      body:
          Column(
        children: [
          Expanded(
            child:
                _listaMensajes(
              oscuro,
            ),
          ),

          _barraEnviar(
            oscuro,
          ),
        ],
      ),
    );
  }

  Widget _listaMensajes(
    bool oscuro,
  ) {
    if (cargando) {
      return const Center(
        child:
            CircularProgressIndicator(
          color:
              naranja,
        ),
      );
    }

    if (error != null) {
      return Center(
        child:
            Padding(
          padding:
              const EdgeInsets.all(
            30,
          ),
          child:
              Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              const Icon(
                Icons
                    .error_outline,
                color:
                    naranja,
                size:
                    50,
              ),

              const SizedBox(
                height:
                    15,
              ),

              Text(
                error!,
                textAlign:
                    TextAlign.center,
              ),

              const SizedBox(
                height:
                    15,
              ),

              FilledButton(
                onPressed:
                    _cargarMensajes,
                child:
                    const Text(
                  'Reintentar',
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (mensajes.isEmpty) {
      return const Center(
        child:
            Padding(
          padding:
              EdgeInsets.all(
            30,
          ),
          child:
              Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              Icon(
                Icons
                    .waving_hand_outlined,
                size:
                    55,
                color:
                    naranja,
              ),

              SizedBox(
                height:
                    15,
              ),

              Text(
                'Inicia la conversación',
                style:
                    TextStyle(
                  fontSize:
                      18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              SizedBox(
                height:
                    6,
              ),

              Text(
                'Envía el primer mensaje.',
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller:
          scrollController,

      padding:
          const EdgeInsets.fromLTRB(
        14,
        18,
        14,
        18,
      ),

      itemCount:
          mensajes.length,

      itemBuilder:
          (context, index) {
        final mensaje =
            mensajes[index];

        final esMio =
            mensaje.esMio;

        return Align(
          alignment:
              esMio
                  ? Alignment
                      .centerRight
                  : Alignment
                      .centerLeft,

          child:
              Container(
            constraints:
                BoxConstraints(
              maxWidth:
                  MediaQuery.of(
                        context,
                      ).size.width *
                      0.76,
            ),

            margin:
                const EdgeInsets.only(
              bottom:
                  8,
            ),

            padding:
                const EdgeInsets.fromLTRB(
              13,
              9,
              10,
              6,
            ),

            decoration:
                BoxDecoration(
              color:
                  esMio
                      ? naranja
                      : oscuro
                          ? const Color(
                              0xFF2A2045,
                            )
                          : Colors
                              .grey
                              .shade200,

              borderRadius:
                  BorderRadius.only(
                topLeft:
                    const Radius.circular(
                  17,
                ),
                topRight:
                    const Radius.circular(
                  17,
                ),
                bottomLeft:
                    Radius.circular(
                  esMio
                      ? 17
                      : 4,
                ),
                bottomRight:
                    Radius.circular(
                  esMio
                      ? 4
                      : 17,
                ),
              ),
            ),

            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.end,

              children: [
                Align(
                  alignment:
                      Alignment.centerLeft,
                  child:
                      Text(
                    mensaje.contenido,
                    style:
                        TextStyle(
                      color:
                          esMio ||
                                  oscuro
                              ? Colors
                                  .white
                              : Colors
                                  .black87,

                      fontSize:
                          15,
                    ),
                  ),
                ),

                const SizedBox(
                  height:
                      3,
                ),

                Row(
                  mainAxisSize:
                      MainAxisSize.min,

                  children: [
                    Text(
                      _hora(
                        mensaje
                            .createdAt,
                      ),
                      style:
                          TextStyle(
                        color:
                            esMio
                                ? Colors
                                    .white70
                                : oscuro
                                    ? Colors.white60
                                    : Colors.black54,

                        fontSize:
                            10,
                      ),
                    ),

                    if (esMio) ...[
                      const SizedBox(
                        width:
                            4,
                      ),

                      Icon(
                        mensaje.leido
                            ? Icons
                                .done_all
                            : Icons.done,

                        size:
                            15,

                        color:
                            Colors.white70,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _barraEnviar(
    bool oscuro,
  ) {
    return SafeArea(
      top:
          false,

      child:
          Container(
        padding:
            const EdgeInsets.fromLTRB(
          10,
          8,
          10,
          8,
        ),

        decoration:
            BoxDecoration(
          color:
              Theme.of(context)
                  .scaffoldBackgroundColor,

          border:
              Border(
            top:
                BorderSide(
              color:
                  Theme.of(context)
                      .dividerColor
                      .withValues(
                    alpha:
                        0.35,
                  ),
            ),
          ),
        ),

        child:
            Row(
          crossAxisAlignment:
              CrossAxisAlignment.end,

          children: [
            Expanded(
              child:
                  TextField(
                controller:
                    mensajeController,

                minLines:
                    1,

                maxLines:
                    5,

                textCapitalization:
                    TextCapitalization
                        .sentences,

                decoration:
                    InputDecoration(
                  hintText:
                      'Escribe un mensaje...',

                  filled:
                      true,

                  fillColor:
                      oscuro
                          ? const Color(
                              0xFF2A2045,
                            )
                          : Colors.grey
                              .shade100,

                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      24,
                    ),
                    borderSide:
                        BorderSide.none,
                  ),

                  contentPadding:
                      const EdgeInsets.symmetric(
                    horizontal:
                        17,
                    vertical:
                        11,
                  ),
                ),
              ),
            ),

            const SizedBox(
              width:
                  8,
            ),

            Material(
              color:
                  naranja,

              shape:
                  const CircleBorder(),

              child:
                  IconButton(
                onPressed:
                    enviando
                        ? null
                        : _enviarMensaje,

                color:
                    Colors.white,

                icon:
                    enviando
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
                            Icons.send_rounded,
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}