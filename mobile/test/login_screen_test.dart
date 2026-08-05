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

  testWidgets(
      'continuar como anónimo pide link + nombre en un solo paso y crea la sesión (Item 5)',
      (tester) async {
    final auth = FakeAuthRepository();

    await tester.pumpWidget(appDePrueba(const LoginScreen(), auth: auth));
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.loginContinueAnonymous));
    await tester.pumpAndSettle();

    // Un solo diálogo, no dos pasos separados (evita el doble prompt).
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text(l10n.loginAnonymousLinkLabel), findsOneWidget);
    expect(find.text(l10n.loginAnonymousNameLabel), findsOneWidget);

    final campos = find.byType(TextField);
    await tester.enterText(campos.at(2), 'planify://invite/f210607e');
    await tester.enterText(campos.at(3), 'Sofía');
    // G1 — el PIN es obligatorio: es lo que permite recuperar la misma
    // identidad si vuelve a entrar con el mismo username a este evento.
    await tester.enterText(campos.at(4), 'pin1234');

    await tester.tap(find.text(l10n.commonConfirm));
    await tester.pumpAndSettle();

    // El nombre viaja junto con el token: el anónimo queda registrado como
    // Participante real desde el primer paso (H-01/H-02 siguen valiendo).
    expect(auth.llamadas, contains('anonimo:evt-1:Sofía:pin1234'));
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('el confirmar del diálogo de anónimo queda deshabilitado sin nombre (Item 5)',
      (tester) async {
    final auth = FakeAuthRepository();

    await tester.pumpWidget(appDePrueba(const LoginScreen(), auth: auth));
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.loginContinueAnonymous));
    await tester.pumpAndSettle();

    final campos = find.byType(TextField);
    await tester.enterText(campos.at(2), 'planify://invite/f210607e');
    // No se completa el nombre.

    await tester.tap(find.text(l10n.commonConfirm));
    await tester.pumpAndSettle();

    // El diálogo sigue abierto: no se puede unir como anónimo sin nombre.
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(auth.llamadas, isEmpty);
  });

  // G1 — el PIN es obligatorio (mismo criterio que el nombre, arriba): sin
  // uno de al menos 4 caracteres, no hay forma de recuperar la sesión más
  // adelante, así que ni siquiera se manda el pedido.
  testWidgets('el confirmar del diálogo de anónimo queda deshabilitado sin PIN válido (G1)',
      (tester) async {
    final auth = FakeAuthRepository();

    await tester.pumpWidget(appDePrueba(const LoginScreen(), auth: auth));
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.loginContinueAnonymous));
    await tester.pumpAndSettle();

    final campos = find.byType(TextField);
    await tester.enterText(campos.at(2), 'planify://invite/f210607e');
    await tester.enterText(campos.at(3), 'Sofía');
    await tester.enterText(campos.at(4), 'abc'); // menos de 4 caracteres

    await tester.tap(find.text(l10n.commonConfirm));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(auth.llamadas, isEmpty);
  });

  // G1 — a diferencia de antes (nunca fallaba, auto-sufijaba en silencio),
  // unirse como anónimo ahora puede rechazarse — ej. el username ya está en
  // uso en otro evento activo. El mensaje específico del backend (con la
  // sugerencia de username) tiene que llegar a la persona.
  testWidgets(
      'si el backend rechaza la unión anónima, se muestra el mensaje '
      'específico (G1)', (tester) async {
    final auth = FakeAuthRepository(
      errorAnonimo: 'El username "Sofía" ya está en uso en otro evento activo. '
          'Probá con "Sofía2".',
    );

    await tester.pumpWidget(appDePrueba(const LoginScreen(), auth: auth));
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.loginContinueAnonymous));
    await tester.pumpAndSettle();

    final campos = find.byType(TextField);
    await tester.enterText(campos.at(2), 'planify://invite/f210607e');
    await tester.enterText(campos.at(3), 'Sofía');
    await tester.enterText(campos.at(4), 'pin1234');

    await tester.tap(find.text(l10n.commonConfirm));
    await tester.pumpAndSettle();

    expect(find.textContaining('Sofía2'), findsOneWidget);
  });

  testWidgets(
      'con una invitación pendiente, el Login muestra el aviso pero sigue '
      'ofreciendo las 3 vías (Item 2)', (tester) async {
    await tester.pumpWidget(
      appDePrueba(const LoginScreen(), pendingInvitation: 'tok-pendiente'),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.loginPendingInvitation), findsOneWidget);
    // Ninguna de las 3 vías queda bloqueada por la invitación pendiente.
    expect(find.text(l10n.loginSubmit), findsOneWidget);
    expect(find.text(l10n.loginCreateAccount), findsOneWidget);
    expect(find.text(l10n.loginContinueAnonymous), findsOneWidget);
  });

  testWidgets('sin invitación pendiente no se muestra el aviso', (tester) async {
    await tester.pumpWidget(appDePrueba(const LoginScreen()));
    await tester.pumpAndSettle();

    expect(find.text(l10n.loginPendingInvitation), findsNothing);
  });

  testWidgets(
      'el diálogo de anónimo precarga el link cuando ya había una invitación '
      'pendiente (Item 2)', (tester) async {
    await tester.pumpWidget(
      appDePrueba(const LoginScreen(), pendingInvitation: 'planify://invite/tok-pendiente'),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.loginContinueAnonymous));
    await tester.pumpAndSettle();

    final campoLink = tester.widget<TextField>(find.byType(TextField).at(2));
    expect(campoLink.controller?.text, 'planify://invite/tok-pendiente');
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

  testWidgets('Item 6 (Tanda 6) — card flotante con logo/tagline arriba, sin AppBar',
      (tester) async {
    await tester.pumpWidget(appDePrueba(const LoginScreen()));
    await tester.pumpAndSettle();

    expect(find.text(l10n.appName), findsOneWidget);
    expect(find.text(l10n.appTagline), findsOneWidget);
    expect(find.byType(AppBar), findsNothing);
    // Es la pantalla raíz: no hay a dónde volver.
    expect(find.byType(BackButton), findsNothing);
  });
}
