import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/models/models.dart';
import 'package:planify/features/events/data/activity_log_repository.dart';
import 'package:planify/features/events/event_detail_screen.dart';
import 'package:planify/features/notifications/notifications_providers.dart';
import 'package:planify/features/notifications/notifications_screen.dart';
import 'package:planify/l10n/generated/app_localizations.dart';

import 'helpers/fake_repositories.dart';
import 'helpers/test_app.dart';

/// Item 2 (Tanda 6) — pantalla de Notificaciones: paginación de a 20 y
/// navegación al evento de cada actividad.
void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await prepararLocalizaciones();
  });

  List<ActividadLog> generarEntradas(int cantidad, {String eventoId = 'evt-1'}) => [
        for (var i = 0; i < cantidad; i++)
          ActividadLog(
            id: 'log-$i',
            tipo: i.isEven ? 'gasto_agregado' : 'evento_creado',
            actorUsername: 'Marcos',
            // Más nueva primero, como las devuelve el backend.
            createdAt: DateTime(2026, 8, 1, 12).subtract(Duration(minutes: i)),
            eventoId: eventoId,
            eventoNombre: 'Asado',
          ),
      ];

  group('notificationsFeedProvider — paginación', () {
    test('la primera página trae hasta 20, y cargarMas trae el resto sin repetir', () async {
      final activityLog = FakeActivityLogRepository(recientesEntradas: generarEntradas(25));
      final container = ProviderContainer(
        overrides: [activityLogRepositoryProvider.overrideWithValue(activityLog)],
      );
      addTearDown(container.dispose);

      final primera = await container.read(notificationsFeedProvider.future);
      expect(primera.items, hasLength(20));
      expect(primera.hasMore, isTrue);

      await container.read(notificationsFeedProvider.notifier).cargarMas();
      final segunda = container.read(notificationsFeedProvider).value!;

      expect(segunda.items, hasLength(25));
      expect(segunda.hasMore, isFalse);
      // La segunda página no repite ids de la primera.
      final idsPrimera = primera.items.map((e) => e.id).toSet();
      final nuevos = segunda.items.skip(20).map((e) => e.id);
      expect(nuevos.every((id) => !idsPrimera.contains(id)), isTrue);
      // Se pidió con el cursor correcto (createdAt de la última de la primera página).
      expect(activityLog.llamadasRecientes, [null, primera.items.last.createdAt]);
    });

    test('con menos de 20 entradas no hay más páginas', () async {
      final activityLog = FakeActivityLogRepository(recientesEntradas: generarEntradas(3));
      final container = ProviderContainer(
        overrides: [activityLogRepositoryProvider.overrideWithValue(activityLog)],
      );
      addTearDown(container.dispose);

      final primera = await container.read(notificationsFeedProvider.future);
      expect(primera.items, hasLength(3));
      expect(primera.hasMore, isFalse);
    });
  });

  group('NotificationsScreen', () {
    testWidgets('muestra las actividades y tocar una rutea al evento', (tester) async {
      final activityLog = FakeActivityLogRepository(recientesEntradas: generarEntradas(2));

      await tester.pumpWidget(
        appDePrueba(const NotificationsScreen(), activityLog: activityLog),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n.notificationsTitle), findsOneWidget);
      expect(find.text('Asado'), findsNWidgets(2));

      await tester.tap(find.text('Asado').first);
      await tester.pumpAndSettle();

      expect(find.byType(EventDetailScreen), findsOneWidget);
    });

    testWidgets('el filtro "Gastos" oculta las actividades que no son de gasto',
        (tester) async {
      final activityLog = FakeActivityLogRepository(recientesEntradas: generarEntradas(2));

      await tester.pumpWidget(
        appDePrueba(const NotificationsScreen(), activityLog: activityLog),
      );
      await tester.pumpAndSettle();

      // Arranca en "Todo": ambos tipos visibles.
      expect(find.text(l10n.activityExpenseAdded('Marcos')), findsOneWidget);
      expect(find.text(l10n.activityEventCreated('Marcos')), findsOneWidget);

      await tester.tap(find.text(l10n.notificationsTabExpenses));
      await tester.pumpAndSettle();

      expect(find.text(l10n.activityExpenseAdded('Marcos')), findsOneWidget);
      expect(find.text(l10n.activityEventCreated('Marcos')), findsNothing);
    });

    testWidgets('sin actividad muestra el estado vacío', (tester) async {
      await tester.pumpWidget(appDePrueba(const NotificationsScreen()));
      await tester.pumpAndSettle();

      expect(find.text(l10n.notificationsEmpty), findsOneWidget);
    });
  });
}
