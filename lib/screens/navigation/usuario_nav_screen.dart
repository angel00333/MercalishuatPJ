import 'package:flutter/material.dart';
import 'package:mercalishuat/screens/navigation/emprendedor_nav_screen.dart';

import '../../services/theme_service.dart';
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
      body: paginas[indexActual],
      bottomNavigationBar: NavigationBar(
        selectedIndex: indexActual,
        onDestinationSelected: (index) {
          setState(() {
            indexActual = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(
              Icons.access_time_outlined,
            ),
            selectedIcon: Icon(
              Icons.access_time,
            ),
            label: 'Recientes',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.search_outlined,
            ),
            selectedIcon: Icon(
              Icons.search,
            ),
            label: 'Explorar',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.map_outlined,
            ),
            selectedIcon: Icon(
              Icons.map,
            ),
            label: 'Mapa',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.storefront_outlined,
            ),
            selectedIcon: Icon(
              Icons.storefront,
            ),
            label: 'Tiendas',
          ),
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