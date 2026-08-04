import 'package:flutter/material.dart';

/// Tokens de color de docs/03-design-system.md.
/// Valores aproximados por lectura visual de las capturas de Figma — ajustar
/// cuando se pueda inspeccionar el archivo real con el MCP de Figma.
abstract final class AppColors {
  static const primary = Color(0xFF2A3EFF);
  static const primaryDark = Color(0xFF1A2BD1);
  static const accent = Color(0xFFFF6B5B);

  /// "Celestito" — ítems no seleccionados de la Navbar y del toggle
  /// Todo/Me deben/Debo (Tanda 6, Items 1 y 4). Mismo tono en ambos
  /// componentes para que compartan una sola línea visual.
  static const inactiveBlue = Color(0xFFA6B6EF);

  static const success = Color(0xFF2ECC71);
  static const danger = Color(0xFFE74C3C);
  static const warning = Color(0xFFF5A623);

  static const background = Color(0xFFF5F7FF);
  static const surface = Color(0xFFFFFFFF);

  static const textPrimary = Color(0xFF14162B);
  static const textSecondary = Color(0xFF6B7280);
  static const border = Color(0xFFE5E7F0);
}
