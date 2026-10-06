import 'package:flutter_test/flutter_test.dart';
import 'package:symbol_random_game/features/profile/perfil_model.dart';

void main() {
  test('profile maps editable identity, avatar and game statistics', () {
    final profile = PerfilUsuario.fromJson({
      'idUsuario': 17,
      'nombreUso': 'Capitana',
      'fechaNacimiento': '2000-08-14',
      'descripcion': 'Rompedora de récords',
      'avatar': 'astronauta',
      'partidas': 6,
      'mejorPuntuacion': 12,
      'puntosTotales': 245,
      'partidasNumeros': 2,
      'mejorNumeros': 8,
      'partidasCaracteres': 1,
      'mejorCaracteres': 4,
      'partidasSimbolos': 1,
      'mejorSimbolos': 2,
      'partidasOperaciones': 2,
      'mejorOperaciones': 12,
    });

    expect(profile.nombreUso, 'Capitana');
    expect(profile.avatar, 'astronauta');
    expect(profile.partidas, 6);
    expect(profile.nivel, 3);
    expect(profile.progresoNivel, 45);
    expect(profile.partidasPorModo('OPERACIONES'), 2);
    expect(profile.mejorPuntuacionPorModo('OPERACIONES'), 12);
    expect(profile.toJson(), {
      'nombreUso': 'Capitana',
      'fechaNacimiento': '2000-08-14',
      'descripcion': 'Rompedora de récords',
      'avatar': 'astronauta',
    });
  });

  test('unknown avatar id resolves to the default avatar', () {
    expect(AvatarPerfil.porId('unknown').id, 'astronauta');
    expect(AvatarPerfil.opciones, hasLength(10));
  });
}
