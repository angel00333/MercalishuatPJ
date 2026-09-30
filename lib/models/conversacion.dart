class Conversacion {
  final int id;
  final int otroUsuarioId;
  final String nombre;
  final String apellido;
  final String? ultimoMensaje;
  final DateTime? ultimoMensajeFecha;
  final int mensajesNoLeidos;

  const Conversacion({
    required this.id,
    required this.otroUsuarioId,
    required this.nombre,
    required this.apellido,
    required this.ultimoMensaje,
    required this.ultimoMensajeFecha,
    required this.mensajesNoLeidos,
  });

  String get nombreCompleto {
    final valor =
        '$nombre $apellido'.trim();

    return valor.isEmpty
        ? 'Usuario'
        : valor;
  }

  factory Conversacion.fromJson(
    Map<String, dynamic> json,
  ) {
    return Conversacion(
      id: int.parse(
        json['id'].toString(),
      ),
      otroUsuarioId: int.parse(
        json['otro_usuario_id']
            .toString(),
      ),
      nombre:
          json['nombre']
                  ?.toString() ??
              '',
      apellido:
          json['apellido']
                  ?.toString() ??
              '',
      ultimoMensaje:
          json['ultimo_mensaje']
              ?.toString(),
      ultimoMensajeFecha:
          json['ultimo_mensaje_fecha'] ==
                  null
              ? null
              : DateTime.tryParse(
                  json[
                          'ultimo_mensaje_fecha']
                      .toString(),
                ),
      mensajesNoLeidos:
          int.tryParse(
                json[
                        'mensajes_no_leidos']
                    ?.toString() ??
                    '0',
              ) ??
              0,
    );
  }
}