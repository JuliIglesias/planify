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

    final fecha = evento.fechaHoraInicio != null
        ? DateFormat("EEEE d 'de' MMMM · HH:mm", 'es').format(evento.fechaHoraInicio!)
        : l10n.commonToBeDefined;

    return EventCard(
      titulo: evento.nombre,
      subtitulo: '$fecha · ${evento.lugarTexto}',
      participantes: evento.participantes.map((p) => p.nombreDisplay).toList(),
      chips: [l10n.groupsConfirmed(evento.confirmados)],
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => EventDetailScreen(eventoId: evento.id),
        ),
      ),
    );
  }
}
