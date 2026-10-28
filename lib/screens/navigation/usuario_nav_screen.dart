import 'package:flutter/material.dart';

import '../../services/theme_service.dart';
import '../../widgets/campana_notificaciones.dart';

import '../chat/conversaciones_screen.dart';
import '../mapa_screen.dart';
import '../explorar/explorar_emprendimientos_screen.dart';
import '../perfil_screen.dart';
import '../publicaciones/feed_screen.dart';

class UsuarioNavScreen
    extends StatefulWidget {
  final ThemeService themeService;

  const UsuarioNavScreen({
    super.key,
    required this.themeService,
  });

  @override
  State<UsuarioNavScreen>
      createState() =>
          _UsuarioNavScreenState();
}

class _UsuarioNavScreenState
    extends State<UsuarioNavScreen> {
  int indexActual = 2;

  late final List<Widget> paginas;

  @override
  void initState() {
    super.initState();

    paginas = [
      const FeedScreen(),

      const ExplorarEmprendimientosScreen(),

      const MapaScreen(),

      const TiendasUsuarioScreen(),

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
              Icons.access_time_outlined,
            ),

            selectedIcon:
                Icon(
              Icons.access_time,
            ),

            label:
                'Recientes',
          ),

          NavigationDestination(
            icon:
                Icon(
              Icons.search_outlined,
            ),

            selectedIcon:
                Icon(
              Icons.search,
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
              Icons.storefront_outlined,
            ),

            selectedIcon:
                Icon(
              Icons.storefront,
            ),

            label:
                'Tiendas',
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


// ============================================================
// TIENDAS USUARIO
// ============================================================

class TiendasUsuarioScreen
    extends StatelessWidget {
  const TiendasUsuarioScreen({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return const Scaffold(
      body:
          Center(
        child:
            Text(
          'Aquí puedes mostrar tiendas destacadas o categorías',
        ),
      ),
    );
  }
}