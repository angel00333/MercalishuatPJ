import 'package:flutter/material.dart';

import '../services/theme_service.dart';
import 'configuracion_screen.dart';
import 'perfil_screen.dart';

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
        children: const [
          Text(
            'Panel del emprendedor',
            style: TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Administra tu emprendimiento desde Mercalishuat.',
          ),
          SizedBox(height: 30),
          Card(
            child: ListTile(
              leading: Icon(
                Icons.storefront,
                color: Color(0xFFFF7E01),
              ),
              title: Text('Mi tienda'),
              subtitle: Text('Disponible en Beta 2'),
              trailing: Icon(Icons.chevron_right),
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(
                Icons.inventory_2_outlined,
                color: Color(0xFFFF7E01),
              ),
              title: Text('Productos'),
              subtitle: Text('Disponible en Beta 2'),
              trailing: Icon(Icons.chevron_right),
            ),
          ),
          Card(
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
          Card(
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
          Card(
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