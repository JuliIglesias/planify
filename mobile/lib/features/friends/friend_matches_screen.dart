import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/weekly_availability_grid.dart';
import '../../l10n/generated/app_localizations.dart';
import '../profile/data/profile_repository.dart';

final _matchesProvider = FutureProvider<CoincidenciasAmigos>(
  (ref) => ref.watch(profileRepositoryProvider).coincidenciasConAmigos(),
);

/// HU-B4 — coincidencias de disponibilidad entre amigos (fuera de un evento).
/// Muestra un heatmap semanal de la disponibilidad de perfil del usuario y sus
/// amigos: dónde coinciden más, más intenso.
class FriendMatchesScreen extends ConsumerWidget {
  const FriendMatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final matches = ref.watch(_matchesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.friendMatchesTitle), backgroundColor: AppColors.surface),
      body: matches.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => AsyncStateView(
          icon: Icons.cloud_off,
          mensaje: l10n.commonError,
          detalle: '$err',
        ),
        data: (c) => ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(
              l10n.friendMatchesHint(c.totalPersonas),
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: WeeklyAvailabilityGrid(
                  horaInicio: 8,
                  horaFin: 24,
                  totalParticipantes: c.totalPersonas,
                  heatmap: {
                    for (final s in c.slots)
                      AvailabilitySlot(s.diaSemana, s.bloqueHora): s.disponibles,
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
