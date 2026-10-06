import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:symbol_random_game/features/game/game_screen.dart';
import 'package:symbol_random_game/features/game/versus_screen.dart';

void main() {
  testWidgets('duel pause menu returns to the principal route', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const VersusScreen(mode: GameMode.numbers),
                  ),
                ),
                child: const Text('PRINCIPAL'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('PRINCIPAL'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('¿LISTOS?'), findsOneWidget);
    await tester.tap(find.text('COMENZAR'));
    await tester.pump(const Duration(milliseconds: 1400));
    await tester.pump();
    await tester.tap(find.text('PAUSA'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('MENÚ'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('SALIR'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('PRINCIPAL'), findsOneWidget);
    expect(find.text('¿LISTOS?'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
