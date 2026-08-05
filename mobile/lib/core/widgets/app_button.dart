import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Jerarquía de énfasis visual — de mayor a menor (docs/guidelines/android-guidelines.md §5).
enum AppButtonVariant {
  /// Acción principal — fondo `primary`, texto blanco. Un solo primario por
  /// pantalla (criterio HIG adoptado — docs/06-design-system.md §1.1).
  primary,

  /// Acción secundaria con énfasis medio — fondo `secondaryContainer`.
  secondary,

  /// Acción secundaria de menor énfasis — borde, sin relleno.
  outlined,

  /// Acción terciaria/de bajo énfasis — sin fondo ni borde.
  text,

  /// Acciones destructivas/irreversibles (eliminar, abandonar, cancelar) —
  /// usa `colorScheme.error`, NO el rojo financiero de "debo"
  /// (docs/06-design-system.md §6.1).
  danger,
}

/// Botón reutilizable de toda la app — docs/06-design-system.md §6.1.
/// Reemplaza los `ElevatedButton`/`FilledButton`/`OutlinedButton`/`TextButton`
/// sueltos, con estilo por `variant` en vez de un `style:` a mano por sitio.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.loading = false,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;

  /// Muestra un spinner en vez del label y deshabilita el botón.
  final bool loading;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final onPressedEfectivo = loading ? null : onPressed;

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
    );
    const minSize = Size.fromHeight(52);

    final child = loading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: _spinnerColor(colorScheme)),
          )
        : icon == null
            ? Text(label)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Text(label),
                ],
              );

    final Widget button = switch (variant) {
      AppButtonVariant.primary => ElevatedButton(
          onPressed: onPressedEfectivo,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            minimumSize: minSize,
            shape: shape,
          ),
          child: child,
        ),
      AppButtonVariant.secondary => ElevatedButton(
          onPressed: onPressedEfectivo,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.secondaryContainer,
            foregroundColor: colorScheme.onSecondaryContainer,
            elevation: 0,
            minimumSize: minSize,
            shape: shape,
          ),
          child: child,
        ),
      AppButtonVariant.outlined => OutlinedButton(
          onPressed: onPressedEfectivo,
          style: OutlinedButton.styleFrom(
            foregroundColor: colorScheme.primary,
            side: BorderSide(color: colorScheme.primary),
            minimumSize: minSize,
            shape: shape,
          ),
          child: child,
        ),
      AppButtonVariant.text => TextButton(
          onPressed: onPressedEfectivo,
          style: TextButton.styleFrom(
            foregroundColor: colorScheme.primary,
            minimumSize: minSize,
            shape: shape,
          ),
          child: child,
        ),
      AppButtonVariant.danger => ElevatedButton(
          onPressed: onPressedEfectivo,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
            minimumSize: minSize,
            shape: shape,
          ),
          child: child,
        ),
    };

    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }

  Color _spinnerColor(ColorScheme colorScheme) => switch (variant) {
        AppButtonVariant.primary => colorScheme.onPrimary,
        AppButtonVariant.secondary => colorScheme.onSecondaryContainer,
        AppButtonVariant.outlined || AppButtonVariant.text => colorScheme.primary,
        AppButtonVariant.danger => colorScheme.onError,
      };
}
