import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/models/models.dart';
import 'package:planify/features/events/widgets/expense_dialog.dart';
import 'package:planify/l10n/generated/app_localizations.dart';

import 'helpers/test_app.dart';

/// D1 — el input de monto repartido por persona (Item 4 de una tanda
/// anterior) tiene que aparecer DEBAJO de "¿Quién pagó?" y "¿Entre quiénes
/// se divide?", no intercalado en cada fila de selección.
void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await prepararLocalizaciones();
  });

  const participantes = [
    Participante(id: 'p1', username: 'Juli', esOrganizador: true),
    Participante(id: 'p2', username: 'Nacho'),
  ];

  Future<DatosGasto?> abrirDialogo(WidgetTester tester) async {
    DatosGasto? resultado;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () async {
                resultado = await pedirDatosGasto(ctx, participantes);
              },
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    return resultado;
  }

  testWidgets(
      'el orden de arriba a abajo es: nombre, monto, quién pagó, entre '
      'quiénes se divide, montos por persona', (tester) async {
    await abrirDialogo(tester);

    // Suma un segundo pagador: si no, "Monto por pagador" ni se pinta.
    await tester.tap(find.text('Nacho').first);
    await tester.pumpAndSettle();

    // Todos los títulos de sección están presentes...
    final yQuienPago = tester.getTopLeft(find.text(l10n.eventDetailWhoPaid)).dy;
    final yEntreQuienes =
        tester.getTopLeft(find.text(l10n.eventDetailDivideBetween)).dy;
    final yMontoPagador =
        tester.getTopLeft(find.text(l10n.eventDetailAmountPerPayer)).dy;
    final yMontoPersona =
        tester.getTopLeft(find.text(l10n.eventDetailAmountPerPerson)).dy;

    // ...y en el orden pedido: quién pagó -> entre quiénes se divide ->
    // montos (primero por pagador, después por persona/deudor).
    expect(yQuienPago, lessThan(yEntreQuienes));
    expect(yEntreQuienes, lessThan(yMontoPagador));
    expect(yMontoPagador, lessThan(yMontoPersona));
  });

  testWidgets(
      'con un solo pagador no se pide el monto por pagador (no hace falta '
      'tipearlo)', (tester) async {
    await abrirDialogo(tester);

    // Por defecto paga un solo participante (el organizador): no debería
    // verse la sección de "monto por pagador".
    expect(find.text(l10n.eventDetailAmountPerPayer), findsNothing);
    expect(find.text(l10n.eventDetailAmountPerPerson), findsOneWidget);
  });

  testWidgets(
      'con varios pagadores, el monto de cada uno aparece debajo de ambas '
      'secciones de selección, no al lado de cada fila', (tester) async {
    await abrirDialogo(tester);

    // Suma un segundo pagador: ahora sí hace falta el monto de cada uno.
    await tester.tap(find.text('Nacho').first);
    await tester.pumpAndSettle();

    expect(find.text(l10n.eventDetailAmountPerPayer), findsOneWidget);
    // Dos filas de selección ("¿Quién pagó?" y "¿Entre quiénes se
    // divide?", donde Nacho ya está seleccionado por default) + una fila
    // en "Monto por pagador" + una fila en "Monto por persona" (deudor,
    // seleccionado por default también).
    expect(find.text('Nacho'), findsNWidgets(4));
  });

  testWidgets('completar los montos arma el gasto con los aportes correctos',
      (tester) async {
    DatosGasto? resultado;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () async {
                resultado = await pedirDatosGasto(ctx, participantes);
              },
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Asado');
    // El segundo TextField es el monto total. Un valor de 3 cifras evita el
    // separador de miles que inserta el formatter de dinero (no relacionado
    // con este item — D1 es sobre el orden del layout, no sobre el
    // formateo de montos).
    await tester.enterText(find.byType(TextField).at(1), '500');
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.commonAdd));
    await tester.pumpAndSettle();

    expect(resultado, isNotNull);
    expect(resultado!.descripcion, 'Asado');
    expect(resultado!.montoTotal, '500.00');
    expect(resultado!.acreedores.single.participanteId, 'p1');
    expect(resultado!.acreedores.single.monto, '500.00');
  });
}
