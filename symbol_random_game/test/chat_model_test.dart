import 'package:flutter_test/flutter_test.dart';
import 'package:symbol_random_game/features/chat/domain/chat_model.dart';

void main() {
  test('parses a persisted chat message from the backend response', () {
    final message = MensajeChat.fromJson({
      'idMensaje': 42,
      'idEmisor': 7,
      'emisor': 'Luna',
      'contenido': '¡Hola! ¿Jugamos una partida?',
      'fechaEnvio': '2026-10-04T21:33:21',
    });

    expect(message.idMensaje, 42);
    expect(message.idEmisor, 7);
    expect(message.emisor, 'Luna');
    expect(message.contenido, '¡Hola! ¿Jugamos una partida?');
    expect(message.fechaEnvio, DateTime(2026, 10, 4, 21, 33, 21));
  });
}
