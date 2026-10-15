import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:symbol_random_game/features/settings/presentation/option_screen.dart';

void main() {
  for (final size in [
    const Size(1366, 692),
    const Size(1024, 640),
    const Size(390, 844),
  ]) {
    testWidgets('options screen adapts without pixel overflow at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: OptionsScreen()));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  }
}
