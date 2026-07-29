import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/models/models.dart';
import 'package:planify/features/balances/balances_screen.dart';
import 'package:planify/features/events/event_detail_screen.dart';
import 'package:planify/features/groups/groups_screen.dart';
import 'package:planify/features/home/home_screen.dart';
import 'package:planify/core/widgets/weekly_availability_grid.dart';
import 'package:planify/features/history/history_screen.dart';
import 'package:planify/l10n/generated/app_localizations.dart';

import 'helpers/fake_repositories.dart';
import 'helpers/test_app.dart';

late AppLocalizations l10n;

void main() {
  setUpAll(() async {
    l10n = await prepararLocalizaciones();
  });

  group('BalancesScreen (HU-16/HU-17)', () {
    testWidgets('muestra el balance neto y los saldos por persona', (tester) async {
      final balances = FakeBalancesRepository(
        balance: const Balance(
          balanceNeto: '2250.00',
          meDeben: '2250.00',
          debo: '0.00',
          saldos: [
            SaldoPorPersona(
              id: 'u1',
              nombre: 'Sofía',
              monto: '2250.00',
              estado: 'pendiente',
            ),
          ],
        ),
      );

      await tester.pumpWidget(appDePrueba(const BalancesScreen(), balances: balances));
      await tester.pumpAndSettle();

      expect(find.text(r'+$2250.00'), findsOneWidget);
      expect(find.text('Sofía'), findsOneWidget);
      expect(find.text(l10n.balancesOweYou), findsOneWidget);
    });

    testWidgets('muestra el estado vacío cuando no hay saldos', (tester) async {
      await tester.pumpWidget(appDePrueba(const BalancesScreen()));
      await tester.pumpAndSettle();

      expect(find.text(l10n.balancesEmpty), findsOneWidget);
    });

    testWidgets('un balance negativo se muestra sin el signo +', (tester) async {
      final balances = FakeBalancesRepository(
        balance: const Balance(
          balanceNeto: '-500.00',
          meDeben: '0.00',
          debo: '500.00',
          saldos: [],
        ),
      );

      await tester.pumpWidget(appDePrueba(const BalancesScreen(), balances: balances));
      await tester.pumpAndSettle();

      expect(find.text(r'$-500.00'), findsOneWidget);
    });
  });


  group('HomeScreen', () {
    testWidgets('muestra saldos, próximos eventos y actividad reciente',
        (tester) async {
      usarPantallaAlta(tester);

      final balances = FakeBalancesRepository(
        balance: const Balance(
          balanceNeto: '930.00',
          meDeben: '1250.00',
          debo: '320.00',
          saldos: [],
        ),
      );
      final events = FakeEventsRepository(
        eventos: const [
          EventoResumen(
            id: 'e1',
            nombre: 'Asado en lo de Marcos',
            lugarTexto: 'Casa de Nacho',
            estado: 'planificacion',
            participantes: [],
            confirmados: 4,
          ),
        ],
      );
      final activityLog = FakeActivityLogRepository(
        recientesEntradas: [
          ActividadLog(
            id: 'a1',
            tipo: 'deuda_saldada',
            actorNombre: 'Mati',
            createdAt: DateTime(2026, 7, 28, 20, 30),
            eventoNombre: 'Asado en lo de Marcos',
            payload: const {'monto': '450.00'},
          ),
        ],
      );

      await tester.pumpWidget(appDePrueba(
        const HomeScreen(),
        balances: balances,
        events: events,
        activityLog: activityLog,
      ));
      await tester.pumpAndSettle();

      expect(find.text(r'$1250.00'), findsOneWidget);
      expect(find.text(r'$320.00'), findsOneWidget);
      expect(find.text('Asado en lo de Marcos'), findsWidgets);
      expect(find.text(l10n.activityDebtSettled('Mati')), findsOneWidget);
      expect(find.text(r'+$450.00'), findsOneWidget);
    });
  });

  group('GroupsScreen', () {
    testWidgets('muestra el badge NUEVO y el punto de no leídos (Duda #2)',
        (tester) async {
      final groups = FakeGroupsRepository(
        grupos: const [
          GrupoResumen(
            id: 'g1',
            nombre: 'Los Fibes',
            miembros: ['Marcos', 'Sofía'],
            noLeidos: 3,
            tieneEventoNuevo: true,
            proximoEvento: ProximoEvento(
              id: 'e1',
              nombre: 'Asado',
              lugarTexto: 'Casa de Nacho',
              estado: 'planificacion',
              confirmados: 4,
            ),
          ),
        ],
      );

      await tester.pumpWidget(appDePrueba(const GroupsScreen(), groups: groups));
      await tester.pumpAndSettle();

      expect(find.text('Los Fibes'), findsOneWidget);
      expect(find.text(l10n.groupsNewEvent), findsOneWidget);
      expect(find.text(l10n.groupsConfirmed(4)), findsOneWidget);
    });

    testWidgets('muestra el estado vacío sin grupos', (tester) async {
      await tester.pumpWidget(appDePrueba(const GroupsScreen()));
      await tester.pumpAndSettle();

      expect(find.text(l10n.groupsNoGroups), findsOneWidget);
    });
  });

  group('Balances — compensación cruzada (FR9)', () {
    testWidgets('tocar una persona abre el detalle con el desglose por evento',
        (tester) async {
      usarPantallaAlta(tester);
      final balances = FakeBalancesRepository(
        balance: const Balance(
          balanceNeto: '-200.00',
          meDeben: '300.00',
          debo: '500.00',
          saldos: [
            SaldoPorPersona(
              id: 'usr-marcos',
              nombre: 'Marcos',
              monto: '200.00',
              estado: 'pagar',
            ),
          ],
        ),
      );

      await tester.pumpWidget(appDePrueba(const BalancesScreen(), balances: balances));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Marcos').first);
      await tester.pumpAndSettle();

      expect(balances.llamadas, contains('detalle:usr-marcos'));
      // El desglose muestra las dos deudas que se compensaron.
      expect(find.text('Asado'), findsOneWidget);
      expect(find.text('Cine'), findsOneWidget);
      // Los montos aparecen tanto en el desglose como en el resumen de atrás.
      expect(find.text(r'$500.00'), findsWidgets);
      expect(find.text(r'$300.00'), findsWidgets);
      // Y el neto compensado.
      expect(find.text(r'$200.00'), findsWidgets);
    });

    testWidgets('saldar todo cierra las deudas de todos los eventos', (tester) async {
      usarPantallaAlta(tester);
      final balances = FakeBalancesRepository(
        balance: const Balance(
          balanceNeto: '-200.00',
          meDeben: '300.00',
          debo: '500.00',
          saldos: [
            SaldoPorPersona(
              id: 'usr-marcos',
              nombre: 'Marcos',
              monto: '200.00',
              estado: 'pagar',
            ),
          ],
        ),
      );

      await tester.pumpWidget(appDePrueba(const BalancesScreen(), balances: balances));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Marcos').first);
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.balancesSettleAll));
      await tester.pumpAndSettle();

      // Pide confirmación antes de saldar en cascada.
      expect(find.text(l10n.balancesSettleAllConfirmMulti('Marcos', 2)), findsOneWidget);
      await tester.tap(find.text(l10n.commonConfirm));
      await tester.pumpAndSettle();

      expect(balances.llamadas, contains('saldarPersona:usr-marcos'));
    });
  });

  group('HistoryScreen (HU-26)', () {
    testWidgets('agrupa por mes y muestra el estado de saldo', (tester) async {
      final events = FakeEventsRepository(
        historialEventos: [
          EventoHistorial(
            id: 'e1',
            nombre: 'Asado en lo de Marcos',
            estadoSaldo: 'pagar',
            monto: '1200.00',
            participantes: const ['Marcos', 'Sofía'],
            fechaHoraInicio: DateTime(2026, 5, 12),
          ),
        ],
      );

      await tester.pumpWidget(appDePrueba(const HistoryScreen(), events: events));
      await tester.pumpAndSettle();

      expect(find.text('Asado en lo de Marcos'), findsOneWidget);
      expect(find.text(l10n.balancesStatePay.toUpperCase()), findsOneWidget);
      expect(find.text(r'$1200.00'), findsOneWidget);
      expect(find.text(l10n.historyToPay), findsOneWidget);
    });
  });

  group('EventDetailScreen', () {
    testWidgets('muestra las acciones rápidas y la asistencia', (tester) async {
      usarPantallaAlta(tester);
      await tester.pumpWidget(
        appDePrueba(const EventDetailScreen(eventoId: 'evt-1')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Asado en lo de Marcos'), findsOneWidget);
      expect(find.text(l10n.eventDetailGoing), findsOneWidget);
      expect(find.text(l10n.eventDetailAddExpense), findsOneWidget);
      expect(find.text(l10n.eventDetailAddTask), findsOneWidget);
      expect(find.text(l10n.eventDetailSettle), findsOneWidget);
    });

    testWidgets('confirmar asistencia llama al repositorio (HU-10)', (tester) async {
      final events = FakeEventsRepository();

      usarPantallaAlta(tester);
      await tester.pumpWidget(
        appDePrueba(const EventDetailScreen(eventoId: 'evt-1'), events: events),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.eventDetailGoing));
      await tester.pumpAndSettle();

      expect(events.llamadas, contains('asistencia:true'));
    });

    testWidgets('guardar disponibilidad envía los bloques marcados (HU-07)',
        (tester) async {
      final availability = FakeAvailabilityRepository();

      usarPantallaAlta(tester);
      await tester.pumpWidget(
        appDePrueba(
          const EventDetailScreen(eventoId: 'evt-1'),
          availability: availability,
        ),
      );
      await tester.pumpAndSettle();

      // La primera grilla es la editable ("Mi disponibilidad"); la segunda es
      // el heatmap de solo lectura. Se busca la celda adentro de la primera
      // para no tocar por accidente otro GestureDetector de la pantalla.
      final celda = find
          .descendant(
            of: find.byType(WeeklyAvailabilityGrid).first,
            matching: find.byType(GestureDetector),
          )
          .first;

      await tester.tap(celda);
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.eventDetailSaveAvailability));
      await tester.pumpAndSettle();

      expect(availability.llamadas, contains('guardar:1'));
    });

    testWidgets('tomar una tarea la asigna al participante (HU-21)', (tester) async {
      final tasks = FakeTasksRepository(
        tareas: const [Tarea(id: 't1', titulo: 'Comprar carne', estado: 'no_asignado')],
      );

      usarPantallaAlta(tester);
      await tester.pumpWidget(
        appDePrueba(const EventDetailScreen(eventoId: 'evt-1'), tasks: tasks),
      );
      await tester.pumpAndSettle();

      expect(find.text('Comprar carne'), findsOneWidget);
      expect(find.text(l10n.eventDetailTaskUnassigned), findsOneWidget);

      await tester.tap(find.text(l10n.eventDetailTakeTask));
      await tester.pumpAndSettle();

      expect(tasks.llamadas, contains('asignar:t1:yo'));
    });

    testWidgets('una tarea completada no ofrece acciones (HU-23)', (tester) async {
      final tasks = FakeTasksRepository(
        tareas: const [
          Tarea(
            id: 't1',
            titulo: 'Comprar hielo',
            estado: 'completado',
            asignadoNombre: 'Sofía',
          ),
        ],
      );

      usarPantallaAlta(tester);
      await tester.pumpWidget(
        appDePrueba(const EventDetailScreen(eventoId: 'evt-1'), tasks: tasks),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n.eventDetailTaskDone), findsOneWidget);
      expect(find.text(l10n.eventDetailTakeTask), findsNothing);
      expect(find.text(l10n.eventDetailCompleteTask), findsNothing);
    });

    testWidgets('un evento cancelado deshabilita las acciones', (tester) async {
      final events = FakeEventsRepository(
        detalleEvento: FakeEventsRepository.detalleDeEjemplo(estado: 'cancelado'),
      );

      usarPantallaAlta(tester);
      await tester.pumpWidget(
        appDePrueba(const EventDetailScreen(eventoId: 'evt-1'), events: events),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n.eventDetailCancelled.toUpperCase()), findsOneWidget);

      // El botón de asistencia queda inerte.
      await tester.tap(find.text(l10n.eventDetailGoing));
      await tester.pumpAndSettle();
      expect(events.llamadas, isEmpty);
    });

    testWidgets('el feed traduce los tipos de actividad (HU-24)', (tester) async {
      final activityLog = FakeActivityLogRepository(
        entradas: [
          ActividadLog(
            id: 'a1',
            tipo: 'gasto_agregado',
            actorNombre: 'Marcos',
            createdAt: DateTime(2026, 7, 28, 20, 30),
          ),
          ActividadLog(
            id: 'a2',
            tipo: 'horario_confirmado',
            actorNombre: 'Julieta',
            createdAt: DateTime(2026, 7, 28, 19, 0),
          ),
        ],
      );

      usarPantallaAlta(tester);
      await tester.pumpWidget(
        appDePrueba(
          const EventDetailScreen(eventoId: 'evt-1'),
          activityLog: activityLog,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n.activityExpenseAdded('Marcos')), findsOneWidget);
      expect(find.text(l10n.activityScheduleConfirmed('Julieta')), findsOneWidget);
    });
  });
}
