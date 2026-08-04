import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/events/create_event_screen.dart';
import 'package:planify/l10n/generated/app_localizations.dart';

import 'helpers/fake_repositories.dart';
import 'helpers/test_app.dart';

/// Item 1 — el organizador elige un rango de fechas calendario al crear el
/// evento, junto al nombre y el lugar (sigue siendo 2 pasos, NFR#3).
void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await prepararLocalizaciones();
  });

  testWidgets('el paso 1 ya trae un rango de fechas por defecto, visible',
      (tester) async {
    usarPantallaAlta(tester);
    await tester.pumpWidget(appDePrueba(const CreateEventScreen()));
    await tester.pumpAndSettle();

    expect(find.text(l10n.eventDateRangeLabel), findsOneWidget);
    expect(find.byIcon(Icons.date_range_outlined), findsOneWidget);
  });

  testWidgets('crear el evento manda el rango de fechas elegido al repositorio',
      (tester) async {
    final events = FakeEventsRepository();

    usarPantallaAlta(tester);
    await tester.pumpWidget(appDePrueba(const CreateEventScreen(), events: events));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Asado');
    await tester.enterText(find.byType(TextField).at(1), 'Casa de Nacho');
    await tester.pumpAndSettle();

    // Paso 2: crear grupo nuevo.
    await tester.tap(find.text(l10n.eventNext));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Amigos');
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.eventCreate));
    await tester.pumpAndSettle();

    expect(events.llamadas, contains('crear:Asado:Casa de Nacho:Amigos'));
  });
}
