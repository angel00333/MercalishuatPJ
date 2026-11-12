import 'package:flutter/material.dart';

class AppColors {
  // ============================================================
  // IDENTIDAD MERCALISHUAT
  // ============================================================

  static const Color naranja =
      Color(0xFFFF7E01);

  static const Color naranjaClaro =
      Color(0xFFFFA347);

  static const Color naranjaSuave =
      Color(0xFFFFC185);

  static const Color naranjaOscuro =
      Color(0xFFE66F00);

  static const Color morado =
      Color(0xFF2A2045);

  static const Color moradoOscuro =
      Color(0xFF171320);

  static const Color moradoMedio =
      Color(0xFF4B286D);

  static const Color moradoClaro =
      Color(0xFF8B4AC7);

  // ============================================================
  // TEMA CLARO
  // ============================================================

  static const Color fondoClaro =
      Color(0xFFF8F7FA);

  static const Color superficieClara =
      Color(0xFFFFFFFF);

  static const Color tarjetaClara =
      Color(0xFFFFFFFF);

  static const Color textoClaro =
      Color(0xFF241A30);

  static const Color textoSecundarioClaro =
      Color(0xFF766F7E);

  static const Color bordeClaro =
      Color(0xFFEAE5EE);

  // ============================================================
  // TEMA OSCURO
  // ============================================================

  static const Color fondoOscuro =
      Color(0xFF171320);

  static const Color superficieOscura =
      Color(0xFF2A2045);

  static const Color tarjetaOscura =
      Color(0xFF352951);

  static const Color tarjetaOscuraSecundaria =
      Color(0xFF402F5D);

  static const Color textoOscuro =
      Color(0xFFFFFFFF);

  static const Color textoSecundarioOscuro =
      Color(0xFFC9C1D3);

  static const Color bordeOscuro =
      Color(0xFF514269);

  // ============================================================
  // ESTADOS
  // ============================================================

  static const Color exito =
      Color(0xFF29B765);

  static const Color error =
      Color(0xFFE84C4C);

  static const Color advertencia =
      Color(0xFFFFB020);

  static const Color textoSobreNaranja =
      Colors.white;
}

class AppTheme {
  // ============================================================
  // TEMA CLARO
  // ============================================================

  static ThemeData get lightTheme {
    const colorScheme =
        ColorScheme.light(
      primary:
          AppColors.naranja,
      onPrimary:
          Colors.white,
      secondary:
          AppColors.morado,
      onSecondary:
          Colors.white,
      surface:
          AppColors.superficieClara,
      onSurface:
          AppColors.textoClaro,
      error:
          AppColors.error,
      onError:
          Colors.white,
      outline:
          AppColors.bordeClaro,
    );

    return ThemeData(
      useMaterial3:
          true,

      brightness:
          Brightness.light,

      colorScheme:
          colorScheme,

      scaffoldBackgroundColor:
          AppColors.fondoClaro,

      canvasColor:
          AppColors.fondoClaro,

      dividerColor:
          AppColors.bordeClaro,

      // ========================================================
      // APP BAR
      // ========================================================

      appBarTheme:
          const AppBarTheme(
        elevation:
            0,

        scrolledUnderElevation:
            0,

        centerTitle:
            true,

        backgroundColor:
            AppColors.naranja,

        foregroundColor:
            Colors.white,

        surfaceTintColor:
            Colors.transparent,

        iconTheme:
            IconThemeData(
          color:
              Colors.white,
        ),

        titleTextStyle:
            TextStyle(
          color:
              Colors.white,

          fontSize:
              20,

          fontWeight:
              FontWeight.w700,

          fontFamily:
              'Outfit',
        ),
      ),

      // ========================================================
      // TEXTOS
      // ========================================================

      textTheme:
          const TextTheme(
        headlineLarge:
            TextStyle(
          color:
              AppColors.textoClaro,

          fontWeight:
              FontWeight.w900,
        ),

        headlineMedium:
            TextStyle(
          color:
              AppColors.textoClaro,

          fontWeight:
              FontWeight.w800,
        ),

        headlineSmall:
            TextStyle(
          color:
              AppColors.textoClaro,

          fontWeight:
              FontWeight.w800,
        ),

        titleLarge:
            TextStyle(
          color:
              AppColors.textoClaro,

          fontWeight:
              FontWeight.w800,
        ),

        titleMedium:
            TextStyle(
          color:
              AppColors.textoClaro,

          fontWeight:
              FontWeight.w700,
        ),

        titleSmall:
            TextStyle(
          color:
              AppColors.textoClaro,

          fontWeight:
              FontWeight.w600,
        ),

        bodyLarge:
            TextStyle(
          color:
              AppColors.textoClaro,
        ),

        bodyMedium:
            TextStyle(
          color:
              AppColors.textoClaro,
        ),

        bodySmall:
            TextStyle(
          color:
              AppColors.textoSecundarioClaro,
        ),
      ),

      // ========================================================
      // ICONOS
      // ========================================================

      iconTheme:
          const IconThemeData(
        color:
            AppColors.morado,
      ),

      // ========================================================
      // TARJETAS
      // ========================================================

      cardTheme:
          CardThemeData(
        color:
            AppColors.tarjetaClara,

        surfaceTintColor:
            Colors.transparent,

        elevation:
            0,

        margin:
            EdgeInsets.zero,

        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            22,
          ),

          side:
              const BorderSide(
            color:
                AppColors.bordeClaro,
          ),
        ),
      ),

