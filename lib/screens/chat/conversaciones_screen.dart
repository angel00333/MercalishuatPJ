import 'package:flutter/material.dart';

import '../../models/conversacion.dart';
import '../../services/chat_service.dart';
import 'chat_screen.dart';

class ConversacionesScreen extends StatefulWidget {
  const ConversacionesScreen({
    super.key,
  });

  @override
  State<ConversacionesScreen> createState() =>
      _ConversacionesScreenState();
}

class _ConversacionesScreenState
    extends State<ConversacionesScreen> {
  static const Color naranja =
      Color(0xFFFF7E01);

  List<Conversacion> conversaciones = [];

  bool cargando = true;

  String? error;

  @override
  void initState() {
    super.initState();

    _cargar();
  }

  // ============================================================
  // CARGAR
  // ============================================================

  Future<void> _cargar() async {
    if (!mounted) {
      return;
    }

    setState(() {
      cargando = true;
      error = null;
    });

    try {
      final resultado =
          await ChatService.listarConversaciones();

      if (!mounted) {
        return;
      }

      if (resultado['success'] == true) {
        final dynamic raw =
            resultado['conversaciones'];

        final List<Conversacion> lista =
            [];

        if (raw is List) {
          for (final item in raw) {
            if (item is Conversacion) {
              lista.add(
                item,
              );
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
            resultado['message']
                    ?.toString() ??
                'No se pudieron cargar las conversaciones';
      });
    } catch (e, stack) {
      debugPrint(
        'ERROR PANTALLA CONVERSACIONES: $e',
      );

      debugPrint(
        '$stack',
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
  // ABRIR CHAT
  // ============================================================

  Future<void> _abrir(
    Conversacion conversacion,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) {
          return ChatScreen(
            conversacionId:
                conversacion.id,
            nombreUsuario:
                conversacion
                    .nombreCompleto,
          );
        },
      ),
    );

    if (!mounted) {
      return;
    }

    await _cargar();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          Theme.of(context)
              .scaffoldBackgroundColor,

      appBar: AppBar(
        automaticallyImplyLeading:
            false,

        backgroundColor:
            naranja,

        foregroundColor:
            Colors.white,

        centerTitle:
            true,

        title:
            const Text(
          'Mensajes',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),

      body: SizedBox.expand(
        child: _contenido(),
      ),
    );
  }

  // ============================================================
  // CONTENIDO
  // ============================================================

  Widget _contenido() {
    // ==========================================================
    // CARGANDO
    // ==========================================================

    if (cargando) {
      return const Center(
        child:
            CircularProgressIndicator(
          color:
              naranja,
        ),
      );
    }

    // ==========================================================
    // ERROR
    // ==========================================================

    if (error != null) {
      return Center(
        child:
            SingleChildScrollView(
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
                Icons.error_outline,
                size:
                    65,
                color:
                    naranja,
              ),

              const SizedBox(
                height:
                    20,
              ),

              Text(
                error!,
                textAlign:
                    TextAlign.center,
              ),

              const SizedBox(
                height:
                    20,
              ),

              FilledButton(
                style:
                    FilledButton.styleFrom(
                  backgroundColor:
                      naranja,

                  foregroundColor:
                      Colors.white,
                ),

                onPressed:
                    _cargar,

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

    // ==========================================================
    // SIN CONVERSACIONES
    // ==========================================================

    if (conversaciones.isEmpty) {
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
                    .chat_bubble_outline,
                size:
                    70,
                color:
                    naranja,
              ),

              SizedBox(
                height:
                    20,
              ),

              Text(
                'Todavía no tienes conversaciones',
                textAlign:
                    TextAlign.center,
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
                    8,
              ),

              Text(
                'Cuando inicies una conversación aparecerá aquí.',
                textAlign:
                    TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // ==========================================================
    // CONVERSACIONES
    // ==========================================================

    return ListView.builder(
      padding:
          const EdgeInsets.symmetric(
        vertical:
            8,
      ),

      itemCount:
          conversaciones.length,

      itemBuilder:
          (
            context,
            index,
          ) {
        final conversacion =
            conversaciones[index];

        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(
            horizontal:
                18,

            vertical:
                6,
          ),

          leading:
              CircleAvatar(
            radius:
                25,

            backgroundColor:
                naranja,

            foregroundColor:
                Colors.white,

            child:
                Text(
              conversacion
                      .nombre
                      .isNotEmpty
                  ? conversacion
                      .nombre[0]
                      .toUpperCase()
                  : '?',

              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),

          title:
              Text(
            conversacion
                .nombreCompleto,

            maxLines:
                1,

            overflow:
                TextOverflow
                    .ellipsis,

            style:
                const TextStyle(
              fontWeight:
                  FontWeight.w600,
            ),
          ),

          subtitle:
              Text(
            conversacion
                    .ultimoMensaje ??
                'Nueva conversación',

            maxLines:
                1,

            overflow:
                TextOverflow
                    .ellipsis,
          ),

          trailing:
              conversacion
                          .mensajesNoLeidos >
                      0
                  ? Container(
                      width:
                          24,
                      height:
                          24,
                      alignment:
                          Alignment.center,
                      decoration:
                          const BoxDecoration(
                        color:
                            naranja,
                        shape:
                            BoxShape.circle,
                      ),
                      child:
                          Text(
                        conversacion
                            .mensajesNoLeidos
                            .toString(),
                        style:
                            const TextStyle(
                          color:
                              Colors.white,
                          fontSize:
                              11,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons
                          .chevron_right,
                    ),

          onTap:
              () {
            _abrir(
              conversacion,
            );
          },
        );
      },
    );
  }
}