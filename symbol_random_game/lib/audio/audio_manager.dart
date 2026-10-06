import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:symbol_random_game/audio/app_sound.dart';

class AudioManager {
  AudioManager._();

  static final AudioPlayer _player = AudioPlayer();

  // ---------- Volumen ----------
  static double volume = 0.5;

  static Future<void> setVolume(double value) async {
    volume = value.clamp(0.0, 1.0);
    await _player.setVolume(volume);
  }

  // ---------- Catálogo de sonidos ----------
  static const sounds = <AppSound>[
    AppSound(name: 'Sin sonido', asset: '', icon: Icons.volume_off_rounded),
    AppSound(name: 'Sonido 1', asset: '1.wav'),
    AppSound(name: 'Sonido 2', asset: '2.wav'),
    AppSound(name: 'Sonido 3', asset: '3.wav'),
    AppSound(name: 'Sonido 4', asset: '4.wav'),
    AppSound(name: 'Sonido 5', asset: '5.wav'),
  ];

  // ---------- Selección actual ----------
  static final ValueNotifier<int> selectedNotifier = ValueNotifier<int>(0);

  static int get selectedIndex => selectedNotifier.value;
  static AppSound get current => sounds[selectedIndex];

  static void select(int index) {
    if (index < 0 || index >= sounds.length) return;
    selectedNotifier.value = index;
  }

  // ---------- Reproducción ----------
  /// Reproduce el sonido elegido (o uno concreto si se pasa [sound]).
  /// Úsalo en el juego: AudioManager.play();
  static Future<void> play([AppSound? sound, bool loop = false]) async {
    try {
      await _player.stop();
      await _player.setVolume(volume);
      await _player.setReleaseMode(
        loop ? ReleaseMode.loop : ReleaseMode.release,
      );
      await _player.play(AssetSource((sound ?? current).asset));
    } catch (e) {
      debugPrint('AudioManager.play error: $e');
    }
  }

  static Future<void> stop() => _player.stop();
}
