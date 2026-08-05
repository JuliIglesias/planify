import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../debug/design_catalog_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../../features/home/home_providers.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../l10n/generated/app_localizations.dart';

/// A1/A2 — altura REAL (medida, no estimada) que ocupa [AppBottomNav] en
/// pantalla, incluida su `SafeArea`/padding. Como la navbar ahora es
/// "hug content" (A1) en vez de un valor fijo, cualquier constante a mano acá
/// se desincronizaría apenas cambiara el contenido de la navbar; `AppShell`
/// la mide de verdad (`GlobalKey` + `RenderBox.size`) y la publica acá para
/// que las pantallas raíz (Item A2) sepan cuánto padding inferior necesitan
/// para que ningún contenido quede tapado por la barra flotante. Arranca en
/// 0 — las pantallas la usan sumada a un mínimo propio, así que no queda sin
/// padding en absoluto mientras `AppShell` todavía no midió (primer frame, o
/// en tests que montan una pantalla suelta sin `AppShell` alrededor).
///
/// Riverpod 3 sacó `StateProvider` (mismo criterio que `_FiltroBalance` en
/// `balances_screen.dart`): estado local simple se modela con un `Notifier`.
class BottomNavHeight extends Notifier<double> {
  @override
  double build() => 0;

  void set(double alto) => state = alto;
}

final bottomNavHeightProvider =
    NotifierProvider<BottomNavHeight, double>(BottomNavHeight.new);

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
            child: GestureDetector(
              // Acceso oculto al catálogo de componentes — solo en builds
              // debug, no visible en producción (docs/06-design-system.md
              // §6.3/§9.1 punto 4). No cambia nada del header en sí.
              onLongPress: kDebugMode
                  ? () => Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => const DesignCatalogScreen()),
                      )
                  : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Color de título: hereda `headlineSmall` del tema (azul
                  // oscuro, docs/06-design-system.md §3.4) — ya no se pisa
                  // con `AppColors.primary` a mano.
                  Text(
                    titulo,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  if (subtitulo != null)
                    Text(subtitulo!, style: theme.textTheme.bodySmall),
                ],
              ),
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
///
/// A1 — la altura ya NO es un valor fijo (`height: 76`, que no tenía
/// relación con nada más): ahora es "hug content", el contenedor mide lo que
/// necesita su propio contenido (ícono + texto + paddings), igual que
/// [PillToggle] (misma familia visual — [AppSpacing.barRadius] compartido).
/// La navbar termina más alta que un `PillToggle` porque tiene ícono además
/// de texto, y eso es esperable, no un bug: por eso el radio de borde NO se
/// calcula como `alto / 2` (dejaría de verse como "rectángulo redondeado" y
/// pasaría a verse como una cápsula rara en un contenedor tan alto) — usa el
/// mismo radio fijo que el resto de la familia. La altura real, medida en
/// tiempo de ejecución, se expone vía [bottomNavHeightProvider] para que las
/// pantallas raíz (Item A2) sepan cuánto padding inferior necesitan para no
/// quedar tapadas por esta barra flotante.
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
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(AppSpacing.barRadius),
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
    final colorScheme = Theme.of(context).colorScheme;
    // `secondary`: color de CONTENIDO sobre blanco para el estado inactivo —
    // no un fondo relleno (docs/06-design-system.md §3.4b). Reemplaza al
    // antiguo `AppColors.inactiveBlue`.
    final color = isSelected ? colorScheme.primary : colorScheme.secondary;

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
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
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
