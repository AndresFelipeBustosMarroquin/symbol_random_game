import 'package:flutter_test/flutter_test.dart';

import 'package:symbol_random_game/features/auth/presentation/login_screen.dart';
import 'package:symbol_random_game/main.dart';

void main() {
  testWidgets('app opens on the login screen', (tester) async {
    await tester.pumpWidget(const RandomGameApp());

    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
