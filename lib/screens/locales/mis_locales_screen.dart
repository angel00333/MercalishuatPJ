import 'package:flutter/material.dart';

import '../../models/local_comercial.dart';
import '../../services/local_comercial_service.dart';
import '../../config/app_theme.dart';
import 'detalle_local_comercial_screen.dart';
import 'publicar_local_screen.dart';

class MisLocalesScreen extends StatefulWidget {
  const MisLocalesScreen({
    super.key,
  });

  @override
  State<MisLocalesScreen> createState() =>
      _MisLocalesScreenState();
}

class _MisLocalesScreenState extends State<MisLocalesScreen> {
  List<LocalComercial> _locales = [];
  bool _cargando = true;
  String? _error;
  final Set<int> _procesando = {};

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    if (mounted) {
      setState(() {
        _cargando = true;
        _error = null;
      });
    }

    try {
      final locales = await LocalComercialService.listarMios();

      if (!mounted) return;

      setState(() {
        _locales = locales;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _cargando = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _nuevo() async {
    final cambiado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const PublicarLocalScreen(),
      ),
    );

    if (cambiado == true) {
      _cargar();
    }
  }

  Future<void> _editar(LocalComercial local) async {
    try {
      final completo = await LocalComercialService.obtener(local.id);

      if (!mounted) return;

      final cambiado = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => PublicarLocalScreen(
            local: completo,
          ),
        ),
      );

      if (cambiado == true) {
        _cargar();
      }
    } catch (e) {
      if (!mounted) return;
      _mensaje(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _cambiarDisponibilidad(
    LocalComercial local,
  ) async {
    final nuevoEstado = !local.disponible;

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            nuevoEstado
                ? 'Marcar como disponible'
                : 'Marcar como no disponible',
          ),
          content: Text(
            nuevoEstado
                ? 'El local volverá a aparecer en el catálogo público.'
                : 'El local dejará de aparecer en el catálogo público.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );

    if (confirmado != true) return;

    setState(() {
      _procesando.add(local.id);
    });

    try {
      await LocalComercialService.cambiarDisponibilidad(
        id: local.id,
        disponible: nuevoEstado,
      );

      if (!mounted) return;

      await _cargar();
    } catch (e) {
      if (!mounted) return;

      _mensaje(
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() {
          _procesando.remove(local.id);
        });
      }
    }
  }

  Future<void> _eliminar(LocalComercial local) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar local'),
          content: Text(
            '¿Deseas eliminar "${local.titulo}"? Esta acción lo retirará del catálogo.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmado != true) return;

    setState(() {
      _procesando.add(local.id);
    });

    try {
      await LocalComercialService.eliminar(local.id);

      if (!mounted) return;

      _mensaje('Local eliminado correctamente');
      await _cargar();
    } catch (e) {
      if (!mounted) return;

      _mensaje(
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() {
          _procesando.remove(local.id);
        });
      }
    }
  }

  void _mensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final oscuro =
        Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          oscuro ? AppColors.fondoOscuro : AppColors.fondoClaro,
      appBar: AppBar(
        title: const Text(
          'Mis locales',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _cargar,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _nuevo,
        backgroundColor: AppColors.naranja,
        foregroundColor: AppColors.textoSobreNaranja,
        icon: const Icon(Icons.add_business_outlined),
        label: const Text('Publicar'),
      ),
      body: RefreshIndicator(
        color: AppColors.naranja,
        onRefresh: _cargar,
        child: _contenido(oscuro),
      ),
    );
  }

  Widget _contenido(bool oscuro) {
    if (_cargando) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 180),
          Center(
            child: CircularProgressIndicator(
              color: AppColors.naranja,
            ),
          ),
        ],
      );
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 100),
          const Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: AppColors.naranja,
          ),
          const SizedBox(height: 16),
          Text(
            _error!,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _cargar,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reintentar'),
          ),
        ],
      );
    }

    if (_locales.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 130),
          const Icon(
            Icons.storefront_outlined,
            size: 76,
            color: AppColors.naranja,
          ),
          const SizedBox(height: 16),
          const Text(
            'Todavía no has publicado locales comerciales',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _nuevo,
            icon: const Icon(Icons.add_business_outlined),
            label: const Text('Publicar mi primer local'),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        16,
        14,
        16,
        100,
      ),
      itemCount: _locales.length,
      itemBuilder: (context, index) {
        return _tarjeta(
          _locales[index],
          oscuro,
        );
      },
    );
  }

  Widget _tarjeta(
    LocalComercial local,
    bool oscuro,
  ) {
    final procesando = _procesando.contains(local.id);
    final imagen = local.imagenPrincipal?.url;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: oscuro
            ? const Color(0xFF352951)
            : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: local.disponible
              ? Colors.transparent
              : Colors.grey.withValues(alpha: 0.25),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DetalleLocalComercialScreen(
                    localId: local.id,
                  ),
                ),
              );
            },
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 58,
                height: 58,
                child: imagen != null && imagen.isNotEmpty
                    ? Image.network(
                        imagen,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),
            title: Text(
              local.titulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(local.precioTexto),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _badge(
                        local.operacionTexto,
                        AppColors.naranja,
                      ),
                      _badge(
                        local.disponible
                            ? 'Disponible'
                            : 'No disponible',
                        local.disponible
                            ? Colors.green
                            : Colors.grey,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            trailing: PopupMenuButton<String>(
              enabled: !procesando,
              onSelected: (value) {
                if (value == 'detalle') {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          DetalleLocalComercialScreen(
                        localId: local.id,
                      ),
                    ),
                  );
                }

                if (value == 'editar') {
                  _editar(local);
                }

                if (value == 'disponibilidad') {
                  _cambiarDisponibilidad(local);
                }

                if (value == 'eliminar') {
                  _eliminar(local);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'detalle',
                  child: Row(
                    children: [
                      Icon(Icons.visibility_outlined),
                      SizedBox(width: 10),
                      Text('Ver detalle'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'editar',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined),
                      SizedBox(width: 10),
                      Text('Editar'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'disponibilidad',
                  child: Row(
                    children: [
                      Icon(
                        local.disponible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        local.disponible
                            ? 'Marcar no disponible'
                            : 'Marcar disponible',
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'eliminar',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                      ),
                      SizedBox(width: 10),
                      Text('Eliminar'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (procesando)
            const LinearProgressIndicator(
              color: AppColors.naranja,
            ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.naranja.withValues(alpha: 0.10),
      child: const Icon(
        Icons.storefront_rounded,
        color: AppColors.naranja,
      ),
    );
  }

  Widget _badge(
    String texto,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
