import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:symbol_random_game/features/home/presentation/principal_screen.dart';
import 'package:symbol_random_game/features/home/domain/wisdom_verses.dart';
import 'package:symbol_random_game/features/profile/domain/perfil_model.dart';
import 'package:symbol_random_game/features/profile/data/perfil_service.dart';

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
          home: PrincipalScreen(
            userId: 1,
            profileService: _FakePerfilService(),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('MINI GAMES'), findsOneWidget);
      expect(find.text('UN MOMENTO DE SABIDURÍA'), findsOneWidget);
      expect(find.textContaining('/50'), findsNothing);
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

  test('home wisdom rotation contains 100 scripture-based reflections', () {
    expect(wisdomVerses, hasLength(100));
    expect(
      wisdomVerses.map((verse) => verse.reference).toSet(),
      hasLength(100),
    );
  });

  testWidgets('home wisdom reflection stays unchanged as time passes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: PrincipalScreen(userId: 1, profileService: _FakePerfilService()),
      ),
    );
    final initialVerse = wisdomVerses.firstWhere(
      (verse) => find.text('“${verse.reflection}”').evaluate().isNotEmpty,
    );

    await tester.pump(const Duration(seconds: 30));

    expect(find.text('“${initialVerse.reflection}”'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

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

    final initialVerse = wisdomVerses.firstWhere(
      (verse) => find.text('“${verse.reflection}”').evaluate().isNotEmpty,
    );
    expect(find.text('10/100 XP'), findsOneWidget);
    await tester.tap(find.text('JUGAR'));
    await tester.pumpAndSettle();
    service.profile = _profile(25);

    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();

    expect(service.loadCount, 2);
    expect(find.text('25/100 XP'), findsOneWidget);
    expect(find.text('“${initialVerse.reflection}”'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
