import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/models.dart';
import '../../core/network/planify_api.dart';

final upcomingEventsProvider = FutureProvider<List<EventoResumen>>(
  (ref) => ref.watch(planifyApiProvider).upcomingEvents(),
);

final groupsOverviewProvider = FutureProvider<List<GrupoResumen>>(
  (ref) => ref.watch(planifyApiProvider).groupsOverview(),
);

final balanceProvider = FutureProvider<Balance>(
  (ref) => ref.watch(planifyApiProvider).myBalance(),
);

final historyProvider = FutureProvider<List<EventoHistorial>>(
  (ref) => ref.watch(planifyApiProvider).history(),
);

final eventDetailProvider = FutureProvider.family<Map<String, dynamic>, String>(
  (ref, eventoId) => ref.watch(planifyApiProvider).eventDetail(eventoId),
);

final eventTasksProvider = FutureProvider.family<List<Tarea>, String>(
  (ref, eventoId) => ref.watch(planifyApiProvider).tasks(eventoId),
);

final eventActivityProvider = FutureProvider.family<List<ActividadLog>, String>(
  (ref, eventoId) => ref.watch(planifyApiProvider).activityLog(eventoId),
);

final eventHeatmapProvider = FutureProvider.family<List<HeatmapSlot>, String>(
  (ref, eventoId) => ref.watch(planifyApiProvider).heatmap(eventoId),
);

/// Refresca todo lo que depende del estado del servidor. Se llama después de
/// cualquier acción que modifique datos (crear gasto, tomar tarea, etc.).
/// Toma WidgetRef porque se invoca desde las pantallas.
void invalidateEventData(WidgetRef ref, String eventoId) {
  ref.invalidate(eventDetailProvider(eventoId));
  ref.invalidate(eventTasksProvider(eventoId));
  ref.invalidate(eventActivityProvider(eventoId));
  ref.invalidate(eventHeatmapProvider(eventoId));
  ref.invalidate(upcomingEventsProvider);
  ref.invalidate(groupsOverviewProvider);
  ref.invalidate(balanceProvider);
}
