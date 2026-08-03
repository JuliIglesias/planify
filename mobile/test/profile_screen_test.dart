import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/profile/profile_screen.dart';
import 'package:planify/l10n/generated/app_localizations.dart';

import 'helpers/test_app.dart';

/// Item 3 — la grilla de disponibilidad cubre las 24hs y la sección de
/// Perfil (la única que trae) arranca abierta.
void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await prepararLocalizaciones();
  });

  testWidgets('la disponibilidad semanal cubre 00h a 23h y arranca abierta',
      (tester) async {
    usarPantallaAlta(tester, alto: 4000);

    await tester.pumpWidget(appDePrueba(const ProfileScreen()));
    await tester.pumpAndSettle();

    expect(find.text(l10n.profileWeeklyAvailability), findsOneWidget);
    // No hace falta tocar nada para ver la grilla: arranca expandida.
    expect(find.text('00h'), findsOneWidget);
    expect(find.text('23h'), findsOneWidget);
    // Antes empezaba a las 8h — ya no debería faltar ningún bloque temprano.
    expect(find.text('04h'), findsOneWidget);
  });
}
