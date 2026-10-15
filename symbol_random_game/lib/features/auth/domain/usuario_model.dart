class UsuarioModel {
  const UsuarioModel({
    this.idUsuario,
    required this.nombreUso,
    required this.contrasenaUs,
    required this.fechaNacimiento,
  });

  final int? idUsuario;
  final String nombreUso;
  final String contrasenaUs;
  final DateTime fechaNacimiento;

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    return UsuarioModel(
      idUsuario: json['idUsuario'] as int?,
      nombreUso: json['nombreUso'] as String,
      contrasenaUs: json['contrasenaUs'] as String,
      fechaNacimiento: DateTime.parse(
        json['fechaNacimiento'] as String,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombreUso': nombreUso,
      'contrasenaUs': contrasenaUs,
      'fechaNacimiento':
          '${fechaNacimiento.year.toString().padLeft(4, '0')}-'
          '${fechaNacimiento.month.toString().padLeft(2, '0')}-'
          '${fechaNacimiento.day.toString().padLeft(2, '0')}',
    };
  }
}

class UsuarioResumen {
  const UsuarioResumen({
    required this.idUsuario,
    required this.nombreUso,
    required this.fechaNacimiento,
  });

  final int idUsuario;
  final String nombreUso;
  final DateTime fechaNacimiento;

  int get edad {
    final hoy = DateTime.now();
    var anos = hoy.year - fechaNacimiento.year;
    if (hoy.month < fechaNacimiento.month ||
        (hoy.month == fechaNacimiento.month && hoy.day < fechaNacimiento.day)) {
      anos--;
    }

    return anos;
  }

  factory UsuarioResumen.fromJson(Map<String, dynamic> json) {
    return UsuarioResumen(
      idUsuario: json['idUsuario'] as int,
      nombreUso: json['nombreUso'] as String,
      fechaNacimiento: DateTime.parse(json['fechaNacimiento'] as String),
    );
  }
}