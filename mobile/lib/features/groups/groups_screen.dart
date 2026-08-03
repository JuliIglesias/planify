import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/models/models.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/event_card.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/unread_dot.dart';
import '../../l10n/generated/app_localizations.dart';
import '../events/event_detail_screen.dart';
import '../home/home_providers.dart';
import 'group_manage_sheet.dart';

/// Grupo seleccionado en el carrusel (Item 1). `null` hasta que se elige uno
/// a propósito; mientras tanto la pantalla usa el primero de la lista.
class GrupoSeleccionado extends Notifier<String?> {
  @override
  String? build() => null;

  void seleccionar(String grupoId) => state = grupoId;
}

final grupoSeleccionadoProvider =
    NotifierProvider<GrupoSeleccionado, String?>(GrupoSeleccionado.new);

/// Groups — carrusel de avatares de grupo arriba + eventos del grupo
/// seleccionado debajo (mockup "Groups").
///
/// Cada `GrupoResumen` ya trae su propia lista de eventos activos
/// (`groupsOverviewProvider`, un solo fetch para todos los grupos). Cambiar
/// de grupo seleccionado solo cambia qué parte de esos datos ya cargados se
/// muestra — no vuelve a pedir nada, así que nunca pisa ni pierde los
/// eventos de los demás grupos.
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
                : _GruposConEventos(grupos: lista),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _GruposConEventos extends ConsumerWidget {
  const _GruposConEventos({required this.grupos});

  final List<GrupoResumen> grupos;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final idPedido = ref.watch(grupoSeleccionadoProvider);
    final grupo = grupos.firstWhere(
      (g) => g.id == idPedido,
      orElse: () => grupos.first,
    );

    return Column(
      children: [
        _CarruselDeGrupos(grupos: grupos, seleccionadoId: grupo.id),
        const SizedBox(height: AppSpacing.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  grupo.nombre,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, size: 20),
                tooltip: l10n.groupsManage,
                visualDensity: VisualDensity.compact,
                onPressed: () => mostrarGestionDeGrupo(context, grupo),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: grupo.eventos.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: AsyncStateView(
                    icon: Icons.event_busy_outlined,
                    mensaje: l10n.groupsNoUpcoming,
                  ),
                )
              : Column(
                  children: [
                    for (final evento in grupo.eventos)
                      _EventoDeGrupoCard(key: ValueKey(evento.id), evento: evento),
                  ],
                ),
        ),
      ],
    );
  }
}

class _CarruselDeGrupos extends ConsumerWidget {
  const _CarruselDeGrupos({required this.grupos, required this.seleccionadoId});

  final List<GrupoResumen> grupos;
  final String seleccionadoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      height: 116,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: grupos.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, i) {
          final grupo = grupos[i];
          final activo = grupo.id == seleccionadoId;

          return GestureDetector(
            onTap: () =>
                ref.read(grupoSeleccionadoProvider.notifier).seleccionar(grupo.id),
            child: SizedBox(
              width: 68,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: activo
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.15),
                        child: Text(
                          _iniciales(grupo.nombre),
                          style: TextStyle(
                            color: activo ? Colors.white : AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Positioned(
                        right: -2,
                        top: -2,
                        child: UnreadDot(cantidad: grupo.noLeidos),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    grupo.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: activo ? FontWeight.bold : FontWeight.normal,
                          color: activo ? AppColors.primary : AppColors.textSecondary,
                        ),
                  ),
                  if (grupo.tieneEventoNuevo)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: StatusBadge.nuevo(l10n.groupsNewEvent),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static String _iniciales(String nombre) {
    final partes = nombre.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return '?';
    if (partes.length == 1) return partes.first.characters.first.toUpperCase();
    return (partes.first.characters.first + partes[1].characters.first).toUpperCase();
  }
}

class _EventoDeGrupoCard extends StatelessWidget {
  const _EventoDeGrupoCard({super.key, required this.evento});

  final EventoDeGrupo evento;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final fecha = evento.fechaHoraInicio != null
        ? DateFormat("EEEE d 'de' MMMM · HH:mm", 'es').format(evento.fechaHoraInicio!)
        : l10n.commonToBeDefined;

    return EventCard(
      titulo: evento.nombre,
      subtitulo: '$fecha · ${evento.lugarTexto}',
      chips: [
        l10n.groupsConfirmed(evento.confirmados),
        if (evento.tareasPendientes > 0) l10n.groupsPendingTasks(evento.tareasPendientes),
        if (evento.gastos > 0) l10n.groupsExpenses(evento.gastos),
      ],
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => EventDetailScreen(eventoId: evento.id),
        ),
      ),
    );
  }
}
