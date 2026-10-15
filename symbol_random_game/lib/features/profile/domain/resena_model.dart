class ResenaPerfil {
  const ResenaPerfil({
    required this.idAutor,
    required this.autor,
    required this.avatar,
    required this.contenido,
    required this.fechaCreacion,
  });

  final int idAutor;
  final String autor;
  final String avatar;
  final String contenido;
  final DateTime fechaCreacion;

  factory ResenaPerfil.fromJson(Map<String, dynamic> json) {
    return ResenaPerfil(
      idAutor: (json['idAutor'] as num).toInt(),
      autor: json['autor'] as String,
      avatar: json['avatar'] as String,
      contenido: json['contenido'] as String,
      fechaCreacion: DateTime.parse(json['fechaCreacion'] as String),
    );
  }
}
