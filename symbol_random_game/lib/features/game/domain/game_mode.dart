enum GameMode { numbers, characters, symbols, operations }

extension GameModeX on GameMode {
  String get title => switch (this) {
    GameMode.numbers => 'NÚMEROS',
    GameMode.symbols => 'SÍMBOLOS',
    GameMode.characters => 'CARACTERES',
    GameMode.operations => 'OPERACIONES',
  };

  String get question => switch (this) {
    GameMode.numbers => '¿Qué número era?',
    GameMode.symbols => '¿Qué símbolos eran?',
    GameMode.characters => '¿Qué caracteres eran?',
    GameMode.operations => '¿Cuánto es?',
  };

  String get pool => switch (this) {
    GameMode.numbers => '0123456789',
    GameMode.symbols => '!@#\$%&*?+=-_/()<>',
    GameMode.characters => 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789',
    GameMode.operations => '',
  };
}
