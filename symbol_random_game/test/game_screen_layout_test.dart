import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:symbol_random_game/features/game/game_screen.dart';

void main() {
  for (final size in [
    const Size(1366, 692),
    const Size(1024, 640),
    const Size(390, 844),
    const Size(360, 640),
  ]) {
    testWidgets('symbol game fits available height at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: GameScreen(mode: GameMode.symbols, userId: 1),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.text('COMPROBAR'), findsOneWidget);
      expect(
        tester.getBottomRight(find.text('COMPROBAR')).dy,
        lessThan(size.height),
      );
    });
  }
}
