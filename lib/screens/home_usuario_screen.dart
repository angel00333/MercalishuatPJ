// lib/screens/home_usuario_screen.dart

import 'package:flutter/material.dart';

import '../services/theme_service.dart';
import 'configuracion_screen.dart';
import 'perfil_screen.dart';
import 'explorar/explorar_emprendimientos_screen.dart';

class HomeUsuarioScreen extends StatelessWidget {
  final ThemeService themeService;

  const HomeUsuarioScreen({
    super.key,
    required this.themeService,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mercalishuat'),
        actions: [
          IconButton(
            tooltip: 'Configuración',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ConfiguracionScreen(
                    themeService: themeService,
                  ),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Perfil',
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PerfilScreen(
                    themeService: themeService,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            '¡Hola!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Descubre emprendimientos salvadoreños.',
            style: TextStyle(
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 30),

          Card(
            child: ListTile(
              leading: const Icon(
                Icons.search,
                color: Color(0xFFFF7E01),
              ),
              title: const Text(
                'Explorar emprendimientos',
              ),
              subtitle: const Text(
                'Descubre tiendas y productos',
              ),
              trailing: const Icon(
                Icons.chevron_right,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const ExplorarEmprendimientosScreen(),
                  ),
                );
              },
            ),
          ),

          const Card(
            child: ListTile(
              leading: Icon(
                Icons.map_outlined,
                color: Color(0xFFFF7E01),
              ),
              title: Text('Mapa'),
              subtitle: Text(
                'Disponible en Beta 4',
              ),
              trailing: Icon(
                Icons.chevron_right,
              ),
            ),
          ),

          const Card(
            child: ListTile(
              leading: Icon(
                Icons.favorite_border,
                color: Color(0xFFFF7E01),
              ),
              title: Text(
                'Mis favoritos',
              ),
              subtitle: Text(
                'Disponible próximamente',
              ),
              trailing: Icon(
                Icons.chevron_right,
              ),
            ),
          ),
        ],
      ),
    );
  }
}