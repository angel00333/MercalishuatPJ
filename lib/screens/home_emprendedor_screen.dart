import 'package:flutter/material.dart';

import 'perfil_screen.dart';

class HomeEmprendedorScreen
    extends StatelessWidget {
  const HomeEmprendedorScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mercalishuat Negocios',
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.person_outline,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const PerfilScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: const Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'Panel del emprendedor',
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 10),

            Text(
              'Administra tu emprendimiento.',
            ),

            SizedBox(height: 30),

            Card(
              child: ListTile(
                leading: Icon(
                  Icons.storefront,
                ),
                title: Text(
                  'Mi tienda',
                ),
                subtitle: Text(
                  'Disponible en Beta 2',
                ),
              ),
            ),

            Card(
              child: ListTile(
                leading: Icon(
                  Icons.inventory_2_outlined,
                ),
                title: Text(
                  'Productos',
                ),
                subtitle: Text(
                  'Disponible en Beta 2',
                ),
              ),
            ),

            Card(
              child: ListTile(
                leading: Icon(
                  Icons.add_photo_alternate_outlined,
                ),
                title: Text(
                  'Publicaciones',
                ),
                subtitle: Text(
                  'Disponible en Beta 3',
                ),
              ),
            ),

            Card(
              child: ListTile(
                leading: Icon(
                  Icons.chat_outlined,
                ),
                title: Text(
                  'Mensajes',
                ),
                subtitle: Text(
                  'Disponible en Beta 5',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}