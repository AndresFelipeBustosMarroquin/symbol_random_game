import 'package:flutter_test/flutter_test.dart';
import 'package:symbol_random_game/features/friends/domain/amistad_model.dart';

void main() {
  test('reads friends and pending requests from the API response', () {
    final relationships = AmistadesUsuario.fromJson({
      'amigos': [
        {
          'idUsuario': 2,
          'nombreUso': 'Luna',
          'avatar': 'gato',
          'mensajesNoVistos': 3,
        },
      ],
      'recibidas': [
        {'idUsuario': 3, 'nombreUso': 'Sol', 'avatar': 'zorro'},
      ],
      'enviadas': [],
    });

    expect(relationships.amigos.single.idUsuario, 2);
    expect(relationships.amigos.single.emoji, '🐱');
    expect(relationships.amigos.single.mensajesNoVistos, 3);
    expect(relationships.recibidas.single.nombreUso, 'Sol');
    expect(relationships.enviadas, isEmpty);
  });

  test('recognizes friendship request states', () {
    final incoming = EstadoAmistad.fromJson({
      'estado': 'RECIBIDA',
      'idSolicitante': 5,
    });
    final accepted = EstadoAmistad.fromJson({
      'estado': 'AMIGOS',
      'idSolicitante': null,
    });

    expect(incoming.recibida, isTrue);
    expect(incoming.esAmigo, isFalse);
    expect(accepted.esAmigo, isTrue);
  });
}
