import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:symbol_random_game/features/game/mode_screen.dart';

void main() {
  for (final size in [const Size(390, 844), const Size(360, 640)]) {
    testWidgets('1 vs 1 mode selection fits on screen at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(home: ModeScreen(versus: true)),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('CONTINUAR'), findsOneWidget);
      expect(find.text('OPERACIONES'), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsNothing);
      expect(
        tester.getBottomRight(find.text('CONTINUAR')).dy,
        lessThan(size.height),
      );
    });
  }

  for (final size in [const Size(1366, 692), const Size(1024, 640)]) {
    testWidgets('2 vs 2 selector fits browser viewport at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(home: ModeScreen(versus: true)),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('CONTINUAR'), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsNothing);
      expect(
        tester.getBottomRight(find.text('CONTINUAR')).dy,
        lessThan(size.height),
      );
    });
  }
}
