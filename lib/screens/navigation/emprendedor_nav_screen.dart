import 'package:flutter/material.dart';

import '../../services/theme_service.dart';
import '../../widgets/campana_notificaciones.dart';

import '../chat/conversaciones_screen.dart';
import '../explorar/explorar_emprendimientos_screen.dart';
import '../mapa_screen_emprendedor.dart';
import '../perfil_screen.dart';
import '../producto_actions/productos_screen.dart';
import '../tienda_actions/mi_tienda_screen.dart';

class EmprendedorNavScreen
    extends StatefulWidget {
  final ThemeService themeService;

  const EmprendedorNavScreen({
    super.key,
    required this.themeService,
  });

  @override
  State<EmprendedorNavScreen>
      createState() =>
          _EmprendedorNavScreenState();
}

class _EmprendedorNavScreenState
    extends State<
        EmprendedorNavScreen> {
  int indexActual = 2;

  late final List<Widget> paginas;

  @override
  void initState() {
    super.initState();

    paginas = [
      const ProductosScreen(),

      const ExplorarEmprendimientosScreen(),

      const MapaScreenEmprendedor(),

      MiTiendaScreen(
        themeService:
            widget.themeService,
      ),

      const ConversacionesScreen(),

      PerfilScreen(
        themeService:
            widget.themeService,
      ),
    ];
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      // ========================================================
      // PANTALLAS
      // ========================================================

      body:
          IndexedStack(
        index:
            indexActual,

        children:
            paginas,
      ),

      // ========================================================
      // CAMPANA
      // ========================================================

      floatingActionButton:
          const SafeArea(
        child:
            CampanaNotificaciones(),
      ),

      floatingActionButtonLocation:
          FloatingActionButtonLocation
              .endFloat,

      // ========================================================
      // NAVEGACIÓN
      // ========================================================

      bottomNavigationBar:
          NavigationBar(
        selectedIndex:
            indexActual,

        onDestinationSelected:
            (
              index,
            ) {
          if (
            index ==
            indexActual
          ) {
            return;
          }

          setState(() {
            indexActual =
                index;
          });
        },

        destinations:
            const [
          NavigationDestination(
            icon:
                Icon(
              Icons.inventory_2_outlined,
            ),

            selectedIcon:
                Icon(
              Icons.inventory_2,
            ),

            label:
                'Productos',
          ),

          NavigationDestination(
            icon:
                Icon(
              Icons.travel_explore_outlined,
            ),

            selectedIcon:
                Icon(
              Icons.travel_explore,
            ),

            label:
                'Explorar',
          ),

          NavigationDestination(
            icon:
                Icon(
              Icons.map_outlined,
            ),

            selectedIcon:
                Icon(
              Icons.map,
            ),

            label:
                'Mapa',
          ),

          NavigationDestination(
            icon:
                Icon(
              Icons.store_outlined,
            ),

            selectedIcon:
                Icon(
              Icons.store,
            ),

            label:
                'Mi tienda',
          ),

          NavigationDestination(
            icon:
                Icon(
              Icons.chat_bubble_outline,
            ),

            selectedIcon:
                Icon(
              Icons.chat_bubble,
            ),

            label:
                'Mensajes',
          ),

          NavigationDestination(
            icon:
                Icon(
              Icons.person_outline,
            ),

            selectedIcon:
                Icon(
              Icons.person,
            ),

            label:
                'Perfil',
          ),
        ],
      ),
    );
  }
}