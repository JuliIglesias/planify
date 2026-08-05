import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../../l10n/generated/app_localizations.dart';

/// Item 6 (Tanda 6) — chrome común a Login y Registro: logo + nombre de la
/// app arriba, y una card blanca flotante abajo con el formulario.
///
/// NOTA: el ícono todavía es un placeholder vectorial (`Icons.autorenew`).
/// El asset oficial (`image_aedb4c.png` de la referencia) se pegó en el chat,
/// no en el repo — en cuanto esté en `mobile/assets/logo.png` (con la entrada
/// correspondiente en `pubspec.yaml`), este es el único lugar que hay que
/// tocar para reemplazar el ícono por `Image.asset(...)`.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.card,
    this.footer,
    this.showBackButton = false,
  });

  /// Contenido del formulario (campos + botón principal).
  final Widget card;

  /// Contenido opcional debajo de la card (ej. "¿No tenés cuenta? Crear cuenta").
  final Widget? footer;

  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const _AuthLogo(),
                    const SizedBox(height: AppSpacing.sm),
                    // Color de "Planify": hereda `displaySmall` del tema
                    // (azul oscuro, docs/06-design-system.md §3.4) — ya no
                    // se pisa con `AppColors.primary` a mano.
                    Text(
                      l10n.appName,
                      style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      l10n.appTagline,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: card,
                    ),
                    if (footer != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      footer!,
                    ],
                  ],
                ),
              ),
            ),
            if (showBackButton)
              const Positioned(
                top: AppSpacing.xs,
                left: AppSpacing.xs,
                child: BackButton(color: AppColors.primary),
              ),
          ],
        ),
      ),
    );
  }
}

class _AuthLogo extends StatelessWidget {
  const _AuthLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(Icons.autorenew, color: AppColors.primary, size: 36),
    );
  }
}
