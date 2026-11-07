import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/../config/app_theme.dart';
// Ajusta la ruta si AppTheme está en otra carpeta.

PreferredSizeWidget buildAdminTopBar({
  required BuildContext context,
  required String title,
  List<Widget>? actions,
}) {
  final bool oscuro =
      Theme.of(context).brightness == Brightness.dark;

  final Color contenido = oscuro
      ? AppColors.textoOscuro
      : AppColors.textoSobreNaranja;

  return AppBar(
    automaticallyImplyLeading: false,

    // CLARO: naranja
    // OSCURO: transparente, se integra al fondo de la pantalla
    backgroundColor:
        oscuro ? Colors.transparent : AppColors.naranja,

    surfaceTintColor: Colors.transparent,

    shadowColor: Colors.transparent,

    elevation: 0,

    scrolledUnderElevation: 0,

    centerTitle: true,

    toolbarHeight: 72,

    leadingWidth: 64,

    systemOverlayStyle: SystemUiOverlayStyle.light,

    leading: IconButton(
      tooltip: 'Volver',
      onPressed: () {
        Navigator.of(context).maybePop();
      },
      icon: Icon(
        Icons.arrow_back_ios_new_rounded,
        color: contenido,
        size: 24,
      ),
    ),

    title: Text(
      title,
      style: TextStyle(
        color: contenido,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),

    iconTheme: IconThemeData(
      color: contenido,
    ),

    actionsIconTheme: IconThemeData(
      color: contenido,
    ),

    actions: actions,
  );
}