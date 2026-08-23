// lib/screens/navigation/usuario_nav_screen.dart

import 'package:flutter/material.dart';

import '../../services/theme_service.dart';
import '../configuracion_screen.dart';
import '../explorar/explorar_emprendimientos_screen.dart';
import '../home_usuario_screen.dart';
import '../perfil_screen.dart';

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
      const RecientesUsuarioScreen(),
      const ExplorarEmprendimientosScreen(),
      HomeUsuarioTab(
        themeService: widget.themeService,
      ),
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
            icon: Icon(Icons.access_time_outlined),
            selectedIcon: Icon(Icons.access_time),
            label: 'Recientes',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Explorar',
          ),
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Tiendas',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
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

class RecientesUsuarioScreen extends StatelessWidget {
  const RecientesUsuarioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Aquí irán las publicaciones recientes',
        ),
      ),
    );
  }
}

class TiendasUsuarioScreen extends StatelessWidget {
  const TiendasUsuarioScreen({super.key});

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