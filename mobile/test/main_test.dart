import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/network/token_storage.dart';
import 'package:planify/features/auth/data/auth_repository.dart';
import 'package:planify/features/auth/pending_invitation_provider.dart';
import 'package:planify/features/auth/session_controller.dart';
import 'package:planify/features/balances/data/balances_repository.dart';
import 'package:planify/features/events/data/activity_log_repository.dart';
import 'package:planify/features/events/data/availability_repository.dart';
import 'package:planify/features/events/data/events_repository.dart';
import 'package:planify/features/events/data/expenses_repository.dart';
import 'package:planify/features/events/data/tasks_repository.dart';
import 'package:planify/features/groups/data/groups_repository.dart';
import 'package:planify/main.dart';

import 'helpers/fake_repositories.dart';
import 'helpers/fake_token_storage.dart';
import 'helpers/test_app.dart';

/// _RootRouter (dentro de main.dart) escucha los deep links durante toda la
/// vida de la app y aplica la invitación pendiente en cuanto hay sesión — el
/// bug de Item 2 era que eso solo pasaba adentro de LoginScreen.
void main() {
  setUpAll(() async {
    await prepararLocalizaciones();
  });

  testWidgets(
      'con sesión de organizador ya iniciada, una invitación pendiente se '
      'aplica sola, sin pedir nada (Item 2)', (tester) async {
    final auth = FakeAuthRepository();
    final container = ProviderContainer(
      overrides: [
        tokenStorageProvider.overrideWithValue(FakeTokenStorage()),
        authRepositoryProvider.overrideWithValue(auth),
        eventsRepositoryProvider.overrideWithValue(FakeEventsRepository()),
        availabilityRepositoryProvider.overrideWithValue(FakeAvailabilityRepository()),
        tasksRepositoryProvider.overrideWithValue(FakeTasksRepository()),
        expensesRepositoryProvider.overrideWithValue(FakeExpensesRepository()),
        activityLogRepositoryProvider.overrideWithValue(FakeActivityLogRepository()),
        balancesRepositoryProvider.overrideWithValue(FakeBalancesRepository()),
        groupsRepositoryProvider.overrideWithValue(FakeGroupsRepository()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const PlanifyApp()),
    );
    await tester.pumpAndSettle();

    // Sesión de organizador ya activa (equivalente a "ya tiene sesión
    // iniciada en el dispositivo").
    await container.read(sessionControllerProvider.notifier).loginOrganizador(
          'organizador@planify.test',
          'planify-mvp-2026',
        );
    await tester.pumpAndSettle();

    // Llega el link de invitación mientras la app ya está en uso.
    container.read(pendingInvitationProvider.notifier).set('tok-abc');
    await tester.pumpAndSettle();

    // Se aplicó sola, sin diálogos ni pasos intermedios.
    expect(auth.llamadas, contains('unirseConInvitacion:tok-abc'));
    expect(container.read(pendingInvitationProvider), isNull);
    expect(find.byType(AlertDialog), findsNothing);
  });
}
