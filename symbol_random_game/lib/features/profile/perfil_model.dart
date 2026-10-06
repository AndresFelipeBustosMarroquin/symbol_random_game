class AvatarPerfil {
  const AvatarPerfil(this.id, this.emoji, this.nombre);

  final String id;
  final String emoji;
  final String nombre;

  static const opciones = [
    AvatarPerfil('astronauta', '🧑‍🚀', 'Cosmonauta'),
    AvatarPerfil('zorro', '🦊', 'Zorro'),
    AvatarPerfil('gato', '🐱', 'Gato'),
    AvatarPerfil('ajolote', '🦎', 'Ajolote'),
    AvatarPerfil('dragon', '🐉', 'Dragón'),
    AvatarPerfil('robot', '🤖', 'Robot'),
    AvatarPerfil('tigre', '🐯', 'Tigre'),
    AvatarPerfil('panda', '🐼', 'Panda'),
    AvatarPerfil('unicornio', '🦄', 'Unicornio'),
    AvatarPerfil('pulpo', '🐙', 'Pulpo'),
  ];

  static AvatarPerfil porId(String id) => opciones.firstWhere(
    (avatar) => avatar.id == id,
    orElse: () => opciones.first,
  );
}

class PerfilUsuario {
  const PerfilUsuario({
    required this.idUsuario,
    required this.nombreUso,
    required this.fechaNacimiento,
    required this.descripcion,
    required this.avatar,
    required this.partidas,
    required this.mejorPuntuacion,
    required this.puntosTotales,
    required this.partidasNumeros,
    required this.mejorNumeros,
    required this.partidasCaracteres,
    required this.mejorCaracteres,
    required this.partidasSimbolos,
    required this.mejorSimbolos,
    required this.partidasOperaciones,
    required this.mejorOperaciones,
  });

  final int idUsuario;
  final String nombreUso;
  final DateTime fechaNacimiento;
  final String descripcion;
  final String avatar;
  final int partidas;
  final int mejorPuntuacion;
  final int puntosTotales;
  final int partidasNumeros;
  final int mejorNumeros;
  final int partidasCaracteres;
  final int mejorCaracteres;
  final int partidasSimbolos;
  final int mejorSimbolos;
  final int partidasOperaciones;
  final int mejorOperaciones;

  int get edad {
    final now = DateTime.now();
    var years = now.year - fechaNacimiento.year;
    if (now.month < fechaNacimiento.month ||
        (now.month == fechaNacimiento.month && now.day < fechaNacimiento.day)) {
      years--;
    }
    return years;
  }

  int get nivel => 1 + (puntosTotales ~/ 100);

  int get progresoNivel => puntosTotales % 100;

  int partidasPorModo(String modo) => switch (modo) {
    'NÚMEROS' => partidasNumeros,
    'CARACTERES' => partidasCaracteres,
    'SÍMBOLOS' => partidasSimbolos,
    'OPERACIONES' => partidasOperaciones,
    _ => 0,
  };

  int mejorPuntuacionPorModo(String modo) => switch (modo) {
    'NÚMEROS' => mejorNumeros,
    'CARACTERES' => mejorCaracteres,
    'SÍMBOLOS' => mejorSimbolos,
    'OPERACIONES' => mejorOperaciones,
    _ => 0,
  };

  factory PerfilUsuario.fromJson(Map<String, dynamic> json) {
    return PerfilUsuario(
      idUsuario: (json['idUsuario'] as num).toInt(),
      nombreUso: json['nombreUso'] as String,
      fechaNacimiento: DateTime.parse(json['fechaNacimiento'] as String),
      descripcion: json['descripcion'] as String,
      avatar: json['avatar'] as String,
      partidas: (json['partidas'] as num).toInt(),
      mejorPuntuacion: (json['mejorPuntuacion'] as num).toInt(),
      puntosTotales: (json['puntosTotales'] as num).toInt(),
      partidasNumeros: (json['partidasNumeros'] as num).toInt(),
      mejorNumeros: (json['mejorNumeros'] as num).toInt(),
      partidasCaracteres: (json['partidasCaracteres'] as num).toInt(),
      mejorCaracteres: (json['mejorCaracteres'] as num).toInt(),
      partidasSimbolos: (json['partidasSimbolos'] as num).toInt(),
      mejorSimbolos: (json['mejorSimbolos'] as num).toInt(),
      partidasOperaciones: (json['partidasOperaciones'] as num).toInt(),
      mejorOperaciones: (json['mejorOperaciones'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    'nombreUso': nombreUso,
    'fechaNacimiento':
        '${fechaNacimiento.year.toString().padLeft(4, '0')}-'
        '${fechaNacimiento.month.toString().padLeft(2, '0')}-'
        '${fechaNacimiento.day.toString().padLeft(2, '0')}',
    'descripcion': descripcion,
    'avatar': avatar,
  };
}
