import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:symbol_random_game/features/leaderboard/score_screen.dart';

void main() {
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
}
