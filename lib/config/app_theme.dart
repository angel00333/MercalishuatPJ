import 'package:flutter/material.dart';

class AppColors {
  static const Color naranja = Color(0xFFFF7E01);

  static const Color naranjaClaro = Color(0xFFFFA347);
  static const Color naranjaSuave = Color(0xFFFFC185);
  static const Color naranjaOscuro = Color(0xFFE66F00);

  static const Color fondoClaro = Color(0xFFFFFFFF);

  static const Color fondoOscuro = Color(0xFF2A2045);

  static const Color textoClaro = Color(0xFF000000);

  static const Color textoOscuro = Color(0xFFFFFFFF);

  static const Color textoSobreNaranja = Color(0xFFFFFFFF);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      scaffoldBackgroundColor: AppColors.fondoClaro,

      colorScheme: const ColorScheme.light(
        primary: AppColors.naranja,
        secondary: AppColors.naranjaClaro,
        surface: AppColors.fondoClaro,
        onPrimary: AppColors.textoSobreNaranja,
        onSurface: AppColors.textoClaro,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.naranja,
        foregroundColor: AppColors.textoSobreNaranja,
        elevation: 0,
        centerTitle: true,
      ),

      iconTheme: const IconThemeData(
        color: AppColors.naranja,
      ),

      textTheme: const TextTheme(
        bodyLarge: TextStyle(
          color: AppColors.textoClaro,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textoClaro,
        ),
        titleLarge: TextStyle(
          color: AppColors.textoClaro,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: TextStyle(
          color: AppColors.textoClaro,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.fondoClaro,
        labelStyle: const TextStyle(
          color: AppColors.naranjaOscuro,
        ),
        prefixIconColor: AppColors.naranja,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.naranja,
            width: 2,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.naranjaSuave,
          ),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.naranja,
          foregroundColor: AppColors.textoSobreNaranja,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.naranja;
            }

            return Colors.grey;
          },
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.naranjaSuave;
            }

            return Colors.grey.shade300;
          },
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      scaffoldBackgroundColor: AppColors.fondoOscuro,

      colorScheme: const ColorScheme.dark(
        primary: AppColors.naranja,
        secondary: AppColors.naranjaClaro,
        surface: AppColors.fondoOscuro,
        onPrimary: AppColors.textoSobreNaranja,
        onSurface: AppColors.textoOscuro,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.fondoOscuro,
        foregroundColor: AppColors.textoOscuro,
        elevation: 0,
        centerTitle: true,
      ),

      iconTheme: const IconThemeData(
        color: AppColors.naranja,
      ),

      textTheme: const TextTheme(
        bodyLarge: TextStyle(
          color: AppColors.textoOscuro,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textoOscuro,
        ),
        titleLarge: TextStyle(
          color: AppColors.textoOscuro,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: TextStyle(
          color: AppColors.textoOscuro,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF352951),
        labelStyle: const TextStyle(
          color: AppColors.naranjaClaro,
        ),
        prefixIconColor: AppColors.naranja,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.naranja,
            width: 2,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.naranjaClaro,
          ),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.naranja,
          foregroundColor: AppColors.textoSobreNaranja,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      cardTheme: CardThemeData(
        color: const Color(0xFF352951),
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.naranja;
            }

            return Colors.grey;
          },
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.naranjaSuave;
            }

            return Colors.grey.shade700;
          },
        ),
      ),
    );
  }
}