import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../services/theme_service.dart';

class ConfiguracionScreen
    extends StatefulWidget {
  final ThemeService themeService;

  const ConfiguracionScreen({
    super.key,
    required this.themeService,
  });

  @override
  State<ConfiguracionScreen> createState() =>
      _ConfiguracionScreenState();
}

class _ConfiguracionScreenState
    extends State<ConfiguracionScreen> {
  @override
  Widget build(BuildContext context) {
    final oscuro =
        widget.themeService.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Configuración',
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Apariencia',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          Card(
            child: SwitchListTile(
              value: oscuro,

              activeThumbColor:
                  AppColors.naranja,

              secondary: Icon(
                oscuro
                    ? Icons.dark_mode
                    : Icons.light_mode,

                color: AppColors.naranja,
              ),

              title: const Text(
                'Modo oscuro',
              ),

              subtitle: Text(
                oscuro
                    ? 'Actualmente estás usando el modo oscuro'
                    : 'Actualmente estás usando el modo claro',
              ),

              onChanged: (valor) async {
                await widget.themeService
                    .cambiarTema(valor);

                if (!mounted) return;

                setState(() {});
              },
            ),
          ),

          const SizedBox(height: 25),

          const Text(
            'Vista del tema',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(20),

            decoration: BoxDecoration(
              color: AppColors.naranja,

              borderRadius:
                  BorderRadius.circular(15),
            ),

            child: const Row(
              children: [
                Icon(
                  Icons.storefront,
                  color: Colors.white,
                  size: 35,
                ),

                SizedBox(width: 15),

                Expanded(
                  child: Text(
                    'Mercalishuat',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}