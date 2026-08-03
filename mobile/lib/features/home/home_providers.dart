import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/models.dart';
import '../balances/data/balances_repository.dart';
import '../events/data/activity_log_repository.dart';
import '../events/data/availability_repository.dart';
import '../events/data/events_repository.dart';
import '../events/data/tasks_repository.dart';
import '../groups/data/groups_repository.dart';

/// Providers de lectura. Cada uno depende de un repositorio (interfaz), así que
/// los tests los sirven con implementaciones falsas sin tocar la red.

final upcomingEventsProvider = FutureProvider<List<EventoResumen>>(
  (ref) => ref.watch(eventsRepositoryProvider).proximos(),
);

final historyProvider = FutureProvider<List<EventoHistorial>>(
  (ref) => ref.watch(eventsRepositoryProvider).historial(),
);

final groupsOverviewProvider = FutureProvider<List<GrupoResumen>>(
  (ref) => ref.watch(groupsRepositoryProvider).resumen(),
);

final balanceProvider = FutureProvider<Balance>(
  (ref) => ref.watch(balancesRepositoryProvider).miBalance(),
);

final eventDetailProvider = FutureProvider.family<DetalleEvento, String>(
  (ref, eventoId) => ref.watch(eventsRepositoryProvider).detalle(eventoId),
);

final eventTasksProvider = FutureProvider.family<List<Tarea>, String>(
  (ref, eventoId) => ref.watch(tasksRepositoryProvider).listar(eventoId),
);

final eventActivityProvider = FutureProvider.family<List<ActividadLog>, String>(
  (ref, eventoId) => ref.watch(activityLogRepositoryProvider).listar(eventoId),
);

/// Feed de "Actividad reciente" de Home (mockup de Figma).
final recentActivityProvider = FutureProvider<List<ActividadLog>>(
  (ref) => ref.watch(activityLogRepositoryProvider).recientes(),
);

/// Total de actividad sin leer (para el badge de la campana — H-17).
final unreadTotalProvider = FutureProvider<int>((ref) async {
  final porEvento = await ref.watch(activityLogRepositoryProvider).noLeidas();
  return porEvento.values.fold<int>(0, (acc, n) => acc + n);
});

final eventHeatmapProvider = FutureProvider.family<List<HeatmapSlot>, String>(
  (ref, eventoId) => ref.watch(availabilityRepositoryProvider).heatmap(eventoId),
);

final eventDebtsProvider = FutureProvider.family<List<DeudaEvento>, String>(
  (ref, eventoId) => ref.watch(balancesRepositoryProvider).deudasDelEvento(eventoId),
);

/// Refresca todo lo que pudo cambiar tras una acción sobre el evento.
/// Está centralizado para que agregar una pantalla nueva no implique buscar
/// todos los lugares donde hay que invalidar.
void invalidateEventData(WidgetRef ref, String eventoId) {
  ref.invalidate(eventDetailProvider(eventoId));
  ref.invalidate(eventTasksProvider(eventoId));
  ref.invalidate(eventActivityProvider(eventoId));
  ref.invalidate(eventHeatmapProvider(eventoId));
  ref.invalidate(eventDebtsProvider(eventoId));
  ref.invalidate(upcomingEventsProvider);
  ref.invalidate(groupsOverviewProvider);
  ref.invalidate(balanceProvider);
  ref.invalidate(historyProvider);
  ref.invalidate(recentActivityProvider);
  ref.invalidate(unreadTotalProvider);
}

/// Refresca los listados de nivel raíz (Home, Groups, Balances, Historial).
void invalidateListas(WidgetRef ref) {
  ref.invalidate(upcomingEventsProvider);
  ref.invalidate(groupsOverviewProvider);
  ref.invalidate(balanceProvider);
  ref.invalidate(historyProvider);
  ref.invalidate(recentActivityProvider);
  ref.invalidate(unreadTotalProvider);
}
