import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/weekly_availability_grid.dart';
import '../../l10n/generated/app_localizations.dart';
import 'data/groups_repository.dart';

final _disponibilidadDeGrupoProvider =
    FutureProvider.family<DisponibilidadDeGrupo, String>(
  (ref, grupoId) => ref.watch(groupsRepositoryProvider).disponibilidadDeGrupo(grupoId),
);

/// Tanda 6, Item 5 — heatmap de disponibilidad de los miembros de UN grupo
/// puntual (reemplaza la vieja "coincidencias con todos los amigos" que vivía
/// en Perfil): se entra desde el menú de 3 puntos del grupo.
class GroupAvailabilityScreen extends ConsumerWidget {
  const GroupAvailabilityScreen({super.key, required this.grupoId});

  final String grupoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final matches = ref.watch(_disponibilidadDeGrupoProvider(grupoId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.groupAvailabilityTitle), backgroundColor: AppColors.surface),
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
              l10n.groupAvailabilityHint(c.totalPersonas),
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
