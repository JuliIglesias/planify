import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/models.dart';
import '../events/data/activity_log_repository.dart';

/// Item 2 (Tanda 6) — feed paginado de a 20 (mismo tamaño de página que el
/// backend, ver `ActivityLogService`). [hasMore] es `true` mientras la
/// última página traída venga completa: si viniera de a menos, ya no hay
/// nada más viejo para pedir.
class NotificationsFeed {
  const NotificationsFeed({required this.items, required this.hasMore});

  final List<ActividadLog> items;
  final bool hasMore;

  static const _pageSize = 20;

  NotificationsFeed conMasPagina(List<ActividadLog> pagina) => NotificationsFeed(
        items: [...items, ...pagina],
        hasMore: pagina.length >= _pageSize,
      );
}

class NotificationsNotifier extends AsyncNotifier<NotificationsFeed> {
  static const _pageSize = 20;
  bool _cargandoMas = false;

  @override
  Future<NotificationsFeed> build() async {
    final primeraPagina = await ref.watch(activityLogRepositoryProvider).recientes();
    return NotificationsFeed(items: primeraPagina, hasMore: primeraPagina.length >= _pageSize);
  }

  /// Pide la página siguiente y la agrega al final. No hace nada si ya se
  /// está cargando, si no hay más páginas, o si la carga inicial falló.
  Future<void> cargarMas() async {
    final actual = state.value;
    if (actual == null || !actual.hasMore || _cargandoMas) return;
    if (actual.items.isEmpty) return;

    _cargandoMas = true;
    try {
      final cursor = actual.items.last.createdAt;
      final pagina =
          await ref.read(activityLogRepositoryProvider).recientes(before: cursor);
      state = AsyncData(actual.conMasPagina(pagina));
    } finally {
      _cargandoMas = false;
    }
  }
}

final notificationsFeedProvider =
    AsyncNotifierProvider<NotificationsNotifier, NotificationsFeed>(NotificationsNotifier.new);
