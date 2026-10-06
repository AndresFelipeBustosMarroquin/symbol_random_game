import 'package:symbol_random_game/audio/audio_manager.dart';

class GameSettings {
  GameSettings._();

  static const int minValue = 1;
  static const int maxValue = 5;
  static const int minTime = 1;
  static const int maxTime = 60;

  static int increment = 1;
  static int hearts = 1;
  static int time = 5;

  /// true  -> mostrar las opciones antes de iniciar cada juego
  /// false -> las opciones solo se cambian desde la pantalla de Opciones
  static bool askBeforeGame = false;

  static double get volume => AudioManager.volume;
  static Future<void> setVolume(double value) => AudioManager.setVolume(value);

  static void reset() {
    increment = 1;
    hearts = 1;
    time = 5;
    // askBeforeGame se deja fuera a propósito: es una preferencia del
    // usuario, no un valor de partida. Agrégalo aquí si quieres que se reinicie.
  }
}