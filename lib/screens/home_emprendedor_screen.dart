import 'package:flutter/material.dart';

import '../services/theme_service.dart';
import 'configuracion_screen.dart';
import 'perfil_screen.dart';
import 'tienda_actions/mi_tienda_screen.dart';
import 'producto_actions/productos_screen.dart';

class HomeEmprendedorScreen extends StatelessWidget {
  final ThemeService themeService;

  const HomeEmprendedorScreen({
    super.key,
    required this.themeService,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mercalishuat Negocios'),
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
            'Panel del emprendedor',
            style: TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Administra tu emprendimiento desde Mercalishuat.',
          ),
          const SizedBox(height: 30),

            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.inventory_2_outlined,
                  color: Color(0xFFFF7E01),
                ),
                title: const Text(
                  'Productos',
                ),
                subtitle: const Text(
                  'Administra tu catálogo',
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const ProductosScreen(),
                    ),
                  );
                },
              ),
            ),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.storefront,
                color: Color(0xFFFF7E01),
              ),
              title: const Text('Mi tienda'),
              subtitle: const Text(
                'Administra tu emprendimiento',
              ),
              trailing: const Icon(
                Icons.chevron_right,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MiTiendaScreen(
                      themeService: themeService,
                    ),
                  ),
                );
              },
            ),
          ),

          const Card(
            child: ListTile(
              leading: Icon(
                Icons.add_photo_alternate_outlined,
                color: Color(0xFFFF7E01),
              ),
              title: Text('Publicaciones'),
              subtitle: Text('Disponible en Beta 3'),
              trailing: Icon(Icons.chevron_right),
            ),
          ),

          const Card(
            child: ListTile(
              leading: Icon(
                Icons.map_outlined,
                color: Color(0xFFFF7E01),
              ),
              title: Text('Ubicación del negocio'),
              subtitle: Text('Disponible en Beta 4'),
              trailing: Icon(Icons.chevron_right),
            ),
          ),

          const Card(
            child: ListTile(
              leading: Icon(
                Icons.chat_outlined,
                color: Color(0xFFFF7E01),
              ),
              title: Text('Mensajes'),
              subtitle: Text('Disponible en Beta 5'),
              trailing: Icon(Icons.chevron_right),
            ),
          ),
        ],
      ),
    );
  }
}