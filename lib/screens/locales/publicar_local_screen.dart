import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/local_comercial.dart';
import '../../services/local_comercial_service.dart';
import '../../config/app_theme.dart';

class PublicarLocalScreen extends StatefulWidget {
  final LocalComercial? local;

  const PublicarLocalScreen({
    super.key,
    this.local,
  });

  @override
  State<PublicarLocalScreen> createState() =>
      _PublicarLocalScreenState();
}

class _PublicarLocalScreenState extends State<PublicarLocalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _precioController = TextEditingController();
  final _municipioController = TextEditingController();
  final _direccionController = TextEditingController();
  final _latitudController = TextEditingController();
  final _longitudController = TextEditingController();
  final _contactoNombreController = TextEditingController();
  final _contactoTelefonoController = TextEditingController();
  final _contactoWhatsappController = TextEditingController();
  final _contactoCorreoController = TextEditingController();

  final List<String> _tiposLocal = const [
    'Local comercial',
    'Oficina',
    'Bodega',
    'Kiosco',
    'Terreno comercial',
    'Otro',
  ];

  final List<String> _departamentos = const [
    'Ahuachapán',
    'Santa Ana',
    'Sonsonate',
    'Chalatenango',
    'La Libertad',
    'San Salvador',
    'Cuscatlán',
    'La Paz',
    'Cabañas',
    'San Vicente',
    'Usulután',
    'San Miguel',
    'Morazán',
    'La Unión',
  ];

  String _tipoOperacion = 'alquiler';
  String _tipoLocal = 'Local comercial';
  String? _departamento;

  bool _guardando = false;
  bool _procesandoImagen = false;

  final List<XFile> _imagenesNuevas = [];
  LocalComercial? _localActual;

  bool get _editando => widget.local != null;

  @override
  void initState() {
    super.initState();

    _localActual = widget.local;
    final local = widget.local;

    if (local != null) {
      _tituloController.text = local.titulo;
      _descripcionController.text = local.descripcion;
      _precioController.text = local.precio.toStringAsFixed(2);
      _municipioController.text = local.municipio;
      _direccionController.text = local.direccion;
      _latitudController.text = local.latitud?.toString() ?? '';
      _longitudController.text = local.longitud?.toString() ?? '';
      _contactoNombreController.text = local.contactoNombre ?? '';
      _contactoTelefonoController.text = local.contactoTelefono ?? '';
      _contactoWhatsappController.text = local.contactoWhatsapp ?? '';
      _contactoCorreoController.text = local.contactoCorreo ?? '';
      _tipoOperacion = local.tipoOperacion;
      _tipoLocal = local.tipoLocal;

      if (local.departamento.trim().isNotEmpty) {
        _departamento = local.departamento;
      }
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _precioController.dispose();
    _municipioController.dispose();
    _direccionController.dispose();
    _latitudController.dispose();
    _longitudController.dispose();
    _contactoNombreController.dispose();
    _contactoTelefonoController.dispose();
    _contactoWhatsappController.dispose();
    _contactoCorreoController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarImagenes() async {
    try {
      final seleccionadas = await _picker.pickMultiImage(
        imageQuality: 88,
      );

      if (seleccionadas.isEmpty) return;

      final actuales = _localActual?.imagenes.length ?? 0;
      final disponibles = 10 - actuales - _imagenesNuevas.length;

      if (disponibles <= 0) {
        _mensaje('El local ya tiene el máximo de 10 imágenes');
        return;
      }

      if (seleccionadas.length > 5) {
        _mensaje('Selecciona máximo 5 imágenes por vez');
        return;
      }

      final porAgregar = seleccionadas.take(disponibles).toList();

      setState(() {
        _imagenesNuevas.addAll(porAgregar);
      });
    } catch (e) {
      _mensaje(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_departamento == null || _departamento!.trim().isEmpty) {
      _mensaje('Selecciona un departamento');
      return;
    }

    final precio = double.tryParse(
      _precioController.text.trim().replaceAll(',', '.'),
    );

    if (precio == null || precio < 0) {
      _mensaje('Ingresa un precio válido');
      return;
    }

    final latitud = _numeroOpcional(_latitudController.text);
    final longitud = _numeroOpcional(_longitudController.text);

    if (latitud != null && (latitud < -90 || latitud > 90)) {
      _mensaje('La latitud debe estar entre -90 y 90');
      return;
    }

    if (longitud != null && (longitud < -180 || longitud > 180)) {
      _mensaje('La longitud debe estar entre -180 y 180');
      return;
    }

    final tieneContacto =
        _contactoTelefonoController.text.trim().isNotEmpty ||
        _contactoWhatsappController.text.trim().isNotEmpty ||
        _contactoCorreoController.text.trim().isNotEmpty;

    if (!tieneContacto) {
      _mensaje('Ingresa al menos un teléfono, WhatsApp o correo');
      return;
    }

    setState(() {
      _guardando = true;
    });

    try {
      LocalComercial local;

      if (_editando) {
        local = await LocalComercialService.actualizar(
          id: widget.local!.id,
          titulo: _tituloController.text,
          descripcion: _descripcionController.text,
          tipoOperacion: _tipoOperacion,
          tipoLocal: _tipoLocal,
          precio: precio,
          departamento: _departamento!,
          municipio: _municipioController.text,
          direccion: _direccionController.text,
          latitud: latitud,
          longitud: longitud,
          contactoNombre: _contactoNombreController.text,
          contactoTelefono: _contactoTelefonoController.text,
          contactoWhatsapp: _contactoWhatsappController.text,
          contactoCorreo: _contactoCorreoController.text,
        );
      } else {
        local = await LocalComercialService.crear(
          titulo: _tituloController.text,
          descripcion: _descripcionController.text,
          tipoOperacion: _tipoOperacion,
          tipoLocal: _tipoLocal,
          precio: precio,
          departamento: _departamento!,
          municipio: _municipioController.text,
          direccion: _direccionController.text,
          latitud: latitud,
          longitud: longitud,
          contactoNombre: _contactoNombreController.text,
          contactoTelefono: _contactoTelefonoController.text,
          contactoWhatsapp: _contactoWhatsappController.text,
          contactoCorreo: _contactoCorreoController.text,
        );
      }

      if (_imagenesNuevas.isNotEmpty) {
        await LocalComercialService.subirImagenes(
          localId: local.id,
          archivos: _imagenesNuevas,
        );

        local = await LocalComercialService.obtener(local.id);
      }

      if (!mounted) return;

      setState(() {
        _localActual = local;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _editando
                ? 'Local actualizado correctamente'
                : 'Local publicado correctamente',
          ),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      _mensaje(
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() {
          _guardando = false;
        });
      }
    }
  }

  Future<void> _eliminarImagen(
    ImagenLocalComercial imagen,
  ) async {
    final local = _localActual;
    if (local == null) return;

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar imagen'),
          content: const Text(
            '¿Deseas eliminar esta imagen del local?',
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
      _procesandoImagen = true;
    });

    try {
      await LocalComercialService.eliminarImagen(
        localId: local.id,
        imagenId: imagen.id,
      );

      final actualizado =
          await LocalComercialService.obtener(local.id);

      if (!mounted) return;

      setState(() {
        _localActual = actualizado;
      });
    } catch (e) {
      if (!mounted) return;
      _mensaje(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _procesandoImagen = false;
        });
      }
    }
  }

  Future<void> _hacerPrincipal(
    ImagenLocalComercial imagen,
  ) async {
    final local = _localActual;

    if (local == null || imagen.principal) return;

    setState(() {
      _procesandoImagen = true;
    });

    try {
      await LocalComercialService.establecerImagenPrincipal(
        localId: local.id,
        imagenId: imagen.id,
      );

      final actualizado =
          await LocalComercialService.obtener(local.id);

      if (!mounted) return;

      setState(() {
        _localActual = actualizado;
      });
    } catch (e) {
      if (!mounted) return;
      _mensaje(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _procesandoImagen = false;
        });
      }
    }
  }

  double? _numeroOpcional(String texto) {
    final valor = texto.trim();
    if (valor.isEmpty) return null;

    return double.tryParse(
      valor.replaceAll(',', '.'),
    );
  }

  void _mensaje(String mensaje) {
    if (!mounted) return;

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
        title: Text(
          _editando ? 'Editar local' : 'Publicar local',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            18,
            18,
            18,
            110,
          ),
          children: [
            _seccion('Información del local'),
            _campo(
              controller: _tituloController,
              label: 'Título',
              icono: Icons.storefront_outlined,
              obligatorio: true,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descripcionController,
              maxLines: 5,
              validator: _obligatorio,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.description_outlined),
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _tipoOperacion,
              decoration: const InputDecoration(
                labelText: 'Operación',
                prefixIcon: Icon(Icons.sell_outlined),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'venta',
                  child: Text('Venta'),
                ),
                DropdownMenuItem(
                  value: 'alquiler',
                  child: Text('Alquiler'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _tipoOperacion = value;
                });
              },
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _tiposLocal.contains(_tipoLocal)
                  ? _tipoLocal
                  : 'Otro',
              decoration: const InputDecoration(
                labelText: 'Tipo de local',
                prefixIcon: Icon(Icons.business_outlined),
              ),
              items: _tiposLocal
                  .map(
                    (tipo) => DropdownMenuItem(
                      value: tipo,
                      child: Text(tipo),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _tipoLocal = value;
                });
              },
            ),
            const SizedBox(height: 14),
            _campo(
              controller: _precioController,
              label: _tipoOperacion == 'alquiler'
                  ? 'Precio mensual (USD)'
                  : 'Precio de venta (USD)',
              icono: Icons.attach_money_rounded,
              obligatorio: true,
              teclado: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 26),
            _seccion('Ubicación'),
            DropdownButtonFormField<String>(
              initialValue: _departamentos.contains(_departamento)
                  ? _departamento
                  : null,
              decoration: const InputDecoration(
                labelText: 'Departamento',
                prefixIcon: Icon(Icons.map_outlined),
              ),
              items: _departamentos
                  .map(
                    (departamento) => DropdownMenuItem(
                      value: departamento,
                      child: Text(departamento),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _departamento = value;
                });
              },
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Selecciona un departamento';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            _campo(
              controller: _municipioController,
              label: 'Municipio / distrito',
              icono: Icons.location_city_outlined,
              obligatorio: true,
            ),
            const SizedBox(height: 14),
            _campo(
              controller: _direccionController,
              label: 'Dirección',
              icono: Icons.signpost_outlined,
              obligatorio: true,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _campo(
                    controller: _latitudController,
                    label: 'Latitud',
                    icono: Icons.my_location_outlined,
                    teclado: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _campo(
                    controller: _longitudController,
                    label: 'Longitud',
                    icono: Icons.explore_outlined,
                    teclado: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            _seccion('Contacto'),
            _campo(
              controller: _contactoNombreController,
              label: 'Nombre de contacto',
              icono: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 14),
            _campo(
              controller: _contactoTelefonoController,
              label: 'Teléfono',
              icono: Icons.phone_outlined,
              teclado: TextInputType.phone,
            ),
            const SizedBox(height: 14),
            _campo(
              controller: _contactoWhatsappController,
              label: 'WhatsApp',
              icono: Icons.chat_outlined,
              teclado: TextInputType.phone,
            ),
            const SizedBox(height: 14),
            _campo(
              controller: _contactoCorreoController,
              label: 'Correo',
              icono: Icons.email_outlined,
              teclado: TextInputType.emailAddress,
            ),
            const SizedBox(height: 26),
            _seccion('Fotografías'),
            Text(
              'Hasta 10 fotografías por local. Puedes subir máximo 5 por vez.',
              style: TextStyle(
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 12),
            if (_localActual?.imagenes.isNotEmpty == true)
              _imagenesExistentes(),
            if (_imagenesNuevas.isNotEmpty) ...[
              const SizedBox(height: 14),
              _imagenesSeleccionadas(),
            ],
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _guardando ? null : _seleccionarImagenes,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Seleccionar fotografías'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            18,
            8,
            18,
            14,
          ),
          child: FilledButton.icon(
            onPressed: _guardando ? null : _guardar,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
            ),
            icon: _guardando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.textoSobreNaranja,
                    ),
                  )
                : Icon(
                    _editando
                        ? Icons.save_outlined
                        : Icons.publish_outlined,
                  ),
            label: Text(
              _guardando
                  ? 'Guardando...'
                  : _editando
                      ? 'Guardar cambios'
                      : 'Publicar local',
            ),
          ),
        ),
      ),
    );
  }

  Widget _seccion(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        titulo,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _campo({
    required TextEditingController controller,
    required String label,
    required IconData icono,
    bool obligatorio = false,
    TextInputType? teclado,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: teclado,
      validator: obligatorio ? _obligatorio : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icono),
      ),
    );
  }

  String? _obligatorio(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Campo obligatorio';
    }
    return null;
  }

  Widget _imagenesExistentes() {
    final imagenes = _localActual!.imagenes;

    return SizedBox(
      height: 116,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: imagenes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final imagen = imagenes[index];

          return SizedBox(
            width: 120,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      imagen.url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color:
                            AppColors.naranja.withValues(alpha: 0.10),
                        child: const Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.naranja,
                        ),
                      ),
                    ),
                  ),
                ),
                if (imagen.principal)
                  Positioned(
                    left: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.naranja,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Principal',
                        style: TextStyle(
                          color: AppColors.textoSobreNaranja,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  right: 2,
                  top: 2,
                  child: PopupMenuButton<String>(
                    enabled: !_procesandoImagen,
                    icon: Container(
                      decoration: BoxDecoration(
                        color:
                            Colors.black.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.more_vert,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    onSelected: (value) {
                      if (value == 'principal') {
                        _hacerPrincipal(imagen);
                      }

                      if (value == 'eliminar') {
                        _eliminarImagen(imagen);
                      }
                    },
                    itemBuilder: (_) => [
                      if (!imagen.principal)
                        const PopupMenuItem(
                          value: 'principal',
                          child: Text('Usar como principal'),
                        ),
                      const PopupMenuItem(
                        value: 'eliminar',
                        child: Text('Eliminar imagen'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _imagenesSeleccionadas() {
    return SizedBox(
      height: 116,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _imagenesNuevas.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final archivo = _imagenesNuevas[index];

          return SizedBox(
            width: 120,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: FutureBuilder<Uint8List>(
                      future: archivo.readAsBytes(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Container(
                            color: AppColors.naranja
                                .withValues(alpha: 0.08),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.naranja,
                              ),
                            ),
                          );
                        }

                        return Image.memory(
                          snapshot.data!,
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  right: 4,
                  top: 4,
                  child: IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor:
                          Colors.black.withValues(alpha: 0.55),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        _imagenesNuevas.removeAt(index);
                      });
                    },
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 19,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
