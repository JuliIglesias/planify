import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/widgets/weekly_availability_grid.dart';
import 'package:planify/features/friends/data/friends_repository.dart';
import 'package:planify/features/friends/friend_profile_screen.dart';
import 'package:planify/l10n/generated/app_localizations.dart';

import 'helpers/fake_repositories.dart';
import 'helpers/test_app.dart';

/// Item 4 — perfil de solo lectura de un amigo: foto/username/email,
/// disponibilidad semanal comparada (4 estados) y eventos/grupos en común.
void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await prepararLocalizaciones();
  });

  testWidgets('muestra username y email del amigo en el encabezado', (tester) async {
    final friends = FakeFriendsRepository(
      perfil: FakeFriendsRepository.perfilDeEjemplo(
        persona: const Persona(id: 'u2', username: 'Marcos', email: 'marcos@mail.com'),
      ),
    );

    usarPantallaAlta(tester);
    await tester.pumpWidget(
      appDePrueba(const FriendProfileScreen(usuarioId: 'u2'), friends: friends),
    );
    await tester.pumpAndSettle();

    expect(find.text('Marcos'), findsWidgets); // AppBar + encabezado
    expect(find.text('marcos@mail.com'), findsOneWidget);
    expect(friends.llamadas, contains('perfilDe:u2'));
  });

  testWidgets(
      'la disponibilidad comparada distingue 4 estados con leyenda de texto (Item 4)',
      (tester) async {
    final friends = FakeFriendsRepository(
      perfil: FakeFriendsRepository.perfilDeEjemplo(
        persona: const Persona(id: 'u2', username: 'Marcos', email: 'marcos@mail.com'),
        heatmapComparado: const [
          SlotComparado(0, 20, EstadoSlotComparado.ambos),
          SlotComparado(1, 10, EstadoSlotComparado.soloYo),
          SlotComparado(2, 15, EstadoSlotComparado.soloAmigo),
        ],
      ),
    );

    usarPantallaAlta(tester);
    await tester.pumpWidget(
      appDePrueba(const FriendProfileScreen(usuarioId: 'u2'), friends: friends),
    );
    await tester.pumpAndSettle();

    expect(find.byType(WeeklyAvailabilityGrid), findsOneWidget);
    // El color nunca va solo: la leyenda nombra los 4 estados como texto,
    // incluido el username del amigo en el estado "solo el amigo".
    expect(find.text(l10n.friendProfileLegendBoth), findsOneWidget);
    expect(find.text(l10n.friendProfileLegendMeOnly), findsOneWidget);
    expect(find.text(l10n.friendProfileLegendFriendOnly('Marcos')), findsOneWidget);
    expect(find.text(l10n.friendProfileLegendNeither), findsOneWidget);
  });

  testWidgets('lista los eventos y grupos en común, o el estado vacío si no hay',
      (tester) async {
    final friends = FakeFriendsRepository(
      perfil: FakeFriendsRepository.perfilDeEjemplo(
        eventosEnComun: const [
          EventoCompartido(
            id: 'e1',
            nombre: 'Asado',
            lugarTexto: 'Casa de Nacho',
            estado: 'planificacion',
          ),
        ],
        gruposEnComun: const [GrupoCompartido(id: 'g1', nombre: 'Los Fibes')],
      ),
    );

    usarPantallaAlta(tester);
    await tester.pumpWidget(
      appDePrueba(const FriendProfileScreen(usuarioId: 'u2'), friends: friends),
    );
    await tester.pumpAndSettle();

    expect(find.text('Asado'), findsOneWidget);
    expect(find.text('Los Fibes'), findsOneWidget);
    expect(find.text(l10n.friendProfileNoEvents), findsNothing);
    expect(find.text(l10n.friendProfileNoGroups), findsNothing);
  });

  testWidgets('sin eventos ni grupos en común muestra los estados vacíos', (tester) async {
    final friends = FakeFriendsRepository(perfil: FakeFriendsRepository.perfilDeEjemplo());

    usarPantallaAlta(tester);
    await tester.pumpWidget(
      appDePrueba(const FriendProfileScreen(usuarioId: 'u2'), friends: friends),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.friendProfileNoEvents), findsOneWidget);
    expect(find.text(l10n.friendProfileNoGroups), findsOneWidget);
  });
}
