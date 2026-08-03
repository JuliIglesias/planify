import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/event_card.dart';
import '../../core/widgets/evento_resumen_card.dart';
import '../../l10n/generated/app_localizations.dart';
import '../auth/session_controller.dart';
import '../events/widgets/activity_presentation.dart';
import 'home_providers.dart';

/// Home — resumen de saldos, próximos eventos y actividad reciente
/// (mockup "Home" de Figma).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final session = ref.watch(sessionControllerProvider).value;
    final nombre = session is SesionOrganizador ? session.nombre.split(' ').first : '';

    final eventos = ref.watch(upcomingEventsProvider);
    final balance = ref.watch(balanceProvider);

    return RefreshIndicator(
      onRefresh: () async => invalidateListas(ref),
      child: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        children: [
          AppHeader(titulo: l10n.homeGreeting(nombre)),

          // Resumen de saldos
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: _ResumenSaldo(
                    label: l10n.homeOwedToMe,
                    monto: balance.value?.meDeben ?? '—',
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _ResumenSaldo(
                    label: l10n.homeIOwe,
                    monto: balance.value?.debo ?? '—',
                    color: AppColors.danger,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              l10n.homeUpcomingEvents,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          eventos.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => AsyncStateView(
              icon: Icons.cloud_off,
              mensaje: l10n.commonError,
              detalle: l10n.commonErrorHint,
            ),
            data: (lista) => lista.isEmpty
                ? AsyncStateView(
                    icon: Icons.event_available_outlined,
                    mensaje: l10n.homeNoEvents,
                    detalle: l10n.homeNoEventsHint,
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Column(
                      children: [
                        for (final evento in lista) EventoResumenCard(evento: evento),
                      ],
                    ),
                  ),
          ),

          // Actividad reciente de todos los eventos (mockup "Home" de Figma).
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              l10n.homeRecentActivity,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          ref.watch(recentActivityProvider).when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, _) => const SizedBox.shrink(),
                data: (entradas) => entradas.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        child: Text(
                          l10n.homeNoActivity,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        child: Column(
                          children: [
                            for (final entrada in entradas)
                              ActivityFeedItem(
                                icon: iconoDeActividad(entrada.tipo),
                                iconColor: colorDeActividad(entrada.tipo),
                                titulo: textoActividad(l10n, entrada),
                                subtitulo: entrada.eventoNombre,
                                trailing: montoDeActividad(entrada),
                              ),
                          ],
                        ),
                      ),
              ),
        ],
      ),
    );
  }
}

class _ResumenSaldo extends StatelessWidget {
  const _ResumenSaldo({required this.label, required this.monto, required this.color});

  final String label;
  final String monto;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              monto == '—' ? monto : '\$$monto',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
