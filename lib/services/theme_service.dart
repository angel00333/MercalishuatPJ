import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'dark_mode';

  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeMode get themeMode {
    return _isDarkMode
        ? ThemeMode.dark
        : ThemeMode.light;
  }

  Future<void> cargarTema() async {
    final prefs =
        await SharedPreferences.getInstance();

    _isDarkMode =
        prefs.getBool(_themeKey) ?? false;

    notifyListeners();
  }

  Future<void> cambiarTema(bool oscuro) async {
    _isDarkMode = oscuro;

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setBool(
      _themeKey,
      oscuro,
    );

    notifyListeners();
  }
}