import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Estados de saldo que comparten Balances e Historial (docs/02-decisiones.md, Duda #2).
enum SaldoEstado { pagar, pendiente, saldado }

/// Pill de estado. Nunca depende solo del color: siempre lleva texto,
/// por accesibilidad (docs/03-design-system.md §6).
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  factory StatusBadge.saldo(SaldoEstado estado, String label) {
    return StatusBadge(
      label: label,
      color: switch (estado) {
        SaldoEstado.pagar => AppColors.danger,
        SaldoEstado.pendiente => AppColors.warning,
        SaldoEstado.saldado => AppColors.success,
      },
    );
  }

  factory StatusBadge.nuevo(String label) =>
      StatusBadge(label: label, color: AppColors.accent);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs / 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
      ),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
      ),
    );
  }
}
