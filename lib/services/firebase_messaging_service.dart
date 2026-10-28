import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'notificacion_service.dart';
import 'session_service.dart';

class FirebaseMessagingService {
  FirebaseMessagingService._();

  static final FirebaseMessagingService instance =
      FirebaseMessagingService._();

  StreamSubscription<String>? _registroSubscription;

  String? _fid;

  String? get fid => _fid;

  // ============================================================
  // INICIAR FCM WEB
  // ============================================================

  Future<void> iniciar() async {
    final FirebaseMessaging messaging =
        FirebaseMessaging.instance;

    // ==========================================================
    // PEDIR PERMISO EN CHROME
    // ==========================================================

    final NotificationSettings settings =
        await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint(
      'FCM PERMISO: ${settings.authorizationStatus}',
    );

    if (
      settings.authorizationStatus !=
          AuthorizationStatus.authorized
    ) {
      debugPrint(
        'FCM: permiso de notificaciones no concedido',
      );

      return;
    }

    // ==========================================================
    // ESCUCHAR FID
    //
    // IMPORTANTE:
    // Firebase recomienda escuchar antes de register().
    // ==========================================================

    await _registroSubscription?.cancel();

    messaging.onRegistered.listen(
  (
    String installationId,
  ) async {
    _fid =
        installationId;

    debugPrint(
      'FCM FID: $installationId',
    );

    final bool haySesion =
        await SessionService
            .haySesion();

    if (!haySesion) {
      debugPrint(
        'FCM: todavía no hay sesión',
      );

      return;
    }

    final bool registrado =
        await NotificacionService
            .registrarFid(
      fid:
          installationId,
    );

    debugPrint(
      registrado
          ? 'FCM FID GUARDADO EN RAILWAY'
          : 'FCM NO SE PUDO GUARDAR EN RAILWAY',
    );
  },
);

    // ==========================================================
    // REGISTRAR WEB
    //
    // AQUÍ VA TU VAPID PUBLIC KEY
    // ==========================================================

    await messaging.register(
      vapidKey:
          'BAliGFfKevNb8BzNko7EdIwBQ-xW1T_2krXM-DnqvPpBvcVOlZsun7_z2jzn5aWk7JuRKdBjWWeIrXY-Ujse7ZY',
    );

    // ==========================================================
    // MENSAJES CON MERCALISHUAT ABIERTO
    // ==========================================================

    FirebaseMessaging.onMessage.listen(
      (
        RemoteMessage message,
      ) {
        debugPrint(
          'FCM FOREGROUND',
        );

        debugPrint(
          'Título: ${message.notification?.title}',
        );

        debugPrint(
          'Mensaje: ${message.notification?.body}',
        );

        debugPrint(
          'Data: ${message.data}',
        );
      },
    );

    // ==========================================================
    // TOCAR NOTIFICACIÓN
    // ==========================================================

    FirebaseMessaging
        .onMessageOpenedApp
        .listen(
      (
        RemoteMessage message,
      ) {
        debugPrint(
          'FCM PUSH ABIERTO: ${message.data}',
        );

        // Después aquí redirigiremos
        // directamente al ChatScreen.
      },
    );
  }

  Future<void> cerrar() async {
    await _registroSubscription
        ?.cancel();

    _registroSubscription =
        null;

    _fid =
        null;
  }

  Future<void> registrarFidSiHaySesion() async {
  final String? fidActual = _fid;

  if (
    fidActual == null ||
    fidActual.isEmpty
  ) {
    debugPrint(
      'FCM: todavía no hay FID',
    );

    return;
  }

  final bool haySesion =
      await SessionService.haySesion();

  if (!haySesion) {
    debugPrint(
      'FCM: todavía no hay sesión',
    );

    return;
  }

  final bool registrado =
      await NotificacionService.registrarFid(
    fid:
        fidActual,
  );

  debugPrint(
    registrado
        ? 'FCM FID GUARDADO EN RAILWAY'
        : 'FCM NO SE PUDO GUARDAR EN RAILWAY',
  );
}
}