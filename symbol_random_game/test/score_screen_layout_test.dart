import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:symbol_random_game/features/game/domain/game_mode.dart';
import 'package:symbol_random_game/features/leaderboard/domain/score_entry.dart';
import 'package:symbol_random_game/features/leaderboard/presentation/score_screen.dart';

void main() {
  test('parses game modes whose accents were replaced by question marks', () {
    ScoreEntry scoreWithBrokenAccent(String mode) => ScoreEntry.fromJson({
      'idPuntuacion': 1,
      'idUsuario': 2,
      'jugador': 'Jugador',
      'modo': mode,
      'incremento': 1,
      'vidas': 3,
      'tiempoPregunta': 10,
      'tiempoTotal': 30,
      'resultado': 100,
      'edad': 20,
    });

    expect(scoreWithBrokenAccent('N??MEROS').modo, GameMode.numbers);
    expect(scoreWithBrokenAccent('S??MBOLOS').modo, GameMode.symbols);
  });

  testWidgets('score mode filters fit without clipping on 810px screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(810, 810);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: ScoreScreen(scores: [])));
    await tester.pumpAndSettle();

    final operations = find.text('OPERACIONES');
    expect(operations, findsOneWidget);
    expect(tester.getRect(operations).right, lessThanOrEqualTo(810));
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop score screen keeps scrolling inside the score table', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: ScoreScreen(scores: [])));
    await tester.pumpAndSettle();

    final scrollViews = tester.widgetList<SingleChildScrollView>(
      find.byType(SingleChildScrollView),
    );
    expect(scrollViews, isNotEmpty);
    expect(
      scrollViews.every(
        (scrollView) => scrollView.scrollDirection == Axis.horizontal,
      ),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows friend and delete actions for the matching score owner', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: ScoreScreen(
          viewerId: 7,
          scores: [
            ScoreEntry(
              idPuntuacion: 12,
              idUsuario: 7,
              jugador: 'Yo',
              modo: GameMode.numbers,
              incremento: 1,
              vidas: 3,
              tiempoPregunta: 10,
              tiempoTotal: 30,
              resultado: 100,
              edad: 20,
            ),
            ScoreEntry(
              idPuntuacion: 13,
              idUsuario: 8,
              jugador: 'Otra persona',
              modo: GameMode.symbols,
              incremento: 2,
              vidas: 2,
              tiempoPregunta: 12,
              tiempoTotal: 40,
              resultado: 90,
              edad: 21,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Eliminar mi puntuación'), findsOneWidget);
    expect(find.byTooltip('Enviar solicitud de amistad'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
