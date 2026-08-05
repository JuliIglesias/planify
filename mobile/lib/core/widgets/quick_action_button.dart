import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'app_icon_badge.dart';

/// Botón de "Acciones rápidas" dentro de un evento (mockup "Log de Actividad").
/// Ícono en círculo pastel + label, como el resto de la iconografía
/// (docs/06-design-system.md §5). El círculo reusa [AppIconBadge]
/// (docs/06-design-system.md §6.2 — antes era una copia del mismo patrón
/// que `ActivityFeedItem`).
class QuickActionButton extends StatelessWidget {
  const QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final habilitado = onPressed != null;

    return Semantics(
      button: true,
      enabled: habilitado,
      label: label,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIconBadge(
                icon: icon,
                color: habilitado ? color : AppColors.textSecondary,
                size: 44,
                iconSize: 22,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: habilitado ? AppColors.textPrimary : AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
