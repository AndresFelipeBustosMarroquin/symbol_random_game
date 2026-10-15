import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:symbol_random_game/features/profile/presentation/profile_screen.dart';
import 'package:symbol_random_game/features/profile/domain/perfil_model.dart';
import 'package:symbol_random_game/features/profile/data/perfil_service.dart';
import 'package:symbol_random_game/features/auth/presentation/login_screen.dart';
import 'package:symbol_random_game/features/auth/data/usuario_service.dart';

class _FakePerfilService extends PerfilService {
  _FakePerfilService(this.profile);

  PerfilUsuario profile;

  @override
  Future<PerfilUsuario> obtener(int userId) async => profile;

  @override
  Future<PerfilUsuario> actualizar(int userId, PerfilUsuario updated) async {
    profile = updated;
    return updated;
  }
}

class _FakeUsuarioService extends UsuarioService {
  int? deletedUserId;
  String? deletedPassword;

  @override
  Future<void> eliminar(int id, {required String contrasenaUs}) async {
    deletedUserId = id;
    deletedPassword = contrasenaUs;
  }
}

PerfilUsuario _profile({String description = 'Descripción anterior'}) =>
    PerfilUsuario(
      idUsuario: 1,
      nombreUso: 'JugadorUno',
      fechaNacimiento: DateTime(2000, 1, 1),
      descripcion: description,
      avatar: 'astronauta',
      partidas: 3,
      mejorPuntuacion: 12,
      puntosTotales: 24,
      partidasNumeros: 1,
      mejorNumeros: 12,
      partidasCaracteres: 1,
      mejorCaracteres: 8,
      partidasSimbolos: 1,
      mejorSimbolos: 4,
      partidasOperaciones: 0,
      mejorOperaciones: 0,
    );

void main() {
  testWidgets('profile description updates immediately after saving', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final service = _FakePerfilService(_profile());
    await tester.pumpWidget(
      MaterialApp(home: ProfileScreen(userId: 1, service: service)),
    );
    await tester.pumpAndSettle();

    expect(find.text('“Descripción anterior”'), findsOneWidget);

    await tester.tap(find.text('PERSONALIZAR'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Nueva descripción');
    await tester.tap(find.text('GUARDAR'));
    await tester.pumpAndSettle();

    expect(find.text('“Nueva descripción”'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('account deletion is only offered on the viewer profile', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: ProfileScreen(
          userId: 1,
          viewerId: 2,
          service: _FakePerfilService(_profile()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ELIMINAR CUENTA'), findsNothing);
  });

  testWidgets('account deletion verifies password and returns to login', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final usuarioService = _FakeUsuarioService();
    await tester.pumpWidget(
      MaterialApp(
        home: ProfileScreen(
          userId: 1,
          viewerId: 1,
          service: _FakePerfilService(_profile()),
          usuarioService: usuarioService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('ELIMINAR CUENTA'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'clave-segura');
    await tester.tap(find.text('ELIMINAR').last);
    await tester.pumpAndSettle();

    expect(usuarioService.deletedUserId, 1);
    expect(usuarioService.deletedPassword, 'clave-segura');
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
