import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_semantic_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/collapsible_section.dart';
import '../../core/widgets/event_card.dart';
import '../../core/widgets/weekly_availability_grid.dart';
import '../../l10n/generated/app_localizations.dart';
import 'data/friends_repository.dart';

final _friendProfileProvider = FutureProvider.family<PerfilAmigo, String>(
  (ref, usuarioId) => ref.watch(friendsRepositoryProvider).perfilDe(usuarioId),
);

/// Item 4 — perfil de solo lectura de un amigo: foto/username/email,
/// disponibilidad semanal comparada (solo esta dupla, no todos los amigos
/// como en `FriendMatchesScreen`), y eventos/grupos en común.
class FriendProfileScreen extends ConsumerWidget {
  const FriendProfileScreen({super.key, required this.usuarioId});

  final String usuarioId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final perfil = ref.watch(_friendProfileProvider(usuarioId));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(perfil.value?.persona.username ?? l10n.commonLoading),
      ),
      body: perfil.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => AsyncStateView(
          icon: Icons.cloud_off,
          mensaje: l10n.commonError,
          detalle: '$err',
        ),
        data: (p) => ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            _Encabezado(persona: p.persona),
            const SizedBox(height: AppSpacing.lg),
            CollapsibleSection(
              titulo: l10n.friendProfileAvailability,
              initiallyExpanded: true,
              child: _HeatmapComparado(persona: p.persona, slots: p.heatmapComparado),
            ),
            const SizedBox(height: AppSpacing.md),
            _Seccion(titulo: l10n.friendProfileEventsInCommon),
            if (p.eventosEnComun.isEmpty)
              _TextoVacio(l10n.friendProfileNoEvents)
            else
              for (final evento in p.eventosEnComun)
                EventCard(titulo: evento.nombre, subtitulo: evento.lugarTexto),
            const SizedBox(height: AppSpacing.sm),
            _Seccion(titulo: l10n.friendProfileGroupsInCommon),
            if (p.gruposEnComun.isEmpty)
              _TextoVacio(l10n.friendProfileNoGroups)
            else
              for (final grupo in p.gruposEnComun)
                Builder(builder: (context) {
                  final colorScheme = Theme.of(context).colorScheme;
                  // Estilo "pastel" (fondo claro + iniciales en color, no
                  // blanco) — distinto del AppAvatar sólido de AvatarStack,
                  // se preserva pasando backgroundColor/foregroundColor
                  // explícitos en vez de forzar el default.
                  return Card(
                    child: ListTile(
                      leading: AppAvatar(
                        nombre: grupo.nombre,
                        imageUrl: grupo.avatarUrl,
                        backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
                        foregroundColor: colorScheme.primary,
                      ),
                      title: Text(grupo.nombre),
                    ),
                  );
                }),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.persona});

  final Persona persona;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        // Mismo estilo "pastel" que el avatar de grupo en común, más abajo.
        AppAvatar(
          nombre: persona.username,
          imageUrl: persona.avatarUrl,
          radius: 40,
          backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
          foregroundColor: colorScheme.primary,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          persona.username,
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        // `bodyMedium` por default es el gris de CUERPO — este texto quiere
        // el secundario, así que el override se queda (vía colorScheme).
        if (persona.email != null)
          Text(
            persona.email!,
            style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
      ],
    );
  }
}

/// Item 4 — heatmap de 4 colores (coincidimos / solo yo / solo el amigo /
/// ninguno libre) en vez de la intensidad de un solo color del heatmap
/// grupal de un evento. El color nunca va solo (design system §6): se
/// acompaña con una leyenda de texto debajo de la grilla.
class _HeatmapComparado extends StatelessWidget {
  const _HeatmapComparado({required this.persona, required this.slots});

  final Persona persona;
  final List<SlotComparado> slots;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = context.appSemanticColors;
    final porSlot = {
      for (final s in slots) AvailabilitySlot(s.diaSemana, s.bloqueHora): s.estado,
    };

    Color colorDe(AvailabilitySlot slot) => switch (porSlot[slot]) {
          EstadoSlotComparado.ambos => semantic.success,
          EstadoSlotComparado.soloYo => colorScheme.primary,
          EstadoSlotComparado.soloAmigo => colorScheme.tertiary,
          null => colorScheme.secondaryContainer,
        };

    String labelDe(AvailabilitySlot slot) => switch (porSlot[slot]) {
          EstadoSlotComparado.ambos => l10n.friendProfileLegendBoth,
          EstadoSlotComparado.soloYo => l10n.friendProfileLegendMeOnly,
          EstadoSlotComparado.soloAmigo =>
            l10n.friendProfileLegendFriendOnly(persona.username),
          null => l10n.friendProfileLegendNeither,
        };

    return Column(
      children: [
        WeeklyAvailabilityGrid(
          horaInicio: 0,
          horaFin: 24,
          colorResolver: colorDe,
          semanticsLabelResolver: labelDe,
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.xs,
          children: [
            _LeyendaItem(color: semantic.success, texto: l10n.friendProfileLegendBoth),
            _LeyendaItem(color: colorScheme.primary, texto: l10n.friendProfileLegendMeOnly),
            _LeyendaItem(
              color: colorScheme.tertiary,
              texto: l10n.friendProfileLegendFriendOnly(persona.username),
            ),
            _LeyendaItem(
              color: colorScheme.secondaryContainer,
              texto: l10n.friendProfileLegendNeither,
            ),
          ],
        ),
      ],
    );
  }
}

class _LeyendaItem extends StatelessWidget {
  const _LeyendaItem({required this.color, required this.texto});

  final Color color;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(texto, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion({required this.titulo});

  final String titulo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
      child: Text(
        titulo,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _TextoVacio extends StatelessWidget {
  const _TextoVacio(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    // `bodySmall` ya usa el gris secundario del tema.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Text(texto, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}
