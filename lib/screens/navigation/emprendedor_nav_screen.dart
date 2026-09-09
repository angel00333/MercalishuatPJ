import 'package:flutter/material.dart';

import '../../services/theme_service.dart';
import '../explorar/explorar_emprendimientos_screen.dart';
import '../home_emprendedor_screen.dart';
import '../perfil_screen.dart';
import '../producto_actions/productos_screen.dart';
import '../tienda_actions/mi_tienda_screen.dart';
import '../mapa_screen_emprendedor.dart';

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

      PerfilScreen(
        themeService: widget.themeService,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ========================================================
      // IMPORTANTE
      //
      // ANTES:
      //
      // body: paginas[indexActual],
      //
      // AHORA:
      //
      // IndexedStack mantiene todas las pantallas montadas.
      //
      // Esto permite que el mapa conserve:
      //
      // - ubicación de cámara
      // - zoom
      // - inclinación
      // - rotación
      // - GPS activo
      // - posición GPS
      // - ruta
      // - tiendas cargadas
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
          // Evitamos reconstrucción innecesaria si pulsa
          // nuevamente la pestaña actual.
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