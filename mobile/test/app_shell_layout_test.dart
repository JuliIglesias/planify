import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/models/models.dart';
import 'package:planify/core/theme/app_spacing.dart';
import 'package:planify/core/widgets/app_scaffold.dart';
import 'package:planify/core/widgets/pill_toggle.dart';
import 'package:planify/features/home/app_shell.dart';
import 'package:planify/features/home/home_screen.dart';
import 'package:planify/l10n/generated/app_localizations.dart';

import 'helpers/fake_repositories.dart';
import 'helpers/test_app.dart';

/// A1/A2 — la navbar flotante ("hug content", sin altura fija) tiene que
/// quedar alineada en altura con el resto de los "pill-bar" de la app, y
/// las 4 pantallas raíz tienen que dejar el padding inferior suficiente
/// para que la barra flotante no tape el último elemento scrolleable.
void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await prepararLocalizaciones();
  });

  testWidgets('A1 — AppBottomNav y PillToggle comparten el mismo radio de borde',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          bottomNavigationBar: AppBottomNav(currentIndex: 0, onTap: (_) {}),
          body: PillToggle<int>(
            options: const [(value: 0, label: 'A'), (value: 1, label: 'B')],
            selected: 0,
            onChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final navContainer = tester.widget<Container>(
      find.descendant(
        of: find.byType(AppBottomNav),
        matching: find.byType(Container),
      ).first,
    );
    final toggleContainer = tester.widget<Container>(
      find.descendant(
        of: find.byType(PillToggle<int>),
        matching: find.byType(Container),
      ).first,
    );

    final navDecoration = navContainer.decoration as BoxDecoration;
    final toggleDecoration = toggleContainer.decoration as BoxDecoration;

    expect(navDecoration.borderRadius, BorderRadius.circular(AppSpacing.barRadius));
    expect(toggleDecoration.borderRadius, BorderRadius.circular(AppSpacing.barRadius));
  });

  testWidgets(
      'A2 — se puede scrollear en Home hasta ver la última actividad reciente '
      'completa, sin que la navbar la tape', (tester) async {
    // Ancho seguro para el resto de la pantalla (evita un overflow horizontal
    // no relacionado con este fix); bajo de alto a propósito para forzar el
    // scroll incluso con pocos ítems.
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final activityLog = FakeActivityLogRepository(
      recientesEntradas: [
        for (var i = 0; i < 15; i++)
          ActividadLog(
            id: 'a$i',
            tipo: 'deuda_saldada',
            actorUsername: 'Persona$i',
            createdAt: DateTime(2026, 8, 1, 12, i),
            eventoNombre: 'Evento $i',
            payload: const {'monto': '100.00'},
          ),
      ],
    );

    await tester.pumpWidget(appDePrueba(const AppShell(), activityLog: activityLog));
    await tester.pumpAndSettle();

    // Scrollea la lista de Home hasta el final (la vertical: Home también
    // tiene un carrusel horizontal de "próximos eventos", otro `ListView`
    // distinto anidado adentro).
    final listaHome = find.descendant(
      of: find.byType(HomeScreen),
      matching: find.byWidgetPredicate(
        (w) => w is ListView && w.scrollDirection == Axis.vertical,
      ),
    );
    // Home limita la actividad reciente a 5 líneas (`agruparActividades`,
    // `limite: 5`) — la "última" visible es la 5ta más reciente, no la más
    // vieja de las 15 sembradas acá.
    final ultimoTitulo = find.text(l10n.activityDebtSettled('Persona10'));
    // Sigue arrastrando más allá del primer frame en el que el ítem ya está
    // construido (puede estar "construido pero todavía no del todo
    // visible", por el cacheExtent del ListView) hasta el tope real del
    // scroll — de ahí los intentos de sobra, son no-op una vez clampeado.
    for (var i = 0; i < 30; i++) {
      await tester.drag(listaHome, const Offset(0, -300));
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(ultimoTitulo, findsOneWidget);

    expect(ultimoTitulo, findsOneWidget);

    final rectUltimo = tester.getRect(ultimoTitulo);
    final rectNavbar = tester.getRect(find.byType(AppBottomNav));

    // El último ítem tiene que terminar ANTES de donde arranca la navbar
    // (no puede quedar ni parcial ni totalmente tapado detrás de ella).
    expect(rectUltimo.bottom, lessThanOrEqualTo(rectNavbar.top));
  });
}
