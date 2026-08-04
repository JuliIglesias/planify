import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import '../../features/events/event_detail_screen.dart';
import '../../l10n/generated/app_localizations.dart';
import 'event_card.dart';

/// Card de un evento puntual (no de un grupo) — mismo patrón en Home
/// ("próximos eventos") y Groups (eventos del grupo seleccionado, Item 1).
class EventoResumenCard extends StatelessWidget {
  const EventoResumenCard({super.key, required this.evento});

  final EventoResumen evento;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final badgeText = evento.fechaHoraInicio != null
        ? DateFormat("MMM d", 'es').format(evento.fechaHoraInicio!).toUpperCase()
        : l10n.commonToBeDefined.toUpperCase();

    final topBadge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        badgeText,
        style: theme.textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    return EventCard(
      width: 260, // Fixed width for carousel
      titulo: evento.nombre,
      topBadge: topBadge,
      trailing: Icon(Icons.more_horiz, color: Theme.of(context).colorScheme.primary),
      participantes: evento.participantes.map((p) => p.username).toList(),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => EventDetailScreen(eventoId: evento.id),
        ),
      ),
    );
  }
}
