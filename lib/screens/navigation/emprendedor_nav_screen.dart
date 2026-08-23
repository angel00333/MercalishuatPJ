// lib/screens/navigation/emprendedor_nav_screen.dart

import 'package:flutter/material.dart';

import '../../services/theme_service.dart';
import '../explorar/explorar_emprendimientos_screen.dart';
import '../home_emprendedor_screen.dart';
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

    paginas = [
      const ProductosScreen(),
      const ExplorarEmprendimientosScreen(),
      HomeEmprendedorTab(
        themeService: widget.themeService,
      ),
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
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Productos',
          ),
          NavigationDestination(
            icon: Icon(Icons.travel_explore_outlined),
            selectedIcon: Icon(Icons.travel_explore),
            label: 'Explorar',
          ),
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.store_outlined),
            selectedIcon: Icon(Icons.store),
            label: 'Mi tienda',
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