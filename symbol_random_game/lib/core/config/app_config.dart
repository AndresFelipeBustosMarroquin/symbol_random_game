import 'package:symbol_random_game/core/audio/audio_manager.dart';

class GameSettings {
  GameSettings._();

  static const int minValue = 1;
  static const int maxValue = 5;
  static const int minTime = 1;
  static const int maxTime = 60;

  static int increment = 1;
  static int hearts = 1;
  static int time = 5;

  static bool askBeforeGame = false;

  static double get volume => AudioManager.volume;
  static Future<void> setVolume(double value) => AudioManager.setVolume(value);

  static void reset() {
    increment = 1;
    hearts = 1;
    time = 5;
  }
}