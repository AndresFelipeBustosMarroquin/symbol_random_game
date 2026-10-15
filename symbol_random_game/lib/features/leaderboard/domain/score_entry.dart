import 'package:symbol_random_game/features/game/domain/game_mode.dart';

class ScoreEntry {
  const ScoreEntry({
    this.idPuntuacion = 0,
    this.idUsuario = 0,
    required this.jugador,
    required this.modo,
    required this.incremento,
    required this.vidas,
    required this.tiempoPregunta,
    required this.tiempoTotal,
    required this.resultado,
    required this.edad,
  });

  final int idPuntuacion;
  final int idUsuario;
  final String jugador;
  final GameMode modo;
  final int incremento;
  final int vidas;
  final int tiempoPregunta;
  final int tiempoTotal;
  final int resultado;
  final int edad;

  factory ScoreEntry.fromJson(Map<String, dynamic> json) {
    final originalModeName = (json['modo'] as String).trim().toUpperCase();
    final modeName = originalModeName
        .replaceAll('Ú', 'U')
        .replaceAll('Ó', 'O')
        .replaceAll(RegExp('[^A-Z]'), '');
    final mode = switch (modeName) {
      'NUMEROS' || 'NMEROS' => GameMode.numbers,
      'CARACTERES' => GameMode.characters,
      'SIMBOLOS' || 'SMBOLOS' => GameMode.symbols,
      'OPERACIONES' => GameMode.operations,
      _ => throw FormatException(
        'Modo de juego desconocido: $originalModeName',
      ),
    };

    return ScoreEntry(
      idPuntuacion: (json['idPuntuacion'] as num?)?.toInt() ?? 0,
      idUsuario: (json['idUsuario'] as num?)?.toInt() ?? 0,
      jugador: json['jugador'] as String,
      modo: mode,
      incremento: (json['incremento'] as num).toInt(),
      vidas: (json['vidas'] as num).toInt(),
      tiempoPregunta: (json['tiempoPregunta'] as num).toInt(),
      tiempoTotal: (json['tiempoTotal'] as num).toInt(),
      resultado: (json['resultado'] as num).toInt(),
      edad: (json['edad'] as num).toInt(),
    );
  }
}
