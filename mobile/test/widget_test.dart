import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/network/token_storage.dart';
import 'package:planify/core/theme/app_theme.dart';
import 'package:planify/features/auth/login_screen.dart';
import 'package:planify/l10n/generated/app_localizations.dart';

import 'helpers/fake_token_storage.dart';

/// Se monta LoginScreen directamente en vez de PlanifyApp: el router raíz lee
/// secure storage al arrancar, que no está disponible en un test de widget.
Widget _app() => ProviderScope(
      overrides: [
        tokenStorageProvider.overrideWithValue(FakeTokenStorage()),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('es'),
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const LoginScreen(),
      ),
    );

void main() {
  testWidgets('La pantalla de Login muestra las acciones del MVP', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('es'));

    expect(find.text(l10n.appName), findsOneWidget);
    expect(find.text(l10n.loginSubmit), findsOneWidget);
    expect(find.text(l10n.loginContinueAnonymous), findsOneWidget);
    expect(find.text(l10n.loginCreateAccount), findsOneWidget);
  });

  testWidgets('El botón de anónimo explica que hace falta un link de invitación',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('es'));

    await tester.tap(find.text(l10n.loginContinueAnonymous));
    await tester.pump();

    expect(find.text(l10n.loginAnonymousHint), findsOneWidget);
  });
}
