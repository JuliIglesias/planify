import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/widgets/weekly_availability_grid.dart';
import 'package:planify/features/events/event_config_screen.dart';
import 'package:planify/l10n/generated/app_localizations.dart';

import 'helpers/fake_repositories.dart';
import 'helpers/test_app.dart';

/// Item 4 — Configuración del evento: asistencia + disponibilidad propia y
/// del grupo, separadas del feed de actividad (event_detail_screen).
void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await prepararLocalizaciones();
  });

  testWidgets('muestra asistencia y las dos disponibilidades, ya expandidas',
      (tester) async {
    usarPantallaAlta(tester, alto: 4000);
    await tester.pumpWidget(
      appDePrueba(const EventConfigScreen(eventoId: 'evt-1')),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.eventConfigTitle), findsOneWidget);
    expect(find.text(l10n.eventDetailAttendance), findsOneWidget);
    expect(find.text(l10n.eventDetailMyAvailability), findsOneWidget);
    expect(find.text(l10n.eventDetailAvailability), findsOneWidget);
    // Arrancan expandidas: no hace falta tocar nada para ver las grillas.
    expect(find.byType(WeeklyAvailabilityGrid), findsNWidgets(2));
  });

  testWidgets('confirmar asistencia llama al repositorio (HU-10)', (tester) async {
    final events = FakeEventsRepository();

    usarPantallaAlta(tester, alto: 4000);
    await tester.pumpWidget(
      appDePrueba(const EventConfigScreen(eventoId: 'evt-1'), events: events),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.eventDetailGoing));
    await tester.pumpAndSettle();

    expect(events.llamadas, contains('asistencia:true'));
  });

  testWidgets('tocar "No voy" llama al repositorio con confirma:false (Item 4)',
      (tester) async {
    final events = FakeEventsRepository();

    usarPantallaAlta(tester, alto: 4000);
    await tester.pumpWidget(
      appDePrueba(const EventConfigScreen(eventoId: 'evt-1'), events: events),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.eventDetailNotGoing));
    await tester.pumpAndSettle();

    expect(events.llamadas, contains('asistencia:false'));
  });

  testWidgets('el botón que refleja mi respuesta actual queda resaltado (Item 4)',
      (tester) async {
    final rechazado = FakeEventsRepository(
      detalleEvento:
          FakeEventsRepository.detalleDeEjemplo(miEstadoAsistencia: 'rechazado'),
    );

    usarPantallaAlta(tester, alto: 4000);
    await tester.pumpWidget(
      appDePrueba(const EventConfigScreen(eventoId: 'evt-1'), events: rechazado),
    );
    await tester.pumpAndSettle();

    // "No voy" queda resaltado (con tilde, un solo botón la muestra); "Voy"
    // queda apagado (outline, sin resaltar).
    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(
      find.ancestor(
        of: find.text(l10n.eventDetailGoing),
        matching: find.byType(OutlinedButton),
      ),
      findsOneWidget,
    );
  });

  testWidgets('guardar disponibilidad envía los bloques marcados (HU-07)',
      (tester) async {
    final availability = FakeAvailabilityRepository();

    usarPantallaAlta(tester, alto: 4000);
    await tester.pumpWidget(
      appDePrueba(
        const EventConfigScreen(eventoId: 'evt-1'),
        availability: availability,
      ),
    );
    await tester.pumpAndSettle();

    // La primera grilla es la editable ("Mi disponibilidad"); la segunda es
    // el heatmap de solo lectura.
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

  testWidgets('un participante no-organizador no ve el hint de confirmar horario',
      (tester) async {
    final anon = FakeEventsRepository(
      detalleEvento: FakeEventsRepository.detalleDeEjemplo(soyOrganizador: false),
    );

    usarPantallaAlta(tester, alto: 4000);
    await tester.pumpWidget(
      appDePrueba(const EventConfigScreen(eventoId: 'evt-1'), events: anon),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.eventDetailTapToConfirm), findsNothing);
  });

  testWidgets('el horario ya fijado se marca con una estrella en el heatmap (Item 5)',
      (tester) async {
    final confirmado = FakeEventsRepository(
      detalleEvento: FakeEventsRepository.detalleDeEjemplo(
        estado: 'confirmado',
        // Lunes (weekday=1) 20:00 → AvailabilitySlot(0, 20).
        fechaHoraInicio: DateTime(2026, 8, 3, 20),
      ),
    );

    usarPantallaAlta(tester, alto: 4000);
    await tester.pumpWidget(
      appDePrueba(const EventConfigScreen(eventoId: 'evt-1'), events: confirmado),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.star), findsOneWidget);
  });

  testWidgets('sin horario confirmado no aparece ninguna estrella', (tester) async {
    usarPantallaAlta(tester, alto: 4000);
    await tester.pumpWidget(
      appDePrueba(const EventConfigScreen(eventoId: 'evt-1')),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.star), findsNothing);
  });

  testWidgets(
      'un rango horario fijado marca TODOS sus bloques con estrella, no solo el primero (Item 5)',
      (tester) async {
    final confirmado = FakeEventsRepository(
      detalleEvento: FakeEventsRepository.detalleDeEjemplo(
        estado: 'confirmado',
        fechaHoraInicio: DateTime(2026, 8, 3, 19), // lunes 19:00
        fechaHoraFin: DateTime(2026, 8, 3, 23), // hasta las 23:00 → 4 bloques
      ),
    );

    usarPantallaAlta(tester, alto: 4000);
    await tester.pumpWidget(
      appDePrueba(const EventConfigScreen(eventoId: 'evt-1'), events: confirmado),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.star), findsNWidgets(4));
  });

  testWidgets(
      'tocar un bloque del heatmap abre el selector de hora de fin, con la '
      'disponibilidad del rango elegido (Item 5)', (tester) async {
    final availability = FakeAvailabilityRepository(
      enRango: (disponibles: 3, total: 5),
    );

    usarPantallaAlta(tester, alto: 4000);
    await tester.pumpWidget(
      appDePrueba(const EventConfigScreen(eventoId: 'evt-1'), availability: availability),
    );
    await tester.pumpAndSettle();

    // La segunda grilla es el heatmap de solo lectura (la primera es "Mi
    // disponibilidad", editable). Tocar su primera celda = lunes 00h.
    final celdaHeatmap = find
        .descendant(
          of: find.byType(WeeklyAvailabilityGrid).at(1),
          matching: find.byType(GestureDetector),
        )
        .first;

    await tester.tap(celdaHeatmap);
    await tester.pumpAndSettle();

    expect(find.text(l10n.eventDetailPickEndTime), findsOneWidget);
    expect(find.text(l10n.eventDetailStartTimeLabel('00:00')), findsOneWidget);
    expect(find.text(l10n.eventDetailAvailableForRange(3, 5)), findsOneWidget);
    expect(availability.llamadas, contains('disponiblesEnRango:0:0:2'));
  });

  testWidgets('confirmar en el selector de fin llama a confirmarHorario con inicio Y fin (Item 5)',
      (tester) async {
    final availability = FakeAvailabilityRepository();

    usarPantallaAlta(tester, alto: 4000);
    await tester.pumpWidget(
      appDePrueba(const EventConfigScreen(eventoId: 'evt-1'), availability: availability),
    );
    await tester.pumpAndSettle();

    final celdaHeatmap = find
        .descendant(
          of: find.byType(WeeklyAvailabilityGrid).at(1),
          matching: find.byType(GestureDetector),
        )
        .first;

    await tester.tap(celdaHeatmap);
    await tester.pumpAndSettle();

    // Default: hora de fin = inicio + 2 (00h → 02h), sin tocar el dropdown.
    await tester.tap(find.text(l10n.commonConfirm));
    await tester.pumpAndSettle();

    final llamada = availability.llamadas.firstWhere((l) => l.startsWith('confirmar:'));
    expect(llamada, contains('T00:00:00.000'));
    expect(llamada, contains('T02:00:00.000'));
  });

  testWidgets('cancelar el selector de fin no confirma ningún horario (Item 5)',
      (tester) async {
    final availability = FakeAvailabilityRepository();

    usarPantallaAlta(tester, alto: 4000);
    await tester.pumpWidget(
      appDePrueba(const EventConfigScreen(eventoId: 'evt-1'), availability: availability),
    );
    await tester.pumpAndSettle();

    final celdaHeatmap = find
        .descendant(
          of: find.byType(WeeklyAvailabilityGrid).at(1),
          matching: find.byType(GestureDetector),
        )
        .first;

    await tester.tap(celdaHeatmap);
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.commonCancel));
    await tester.pumpAndSettle();

    expect(availability.llamadas.where((l) => l.startsWith('confirmar:')), isEmpty);
  });
}
