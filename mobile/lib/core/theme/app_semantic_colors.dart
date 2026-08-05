import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Colores semánticos de producto que Material 3 no modela como roles
/// nativos de `ColorScheme` (success/warning no existen; el "debo"
/// financiero es un tercer rojo distinto del `error` de formularios) —
/// docs/06-design-system.md §3.6.
///
/// Se registran como `ThemeExtension` en vez de constantes sueltas para que
/// sigan viviendo "dentro" del tema central — ver [AppSemanticColorsX] más
/// abajo para el atajo de acceso — en vez de importar `AppColors` directo
/// widget por widget.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.onWarning,
    required this.danger,
    required this.onDanger,
  });

  /// Estado "a favor" / saldado — docs/06-design-system.md §3.6.
  final Color success;
  final Color onSuccess;

  /// Estado "pendiente".
  final Color warning;
  final Color onWarning;

  /// Estado financiero negativo ("debo"/"pagar" en Balances/Historial).
  /// Deliberadamente distinto del `colorScheme.error` de formularios
  /// (confirmado con el usuario — docs/06-design-system.md §3.6).
  final Color danger;
  final Color onDanger;

  static const light = AppSemanticColors(
    success: AppColors.success,
    onSuccess: Colors.white,
    warning: AppColors.warning,
    onWarning: Colors.white,
    danger: AppColors.danger,
    onDanger: Colors.white,
  );

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? warning,
    Color? onWarning,
    Color? danger,
    Color? onDanger,
  }) {
    return AppSemanticColors(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      danger: danger ?? this.danger,
      onDanger: onDanger ?? this.onDanger,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      onDanger: Color.lerp(onDanger, other.onDanger, t)!,
    );
  }
}

/// Atajo — `context.appSemanticColors.success`, etc.
extension AppSemanticColorsX on BuildContext {
  AppSemanticColors get appSemanticColors =>
      Theme.of(this).extension<AppSemanticColors>() ?? AppSemanticColors.light;
}
