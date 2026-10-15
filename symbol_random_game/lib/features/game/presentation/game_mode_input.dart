import 'package:flutter/material.dart';
import 'package:symbol_random_game/features/game/domain/game_mode.dart';

extension GameModeInputX on GameMode {
  TextInputType get keyboard => switch (this) {
    GameMode.numbers => TextInputType.number,
    GameMode.symbols => TextInputType.none,
    GameMode.operations => TextInputType.number,
    _ => TextInputType.text,
  };
}
