import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../../l10n/generated/app_localizations.dart';

/// Header con título + campana, común a las 4 pantallas raíz.
class AppHeader extends StatelessWidget {
  const AppHeader({super.key, required this.titulo, this.subtitulo, this.trailing});

  final String titulo;
  final String? subtitulo;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
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
          trailing ?? const Icon(Icons.notifications_none, color: AppColors.primary),
        ],
      ),
    );
  }
}

/// Bottom nav de 4 tabs (docs/00-ui-entendimiento.md §1).
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      backgroundColor: AppColors.surface,
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home),
          label: l10n.navHome,
        ),
        NavigationDestination(
          icon: const Icon(Icons.groups_outlined),
          selectedIcon: const Icon(Icons.groups),
          label: l10n.navGroups,
        ),
        NavigationDestination(
          icon: const Icon(Icons.account_balance_wallet_outlined),
          selectedIcon: const Icon(Icons.account_balance_wallet),
          label: l10n.navBalances,
        ),
        NavigationDestination(
          icon: const Icon(Icons.person_outline),
          selectedIcon: const Icon(Icons.person),
          label: l10n.navProfile,
        ),
      ],
    );
  }
}

/// Estado vacío / error / carga, reutilizable en todas las listas.
class AsyncStateView extends StatelessWidget {
  const AsyncStateView({super.key, required this.icon, required this.mensaje, this.detalle});

  final IconData icon;
  final String mensaje;
  final String? detalle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.md),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            if (detalle != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                detalle!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
