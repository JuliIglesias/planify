import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/theme/app_colors.dart';
import 'package:planify/core/widgets/app_scaffold.dart';
import 'package:planify/l10n/generated/app_localizations.dart';

/// Item 1 (Tanda 6) — estilos, textos siempre visibles y bug de layout.
void main() {
  Widget conNavbar(int seleccionado, {ValueChanged<int>? onTap}) {
    return MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        bottomNavigationBar: AppBottomNav(
          currentIndex: seleccionado,
          onTap: onTap ?? (_) {},
        ),
      ),
    );
  }

  testWidgets('los 4 textos están siempre visibles, estén o no seleccionados',
      (tester) async {
    await tester.pumpWidget(conNavbar(0));
    await tester.pumpAndSettle();

    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Grupos'), findsOneWidget);
    expect(find.text('Saldos'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);
  });

  testWidgets(
      'no overfloea en una pantalla angosta (bug de layout original: '
      'Row sin Expanded se cortaba)', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(conNavbar(0));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('el ítem seleccionado usa el azul principal; el resto, celestito',
      (tester) async {
    await tester.pumpWidget(conNavbar(1)); // "Grupos" seleccionado
    await tester.pumpAndSettle();

    final iconoGrupos = tester.widget<Icon>(find.byIcon(Icons.groups));
    expect(iconoGrupos.color, AppColors.primary);

    final iconoInicio = tester.widget<Icon>(find.byIcon(Icons.home_outlined));
    expect(iconoInicio.color, AppColors.inactiveBlue);
  });

  testWidgets('tocar un tab dispara onTap con su índice', (tester) async {
    int? tocado;
    await tester.pumpWidget(conNavbar(0, onTap: (i) => tocado = i));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Saldos'));
    await tester.pumpAndSettle();

    expect(tocado, 2);
  });
}
