import 'package:symbol_random_game/features/profile/perfil_model.dart';

class PersonaAmistad {
  const PersonaAmistad({
    required this.idUsuario,
    required this.nombreUso,
    required this.avatar,
    this.mensajesNoVistos = 0,
  });

  final int idUsuario;
  final String nombreUso;
  final String avatar;
  final int mensajesNoVistos;

  factory PersonaAmistad.fromJson(Map<String, dynamic> json) {
    return PersonaAmistad(
      idUsuario: (json['idUsuario'] as num).toInt(),
      nombreUso: json['nombreUso'] as String,
      avatar: json['avatar'] as String,
      mensajesNoVistos: (json['mensajesNoVistos'] as num?)?.toInt() ?? 0,
    );
  }

  String get emoji => AvatarPerfil.porId(avatar).emoji;
}

class AmistadesUsuario {
  const AmistadesUsuario({
    required this.amigos,
    required this.recibidas,
    required this.enviadas,
  });

  final List<PersonaAmistad> amigos;
  final List<PersonaAmistad> recibidas;
  final List<PersonaAmistad> enviadas;

  factory AmistadesUsuario.fromJson(Map<String, dynamic> json) {
    List<PersonaAmistad> people(String key) => (json[key] as List<dynamic>)
        .map(
          (person) => PersonaAmistad.fromJson(person as Map<String, dynamic>),
        )
        .toList();

    return AmistadesUsuario(
      amigos: people('amigos'),
      recibidas: people('recibidas'),
      enviadas: people('enviadas'),
    );
  }
}

class EstadoAmistad {
  const EstadoAmistad({required this.estado, this.idSolicitante});

  final String estado;
  final int? idSolicitante;

  bool get esAmigo => estado == 'AMIGOS';
  bool get enviada => estado == 'ENVIADA';
  bool get recibida => estado == 'RECIBIDA';

  factory EstadoAmistad.fromJson(Map<String, dynamic> json) {
    return EstadoAmistad(
      estado: json['estado'] as String,
      idSolicitante: (json['idSolicitante'] as num?)?.toInt(),
    );
  }
}
