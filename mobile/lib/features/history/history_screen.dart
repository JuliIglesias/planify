import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/models/models.dart';
import '../../core/theme/app_colors.dart';
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
        backgroundColor: AppColors.surface,
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
            children: [
              for (final entry in porMes.entries) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Text(
                    entry.key.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.6,
                        ),
                  ),
                ),
                for (final evento in entry.value) _HistorialCard(evento: evento),
              ],
            ],
          );
        },
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
        SaldoEstado.pagar => AppColors.danger,
        SaldoEstado.pendiente => AppColors.warning,
        SaldoEstado.saldado => AppColors.success,
      },
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => EventDetailScreen(eventoId: evento.id),
        ),
      ),
    );
  }
}
