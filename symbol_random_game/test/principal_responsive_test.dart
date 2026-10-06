import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:symbol_random_game/features/home/principal_screen.dart';
import 'package:symbol_random_game/features/profile/perfil_model.dart';
import 'package:symbol_random_game/features/profile/perfil_service.dart';

class _FakePerfilService extends PerfilService {
  PerfilUsuario profile = _profile(10);
  int loadCount = 0;

  @override
  Future<PerfilUsuario> obtener(int userId) async {
    loadCount++;
    return profile;
  }
}

PerfilUsuario _profile(int points) => PerfilUsuario(
  idUsuario: 1,
  nombreUso: 'JugadorUno',
  fechaNacimiento: DateTime(2000, 1, 1),
  descripcion: '',
  avatar: 'astronauta',
  partidas: 1,
  mejorPuntuacion: points,
  puntosTotales: points,
  partidasNumeros: 1,
  mejorNumeros: points,
  partidasCaracteres: 0,
  mejorCaracteres: 0,
  partidasSimbolos: 0,
  mejorSimbolos: 0,
  partidasOperaciones: 0,
  mejorOperaciones: 0,
);

void main() {
  for (final size in [
    const Size(390, 844),
    const Size(820, 900),
    const Size(1280, 800),
  ]) {
    testWidgets('home adapts without layout errors at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: PrincipalScreen(userId: 1, profileService: _FakePerfilService()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 11));

      expect(find.text('MINI GAMES'), findsOneWidget);
      for (final label in [
        'JUGAR',
        '2 JUGADORES',
        'OPCIONES',
        'PUNTUACIÓN',
        'AMIGOS',
        'CERRAR SESIÓN',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.text('¿Listo para'), findsNothing);
      if (size.width >= 900) {
        expect(find.byType(SingleChildScrollView), findsNothing);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('home refreshes profile progress after returning from a game', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final service = _FakePerfilService();
    await tester.pumpWidget(
      MaterialApp(home: PrincipalScreen(userId: 1, profileService: service)),
    );
    await tester.pumpAndSettle();

    expect(find.text('10/100 XP'), findsOneWidget);
    await tester.tap(find.text('JUGAR'));
    await tester.pumpAndSettle();
    service.profile = _profile(25);

    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();

    expect(service.loadCount, 2);
    expect(find.text('25/100 XP'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
