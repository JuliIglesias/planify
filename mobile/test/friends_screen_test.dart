import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/friends/data/friends_repository.dart';
import 'package:planify/features/friends/friends_screen.dart';
import 'package:planify/l10n/generated/app_localizations.dart';

import 'helpers/fake_repositories.dart';
import 'helpers/test_app.dart';

/// Item 3 (Fase 4) — el buscador y las solicitudes pendientes ya conviven en
/// esta pantalla (no había que "moverlos" de Perfil, ya estaban acá). Se
/// agrega cobertura porque no tenía ningún test hasta ahora.
void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await prepararLocalizaciones();
  });

  testWidgets('buscar muestra el email en gris debajo del nombre (Item 3)',
      (tester) async {
    final friends = FakeFriendsRepository(
      resultadosBusqueda: const [
        Persona(id: 'u1', username: 'Bruno', email: 'bruno@mail.com'),
      ],
    );

    await tester.pumpWidget(appDePrueba(const FriendsScreen(), friends: friends));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'bru');
    await tester.pumpAndSettle();

    expect(friends.llamadas, contains('buscar:bru'));
    expect(find.text('Bruno'), findsOneWidget);
    expect(find.text('bruno@mail.com'), findsOneWidget);
  });

  testWidgets('enviar solicitud llama al repositorio', (tester) async {
    final friends = FakeFriendsRepository(
      resultadosBusqueda: const [Persona(id: 'u1', username: 'Bruno', email: 'b@mail.com')],
    );

    await tester.pumpWidget(appDePrueba(const FriendsScreen(), friends: friends));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'bru');
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.friendsAdd));
    await tester.pumpAndSettle();

    expect(friends.llamadas, contains('enviarSolicitud:u1'));
  });

  testWidgets(
      'las solicitudes pendientes se ven y se aceptan en la misma pantalla (Item 3)',
      (tester) async {
    final friends = FakeFriendsRepository(
      solicitudes: const [
        SolicitudAmistad(amistadId: 'am1', de: Persona(id: 'u2', username: 'Sofía')),
      ],
    );

    await tester.pumpWidget(appDePrueba(const FriendsScreen(), friends: friends));
    await tester.pumpAndSettle();

    expect(find.text('Sofía'), findsOneWidget);

    await tester.tap(find.text(l10n.friendsAccept));
    await tester.pumpAndSettle();

    expect(friends.llamadas, contains('aceptar:am1'));
  });

  testWidgets('tocar un amigo de la lista abre su perfil de solo lectura (Item 4)',
      (tester) async {
    final friends = FakeFriendsRepository(
      amigos: const [Persona(id: 'u3', username: 'Lucas')],
      perfil: FakeFriendsRepository.perfilDeEjemplo(
        persona: const Persona(id: 'u3', username: 'Lucas', email: 'lucas@mail.com'),
      ),
    );

    usarPantallaAlta(tester);
    await tester.pumpWidget(appDePrueba(const FriendsScreen(), friends: friends));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lucas'));
    await tester.pumpAndSettle();

    expect(find.text('lucas@mail.com'), findsOneWidget);
    expect(friends.llamadas, contains('perfilDe:u3'));
  });
        
  testWidgets(
      'tocar cualquier parte de la fila de un resultado envía la solicitud, no '
      'solo el botón (Item 3, Fase 5)', (tester) async {
    final friends = FakeFriendsRepository(
      resultadosBusqueda: const [
        Persona(id: 'u1', username: 'Bruno', email: 'bruno@mail.com'),
      ],
    );

    await tester.pumpWidget(appDePrueba(const FriendsScreen(), friends: friends));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'bru');
    await tester.pumpAndSettle();

    // Toca el nombre, no el botón "Agregar".
    await tester.tap(find.text('Bruno'));
    await tester.pumpAndSettle();

    expect(friends.llamadas, contains('enviarSolicitud:u1'));
  });

  testWidgets(
      'tocar cualquier parte de la fila de una solicitud la acepta, y se ve el '
      'email de quien la envió (Item 3, Fase 5)', (tester) async {
    final friends = FakeFriendsRepository(
      solicitudes: const [
        SolicitudAmistad(
          amistadId: 'am1',
          de: Persona(id: 'u2', username: 'Sofía', email: 'sofia@mail.com'),
        ),
      ],
    );

    await tester.pumpWidget(appDePrueba(const FriendsScreen(), friends: friends));
    await tester.pumpAndSettle();

    expect(find.text('sofia@mail.com'), findsOneWidget);

    // Toca el nombre, no el botón "Aceptar".
    await tester.tap(find.text('Sofía'));
    await tester.pumpAndSettle();

    expect(friends.llamadas, contains('aceptar:am1'));
  });

  testWidgets('la lista de amigos ya agregados también muestra el email en gris (Item 3, Fase 5)',
      (tester) async {
    final friends = FakeFriendsRepository(
      amigos: const [Persona(id: 'u3', username: 'Lucas', email: 'lucas@mail.com')],
    );

    await tester.pumpWidget(appDePrueba(const FriendsScreen(), friends: friends));
    await tester.pumpAndSettle();

    expect(find.text('Lucas'), findsOneWidget);
    expect(find.text('lucas@mail.com'), findsOneWidget);
  });
}
