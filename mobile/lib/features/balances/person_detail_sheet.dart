import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/models.dart';
import '../../core/theme/app_semantic_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/money_format.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/avatar_stack.dart';
import '../../core/widgets/status_badge.dart';
import '../../l10n/generated/app_localizations.dart';
import '../events/event_detail_screen.dart';
import '../home/home_providers.dart';
import 'data/balances_repository.dart';

/// FR9 — detalle de la relación con una persona, desde la pantalla Balances.
///
/// Muestra el desglose por evento y el neto ya compensado. Saldar desde acá
/// cierra las deudas de **todos** los eventos con esa persona ([Duda #26]).
/// Dentro de un evento, en cambio, se opera solo sobre las deudas de ese evento.
Future<void> mostrarDetalleConPersona(BuildContext context, String personaId) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _DetallePersonaSheet(personaId: personaId),
  );
}

final _detalleProvider = FutureProvider.family<DetalleConPersona, String>(
  (ref, personaId) => ref.watch(balancesRepositoryProvider).detalleConPersona(personaId),
);

class _DetallePersonaSheet extends ConsumerStatefulWidget {
  const _DetallePersonaSheet({required this.personaId});

  final String personaId;

  @override
  ConsumerState<_DetallePersonaSheet> createState() => _DetallePersonaSheetState();
}

class _DetallePersonaSheetState extends ConsumerState<_DetallePersonaSheet> {
  bool _saldando = false;

  Future<void> _saldarTodo(DetalleConPersona detalle) async {
    final l10n = AppLocalizations.of(context)!;

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AppDialog(
        title: Text(l10n.balancesSettleAll),
        content: Text(
          detalle.deudas.length > 1
              ? l10n.balancesSettleAllConfirmMulti(detalle.username, detalle.deudas.length)
              : l10n.balancesSettleAllConfirm(detalle.username),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.commonConfirm),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    setState(() => _saldando = true);
    try {
      await ref.read(balancesRepositoryProvider).saldarConPersona(widget.personaId);
      if (!mounted) return;
      invalidateListas(ref);
      Navigator.pop(context);
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$err')));
        setState(() => _saldando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final detalle = ref.watch(_detalleProvider(widget.personaId));

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: detalle.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (err, _) => Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text('$err'),
          ),
          data: (d) => _Contenido(
            detalle: d,
            saldando: _saldando,
            onSaldarTodo: () => _saldarTodo(d),
          ),
        ),
      ),
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido({
    required this.detalle,
    required this.saldando,
    required this.onSaldarTodo,
  });

  final DetalleConPersona detalle;
  final bool saldando;
  final VoidCallback onSaldarTodo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantic = context.appSemanticColors;

    final estado = switch (detalle.estado) {
      'pagar' => SaldoEstado.pagar,
      'pendiente' => SaldoEstado.pendiente,
      _ => SaldoEstado.saldado,
    };
    final color = switch (estado) {
      SaldoEstado.pagar => semantic.danger,
      SaldoEstado.pendiente => semantic.warning,
      SaldoEstado.saldado => semantic.success,
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Encabezado: persona y neto compensado ──────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: Column(
            children: [
              AvatarStack(nombres: [detalle.username], radius: 28),
              const SizedBox(height: AppSpacing.sm),
              Text(
                detalle.username,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.xs),
              // `bodySmall` ya usa el gris secundario del tema.
              Text(
                detalle.estaSaldado
                    ? l10n.balancesStateSettled
                    : estado == SaldoEstado.pagar
                        ? l10n.balancesYouOwe
                        : l10n.balancesOweYou,
                style: theme.textTheme.bodySmall,
              ),
              Text(
                '\$${MoneyFormat.format(detalle.monto)}',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),

              // Solo tiene sentido explicar la cuenta si hubo compensación.
              if (detalle.hayCompensacion) ...[
                const SizedBox(height: AppSpacing.sm),
                // Mismo par primaryContainer/onPrimaryContainer que el
                // banner de invitación pendiente de Login (superficie
                // tintada de marca, docs/06-design-system.md §3.3).
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.swap_horiz, size: 16, color: colorScheme.onPrimaryContainer),
                      const SizedBox(width: AppSpacing.xs),
                      Flexible(
                        child: Text(
                          l10n.balancesCompensationHint(
                            MoneyFormat.format(detalle.totalQueDebo),
                            MoneyFormat.format(detalle.totalQueMeDebe),
                          ),
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        const Divider(height: 1),

        // ── Desglose por evento ────────────────────────────────────────────
        Flexible(
          child: detalle.deudas.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    l10n.balancesNoDebtsWith(detalle.username),
                    style: theme.textTheme.bodyMedium,
                  ),
                )
              : ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.xs,
                        AppSpacing.md,
                        AppSpacing.sm,
                      ),
                      // `labelSmall` ya usa el gris secundario del tema —
                      // solo hace falta el peso/espaciado extra acá.
                      child: Text(
                        l10n.balancesBreakdown,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    for (final deuda in detalle.deudas)
                      ListTile(
                        dense: true,
                        leading: Icon(
                          deuda.yoDebo ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 18,
                          color: deuda.yoDebo ? semantic.danger : semantic.success,
                        ),
                        title: Text(deuda.eventoNombre),
                        subtitle: Text(
                          deuda.yoDebo ? l10n.balancesYouOwe : l10n.balancesOweYou,
                        ),
                        trailing: Text(
                          '\$${MoneyFormat.format(deuda.monto)}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: deuda.yoDebo ? semantic.danger : semantic.success,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => EventDetailScreen(eventoId: deuda.eventoId),
                            ),
                          );
                        },
                      ),
                  ],
                ),
        ),

        // ── Acción principal ───────────────────────────────────────────────
        if (detalle.deudas.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: AppButton(
              label: l10n.balancesSettleAll,
              icon: Icons.price_check,
              loading: saldando,
              onPressed: saldando ? null : onSaldarTodo,
            ),
          ),
      ],
    );
  }
}
