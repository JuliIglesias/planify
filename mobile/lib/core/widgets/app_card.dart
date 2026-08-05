import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Contenedor blanco genérico (no-evento) — docs/06-design-system.md §6.1.
/// Reemplaza los `Container`/`Card` ad-hoc con `AppColors.surface` + radio +
/// padding a mano repetidos en Perfil, hoja de detalle de persona y
/// configuración de evento.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(AppSpacing.cardRadius);

    return Material(
      color: colorScheme.surface,
      borderRadius: borderRadius,
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
