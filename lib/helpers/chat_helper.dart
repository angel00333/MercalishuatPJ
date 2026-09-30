import 'package:flutter/material.dart';

import '../screens/chat/chat_screen.dart';
import '../services/chat_service.dart';

class ChatHelper {
  static Future<void> abrirChat({
    required BuildContext context,
    required int usuarioDestinoId,
    required String nombreDestino,
  }) async {
    final resultado =
        await ChatService.crearConversacion(
      usuarioDestinoId:
          usuarioDestinoId,
    );

    if (!context.mounted) {
      return;
    }

    if (resultado['success'] !=
        true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            resultado['message'] ??
                'No se pudo iniciar la conversación',
          ),
        ),
      );

      return;
    }

    final int? conversacionId =
        int.tryParse(
      resultado['conversacion_id']
          .toString(),
    );

    if (conversacionId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'La conversación no es válida',
          ),
        ),
      );

      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) =>
                ChatScreen(
          conversacionId:
              conversacionId,
          nombreUsuario:
              nombreDestino,
        ),
      ),
    );
  }
}