import 'package:flutter_test/flutter_test.dart';
import 'package:symbol_random_game/features/profile/resena_model.dart';

void main() {
  test('parses review fields and ISO timestamp returned by the API', () {
    final review = ResenaPerfil.fromJson({
      'idAutor': 12,
      'autor': 'Jugador',
      'avatar': 'zorro',
      'contenido': 'Gran jugador, partidas muy divertidas.',
      'fechaCreacion': '2026-10-04T21:03:34',
    });

    expect(review.idAutor, 12);
    expect(review.autor, 'Jugador');
    expect(review.avatar, 'zorro');
    expect(review.contenido, 'Gran jugador, partidas muy divertidas.');
    expect(review.fechaCreacion, DateTime(2026, 10, 4, 21, 3, 34));
  });
}
