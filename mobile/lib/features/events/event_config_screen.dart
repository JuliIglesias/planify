import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/collapsible_section.dart';
import '../../core/widgets/weekly_availability_grid.dart';
import '../../l10n/generated/app_localizations.dart';
import '../home/home_providers.dart';
import '../profile/profile_availability_provider.dart';
import 'data/availability_repository.dart';
import 'data/events_repository.dart';

/// Configuración del evento (Item 4) — separada del feed de actividad:
/// confirmar asistencia (HU-10), mi disponibilidad (HU-07) y la
/// disponibilidad del grupo (HU-08/HU-09). Se entra desde el ícono de
/// engranaje en el detalle del evento.
class EventConfigScreen extends ConsumerStatefulWidget {
  const EventConfigScreen({super.key, required this.eventoId});

  final String eventoId;

  @override
  ConsumerState<EventConfigScreen> createState() => _EventConfigScreenState();
}

class _EventConfigScreenState extends ConsumerState<EventConfigScreen> {
  final _miDisponibilidad = <AvailabilitySlot>{};
  bool _disponibilidadInicializada = false;
  bool _ocupado = false;

  Future<void> _accion(Future<void> Function() accion) async {
    if (_ocupado) return;
    setState(() => _ocupado = true);

    try {
      await accion();
      if (mounted) invalidateEventData(ref, widget.eventoId);
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$err')));
      }
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final detalle = ref.watch(eventDetailProvider(widget.eventoId));
    final savedAvailAsync = ref.watch(myEventAvailabilityProvider(widget.eventoId));
    final profileAvailAsync = ref.watch(profileAvailabilityProvider);

    if (!_disponibilidadInicializada) {
      if (savedAvailAsync.hasValue) {
        final eventSlots = savedAvailAsync.value!;
        if (eventSlots.isNotEmpty) {
          _miDisponibilidad.clear();
          _miDisponibilidad.addAll(
            eventSlots.map((s) => AvailabilitySlot(s.diaSemana, s.bloqueHora)),
          );
          _disponibilidadInicializada = true;
        } else if (profileAvailAsync.hasValue) {
          final profileSlots = profileAvailAsync.value!;
          if (profileSlots.isNotEmpty) {
            _miDisponibilidad.clear();
            _miDisponibilidad.addAll(profileSlots);
          }
          _disponibilidadInicializada = true;
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(l10n.eventConfigTitle),
      ),
      body: detalle.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => AsyncStateView(
          icon: Icons.cloud_off,
          mensaje: l10n.commonError,
          detalle: '$err',
        ),
        data: (evento) {
          final habilitado = !_ocupado && !evento.estaCancelado;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              // ── Asistencia (HU-10) ──────────────────────────────────────
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Expanded(child: Text(l10n.eventDetailAttendance)),
                      TextButton(
                        onPressed: habilitado
                            ? () => _accion(() => ref
                                .read(eventsRepositoryProvider)
                                .responderAsistencia(
                                    eventoId: evento.id, confirma: false))
                            : null,
                        child: Text(l10n.eventDetailNotGoing),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      FilledButton(
                        onPressed: habilitado
                            ? () => _accion(() => ref
                                .read(eventsRepositoryProvider)
                                .responderAsistencia(
                                    eventoId: evento.id, confirma: true))
                            : null,
                        child: Text(l10n.eventDetailGoing),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Mi disponibilidad (HU-07) ───────────────────────────────
              CollapsibleSection(
                titulo: l10n.eventDetailMyAvailability,
                initiallyExpanded: true,
                child: Column(
                  children: [
                    WeeklyAvailabilityGrid(
                      horaInicio: 0,
                      horaFin: 24,
                      seleccionados: _miDisponibilidad,
                      onToggle: habilitado
                          ? (slot) => setState(() {
                                _disponibilidadInicializada = true;
                                if (!_miDisponibilidad.remove(slot)) {
                                  _miDisponibilidad.add(slot);
                                }
                              })
                          : (_) {},
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: habilitado
                            ? () => _accion(() async {
                                  await ref
                                      .read(availabilityRepositoryProvider)
                                      .guardar(
                                        eventoId: evento.id,
                                        slots: _miDisponibilidad
                                            .map((s) => (
                                                  diaSemana: s.diaSemana,
                                                  bloqueHora: s.bloqueHora,
                                                ))
                                            .toList(),
                                      );
                                  ref.invalidate(
                                      myEventAvailabilityProvider(evento.id));
                                })
                            : null,
                        child: Text(l10n.eventDetailSaveAvailability),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // ── Heatmap del grupo (HU-08/HU-09) ─────────────────────────
              CollapsibleSection(
                titulo: l10n.eventDetailAvailability,
                initiallyExpanded: true,
                child: ref.watch(eventHeatmapProvider(evento.id)).when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, _) => Text('$err'),
                      data: (slots) => Column(
                        children: [
                          WeeklyAvailabilityGrid(
                            horaInicio: 0,
                            horaFin: 24,
                            totalParticipantes: evento.participantes.length,
                            heatmap: {
                              for (final s in slots)
                                AvailabilitySlot(s.diaSemana, s.bloqueHora):
                                    s.disponibles,
                            },
                            // HU-09: tocar un bloque confirma el horario.
                            onSlotTap: habilitado && evento.soyOrganizador
                                ? (slot) => _confirmarHorario(slot)
                                : null,
                          ),
                          if (evento.soyOrganizador) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              l10n.eventDetailTapToConfirm,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ],
                      ),
                    ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmarHorario(AvailabilitySlot slot) async {
    // El heatmap trabaja en día de la semana + hora; se traduce a la próxima
    // fecha real que caiga en ese día (la fecha sale de acá, no del alta — F4).
    final ahora = DateTime.now();
    final diasHasta = (slot.diaSemana + 1 - ahora.weekday + 7) % 7;
    final fecha = DateTime(
      ahora.year,
      ahora.month,
      ahora.day + (diasHasta == 0 ? 7 : diasHasta),
      slot.bloqueHora,
    );

    await _accion(
      () => ref
          .read(availabilityRepositoryProvider)
          .confirmarHorario(eventoId: widget.eventoId, fechaHoraInicio: fecha),
    );
  }
}
