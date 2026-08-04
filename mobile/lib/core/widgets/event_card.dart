import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'avatar_stack.dart';
import 'status_badge.dart';

class EventCardPill {
  const EventCardPill({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
}

/// Card de evento reutilizada en Home, Groups e Historial
/// (docs/00-ui-entendimiento.md §5 — componente compartido #1).
class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.participantes = const [],
    this.badge,
    this.montoLabel,
    this.monto,
    this.montoColor,
    this.chips = const [],
    this.pills,
    this.width,
    this.topBadge,
    this.trailing,
    this.onTap,
  });

  final String titulo;
  final String? subtitulo;
  final List<String> participantes;
  final Widget? badge;
  final String? montoLabel;
  final String? monto;
  final Color? montoColor;
  final List<String> chips;
  final List<EventCardPill>? pills;
  final double? width;
  final Widget? topBadge;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: width,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (topBadge != null || trailing != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (topBadge != null) topBadge! else const SizedBox(),
                      if (trailing != null) trailing!,
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        titulo,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  if (badge != null) badge!,
                ],
              ),
              if (subtitulo != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitulo!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              if (pills != null && pills!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final pill in pills!)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: pill.backgroundColor,
                          borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              pill.icon,
                              size: 14,
                              color: pill.foregroundColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              pill.label,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: pill.foregroundColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ] else if (chips.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final chip in chips)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
                        ),
                        child: Text(chip, style: theme.textTheme.labelSmall),
                      ),
                  ],
                ),
              ],
              if (participantes.isNotEmpty || monto != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AvatarStack(nombres: participantes),
                    if (monto != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (montoLabel != null)
                            Text(
                              montoLabel!,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          Text(
                            monto!,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: montoColor ?? AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
  }
}

/// Fila de saldo por persona (pantalla Balances).
class BalanceRow extends StatelessWidget {
  const BalanceRow({
    super.key,
    required this.nombre,
    required this.monto,
    required this.estado,
    required this.estadoLabel,
    this.onTap,
  });

  final String nombre;
  final String monto;
  final SaldoEstado estado;
  final String estadoLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (estado) {
      SaldoEstado.pagar => AppColors.danger,
      SaldoEstado.pendiente => AppColors.warning,
      SaldoEstado.saldado => AppColors.success,
    };

    return Card(
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        leading: AvatarStack(nombres: [nombre], radius: 18),
        title: Text(nombre, style: theme.textTheme.titleSmall),
        subtitle: Text(estadoLabel, style: theme.textTheme.bodySmall),
        trailing: Text(
          monto,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}

/// Ítem del feed de actividad (Home "Actividad reciente", Notificaciones y
/// Log del evento). Item 2 (Tanda 6) — clickeable: si se pasa [onTap], rutea
/// al evento específico de esa actividad.
class ActivityFeedItem extends StatelessWidget {
  const ActivityFeedItem({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.titulo,
    this.subtitulo,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String titulo;
  final String? subtitulo;
  final String? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: theme.textTheme.bodyMedium),
                    if (subtitulo != null)
                      Text(
                        subtitulo!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              if (trailing != null)
                Text(
                  trailing!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
