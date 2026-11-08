import 'package:flutter/material.dart';

import '../../models/local_comercial.dart';
import '../../services/local_comercial_service.dart';
import '../../config/app_theme.dart';

class DetalleLocalComercialScreen extends StatefulWidget {
  final int localId;

  const DetalleLocalComercialScreen({
    super.key,
    required this.localId,
  });

  @override
  State<DetalleLocalComercialScreen> createState() =>
      _DetalleLocalComercialScreenState();
}

class _DetalleLocalComercialScreenState
    extends State<DetalleLocalComercialScreen> {
  LocalComercial? _local;
  bool _cargando = true;
  String? _error;
  int _imagenActual = 0;

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
      final local =
          await LocalComercialService.obtener(widget.localId);

      if (!mounted) return;

      setState(() {
        _local = local;
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

  @override
  Widget build(BuildContext context) {
    final oscuro =
        Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          oscuro ? AppColors.fondoOscuro : AppColors.fondoClaro,
      appBar: AppBar(
        title: const Text(
          'Detalle del local',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _contenido(oscuro),
    );
  }

  Widget _contenido(bool oscuro) {
    if (_cargando) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.naranja,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
          ),
        ),
      );
    }

    final local = _local;

    if (local == null) {
      return const Center(
        child: Text('Local no disponible'),
      );
    }

    return RefreshIndicator(
      color: AppColors.naranja,
      onRefresh: _cargar,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          _galeria(local, oscuro),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              20,
              20,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _badge(local.operacionTexto),
                    _badge(local.tipoLocal),
                    _badge(
                      local.disponible
                          ? 'Disponible'
                          : 'No disponible',
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  local.titulo,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  local.precioTexto,
                  style: const TextStyle(
                    color: AppColors.naranja,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 24),
                _titulo('Descripción'),
                const SizedBox(height: 8),
                Text(
                  local.descripcion,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 26),
                _titulo('Ubicación'),
                const SizedBox(height: 12),
                _fila(
                  Icons.location_city_outlined,
                  'Departamento',
                  local.departamento,
                ),
                _fila(
                  Icons.location_on_outlined,
                  'Municipio',
                  local.municipio,
                ),
                _fila(
                  Icons.signpost_outlined,
                  'Dirección',
                  local.direccion,
                ),
                if (local.latitud != null &&
                    local.longitud != null)
                  _fila(
                    Icons.my_location_outlined,
                    'Coordenadas',
                    '${local.latitud}, ${local.longitud}',
                  ),
                const SizedBox(height: 26),
                _titulo('Contacto'),
                const SizedBox(height: 12),
                if (local.contactoNombre != null)
                  _fila(
                    Icons.person_outline_rounded,
                    'Contacto',
                    local.contactoNombre!,
                  ),
                if (local.contactoTelefono != null)
                  _fila(
                    Icons.phone_outlined,
                    'Teléfono',
                    local.contactoTelefono!,
                  ),
                if (local.contactoWhatsapp != null)
                  _fila(
                    Icons.chat_outlined,
                    'WhatsApp',
                    local.contactoWhatsapp!,
                  ),
                if (local.contactoCorreo != null)
                  _fila(
                    Icons.email_outlined,
                    'Correo',
                    local.contactoCorreo!,
                  ),
                const SizedBox(height: 26),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        AppColors.naranja.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.account_circle_outlined,
                        color: AppColors.naranja,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Publicado por',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.naranja,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              local.propietarioNombre,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _galeria(
    LocalComercial local,
    bool oscuro,
  ) {
    if (local.imagenes.isEmpty) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: AppColors.naranja.withValues(
            alpha: oscuro ? 0.12 : 0.08,
          ),
          child: const Center(
            child: Icon(
              Icons.storefront_rounded,
              size: 80,
              color: AppColors.naranja,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: PageView.builder(
            itemCount: local.imagenes.length,
            onPageChanged: (index) {
              setState(() {
                _imagenActual = index;
              });
            },
            itemBuilder: (context, index) {
              return Image.network(
                local.imagenes[index].url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return Container(
                    color:
                        AppColors.naranja.withValues(alpha: 0.10),
                    child: const Icon(
                      Icons.broken_image_outlined,
                      size: 60,
                      color: AppColors.naranja,
                    ),
                  );
                },
              );
            },
          ),
        ),
        if (local.imagenes.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                local.imagenes.length,
                (index) {
                  final activo = index == _imagenActual;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: activo ? 22 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 3,
                    ),
                    decoration: BoxDecoration(
                      color: activo
                          ? AppColors.naranja
                          : Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _badge(String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: AppColors.naranja.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        texto,
        style: const TextStyle(
          color: AppColors.naranja,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _titulo(String texto) {
    return Text(
      texto,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _fila(
    IconData icono,
    String titulo,
    String valor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icono,
            size: 21,
            color: AppColors.naranja,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  valor,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
