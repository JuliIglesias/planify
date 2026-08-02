import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/models/models.dart';
import 'package:planify/features/events/widgets/expense_dialog.dart';
import 'package:planify/l10n/generated/app_localizations.dart';

/// Pantalla mínima con un botón que abre el diálogo de gasto y guarda el
/// resultado, para poder verificar qué devuelve (FR7).
class _Host extends StatelessWidget {
  const _Host({required this.participantes, required this.onResult});
  final List<Participante> participantes;
  final ValueChanged<DatosGasto?> onResult;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            onResult(await pedirDatosGasto(context, participantes));
          },
          child: const Text('abrir'),
        ),
      ),
    );
  }
}

Widget _app(Widget child) => MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );

void main() {
  const participantes = [
    Participante(id: 'p1', nombreDisplay: 'Marcos', esOrganizador: true),
    Participante(id: 'p2', nombreDisplay: 'Sofía', esAnonimo: true),
  ];

  // La hoja es alta: se agranda la ventana para que el ListView construya todo.
  void agrandar(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  testWidgets('un solo pagador: su aporte es el total y se divide entre los marcados (FR7)',
      (tester) async {
    agrandar(tester);
    DatosGasto? resultado;
    await tester.pumpWidget(
      _app(_Host(participantes: participantes, onResult: (r) => resultado = r)),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, '¿Qué compraste?'), 'Carne');
    await tester.enterText(find.widgetWithText(TextField, 'Monto'), '4500');

    // Marca a Marcos como pagador (primer checkbox 'Marcos' = sección pagadores).
    await tester.tap(find.widgetWithText(CheckboxListTile, 'Marcos').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Agregar'));
    await tester.pumpAndSettle();

    final datos = resultado!;
    expect(datos.descripcion, 'Carne');
    expect(datos.monto, '4500.00');
    expect(datos.acreedores, hasLength(1));
    expect(datos.acreedores.first.participanteId, 'p1');
    expect(datos.acreedores.first.monto, '4500.00');
    // Por defecto se divide entre todos los participantes.
    expect(datos.dividirEntre.toSet(), {'p1', 'p2'});
  });

  testWidgets('varios pagadores: "Partes iguales" reparte el total y valida la suma (FR7)',
      (tester) async {
    agrandar(tester);
    DatosGasto? resultado;
    await tester.pumpWidget(
      _app(_Host(participantes: participantes, onResult: (r) => resultado = r)),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, '¿Qué compraste?'), 'Bebidas');
    await tester.enterText(find.widgetWithText(TextField, 'Monto'), '1000');

    // Ambos pagan: se marcan los dos checkboxes de la sección de pagadores.
    await tester.tap(find.widgetWithText(CheckboxListTile, 'Marcos').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(CheckboxListTile, 'Sofía').first);
    await tester.pumpAndSettle();

    // Reparte en partes iguales: 500 y 500.
    await tester.tap(find.text('Partes iguales'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Agregar'));
    await tester.pumpAndSettle();

    final datos = resultado!;
    expect(datos.acreedores, hasLength(2));
    final montos = datos.acreedores.map((a) => a.monto).toList()..sort();
    expect(montos, ['500.00', '500.00']);
  });
}
