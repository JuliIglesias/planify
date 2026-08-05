import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/models/models.dart';
import '../../core/theme/app_semantic_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/money_format.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/event_card.dart';
import '../../core/widgets/status_badge.dart';
import '../../l10n/generated/app_localizations.dart';
import '../events/event_detail_screen.dart';
import '../home/home_providers.dart';

/// Historial — eventos pasados agrupados por mes, con estado de saldo
/// (mockup "Historial"). Usa los mismos 3 estados que Balances (Duda #2).
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final historial = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.historyTitle),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: historial.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => AsyncStateView(
          icon: Icons.cloud_off,
          mensaje: l10n.commonError,
          detalle: l10n.commonErrorHint,
        ),
        data: (eventos) {
          if (eventos.isEmpty) {
            return AsyncStateView(
              icon: Icons.history,
              mensaje: l10n.historyEmpty,
            );
          }

          final porMes = <String, List<EventoHistorial>>{};
          for (final evento in eventos) {
            final clave = DateFormat('MMMM yyyy', 'es').format(evento.fechaOrdenamiento);
            porMes.putIfAbsent(clave, () => []).add(evento);
          }

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            // Item 3 (Tanda 6) — cada mes es un tramo de la línea de tiempo:
            // el punto de "_TimelineRail" queda a la altura de su propio
            // encabezado, y la barra vertical se extiende exactamente hasta
            // el final de las cards de ESE mes (IntrinsicHeight). Como los
            // tramos van pegados uno debajo del otro, la barra se ve
            // continua a lo largo de toda la lista.
            children: [
              for (final entry in porMes.entries)
                _TimelineRail(
                  mes: entry.key,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final evento in entry.value) _HistorialCard(evento: evento),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Item 3 (Tanda 6) — guía visual de la línea de tiempo: un punto por mes
/// sobre una barra vertical continua, para agrupar los eventos del
/// historial de un vistazo (antes era una lista plana sin esa jerarquía).
class _TimelineRail extends StatelessWidget {
  const _TimelineRail({required this.mes, required this.child});

  final String mes;
  final Widget child;

  static const _diametroPunto = 14.0;
  static const _anchoBarra = 2.0;
  static const _anchoRiel = 24.0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: _anchoRiel,
            child: Column(
              children: [
                // Centrado con la línea base del encabezado del mes.
                const SizedBox(height: 6),
                Container(
                  width: _diametroPunto,
                  height: _diametroPunto,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: colorScheme.primary),
                ),
                Expanded(
                  child: Center(
                    child: Container(width: _anchoBarra, color: colorScheme.outline),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  // Item 3 — antes labelSmall (11sp): muy chico para el
                  // encabezado principal de cada grupo. titleMedium/bold es
                  // la misma jerarquía que usan los encabezados de sección
                  // de Home ("Próximos eventos", "Actividad reciente") —
                  // ya no se pisa el color a mano, hereda el azul oscuro
                  // del tema igual que esos (docs/06-design-system.md §3.4).
                  child: Text(
                    mes.toUpperCase(),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistorialCard extends StatelessWidget {
  const _HistorialCard({required this.evento});

  final EventoHistorial evento;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final estado = switch (evento.estadoSaldo) {
      'pagar' => SaldoEstado.pagar,
      'pendiente' => SaldoEstado.pendiente,
      _ => SaldoEstado.saldado,
    };

    final estadoLabel = switch (estado) {
      SaldoEstado.pagar => l10n.balancesStatePay,
      SaldoEstado.pendiente => l10n.balancesStatePending,
      SaldoEstado.saldado => l10n.balancesStateSettled,
    };

    return EventCard(
      titulo: evento.nombre,
      subtitulo: DateFormat("EEEE, d 'de' MMMM", 'es').format(evento.fechaOrdenamiento),
      participantes: evento.participantes,
      badge: StatusBadge.saldo(estado, estadoLabel),
      montoLabel: estado == SaldoEstado.pagar ? l10n.historyToPay : l10n.historyYourShare,
      monto: '\$${MoneyFormat.format(evento.monto)}',
      montoColor: switch (estado) {
        SaldoEstado.pagar => context.appSemanticColors.danger,
        SaldoEstado.pendiente => context.appSemanticColors.warning,
        SaldoEstado.saldado => context.appSemanticColors.success,
      },
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => EventDetailScreen(eventoId: evento.id),
        ),
      ),
    );
  }
}