      // ========================================================
      // INPUTS
      // ========================================================

      inputDecorationTheme:
          InputDecorationTheme(
        filled:
            true,

        fillColor:
            Colors.white,

        hintStyle:
            const TextStyle(
          color:
              AppColors.textoSecundarioClaro,

          fontWeight:
              FontWeight.w500,
        ),

        labelStyle:
            const TextStyle(
          color:
              AppColors.textoSecundarioClaro,
        ),

        prefixIconColor:
            AppColors.morado,

        suffixIconColor:
            AppColors.morado,

        contentPadding:
            const EdgeInsets.symmetric(
          horizontal:
              18,

          vertical:
              16,
        ),

        border:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            20,
          ),

          borderSide:
              const BorderSide(
            color:
                AppColors.bordeClaro,
          ),
        ),

        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            20,
          ),

          borderSide:
              const BorderSide(
            color:
                AppColors.bordeClaro,
          ),
        ),

        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            20,
          ),

          borderSide:
              const BorderSide(
            color:
                AppColors.naranja,

            width:
                1.8,
          ),
        ),

        errorBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            20,
          ),

          borderSide:
              const BorderSide(
            color:
                AppColors.error,
          ),
        ),
      ),

      // ========================================================
      // BOTONES
      // ========================================================

      filledButtonTheme:
          FilledButtonThemeData(
        style:
            FilledButton.styleFrom(
          backgroundColor:
              AppColors.naranja,

          foregroundColor:
              Colors.white,

          elevation:
              0,

          padding:
              const EdgeInsets.symmetric(
            horizontal:
                20,

            vertical:
                14,
          ),

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              16,
            ),
          ),
        ),
      ),

      elevatedButtonTheme:
          ElevatedButtonThemeData(
        style:
            ElevatedButton.styleFrom(
          backgroundColor:
              AppColors.naranja,

          foregroundColor:
              Colors.white,

          elevation:
              0,

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              16,
            ),
          ),
        ),
      ),

      outlinedButtonTheme:
          OutlinedButtonThemeData(
        style:
            OutlinedButton.styleFrom(
          foregroundColor:
              AppColors.naranja,

          side:
              const BorderSide(
            color:
                AppColors.naranja,
          ),

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              16,
            ),
          ),
        ),
      ),

      textButtonTheme:
          TextButtonThemeData(
        style:
            TextButton.styleFrom(
          foregroundColor:
              AppColors.naranja,
        ),
      ),

      floatingActionButtonTheme:
          const FloatingActionButtonThemeData(
        backgroundColor:
            AppColors.naranja,

        foregroundColor:
            Colors.white,

        elevation:
            3,
      ),

      // ========================================================
      // BOTTOM SHEET
      // ========================================================

      bottomSheetTheme:
          const BottomSheetThemeData(
        backgroundColor:
            Colors.white,

        surfaceTintColor:
            Colors.transparent,

        showDragHandle:
            true,

        dragHandleColor:
            AppColors.bordeClaro,
      ),

      // ========================================================
      // DIALOG
      // ========================================================

      dialogTheme:
          DialogThemeData(
        backgroundColor:
            Colors.white,

        surfaceTintColor:
            Colors.transparent,

        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            24,
          ),
        ),
      ),

      // ========================================================
      // SNACKBAR
      // ========================================================

      snackBarTheme:
          SnackBarThemeData(
        backgroundColor:
            AppColors.morado,

        contentTextStyle:
            const TextStyle(
          color:
              Colors.white,
        ),

        behavior:
            SnackBarBehavior.floating,

        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            15,
          ),
        ),
      ),

      // ========================================================
      // SWITCH
      // ========================================================

      switchTheme:
          SwitchThemeData(
        thumbColor:
            WidgetStateProperty.resolveWith(
          (
            states,
          ) {
            if (states.contains(
              WidgetState.selected,
            )) {
              return AppColors.naranja;
            }

            return Colors.grey.shade500;
          },
        ),

        trackColor:
            WidgetStateProperty.resolveWith(
          (
            states,
          ) {
            if (states.contains(
              WidgetState.selected,
            )) {
              return AppColors.naranjaSuave;
            }

            return Colors.grey.shade300;
          },
        ),
      ),

      progressIndicatorTheme:
          const ProgressIndicatorThemeData(
        color:
            AppColors.naranja,
      ),
    );
  }

  // ============================================================
  // TEMA OSCURO
  // ============================================================

  static ThemeData get darkTheme {
    const colorScheme =
        ColorScheme.dark(
      primary:
          AppColors.naranja,
      onPrimary:
          Colors.white,
      secondary:
          AppColors.naranjaClaro,
      onSecondary:
          Colors.white,
      surface:
          AppColors.superficieOscura,
      onSurface:
          AppColors.textoOscuro,
      error:
          AppColors.error,
      onError:
          Colors.white,
      outline:
          AppColors.bordeOscuro,
    );

    return ThemeData(
      useMaterial3:
          true,

      brightness:
          Brightness.dark,

      colorScheme:
          colorScheme,

      scaffoldBackgroundColor:
          AppColors.fondoOscuro,

      canvasColor:
          AppColors.fondoOscuro,

      dividerColor:
          AppColors.bordeOscuro,

      appBarTheme:
          const AppBarTheme(
        elevation:
            0,

        scrolledUnderElevation:
            0,

        centerTitle:
            true,

        backgroundColor:
            AppColors.moradoOscuro,

        foregroundColor:
            Colors.white,

        surfaceTintColor:
            Colors.transparent,

        titleTextStyle:
            TextStyle(
          color:
              Colors.white,

          fontSize:
              20,

          fontWeight:
              FontWeight.w700,

          fontFamily:
              'Outfit',
        ),
      ),

      textTheme:
          const TextTheme(
        headlineLarge:
            TextStyle(
          color:
              Colors.white,

          fontWeight:
              FontWeight.w900,
        ),

        headlineMedium:
            TextStyle(
          color:
              Colors.white,

          fontWeight:
              FontWeight.w800,
        ),

        headlineSmall:
            TextStyle(
          color:
              Colors.white,

          fontWeight:
              FontWeight.w800,
        ),

        titleLarge:
            TextStyle(
          color:
              Colors.white,

          fontWeight:
              FontWeight.w800,
        ),

        titleMedium:
            TextStyle(
          color:
              Colors.white,

          fontWeight:
              FontWeight.w700,
        ),

        titleSmall:
            TextStyle(
          color:
              Colors.white,

          fontWeight:
              FontWeight.w600,
        ),

        bodyLarge:
            TextStyle(
          color:
              Colors.white,
        ),

        bodyMedium:
            TextStyle(
          color:
              Colors.white,
        ),

        bodySmall:
            TextStyle(
          color:
              AppColors.textoSecundarioOscuro,
        ),
      ),

      iconTheme:
          const IconThemeData(
        color:
            AppColors.naranjaClaro,
      ),

      cardTheme:
          CardThemeData(
        color:
            AppColors.tarjetaOscura,

        surfaceTintColor:
            Colors.transparent,

        elevation:
            0,

        margin:
            EdgeInsets.zero,

        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            22,
          ),

          side:
              const BorderSide(
            color:
                AppColors.bordeOscuro,
          ),
        ),
      ),

      inputDecorationTheme:
          InputDecorationTheme(
        filled:
            true,

        fillColor:
            AppColors.tarjetaOscura,

        hintStyle:
            const TextStyle(
          color:
              AppColors.textoSecundarioOscuro,

          fontWeight:
              FontWeight.w500,
        ),

        labelStyle:
            const TextStyle(
          color:
              AppColors.textoSecundarioOscuro,
        ),

        prefixIconColor:
            AppColors.naranjaClaro,

        suffixIconColor:
            AppColors.naranjaClaro,

        contentPadding:
            const EdgeInsets.symmetric(
          horizontal:
              18,

          vertical:
              16,
        ),

        border:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            20,
          ),

          borderSide:
              const BorderSide(
            color:
                AppColors.bordeOscuro,
          ),
        ),

        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            20,
          ),

          borderSide:
              const BorderSide(
            color:
                AppColors.bordeOscuro,
          ),
        ),

        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            20,
          ),

          borderSide:
              const BorderSide(
            color:
                AppColors.naranja,

            width:
                1.8,
          ),
        ),
      ),

      filledButtonTheme:
          FilledButtonThemeData(
        style:
            FilledButton.styleFrom(
          backgroundColor:
              AppColors.naranja,

          foregroundColor:
              Colors.white,

          elevation:
              0,

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              16,
            ),
          ),
        ),
      ),

      elevatedButtonTheme:
          ElevatedButtonThemeData(
        style:
            ElevatedButton.styleFrom(
          backgroundColor:
              AppColors.naranja,

          foregroundColor:
              Colors.white,

          elevation:
              0,

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              16,
            ),
          ),
        ),
      ),

      outlinedButtonTheme:
          OutlinedButtonThemeData(
        style:
            OutlinedButton.styleFrom(
          foregroundColor:
              AppColors.naranjaClaro,

          side:
              const BorderSide(
            color:
                AppColors.naranja,
          ),

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              16,
            ),
          ),
        ),
      ),

      textButtonTheme:
          TextButtonThemeData(
        style:
            TextButton.styleFrom(
          foregroundColor:
              AppColors.naranjaClaro,
        ),
      ),

      floatingActionButtonTheme:
          const FloatingActionButtonThemeData(
        backgroundColor:
            AppColors.naranja,

        foregroundColor:
            Colors.white,

        elevation:
            3,
      ),

      bottomSheetTheme:
          const BottomSheetThemeData(
        backgroundColor:
            AppColors.tarjetaOscura,

        surfaceTintColor:
            Colors.transparent,

        showDragHandle:
            true,

        dragHandleColor:
            AppColors.bordeOscuro,
      ),

      dialogTheme:
          DialogThemeData(
        backgroundColor:
            AppColors.tarjetaOscura,

        surfaceTintColor:
            Colors.transparent,

        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            24,
          ),
        ),
      ),

      snackBarTheme:
          SnackBarThemeData(
        backgroundColor:
            AppColors.tarjetaOscuraSecundaria,

        contentTextStyle:
            const TextStyle(
          color:
              Colors.white,
        ),

        behavior:
            SnackBarBehavior.floating,

        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            15,
          ),
        ),
      ),

      switchTheme:
          SwitchThemeData(
        thumbColor:
            WidgetStateProperty.resolveWith(
          (
            states,
          ) {
            if (states.contains(
              WidgetState.selected,
            )) {
              return AppColors.naranja;
            }

            return Colors.grey.shade400;
          },
        ),

        trackColor:
            WidgetStateProperty.resolveWith(
          (
            states,
          ) {
            if (states.contains(
              WidgetState.selected,
            )) {
              return AppColors.naranjaOscuro;
            }

            return Colors.grey.shade700;
          },
        ),
      ),

      progressIndicatorTheme:
          const ProgressIndicatorThemeData(
        color:
            AppColors.naranja,
      ),
    );
  }
}