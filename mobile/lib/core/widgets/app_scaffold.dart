import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../../features/home/home_providers.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../l10n/generated/app_localizations.dart';

/// Header con título + campana, común a las 4 pantallas raíz.
/// La campana muestra un badge con la actividad sin leer (H-17) y, desde el
/// Item 2 (Tanda 6), abre la pantalla de Notificaciones.
class AppHeader extends ConsumerWidget {
  const AppHeader({super.key, required this.titulo, this.subtitulo, this.trailing});

  final String titulo;
  final String? subtitulo;
  final Widget? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final noLeidos = ref.watch(unreadTotalProvider).value ?? 0;

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
          trailing ??
              IconButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
                ),
                icon: noLeidos > 0
                    ? Badge(
                        label: Text('$noLeidos'),
                        child: const Icon(Icons.notifications_none, color: AppColors.primary),
                      )
                    : const Icon(Icons.notifications_none, color: AppColors.primary),
              ),
        ],
      ),
    );
  }
}

/// Bottom nav de 4 tabs (docs/00-ui-entendimiento.md §1).
///
/// Item 1 (Tanda 6) — se sacó el glassmorphism (blur): ahora es un contenedor
/// blanco translúcido fijo, sin `BackdropFilter`. El bug de layout era que
/// cada `_NavItem` no era flexible dentro del `Row`: con el texto oculto
/// (versión vieja) el ancho intrínseco entraba de casualidad, pero apenas el
/// texto pasa a estar siempre visible el ancho combinado de los 4 ítems
/// supera el ancho disponible y el `Row` overfloea (se corta, sin poder
/// hacer scroll). El fix es envolver cada ítem en `Expanded` para que se
/// repartan el ancho de la barra en partes iguales.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Container(
          height: 76,
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: _NavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: l10n.navHome,
                  isSelected: currentIndex == 0,
                  onTap: () => onTap(0),
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.groups_outlined,
                  activeIcon: Icons.groups,
                  label: l10n.navGroups,
                  isSelected: currentIndex == 1,
                  onTap: () => onTap(1),
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.account_balance_wallet_outlined,
                  activeIcon: Icons.account_balance_wallet,
                  label: l10n.navBalances,
                  isSelected: currentIndex == 2,
                  onTap: () => onTap(2),
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: l10n.navProfile,
                  isSelected: currentIndex == 3,
                  onTap: () => onTap(3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ícono arriba, texto SIEMPRE visible debajo (antes solo aparecía al
/// costado del ícono, y solo si estaba seleccionado).
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.primary : AppColors.inactiveBlue;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: isSelected
              ? BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                )
              : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(isSelected ? activeIcon : icon, color: color, size: 24),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
              ),
            ],
          ),
        ),
      ),
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
