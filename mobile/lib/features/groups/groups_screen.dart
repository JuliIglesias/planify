import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/models.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/event_card.dart';
import '../../core/widgets/status_badge.dart';
import '../../l10n/generated/app_localizations.dart';
import '../events/event_detail_screen.dart';
import '../home/home_providers.dart';

/// Groups — cada card es un grupo con su evento activo (mockup "Groups").
class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final grupos = ref.watch(groupsOverviewProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(groupsOverviewProvider),
      child: ListView(
        children: [
          AppHeader(titulo: l10n.groupsTitle),
          grupos.when(
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
                    icon: Icons.groups_outlined,
                    mensaje: l10n.groupsNoGroups,
                    detalle: l10n.groupsNoGroupsHint,
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Column(
                      children: [for (final grupo in lista) _GrupoCard(grupo: grupo)],
                    ),
                  ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _GrupoCard extends StatelessWidget {
  const _GrupoCard({required this.grupo});

  final GrupoResumen grupo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final proximo = grupo.proximoEvento;

    return EventCard(
      titulo: grupo.nombre,
      subtitulo: proximo == null
          ? l10n.groupsNoUpcoming
          : '${proximo.nombre} · ${proximo.lugarTexto}',
      participantes: grupo.miembros,
      badge: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (grupo.noLeidos > 0) ...[
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.danger,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          if (grupo.tieneEventoNuevo) StatusBadge.nuevo(l10n.groupsNewEvent),
        ],
      ),
      chips: proximo == null
          ? const []
          : [
              l10n.groupsConfirmed(proximo.confirmados),
              if (proximo.tareasPendientes > 0)
                l10n.groupsPendingTasks(proximo.tareasPendientes),
              if (proximo.gastos > 0) l10n.groupsExpenses(proximo.gastos),
            ],
      onTap: proximo == null
          ? null
          : () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => EventDetailScreen(eventoId: proximo.id),
                ),
              ),
    );
  }
}
