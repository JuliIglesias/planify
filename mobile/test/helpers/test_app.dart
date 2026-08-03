import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:planify/core/network/token_storage.dart';
import 'package:planify/core/theme/app_theme.dart';
import 'package:planify/features/auth/data/auth_repository.dart';
import 'package:planify/features/auth/pending_invitation_provider.dart';
import 'package:planify/features/balances/data/balances_repository.dart';
import 'package:planify/features/events/data/activity_log_repository.dart';
import 'package:planify/features/events/data/availability_repository.dart';
import 'package:planify/features/events/data/events_repository.dart';
import 'package:planify/features/events/data/expenses_repository.dart';
import 'package:planify/features/events/data/tasks_repository.dart';
import 'package:planify/features/groups/data/groups_repository.dart';
import 'package:planify/l10n/generated/app_localizations.dart';

import 'fake_repositories.dart';
import 'fake_token_storage.dart';

class _PendingInvitationSemilla extends PendingInvitation {
  _PendingInvitationSemilla(this._semilla);
  final String? _semilla;

  @override
  String? build() => _semilla;
}

/// Envuelve una pantalla con todo lo que necesita para renderizar en un test,
/// sustituyendo cada repositorio por su versión falsa.
///
/// Es el equivalente del `test-container.ts` del backend: mismo cableado que
/// producción, pero sin red.
Widget appDePrueba(
  Widget pantalla, {
  AuthRepository? auth,
  EventsRepository? events,
  AvailabilityRepository? availability,
  TasksRepository? tasks,
  ExpensesRepository? expenses,
  ActivityLogRepository? activityLog,
  BalancesRepository? balances,
  GroupsRepository? groups,
  String? pendingInvitation,
  FakeTokenStorage? tokenStorage,
}) {
  return ProviderScope(
    overrides: [
      tokenStorageProvider.overrideWithValue(tokenStorage ?? FakeTokenStorage()),
      authRepositoryProvider.overrideWithValue(auth ?? FakeAuthRepository()),
      eventsRepositoryProvider.overrideWithValue(events ?? FakeEventsRepository()),
      availabilityRepositoryProvider
          .overrideWithValue(availability ?? FakeAvailabilityRepository()),
      tasksRepositoryProvider.overrideWithValue(tasks ?? FakeTasksRepository()),
      expensesRepositoryProvider.overrideWithValue(expenses ?? FakeExpensesRepository()),
      activityLogRepositoryProvider
          .overrideWithValue(activityLog ?? FakeActivityLogRepository()),
      balancesRepositoryProvider.overrideWithValue(balances ?? FakeBalancesRepository()),
      groupsRepositoryProvider.overrideWithValue(groups ?? FakeGroupsRepository()),
      if (pendingInvitation != null)
        pendingInvitationProvider
            .overrideWith(() => _PendingInvitationSemilla(pendingInvitation)),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('es'),
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      // Las pantallas raíz (Home/Groups/Balances/Profile) dependen de vivir
      // dentro de un Scaffold+Material real (así las monta AppShell en
      // producción); sin esto, widgets como ListTile fallan con "No Material
      // widget found" al testearlas sueltas.
      home: Scaffold(body: SafeArea(child: pantalla)),
    ),
  );
}

/// Los textos en español usan `DateFormat` con locale, que necesita esta
/// inicialización o los tests fallan con LocaleDataException.
Future<AppLocalizations> prepararLocalizaciones() async {
  await initializeDateFormatting('es');
  return AppLocalizations.delegate.load(const Locale('es'));
}

/// Agranda la ventana de prueba.
///
/// Por defecto mide 800x600 y las pantallas largas usan `ListView`, que
/// construye de forma perezosa: sin esto, todo lo que queda debajo del pliegue
/// simplemente no existe en el árbol y `find.text` no lo encuentra.
void usarPantallaAlta(WidgetTester tester, {double alto = 3000}) {
  tester.view.physicalSize = Size(1000, alto);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
