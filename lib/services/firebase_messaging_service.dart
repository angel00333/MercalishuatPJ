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

  StreamSubscription<RemoteMessage>? _mensajeSubscription;

  StreamSubscription<RemoteMessage>? _mensajeAbiertoSubscription;

  String? _fid;

  String? get fid => _fid;

  // ============================================================
  // INICIAR FIREBASE MESSAGING
  // ============================================================

  Future<void> iniciar() async {
    try {
      final FirebaseMessaging messaging =
          FirebaseMessaging.instance;

      debugPrint(
        'FCM: iniciando...',
      );

      // ========================================================
      // PEDIR PERMISOS
      // ========================================================

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
          settings.authorizationStatus ==
              AuthorizationStatus.denied) {
        debugPrint(
          'FCM: permiso denegado',
        );

        return;
      }

      // ========================================================
      // ESCUCHAR FID
      //
      // IMPORTANTE:
      // Firebase recomienda escuchar onRegistered ANTES
      // de llamar register().
      // ========================================================

      await _registroSubscription?.cancel();

      _registroSubscription =
          messaging.onRegistered.listen(
        (String installationId) async {
          _fid = installationId;

          debugPrint(
            '========================================',
          );

          debugPrint(
            'FCM FID: $installationId',
          );

          debugPrint(
            '========================================',
          );

          await registrarFidSiHaySesion();
        },
        onError: (
          Object error,
        ) {
          debugPrint(
            'FCM ERROR REGISTRO: $error',
          );
        },
      );

      // ========================================================
      // REGISTRO
      // ========================================================

      if (kIsWeb) {
        // ======================================================
        // WEB
        // ======================================================

        debugPrint(
          'FCM WEB: registrando...',
        );

        await messaging.register(
          vapidKey:
              'BAliGFfKevNb8BzNko7EdIwBQ-xW1T_2krXM-DnqvPpBvcVOlZsun7_z2jzn5aWk7JuRKdBjWWeIrXY-Ujse7ZY',
          serviceWorkerScriptPath:
              'firebase-messaging-sw.js',
        );

        debugPrint(
          'FCM WEB: registro completado',
        );
      } else {
        // ======================================================
        // ANDROID
        // ======================================================

        debugPrint(
          'FCM ANDROID: activando auto-init...',
        );

        await messaging.setAutoInitEnabled(
          true,
        );

        debugPrint(
          'FCM ANDROID: registrando instalación...',
        );

        await messaging.register();

        debugPrint(
          'FCM ANDROID: register() completado',
        );
      }

      // ========================================================
      // MENSAJES EN PRIMER PLANO
      // ========================================================

      await _mensajeSubscription?.cancel();

      _mensajeSubscription =
          FirebaseMessaging.onMessage.listen(
        (
          RemoteMessage message,
        ) {
          debugPrint(
            '========================================',
          );

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

          debugPrint(
            '========================================',
          );
        },
        onError: (
          Object error,
        ) {
          debugPrint(
            'FCM ERROR FOREGROUND: $error',
          );
        },
      );

      // ========================================================
      // USUARIO TOCA NOTIFICACIÓN DESDE BACKGROUND
      // ========================================================

      await _mensajeAbiertoSubscription?.cancel();

      _mensajeAbiertoSubscription =
          FirebaseMessaging
              .onMessageOpenedApp
              .listen(
        (
          RemoteMessage message,
        ) {
          debugPrint(
            'FCM NOTIFICACIÓN ABIERTA: ${message.data}',
          );
        },
        onError: (
          Object error,
        ) {
          debugPrint(
            'FCM ERROR ABRIENDO NOTIFICACIÓN: $error',
          );
        },
      );

      // ========================================================
      // APP ABIERTA DESDE ESTADO TERMINADO
      // ========================================================

      final RemoteMessage? initialMessage =
          await messaging.getInitialMessage();

      if (initialMessage != null) {
        debugPrint(
          'FCM APP ABIERTA DESDE NOTIFICACIÓN: '
          '${initialMessage.data}',
        );
      }

      debugPrint(
        'FCM: inicialización completada',
      );
    } catch (
      e,
      stackTrace
    ) {
      debugPrint(
        'FCM ERROR GENERAL: $e',
      );

      debugPrint(
        '$stackTrace',
      );
    }
  }

  // ============================================================
  // REGISTRAR FID EN RAILWAY
  // ============================================================

  Future<void> registrarFidSiHaySesion() async {
    final String? fidActual =
        _fid;

    if (
        fidActual == null ||
        fidActual.isEmpty) {
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

    debugPrint(
      'FCM: enviando FID a Railway...',
    );

    final bool registrado =
        await NotificacionService.registrarFid(
      fid:
          fidActual,

      plataforma:
          kIsWeb
              ? 'web'
              : 'android',
    );

    if (registrado) {
      debugPrint(
        'FCM FID GUARDADO EN RAILWAY',
      );
    } else {
      debugPrint(
        'FCM NO SE PUDO GUARDAR EN RAILWAY',
      );
    }
  }

  // ============================================================
  // CERRAR
  // ============================================================

  Future<void> cerrar() async {
    await _registroSubscription?.cancel();

    await _mensajeSubscription?.cancel();

    await _mensajeAbiertoSubscription?.cancel();

    _registroSubscription =
        null;

    _mensajeSubscription =
        null;

    _mensajeAbiertoSubscription =
        null;

    _fid =
        null;

    debugPrint(
      'FCM: servicio cerrado',
    );
  }
}