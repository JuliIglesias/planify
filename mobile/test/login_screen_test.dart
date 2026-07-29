import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/auth/login_screen.dart';
import 'package:planify/l10n/generated/app_localizations.dart';

import 'helpers/fake_repositories.dart';
import 'helpers/test_app.dart';

/// Pantalla de Login — HU-41 (organizador semilla) y HU-01 (anónimo).
/// Se monta LoginScreen directamente en vez de PlanifyApp porque el router
/// raíz lee el almacenamiento seguro al arrancar.
void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await prepararLocalizaciones();
  });

  testWidgets('muestra las acciones del MVP', (tester) async {
    await tester.pumpWidget(appDePrueba(const LoginScreen()));
    await tester.pumpAndSettle();

    expect(find.text(l10n.appName), findsOneWidget);
    expect(find.text(l10n.loginSubmit), findsOneWidget);
    expect(find.text(l10n.loginContinueAnonymous), findsOneWidget);
    expect(find.text(l10n.loginCreateAccount), findsOneWidget);
  });

  testWidgets('el botón de anónimo explica que hace falta un link (Duda #19)',
      (tester) async {
    await tester.pumpWidget(appDePrueba(const LoginScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.loginContinueAnonymous));
    await tester.pump();

    expect(find.text(l10n.loginAnonymousHint), findsOneWidget);
  });

  testWidgets('ingresar llama al repositorio con las credenciales (HU-41)',
      (tester) async {
    final auth = FakeAuthRepository();

    await tester.pumpWidget(appDePrueba(const LoginScreen(), auth: auth));
    await tester.pumpAndSettle();

    final campos = find.byType(TextField);
    await tester.enterText(campos.first, 'organizador@planify.test');
    await tester.enterText(campos.last, 'planify-mvp-2026');

    await tester.tap(find.text(l10n.loginSubmit));
    await tester.pumpAndSettle();

    expect(auth.llamadas, contains('login:organizador@planify.test'));
  });

  testWidgets('muestra un mensaje si las credenciales fallan', (tester) async {
    final auth = FakeAuthRepository(fallaLogin: true);

    await tester.pumpWidget(appDePrueba(const LoginScreen(), auth: auth));
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.loginSubmit));
    await tester.pump();
    await tester.pump();

    expect(find.text(l10n.loginError), findsOneWidget);
  });
}
