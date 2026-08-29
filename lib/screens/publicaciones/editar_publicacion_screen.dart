import 'package:flutter/material.dart';

import '../../models/publicacion.dart';
import '../../services/publicacion_service.dart';

class EditarPublicacionScreen
    extends StatefulWidget {
  final Publicacion publicacion;

  const EditarPublicacionScreen({
    super.key,
    required this.publicacion,
  });

  @override
  State<EditarPublicacionScreen>
      createState() =>
          _EditarPublicacionScreenState();
}

class _EditarPublicacionScreenState
    extends State<
        EditarPublicacionScreen> {
  late TextEditingController
      textoController;

  bool guardando = false;

  @override
  void initState() {
    super.initState();

    textoController =
        TextEditingController(
      text:
          widget.publicacion.texto,
    );
  }

  Future<void> guardar() async {
    final texto =
        textoController.text
            .trim();

    if (texto.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'El texto no puede estar vacío',
          ),
        ),
      );

      return;
    }

    setState(() {
      guardando = true;
    });

    final resultado =
        await PublicacionService.editar(
      id:
          widget.publicacion.id,
      texto:
          texto,
      productoId:
          widget.publicacion.productoId,
    );

    if (!mounted) return;

    setState(() {
      guardando = false;
    });

    if (resultado['success'] == true) {
      Navigator.pop(
        context,
        true,
      );

      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          resultado['message'] ??
              'No se pudo editar',
        ),
      ),
    );
  }

  @override
  void dispose() {
    textoController.dispose();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text(
          'Editar publicación',
        ),

        actions: [
          IconButton(
            tooltip:
                'Guardar',

            onPressed:
                guardando
                    ? null
                    : guardar,

            icon:
                guardando
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color:
                              Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.check,
                        color:
                            Colors.white,
                      ),
          ),
        ],
      ),

      body: Padding(
        padding:
            const EdgeInsets.all(
          20,
        ),

        child: TextField(
          controller:
              textoController,

          maxLength: 1500,

          minLines: 8,

          maxLines: null,

          decoration:
              const InputDecoration(
            hintText:
                'Contenido de la publicación',
          ),
        ),
      ),
    );
  }
}