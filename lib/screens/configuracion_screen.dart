import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../services/theme_service.dart';

import 'politicas_privacidad_screen.dart';

class ConfiguracionScreen extends StatefulWidget {
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

    final Color textoSecundario = oscuro
        ? AppColors.textoSecundarioOscuro
        : AppColors.textoSecundarioClaro;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Configuración',
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // =====================================================
          // APARIENCIA
          // =====================================================

          const Text(
            'Apariencia',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          Card(
            child: SwitchListTile(
              value: oscuro,

              activeThumbColor:
                  AppColors.naranja,

              secondary: Icon(
                oscuro
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,

                color: AppColors.naranja,
              ),

              title: const Text(
                'Modo oscuro',
                style: TextStyle(
                  fontWeight:
                      FontWeight.w700,
                ),
              ),

              subtitle: Text(
                oscuro
                    ? 'Actualmente estás usando el modo oscuro'
                    : 'Actualmente estás usando el modo claro',
              ),

              onChanged: (valor) async {
                await widget.themeService
                    .cambiarTema(valor);

                if (!mounted) {
                  return;
                }

                setState(() {});
              },
            ),
          ),

          const SizedBox(
            height: 28,
          ),

          // =====================================================
          // PRIVACIDAD
          // =====================================================

          const Text(
            'Privacidad y seguridad',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          // =====================================================
          // POLÍTICA DE PRIVACIDAD
          // =====================================================

          Card(
            child: InkWell(
              borderRadius:
                  BorderRadius.circular(
                22,
              ),

              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (
                      context,
                    ) {
                      return const PoliticasPrivacidadScreen();
                    },
                  ),
                );
              },

              child: Padding(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),

                child: Row(
                  children: [
                    // =============================================
                    // ICONO
                    // =============================================

                    Container(
                      width: 48,
                      height: 48,

                      decoration:
                          BoxDecoration(
                        color: AppColors
                            .naranja
                            .withValues(
                          alpha: 0.12,
                        ),

                        borderRadius:
                            BorderRadius.circular(
                          15,
                        ),
                      ),

                      child:
                          const Icon(
                        Icons
                            .privacy_tip_outlined,

                        color:
                            AppColors.naranja,

                        size:
                            25,
                      ),
                    ),

                    const SizedBox(
                      width: 15,
                    ),

                    // =============================================
                    // TEXTO
                    // =============================================

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,

                        children: [
                          const Text(
                            'Política de privacidad',

                            style:
                                TextStyle(
                              fontSize:
                                  16,

                              fontWeight:
                                  FontWeight
                                      .w700,
                            ),
                          ),

                          const SizedBox(
                            height: 4,
                          ),

                          Text(
                            'Consulta cómo Mercalishuat utiliza y protege tus datos.',

                            style:
                                TextStyle(
                              color:
                                  textoSecundario,

                              fontSize:
                                  13,

                              height:
                                  1.3,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      width: 10,
                    ),

                    Icon(
                      Icons
                          .arrow_forward_ios_rounded,

                      color:
                          textoSecundario,

                      size: 17,
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(
            height: 28,
          ),

          // =====================================================
          // VISTA DEL TEMA
          // =====================================================

          const Text(
            'Vista del tema',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          Container(
            padding:
                const EdgeInsets.all(
              20,
            ),

            decoration: BoxDecoration(
              color: AppColors.naranja,

              borderRadius:
                  BorderRadius.circular(
                15,
              ),
            ),

            child: const Row(
              children: [
                Icon(
                  Icons.storefront,
                  color: Colors.white,
                  size: 35,
                ),

                SizedBox(
                  width: 15,
                ),

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