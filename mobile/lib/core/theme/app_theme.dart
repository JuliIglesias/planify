import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_semantic_colors.dart';
import 'app_spacing.dart';

/// Tema base de Planify — docs/06-design-system.md.
abstract final class AppTheme {
  /// Tinte claro de un color base hacia blanco — misma técnica que usan las
  /// paletas tonales de Material para derivar un "container" a partir de un
  /// color semilla (docs/06-design-system.md §3.3). Se usa para
  /// `tertiaryContainer`/`errorContainer`, que no tienen un hex de marca
  /// propio.
  static Color _lightContainerOf(Color base) => Color.lerp(base, Colors.white, 0.85)!;

  /// Tono oscuro de un color base — el "on-container" que acompaña al tinte
  /// de arriba.
  static Color _darkOnContainerOf(Color base) => Color.lerp(base, Colors.black, 0.35)!;

  static ThemeData get light {
    final tertiaryContainer = _lightContainerOf(AppColors.accent);
    final onTertiaryContainer = _darkOnContainerOf(AppColors.accent);
    final errorContainer = _lightContainerOf(AppColors.error);
    final onErrorContainer = _darkOnContainerOf(AppColors.error);

    final colorScheme = ColorScheme(
      brightness: Brightness.light,

      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.lightBlue,
      onPrimaryContainer: AppColors.darkBlue,

      // Uso principal de `secondary`: COMO contenido (ícono/texto) sobre
      // blanco — no como fondo relleno (docs/06-design-system.md §3.4b).
      // `onSecondary`/`onSecondaryContainer` cubren el caso raro en el que
      // sí se usa como fondo: nunca blanco sobre este celeste tan claro.
      secondary: AppColors.secondary,
      onSecondary: AppColors.darkBlue,
      secondaryContainer: AppColors.background,
      onSecondaryContainer: AppColors.darkBlue,

      // Acento puro — FAB, badges "nuevo". Sin relación con `error` (§3.5).
      tertiary: AppColors.accent,
      onTertiary: Colors.white,
      tertiaryContainer: tertiaryContainer,
      onTertiaryContainer: onTertiaryContainer,

      // Rojo propio de formularios/validación — menos vívido que el acento,
      // y distinto del rojo financiero "debo" (`AppSemanticColors.danger`).
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: errorContainer,
      onErrorContainer: onErrorContainer,

      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.lightBlue,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.lightBlue,
    );

    final base = ThemeData(useMaterial3: true, colorScheme: colorScheme);

    // Título vs. cuerpo (docs/06-design-system.md §3.4): los tiers de
    // "título" (display/headline/title) usan el azul oscuro de marca; los
    // de "cuerpo" (body/label) se quedan en el gris-casi-negro de siempre.
    // Un solo ColorScheme, dos comportamientos según el rol tipográfico.
    final rawTextTheme = GoogleFonts.poppinsTextTheme(base.textTheme);
    final textTheme = rawTextTheme.copyWith(
      displayLarge: rawTextTheme.displayLarge?.copyWith(color: colorScheme.onPrimaryContainer),
      displayMedium: rawTextTheme.displayMedium?.copyWith(color: colorScheme.onPrimaryContainer),
      displaySmall: rawTextTheme.displaySmall?.copyWith(color: colorScheme.onPrimaryContainer),
      headlineLarge: rawTextTheme.headlineLarge?.copyWith(color: colorScheme.onPrimaryContainer),
      headlineMedium: rawTextTheme.headlineMedium?.copyWith(color: colorScheme.onPrimaryContainer),
      headlineSmall: rawTextTheme.headlineSmall?.copyWith(color: colorScheme.onPrimaryContainer),
      titleLarge: rawTextTheme.titleLarge?.copyWith(color: colorScheme.onPrimaryContainer),
      titleMedium: rawTextTheme.titleMedium?.copyWith(color: colorScheme.onPrimaryContainer),
      titleSmall: rawTextTheme.titleSmall?.copyWith(color: colorScheme.onPrimaryContainer),
      bodyLarge: rawTextTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
      bodyMedium: rawTextTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
      bodySmall: rawTextTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
      labelLarge: rawTextTheme.labelLarge?.copyWith(color: colorScheme.onSurface),
      labelMedium: rawTextTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant),
      labelSmall: rawTextTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
    );

    return base.copyWith(
      // NO se define `pageTransitionsTheme` — Flutter ya mapea iOS a
      // `CupertinoPageTransitionsBuilder` (swipe-back nativo) por default;
      // pisarlo acá lo rompería (docs/06-design-system.md §1.2).
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,
      extensions: const [AppSemanticColors.light],
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 1,
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.tertiary,
        foregroundColor: colorScheme.onTertiary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: const EdgeInsets.all(AppSpacing.md),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
      ),
    );
  }
}
