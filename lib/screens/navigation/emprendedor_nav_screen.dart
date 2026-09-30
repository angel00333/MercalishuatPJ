import 'package:flutter/material.dart';

import '../../services/theme_service.dart';
import '../chat/conversaciones_screen.dart';
import '../explorar/explorar_emprendimientos_screen.dart';
import '../home_emprendedor_screen.dart';
import '../mapa_screen_emprendedor.dart';
import '../perfil_screen.dart';
import '../producto_actions/productos_screen.dart';
import '../tienda_actions/mi_tienda_screen.dart';

class EmprendedorNavScreen extends StatefulWidget {
  final ThemeService themeService;

  const EmprendedorNavScreen({
    super.key,
    required this.themeService,
  });

  @override
  State<EmprendedorNavScreen> createState() =>
      _EmprendedorNavScreenState();
}

class _EmprendedorNavScreenState
    extends State<EmprendedorNavScreen> {
  int indexActual = 2;

  late final List<Widget> paginas;

  @override
  void initState() {
    super.initState();

    // ==========================================================
    // LAS PANTALLAS SE CREAN UNA SOLA VEZ
    // ==========================================================

    paginas = [
      const ProductosScreen(),

      const ExplorarEmprendimientosScreen(),

      const MapaScreenEmprendedor(),

      MiTiendaScreen(
        themeService: widget.themeService,
      ),

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
      // PANTALLAS
      //
      // IndexedStack mantiene todas las pantallas montadas.
      //
      // Esto permite conservar:
      //
      // - estado del mapa
      // - GPS
      // - zoom
      // - rutas
      // - tiendas cargadas
      // - estado de conversaciones
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
          // PRODUCTOS
          // ====================================================

          NavigationDestination(
            icon: Icon(
              Icons.inventory_2_outlined,
            ),
            selectedIcon: Icon(
              Icons.inventory_2,
            ),
            label: 'Productos',
          ),

          // ====================================================
          // EXPLORAR
          // ====================================================

          NavigationDestination(
            icon: Icon(
              Icons.travel_explore_outlined,
            ),
            selectedIcon: Icon(
              Icons.travel_explore,
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
          // MI TIENDA
          // ====================================================

          NavigationDestination(
            icon: Icon(
              Icons.store_outlined,
            ),
            selectedIcon: Icon(
              Icons.store,
            ),
            label: 'Mi tienda',
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
// HOME EMPRENDEDOR TAB
// ============================================================

class HomeEmprendedorTab extends StatelessWidget {
  final ThemeService themeService;

  const HomeEmprendedorTab({
    super.key,
    required this.themeService,
  });

  @override
  Widget build(BuildContext context) {
    return HomeEmprendedorScreen(
      themeService: themeService,
    );
  }
}