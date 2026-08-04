import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Un bloque de la grilla: día de la semana (0=lunes) + franja horaria.
@immutable
class AvailabilitySlot {
  const AvailabilitySlot(this.diaSemana, this.bloqueHora);

  final int diaSemana;
  final int bloqueHora;

  @override
  bool operator ==(Object other) =>
      other is AvailabilitySlot &&
      other.diaSemana == diaSemana &&
      other.bloqueHora == bloqueHora;

  @override
  int get hashCode => Object.hash(diaSemana, bloqueHora);
}

/// Grilla semanal L-D usada en dos modos (docs/00-ui-entendimiento.md §5):
///  - editable: el participante marca su disponibilidad (HU-07)
///  - heatmap: solo lectura, con intensidad según cuántos pueden (HU-08)
class WeeklyAvailabilityGrid extends StatelessWidget {
  const WeeklyAvailabilityGrid({
    super.key,
    required this.horaInicio,
    required this.horaFin,
    this.seleccionados = const {},
    this.heatmap = const {},
    this.totalParticipantes = 0,
    this.onToggle,
    this.onSlotTap,
    this.slotsFijados = const {},
    this.colorResolver,
    this.semanticsLabelResolver,
  });

  /// Primera franja mostrada, en horas (ej. 8 = 08:00).
  final int horaInicio;
  final int horaFin;
  final Set<AvailabilitySlot> seleccionados;

  /// Cantidad de participantes disponibles por slot (modo heatmap).
  final Map<AvailabilitySlot, int> heatmap;
  final int totalParticipantes;

  final ValueChanged<AvailabilitySlot>? onToggle;
  final ValueChanged<AvailabilitySlot>? onSlotTap;

  /// Item 5 — el RANGO horario que el organizador ya fijó para el evento
  /// (HU-09): un slot por cada hora entre el inicio y el fin, no uno solo.
  /// Se distinguen del resto del heatmap con otro color + una estrella, para
  /// que se note que es EL horario elegido y no solo un bloque con buena
  /// disponibilidad.
  final Set<AvailabilitySlot> slotsFijados;

  /// Item 4 — para modos con más de dos colores por celda (ej. disponibilidad
  /// comparada con un amigo: coincide/solo yo/solo el amigo/ninguno), en vez
  /// de la intensidad de un solo color que usa el heatmap normal. Cuando se
  /// pasa, tiene prioridad sobre `esFijado`/heatmap/selección para decidir
  /// el color de la celda.
  final Color Function(AvailabilitySlot slot)? colorResolver;

  /// Texto accesible por celda cuando se usa `colorResolver` (el color solo
  /// no alcanza, ver design system §6).
  final String Function(AvailabilitySlot slot)? semanticsLabelResolver;

  bool get _esHeatmap => onToggle == null;

  static const _dias = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filas = horaFin - horaInicio;

    return Column(
      children: [
        Row(
          children: [
            const SizedBox(width: 36),
            for (final dia in _dias)
              Expanded(
                child: Center(
                  child: Text(
                    dia,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        for (var fila = 0; fila < filas; fila++)
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  child: Text(
                    '${(horaInicio + fila).toString().padLeft(2, '0')}h',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                for (var dia = 0; dia < 7; dia++)
                  Expanded(
                    child: _Celda(
                      slot: AvailabilitySlot(dia, horaInicio + fila),
                      seleccionado: seleccionados.contains(
                        AvailabilitySlot(dia, horaInicio + fila),
                      ),
                      disponibles: heatmap[AvailabilitySlot(dia, horaInicio + fila)] ?? 0,
                      totalParticipantes: totalParticipantes,
                      esHeatmap: _esHeatmap,
                      esFijado: slotsFijados.contains(AvailabilitySlot(dia, horaInicio + fila)),
                      colorResolver: colorResolver,
                      semanticsLabelResolver: semanticsLabelResolver,
                      onTap: () {
                        final slot = AvailabilitySlot(dia, horaInicio + fila);
                        onToggle?.call(slot);
                        onSlotTap?.call(slot);
                      },
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Celda extends StatelessWidget {
  const _Celda({
    required this.slot,
    required this.seleccionado,
    required this.disponibles,
    required this.totalParticipantes,
    required this.esHeatmap,
    required this.onTap,
    this.esFijado = false,
    this.colorResolver,
    this.semanticsLabelResolver,
  });

  final AvailabilitySlot slot;
  final bool seleccionado;
  final int disponibles;
  final int totalParticipantes;
  final bool esHeatmap;
  final bool esFijado;
  final VoidCallback onTap;
  final Color Function(AvailabilitySlot slot)? colorResolver;
  final String Function(AvailabilitySlot slot)? semanticsLabelResolver;

  @override
  Widget build(BuildContext context) {
    final Color color;
    if (colorResolver != null) {
      color = colorResolver!(slot);
    } else if (esFijado) {
      // Item 5 — el horario ya elegido por el organizador se distingue del
      // resto del heatmap: no es "buena disponibilidad", es EL horario.
      color = AppColors.warning;
    } else if (esHeatmap) {
      // Cuanta más gente puede, más saturado el azul.
      final ratio = totalParticipantes == 0 ? 0.0 : disponibles / totalParticipantes;
      color = ratio == 0
          ? AppColors.background
          : AppColors.primary.withValues(alpha: 0.15 + ratio * 0.75);
    } else {
      color = seleccionado ? AppColors.primary : AppColors.background;
    }

    return Semantics(
      button: true,
      selected: seleccionado || esFijado,
      label: semanticsLabelResolver != null
          ? semanticsLabelResolver!(slot)
          : (esFijado ? 'Horario confirmado' : null),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 22,
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: esFijado
              ? const Center(child: Icon(Icons.star, size: 14, color: Colors.white))
              : (esHeatmap && disponibles > 0
                  ? Center(
                      child: Text(
                        '$disponibles',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color:
                              disponibles / (totalParticipantes == 0 ? 1 : totalParticipantes) >
                                      0.5
                                  ? Colors.white
                                  : AppColors.textPrimary,
                        ),
                      ),
                    )
                  : null),
        ),
      ),
    );
  }
}
