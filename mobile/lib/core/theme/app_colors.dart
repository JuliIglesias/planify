import 'package:flutter/material.dart';

/// Paleta de marca — docs/06-design-system.md §3.
///
/// Estos son los tokens "crudos" (hex de marca + derivados semánticos). El
/// `ColorScheme`/`TextTheme` de [AppTheme] es lo que efectivamente se
/// consulta desde los widgets (`Theme.of(context).colorScheme.xxx`) — esta
/// clase existe para tener un único lugar donde viven los valores hex, y
/// para los tokens semánticos (success/warning/danger) que no tienen rol
/// nativo en `ColorScheme` (ver [AppSemanticColors]).
abstract final class AppColors {
  // --- Los 6 colores de marca (valores exactos, docs/06-design-system.md §3.1) ---
  static const primary = Color(0xFF296CF2); // Azul primario
  static const secondary = Color(0xFF92C2FC); // Azul secundario
  static const lightBlue = Color(0xFFDBEAFE); // Azul claro
  static const background = Color(0xFFECF4FF); // Azul fondo
  static const accent = Color(0xFFFF6B6B); // Rojo/coral (acento)
  static const darkBlue = Color(0xFF3E579C); // Azul oscuro (títulos)

  // --- Derivados de marca (§3.2/§3.5) ---
  static const error = Color(0xFFCC5A5A); // Rojo propio de formularios/errores — distinto del acento
  static const surface = Colors.white;
  static const textPrimary = Color(0xFF14162B); // Texto de cuerpo — SIN cambio (§3.4)
  static const textSecondary = Color(0xFF6B7280); // Texto secundario/caption — SIN cambio
  static const border = lightBlue;

  // --- Semánticos de producto (§3.6) — ver AppSemanticColors para el uso vía tema ---
  static const success = Color(0xFF3FA873);
  static const warning = Color(0xFFE3A94A);
  static const danger = Color(0xFFE74C3C); // "Debo"/"pagar" — distinto de `error` (confirmado con el usuario)
}
