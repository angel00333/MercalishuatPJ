import 'package:flutter/material.dart';

import '../../models/emprendimiento.dart';
import '../../services/emprendimiento_service.dart';
import 'detalle_tienda_screen.dart';

class ExplorarEmprendimientosScreen
    extends StatefulWidget {
  const ExplorarEmprendimientosScreen({
    super.key,
  });

  @override
  State<ExplorarEmprendimientosScreen>
      createState() =>
          _ExplorarEmprendimientosScreenState();
}

class _ExplorarEmprendimientosScreenState
    extends State<
        ExplorarEmprendimientosScreen> {
  List<Emprendimiento>
      emprendimientos = [];

  List<Emprendimiento>
      filtrados = [];

  bool cargando = true;

  final buscarController =
      TextEditingController();

  @override
  void initState() {
    super.initState();

    cargar();
  }

  Future<void> cargar() async {
    final resultado =
        await EmprendimientoService
            .listar();

    if (!mounted) return;

    if (resultado['success'] == true) {
      setState(() {
        emprendimientos =
            resultado[
                'emprendimientos'];

        filtrados =
            List.from(
          emprendimientos,
        );

        cargando = false;
      });
    } else {
      setState(() {
        cargando = false;
      });
    }
  }

  void buscar(
    String texto,
  ) {
    final consulta =
        texto.toLowerCase();

    setState(() {
      filtrados =
          emprendimientos
              .where(
        (e) {
          return e.nombre
                  .toLowerCase()
                  .contains(
                    consulta,
                  ) ||
              (e.descripcion ??
                      '')
                  .toLowerCase()
                  .contains(
                    consulta,
                  );
        },
      ).toList();
    });
  }

  @override
  void dispose() {
    buscarController.dispose();

    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Explorar',
        ),
      ),

      body: cargando
          ? const Center(
              child:
                  CircularProgressIndicator(
                color:
                    Color(0xFFFF7E01),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.all(
                    16,
                  ),
                  child:
                      TextField(
                    controller:
                        buscarController,
                    onChanged:
                        buscar,
                    decoration:
                        const InputDecoration(
                      hintText:
                          'Buscar emprendimiento...',
                      prefixIcon:
                          Icon(
                        Icons.search,
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child:
                      filtrados.isEmpty
                          ? const Center(
                              child:
                                  Text(
                                'No se encontraron emprendimientos',
                              ),
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal:
                                    16,
                              ),
                              itemCount:
                                  filtrados.length,
                              itemBuilder:
                                  (context,
                                      index) {
                                final tienda =
                                    filtrados[index];

                                return Card(
                                  child:
                                      ListTile(
                                    leading:
                                        const CircleAvatar(
                                      backgroundColor:
                                          Color(
                                        0xFFFF7E01,
                                      ),
                                      child:
                                          Icon(
                                        Icons.storefront,
                                        color:
                                            Colors.white,
                                      ),
                                    ),

                                    title:
                                        Text(
                                      tienda.nombre,
                                      style:
                                          const TextStyle(
                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                    ),

                                    subtitle:
                                        Text(
                                      tienda.descripcion ??
                                          'Emprendimiento',
                                      maxLines:
                                          2,
                                      overflow:
                                          TextOverflow.ellipsis,
                                    ),

                                    trailing:
                                        const Icon(
                                      Icons.chevron_right,
                                    ),

                                    onTap:
                                        () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              DetalleTiendaScreen(
                                            emprendimientoId:
                                                tienda.id,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
    );
  }
}