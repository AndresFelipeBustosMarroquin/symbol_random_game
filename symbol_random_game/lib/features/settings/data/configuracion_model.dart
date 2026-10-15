import 'package:symbol_random_game/core/audio/audio_manager.dart';
import 'package:symbol_random_game/core/app_fonts.dart';
import 'package:symbol_random_game/core/app_theme.dart';
import 'package:symbol_random_game/core/config/app_config.dart';

class ConfiguracionUsuario {
  const ConfiguracionUsuario({
    this.incremento = 1,
    this.vidas = 1,
    this.tiempo = 5,
    this.sonido = 0,
    this.paleta = 0,
    this.volumen = 0.5,
    this.fuente = 0,
  });

  final int incremento;
  final int vidas;
  final int tiempo;
  final int sonido;
  final int paleta;
  final double volumen;
  final int fuente;

  factory ConfiguracionUsuario.fromJson(Map<String, dynamic> json) {
    return ConfiguracionUsuario(
      incremento: (json['incremento'] as num).toInt(),
      vidas: (json['vidas'] as num).toInt(),
      tiempo: (json['tiempo'] as num).toInt(),
      sonido: (json['sonido'] as num).toInt(),
      paleta: (json['paleta'] as num).toInt(),
      volumen: (json['volumen'] as num).toDouble(),
      fuente: (json['fuente'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    'incremento': incremento,
    'vidas': vidas,
    'tiempo': tiempo,
    'sonido': sonido,
    'paleta': paleta,
    'volumen': volumen,
    'fuente': fuente,
  };

  static ConfiguracionUsuario actual() {
    return ConfiguracionUsuario(
      incremento: GameSettings.increment,
      vidas: GameSettings.hearts,
      tiempo: GameSettings.time,
      sonido: AudioManager.selectedIndex,
      paleta: AppColors.selectedIndex,
      volumen: GameSettings.volume,
      fuente: AppFonts.selectedIndex,
    );
  }

  Future<void> aplicar() async {
    GameSettings.increment = incremento.clamp(
      GameSettings.minValue,
      GameSettings.maxValue,
    );
    GameSettings.hearts = vidas.clamp(
      GameSettings.minValue,
      GameSettings.maxValue,
    );
    GameSettings.time = tiempo.clamp(
      GameSettings.minTime,
      GameSettings.maxTime,
    );
    AudioManager.select(sonido);
    AppColors.selectPalette(paleta);
    AppFonts.select(fuente);
    await GameSettings.setVolume(volumen.clamp(0.0, 1.0));
  }
}
