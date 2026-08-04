import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/auth/register_screen.dart';
import 'package:planify/l10n/generated/app_localizations.dart';

import 'helpers/fake_repositories.dart';
import 'helpers/test_app.dart';

/// Pantalla de registro — HU-27. El campo de identidad pide un username
/// único (reemplaza al viejo "nombre" libre — ver docs/05-fixes.md).
void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await prepararLocalizaciones();
  });

  testWidgets('registrar envía username, email y password al repositorio', (tester) async {
    final auth = FakeAuthRepository();

    await tester.pumpWidget(appDePrueba(const RegisterScreen(), auth: auth));
    await tester.pumpAndSettle();

    expect(find.text(l10n.registerName), findsOneWidget);

    final campos = find.byType(TextField);
    await tester.enterText(campos.at(0), 'sofia');
    await tester.enterText(campos.at(1), 'sofia@planify.test');
    await tester.enterText(campos.at(2), 'secreto1');

    await tester.tap(find.text(l10n.registerSubmit));
    await tester.pumpAndSettle();

    expect(auth.llamadas, contains('register:sofia@planify.test'));
  });

  testWidgets('muestra un mensaje si el registro falla (ej. username ya usado)',
      (tester) async {
    final auth = FakeAuthRepository(fallaLogin: true);

    await tester.pumpWidget(appDePrueba(const RegisterScreen(), auth: auth));
    await tester.pumpAndSettle();

    final campos = find.byType(TextField);
    await tester.enterText(campos.at(0), 'sofia');
    await tester.enterText(campos.at(1), 'sofia@planify.test');
    await tester.enterText(campos.at(2), 'secreto1');

    await tester.tap(find.text(l10n.registerSubmit));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('No se pudo registrar'), findsOneWidget);
  });
}
