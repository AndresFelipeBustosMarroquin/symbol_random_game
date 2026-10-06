class MensajeChat {
  const MensajeChat({
    required this.idMensaje,
    required this.idEmisor,
    required this.emisor,
    required this.contenido,
    required this.fechaEnvio,
  });

  final int idMensaje;
  final int idEmisor;
  final String emisor;
  final String contenido;
  final DateTime fechaEnvio;

  factory MensajeChat.fromJson(Map<String, dynamic> json) {
    return MensajeChat(
      idMensaje: (json['idMensaje'] as num).toInt(),
      idEmisor: (json['idEmisor'] as num).toInt(),
      emisor: json['emisor'] as String,
      contenido: json['contenido'] as String,
      fechaEnvio: DateTime.parse(json['fechaEnvio'] as String),
    );
  }
}
