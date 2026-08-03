import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/models/models.dart';
import 'package:planify/core/widgets/quick_action_button.dart';
import 'package:planify/features/balances/balances_screen.dart';
import 'package:planify/features/events/event_detail_screen.dart';
import 'package:planify/features/groups/groups_screen.dart';
import 'package:planify/features/home/home_screen.dart';
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
            grupoId: 'g1',
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

  group('GroupsScreen (Item 1 — carrusel + eventos por grupo)', () {
    final dosGrupos = FakeGroupsRepository(
      grupos: const [
        GrupoResumen(
          id: 'g1',
          nombre: 'Los Fibes',
          miembros: ['Marcos', 'Sofía'],
          noLeidos: 3,
          tieneEventoNuevo: true,
          eventos: [
            EventoDeGrupo(
              id: 'e1',
              nombre: 'Asado',
              lugarTexto: 'Casa de Nacho',
              estado: 'planificacion',
              confirmados: 4,
            ),
          ],
        ),
        GrupoResumen(
          id: 'g2',
          nombre: 'Fútbol 5',
          miembros: ['Lucas'],
          eventos: [
            EventoDeGrupo(
              id: 'e2',
              nombre: 'Picadito',
              lugarTexto: 'Cancha del club',
              estado: 'confirmado',
              confirmados: 8,
              tareasPendientes: 2,
            ),
          ],
        ),
      ],
    );

    testWidgets('arranca en el primer grupo y muestra sus eventos', (tester) async {
      await tester.pumpWidget(appDePrueba(const GroupsScreen(), groups: dosGrupos));
      await tester.pumpAndSettle();

      // "Los Fibes" aparece dos veces: en el carrusel y como título del
      // grupo activo.
      expect(find.text('Los Fibes'), findsNWidgets(2));
      expect(find.text(l10n.groupsNewEvent), findsOneWidget);
      expect(find.text('Asado'), findsOneWidget);
      expect(find.text(l10n.groupsConfirmed(4)), findsOneWidget);
      // El evento del otro grupo no se ve todavía.
      expect(find.text('Picadito'), findsNothing);
    });

    testWidgets(
        'tocar otro grupo en el carrusel cambia los eventos, y volver al '
        'primero los conserva intactos (criterio de aceptación del Item 1)',
        (tester) async {
      await tester.pumpWidget(appDePrueba(const GroupsScreen(), groups: dosGrupos));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Fútbol 5'));
      await tester.pumpAndSettle();

      expect(find.text('Picadito'), findsOneWidget);
      expect(find.text(l10n.groupsPendingTasks(2)), findsOneWidget);
      // El evento de "Los Fibes" ya no se muestra (está filtrado, no perdido).
      expect(find.text('Asado'), findsNothing);

      await tester.tap(find.text('Los Fibes').first);
      await tester.pumpAndSettle();

      // Sigue completo, no se perdió ni se re-pisó con el otro grupo.
      expect(find.text('Asado'), findsOneWidget);
      expect(find.text(l10n.groupsConfirmed(4)), findsOneWidget);
      expect(find.text('Picadito'), findsNothing);
    });

    testWidgets('un grupo sin eventos activos muestra el estado vacío', (tester) async {
      final soloUno = FakeGroupsRepository(
        grupos: const [
          GrupoResumen(id: 'g1', nombre: 'Sin planes', miembros: ['Ana']),
        ],
      );

      await tester.pumpWidget(appDePrueba(const GroupsScreen(), groups: soloUno));
      await tester.pumpAndSettle();

      expect(find.text(l10n.groupsNoUpcoming), findsOneWidget);
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

  group('EventDetailScreen (Item 4 — feed de actividad)', () {
    testWidgets('muestra las acciones rápidas y el acceso a Configuración',
        (tester) async {
      usarPantallaAlta(tester);
      await tester.pumpWidget(
        appDePrueba(const EventDetailScreen(eventoId: 'evt-1')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Asado en lo de Marcos'), findsOneWidget);
      expect(find.text(l10n.eventDetailAddExpense), findsOneWidget);
      expect(find.text(l10n.eventDetailAddTask), findsOneWidget);
      expect(find.text(l10n.eventDetailSettle), findsOneWidget);
      // Asistencia y disponibilidad ya no viven acá — se accede por el
      // ícono de engranaje a la pantalla de Configuración aparte.
      expect(find.text(l10n.eventDetailGoing), findsNothing);
      expect(find.text(l10n.eventDetailMyAvailability), findsNothing);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    });

    testWidgets('el ícono de engranaje abre la pantalla de Configuración',
        (tester) async {
      usarPantallaAlta(tester);
      await tester.pumpWidget(
        appDePrueba(const EventDetailScreen(eventoId: 'evt-1')),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      expect(find.text(l10n.eventConfigTitle), findsOneWidget);
      expect(find.text(l10n.eventDetailAttendance), findsOneWidget);
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

    testWidgets('un evento cancelado deshabilita las acciones rápidas', (tester) async {
      final events = FakeEventsRepository(
        detalleEvento: FakeEventsRepository.detalleDeEjemplo(estado: 'cancelado'),
      );

      usarPantallaAlta(tester);
      await tester.pumpWidget(
        appDePrueba(const EventDetailScreen(eventoId: 'evt-1'), events: events),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n.eventDetailCancelled.toUpperCase()), findsOneWidget);

      final gasto = tester.widget<QuickActionButton>(
        find.widgetWithText(QuickActionButton, l10n.eventDetailAddExpense),
      );
      expect(gasto.onPressed, isNull);
    });

    testWidgets('un anónimo no ve las acciones de organizador (H-04)', (tester) async {
      // Vista del organizador: el menú (cancelar / cerrar gastos) está.
      usarPantallaAlta(tester);
      await tester.pumpWidget(appDePrueba(const EventDetailScreen(eventoId: 'evt-1')));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.more_vert), findsOneWidget);

      // Vista de un participante no-organizador: el menú NO está (antes lo veía
      // y las acciones le devolvían 401).
      final anon = FakeEventsRepository(
        detalleEvento: FakeEventsRepository.detalleDeEjemplo(soyOrganizador: false),
      );
      await tester.pumpWidget(
        appDePrueba(const EventDetailScreen(eventoId: 'evt-1'), events: anon),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.more_vert), findsNothing);
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
