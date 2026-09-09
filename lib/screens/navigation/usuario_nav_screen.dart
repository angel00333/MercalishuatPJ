
import 'package:flutter/material.dart';
import 'package:mercalishuat/screens/navigation/emprendedor_nav_screen.dart';

import '../../services/theme_service.dart';
import '../mapa_screen.dart';
import '../explorar/explorar_emprendimientos_screen.dart';
import '../home_usuario_screen.dart';
import '../perfil_screen.dart';
import '../publicaciones/feed_screen.dart';

class UsuarioNavScreen extends StatefulWidget {
  final ThemeService themeService;

  const UsuarioNavScreen({
    super.key,
    required this.themeService,
  });

  @override
  State<UsuarioNavScreen> createState() =>
      _UsuarioNavScreenState();
}

class _UsuarioNavScreenState
    extends State<UsuarioNavScreen> {
  int indexActual = 2;

  late final List<Widget> paginas;

  @override
  void initState() {
    super.initState();

    // ==========================================================
    // IMPORTANTE
    //
    // Estas pantallas se crean UNA SOLA VEZ.
    //
    // Al utilizar IndexedStack más abajo:
    //
    // - MapaScreen no se destruye.
    // - conserva zoom.
    // - conserva rotación.
    // - conserva inclinación.
    // - conserva posición.
    // - conserva GPS activo.
    // - conserva rutas.
    // - conserva estado de las demás pantallas.
    // ==========================================================

    paginas = [
      const FeedScreen(),

      const ExplorarEmprendimientosScreen(),

      const MapaScreen(),

      const TiendasUsuarioScreen(),

      PerfilScreen(
        themeService: widget.themeService,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ========================================================
      // PANTALLAS
      //
      // ANTES:
      //
      // body: paginas[indexActual],
      //
      // AHORA:
      //
      // IndexedStack mantiene todas las pantallas vivas,
      // mostrando solamente la seleccionada.
      // ========================================================

      body: IndexedStack(
        index: indexActual,
        children: paginas,
      ),

      // ========================================================
      // NAVEGACIÓN INFERIOR
      // ========================================================

      bottomNavigationBar: NavigationBar(
        selectedIndex: indexActual,

        onDestinationSelected: (index) {
          if (index == indexActual) {
            return;
          }

          setState(() {
            indexActual = index;
          });
        },

        destinations: const [
          // ====================================================
          // RECIENTES
          // ====================================================

          NavigationDestination(
            icon: Icon(
              Icons.access_time_outlined,
            ),
            selectedIcon: Icon(
              Icons.access_time,
            ),
            label: 'Recientes',
          ),

          // ====================================================
          // EXPLORAR
          // ====================================================

          NavigationDestination(
            icon: Icon(
              Icons.search_outlined,
            ),
            selectedIcon: Icon(
              Icons.search,
            ),
            label: 'Explorar',
          ),

          // ====================================================
          // MAPA
          // ====================================================

          NavigationDestination(
            icon: Icon(
              Icons.map_outlined,
            ),
            selectedIcon: Icon(
              Icons.map,
            ),
            label: 'Mapa',
          ),

          // ====================================================
          // TIENDAS
          // ====================================================

          NavigationDestination(
            icon: Icon(
              Icons.storefront_outlined,
            ),
            selectedIcon: Icon(
              Icons.storefront,
            ),
            label: 'Tiendas',
          ),

          // ====================================================
          // PERFIL
          // ====================================================

          NavigationDestination(
            icon: Icon(
              Icons.person_outline,
            ),
            selectedIcon: Icon(
              Icons.person,
            ),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// HOME USUARIO TAB
// ============================================================

class HomeUsuarioTab extends StatelessWidget {
  final ThemeService themeService;

  const HomeUsuarioTab({
    super.key,
    required this.themeService,
  });

  @override
  Widget build(BuildContext context) {
    return HomeUsuarioScreen(
      themeService: themeService,
    );
  }
}

// ============================================================
// TIENDAS USUARIO
// ============================================================

class TiendasUsuarioScreen extends StatelessWidget {
  const TiendasUsuarioScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Aquí puedes mostrar tiendas destacadas o categorías',
        ),
      ),
    );
  }
}