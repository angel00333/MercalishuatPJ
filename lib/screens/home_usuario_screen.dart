import 'package:flutter/material.dart';

import 'perfil_screen.dart';

class HomeUsuarioScreen extends StatelessWidget {
  const HomeUsuarioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mercalishuat',
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
              '¡Hola!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 10),

            Text(
              'Descubre emprendimientos salvadoreños.',
              style: TextStyle(
                fontSize: 17,
              ),
            ),

            SizedBox(height: 30),

            Card(
              child: ListTile(
                leading: Icon(
                  Icons.search,
                ),
                title: Text(
                  'Explorar emprendimientos',
                ),
                subtitle: Text(
                  'Próximamente en Beta 2',
                ),
              ),
            ),

            Card(
              child: ListTile(
                leading: Icon(
                  Icons.map_outlined,
                ),
                title: Text(
                  'Mapa',
                ),
                subtitle: Text(
                  'Disponible en Beta 4',
                ),
              ),
            ),

            Card(
              child: ListTile(
                leading: Icon(
                  Icons.favorite_border,
                ),
                title: Text(
                  'Mis favoritos',
                ),
                subtitle: Text(
                  'Próximamente',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}