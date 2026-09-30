class Mensaje {
  final int id;
  final int conversacionId;
  final int remitenteId;
  final String contenido;
  final bool leido;
  final DateTime createdAt;
  final bool esMio;

  const Mensaje({
    required this.id,
    required this.conversacionId,
    required this.remitenteId,
    required this.contenido,
    required this.leido,
    required this.createdAt,
    required this.esMio,
  });

  factory Mensaje.fromJson(
    Map<String, dynamic> json,
  ) {
    return Mensaje(
      id: int.parse(
        json['id'].toString(),
      ),
      conversacionId: int.parse(
        json['conversacion_id']
            .toString(),
      ),
      remitenteId: int.parse(
        json['remitente_id']
            .toString(),
      ),
      contenido:
          json['contenido']
                  ?.toString() ??
              '',
      leido:
          json['leido'] == true,
      createdAt:
          DateTime.tryParse(
            json['created_at']
                    ?.toString() ??
                '',
          ) ??
              DateTime.now(),
      esMio:
          json['es_mio'] == true,
    );
  }
}