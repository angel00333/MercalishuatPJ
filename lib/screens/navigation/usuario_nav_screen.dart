import 'package:flutter/material.dart';
import 'package:mercalishuat/screens/navigation/emprendedor_nav_screen.dart';

import '../../services/theme_service.dart';
import '../chat/conversaciones_screen.dart';
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
    // PANTALLAS
    //
    // Se crean una sola vez.
    //
    // IndexedStack permite conservar:
    //
    // - estado del mapa
    // - zoom
    // - GPS
    // - rutas
    // - posición
    // - estado del feed
    // - conversaciones
    // ==========================================================

    paginas = [
      const FeedScreen(),

      const ExplorarEmprendimientosScreen(),

      const MapaScreen(),

      const TiendasUsuarioScreen(),

      const ConversacionesScreen(),

      PerfilScreen(
        themeService: widget.themeService,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ========================================================
      // CONTENIDO
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
          // MENSAJES
          // ====================================================

          NavigationDestination(
            icon: Icon(
              Icons.chat_bubble_outline,
            ),
            selectedIcon: Icon(
              Icons.chat_bubble,
            ),
            label: 'Mensajes',
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