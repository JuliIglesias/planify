import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/models/models.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/event_card.dart';
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
    // A2 — misma altura real de la navbar que usan las otras pantallas
    // raíz (Home, Saldos, Perfil): un solo lugar (`bottomNavHeightProvider`)
    // evita que cada pantalla adivine un número distinto.
    final bottomPad = ref.watch(bottomNavHeightProvider) + AppSpacing.md;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(groupsOverviewProvider),
      child: ListView(
        padding: EdgeInsets.only(bottom: bottomPad),
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
          final colorScheme = Theme.of(context).colorScheme;

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
                      // AppAvatar (docs/06-design-system.md §6.1) reemplaza
                      // el CircleAvatar + cálculo de iniciales duplicado.
                      AppAvatar(
                        nombre: grupo.nombre,
                        imageUrl: grupo.avatarUrl,
                        radius: 26,
                        backgroundColor: activo
                            ? colorScheme.primary
                            : colorScheme.primary.withValues(alpha: 0.15),
                        foregroundColor: activo ? colorScheme.onPrimary : colorScheme.primary,
                      ),
                      Positioned(
                        right: -2,
                        top: -2,
                        child: UnreadDot(cantidad: grupo.noLeidos, mostrarNumero: true),
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
                          color: activo ? colorScheme.primary : colorScheme.onSurfaceVariant,
                        ),
                  ),
                  // E1 — se sacó el badge de texto "NUEVO" (no se iba nunca:
                  // `tieneEventoNuevo` es una ventana de tiempo desde que se
                  // creó el evento, no un estado de leído/no leído, así que
                  // entrar al evento/grupo no lo actualizaba). El punto de
                  // no-leído de arriba (`UnreadDot`, con contador estilo
                  // WhatsApp) ya cubre lo que el usuario pidió en su lugar:
                  // avisar que hay actividad nueva sin leer, y desaparecer
                  // una vez que se lee. Solo se oculta la UI —
                  // `tieneEventoNuevo` se mantiene en el modelo/backend por
                  // si se reutiliza más adelante.
                ],
              ),
            ),
          );
        },
      ),
    );
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

    // Constructores semánticos de EventCardPill (docs/06-design-system.md
    // §6.2) — reemplazan los 8 `Color(0x...)` hardcodeados que traía cada
    // pill (tonos "de catálogo" de Material pegados a mano, ninguno de la
    // paleta de marca).
    final pills = [
      if (evento.necesitaDecisionRango)
        // NOTA: 'Decisión pendiente' sigue hardcodeado en español, igual que
        // en el código original — no lo até a `l10n.eventUrgentDecision`
        // (que existe con el mismo texto) para no mezclar un fix de i18n
        // con este refactor de presentación. Ver docs/05-fixes.md.
        EventCardPill.danger(
          label: 'Decisión pendiente',
          icon: Icons.warning_amber_outlined,
          context: context,
        ),
      if (evento.noLeidos > 0)
        EventCardPill.info(
          label: l10n.unreadActivities(evento.noLeidos),
          icon: Icons.chat_bubble_outline,
          context: context,
        ),
      EventCardPill.success(
        label: l10n.groupsConfirmed(evento.confirmados),
        icon: Icons.people_outline,
        context: context,
      ),
      if (evento.tareasPendientes > 0)
        EventCardPill.warning(
          label: l10n.groupsPendingTasks(evento.tareasPendientes),
          icon: Icons.assignment_outlined,
          context: context,
        ),
      if (evento.gastos > 0)
        EventCardPill.accent(
          label: l10n.groupsExpenses(evento.gastos),
          icon: Icons.monetization_on_outlined,
          context: context,
        ),
    ];

    return EventCard(
      titulo: evento.nombre,
      subtitulo: '$fecha · ${evento.lugarTexto}',
      pills: pills,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => EventDetailScreen(eventoId: evento.id),
        ),
      ),
    );
  }
}
