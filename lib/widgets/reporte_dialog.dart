import 'package:flutter/material.dart';

import '../services/reporte_service.dart';

Future<bool> mostrarDialogoReporte({
  required BuildContext context,
  required String tipo,
  required int objetivoId,
}) async {
  final resultado =
      await showDialog<bool>(
    context:
        context,
    barrierDismissible:
        false,
    builder:
        (_) => _ReporteDialog(
      tipo:
          tipo,
      objetivoId:
          objetivoId,
    ),
  );

  return resultado ??
      false;
}

class _ReporteDialog
    extends StatefulWidget {
  final String tipo;
  final int objetivoId;

  const _ReporteDialog({
    required this.tipo,
    required this.objetivoId,
  });

  @override
  State<_ReporteDialog>
      createState() =>
          _ReporteDialogState();
}

class _ReporteDialogState
    extends State<_ReporteDialog> {
  final TextEditingController
      _descripcionController =
      TextEditingController();

  final List<String> _motivos = [
    'Spam',
    'Contenido ofensivo',
    'Acoso',
    'Información falsa',
    'Otro',
  ];

  String? _motivo;

  bool _enviando =
      false;

  String? _error;

  @override
  void dispose() {
    _descripcionController.dispose();

    super.dispose();
  }

  // ============================================================
  // ENVIAR REPORTE
  // ============================================================

  Future<void> _enviar() async {
    if (_motivo == null) {
      setState(() {
        _error =
            'Selecciona un motivo';
      });

      return;
    }

    setState(() {
      _enviando =
          true;

      _error =
          null;
    });

    try {
      await ReporteService.crearReporte(
        tipo:
            widget.tipo,
        objetivoId:
            widget.objetivoId,
        motivo:
            _motivo!,
        descripcion:
            _descripcionController.text,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(
        true,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error =
            e
                .toString()
                .replaceFirst(
                  'Exception: ',
                  '',
                );

        _enviando =
            false;
      });
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final bool oscuro =
        Theme.of(context).brightness ==
            Brightness.dark;

    final nombreTipo =
        widget.tipo ==
                'comentario'
            ? 'comentario'
            : 'publicación';

    return AlertDialog(
      backgroundColor:
          oscuro
              ? const Color(
                  0xFF2A2045,
                )
              : Colors.white,

      title: Row(
        children: [
          Container(
            width:
                42,
            height:
                42,
            decoration:
                BoxDecoration(
              color:
                  const Color(
                    0xFFFF7E01,
                  ).withValues(
                alpha:
                    0.12,
              ),
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),
            child:
                const Icon(
              Icons.flag_outlined,
              color:
                  Color(
                0xFFFF7E01,
              ),
            ),
          ),

          const SizedBox(
            width:
                12,
          ),

          Expanded(
            child: Text(
              'Reportar $nombreTipo',
              style:
                  const TextStyle(
                fontSize:
                    19,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
          ),
        ],
      ),

      content:
          SingleChildScrollView(
        child:
            Column(
          mainAxisSize:
              MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'Selecciona el motivo del reporte.',
              style:
                  TextStyle(
                color:
                    Colors.grey.shade500,
              ),
            ),

            const SizedBox(
              height:
                  18,
            ),

            DropdownButtonFormField<String>(
              initialValue:
                  _motivo,

              decoration:
                  InputDecoration(
                labelText:
                    'Motivo',
                prefixIcon:
                    const Icon(
                  Icons
                      .report_problem_outlined,
                ),
                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
              ),

              items:
                  _motivos
                      .map(
                        (
                          motivo,
                        ) =>
                            DropdownMenuItem<String>(
                          value:
                              motivo,
                          child:
                              Text(
                            motivo,
                          ),
                        ),
                      )
                      .toList(),

              onChanged:
                  _enviando
                      ? null
                      : (
                          value,
                        ) {
                          setState(() {
                            _motivo =
                                value;
                            _error =
                                null;
                          });
                        },
            ),

            const SizedBox(
              height:
                  16,
            ),

            TextField(
              controller:
                  _descripcionController,

              enabled:
                  !_enviando,

              maxLines:
                  4,

              maxLength:
                  500,

              decoration:
                  InputDecoration(
                labelText:
                    'Descripción opcional',

                hintText:
                    'Agrega información adicional sobre el problema...',

                alignLabelWithHint:
                    true,

                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
              ),
            ),

            if (_error !=
                null) ...[
              const SizedBox(
                height:
                    4,
              ),

              Container(
                width:
                    double.infinity,
                padding:
                    const EdgeInsets.all(
                  12,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      Colors.red.withValues(
                    alpha:
                        0.10,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),
                child:
                    Text(
                  _error!,
                  style:
                      const TextStyle(
                    color:
                        Colors.red,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),

      actions: [
        TextButton(
          onPressed:
              _enviando
                  ? null
                  : () {
                      Navigator.of(
                        context,
                      ).pop(
                        false,
                      );
                    },
          child:
              const Text(
            'Cancelar',
          ),
        ),

        FilledButton.icon(
          onPressed:
              _enviando
                  ? null
                  : _enviar,

          style:
              FilledButton.styleFrom(
            backgroundColor:
                const Color(
              0xFFFF7E01,
            ),
            foregroundColor:
                Colors.white,
          ),

          icon:
              _enviando
                  ? const SizedBox(
                      width:
                          18,
                      height:
                          18,
                      child:
                          CircularProgressIndicator(
                        strokeWidth:
                            2,
                        color:
                            Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons
                          .flag_outlined,
                    ),

          label:
              Text(
            _enviando
                ? 'Enviando...'
                : 'Enviar reporte',
          ),
        ),
      ],
    );
  }
}