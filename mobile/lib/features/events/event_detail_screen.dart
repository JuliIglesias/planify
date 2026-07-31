import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/models/models.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/event_card.dart';
import '../../core/widgets/quick_action_button.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/weekly_availability_grid.dart';
import '../../l10n/generated/app_localizations.dart';
import '../home/home_providers.dart';
import 'data/availability_repository.dart';
import 'data/events_repository.dart';
import 'data/expenses_repository.dart';
import 'data/tasks_repository.dart';
import 'widgets/expense_dialog.dart';
import 'widgets/activity_presentation.dart';
import 'widgets/task_dialogs.dart';
import '../balances/data/balances_repository.dart';

import '../profile/profile_availability_provider.dart';

/// Detalle del evento: asistencia (HU-10), disponibilidad y heatmap
/// (HU-07/08/09), tareas (HU-20..23), gastos y deudas (HU-13..19) y log de
/// actividad (HU-24).
class EventDetailScreen extends ConsumerStatefulWidget {
  const EventDetailScreen({super.key, required this.eventoId});

  final String eventoId;

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  final _miDisponibilidad = <AvailabilitySlot>{};
  bool _disponibilidadInicializada = false;
  bool _ocupado = false;

  /// Ejecuta una acción mostrando el estado de carga y refrescando al terminar.
  /// Centralizado para que ninguna acción se olvide de invalidar los providers.
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
        title: Text(detalle.value?.nombre ?? l10n.commonLoading),
        actions: [
          if (detalle.value?.organizador != null && !(detalle.value?.estaCancelado ?? false))
            PopupMenuButton<String>(
              onSelected: (opcion) => switch (opcion) {
                'cerrar' => _accion(() => ref
                    .read(expensesRepositoryProvider)
                    .cerrar(widget.eventoId)),
                'cancelar' => _confirmarCancelacion(),
                _ => null,
              },
              itemBuilder: (_) => [
                // HU-19 y HU-11: acciones exclusivas del organizador (Duda #6).
                PopupMenuItem(value: 'cerrar', child: Text(l10n.eventDetailCloseExpenses)),
                PopupMenuItem(value: 'cancelar', child: Text(l10n.eventDetailCancelEvent)),
              ],
            ),
        ],
      ),
      body: detalle.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => AsyncStateView(
          icon: Icons.cloud_off,
          mensaje: l10n.commonError,
          detalle: '$err',
        ),
        data: (evento) => _Contenido(
          evento: evento,
          miDisponibilidad: _miDisponibilidad,
          ocupado: _ocupado,
          onToggleSlot: (slot) => setState(() {
            _disponibilidadInicializada = true;
            if (!_miDisponibilidad.remove(slot)) _miDisponibilidad.add(slot);
          }),
          onAccion: _accion,
        ),
      ),
    );
  }


  Future<void> _confirmarCancelacion() async {
    final l10n = AppLocalizations.of(context)!;

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.eventDetailCancelEvent),
        content: Text(l10n.eventDetailCancelConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.commonConfirm),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      await _accion(() => ref.read(eventsRepositoryProvider).cancelar(widget.eventoId));
      if (mounted) Navigator.of(context).pop();
    }
  }
}

class _Contenido extends ConsumerWidget {
  const _Contenido({
    required this.evento,
    required this.miDisponibilidad,
    required this.ocupado,
    required this.onToggleSlot,
    required this.onAccion,
  });

  final DetalleEvento evento;
  final Set<AvailabilitySlot> miDisponibilidad;
  final bool ocupado;
  final ValueChanged<AvailabilitySlot> onToggleSlot;
  final Future<void> Function(Future<void> Function()) onAccion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final fecha = evento.fechaHoraInicio != null
        ? DateFormat("EEEE d 'de' MMMM · HH:mm", 'es').format(evento.fechaHoraInicio!)
        : l10n.commonToBeDefined;

    final habilitado = !ocupado && !evento.estaCancelado;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Row(
          children: [
            Expanded(child: Text('$fecha · ${evento.lugarTexto}')),
            if (evento.estaCancelado)
              StatusBadge(label: l10n.eventDetailCancelled, color: AppColors.danger)
            else if (evento.estaFinalizado)
              StatusBadge.saldo(SaldoEstado.saldado, l10n.balancesStateSettled),
          ],
        ),

        // ── Asistencia (HU-10) ────────────────────────────────────────────
        const SizedBox(height: AppSpacing.md),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(child: Text(l10n.eventDetailAttendance)),
                TextButton(
                  onPressed: habilitado
                      ? () => onAccion(() => ref
                          .read(eventsRepositoryProvider)
                          .responderAsistencia(eventoId: evento.id, confirma: false))
                      : null,
                  child: Text(l10n.eventDetailNotGoing),
                ),
                const SizedBox(width: AppSpacing.xs),
                FilledButton(
                  onPressed: habilitado
                      ? () => onAccion(() => ref
                          .read(eventsRepositoryProvider)
                          .responderAsistencia(eventoId: evento.id, confirma: true))
                      : null,
                  child: Text(l10n.eventDetailGoing),
                ),
              ],
            ),
          ),
        ),

        // ── Acciones rápidas (mockup "Log de Actividad") ──────────────────
        _Seccion(titulo: l10n.eventDetailQuickActions),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                QuickActionButton(
                  icon: Icons.receipt_long_outlined,
                  label: l10n.eventDetailAddExpense,
                  color: AppColors.danger,
                  onPressed: habilitado ? () => _agregarGasto(context, ref) : null,
                ),
                QuickActionButton(
                  icon: Icons.check_box_outlined,
                  label: l10n.eventDetailAddTask,
                  color: AppColors.warning,
                  onPressed: habilitado ? () => _agregarTarea(context, ref) : null,
                ),
                QuickActionButton(
                  icon: Icons.price_check,
                  label: l10n.eventDetailSettle,
                  color: AppColors.success,
                  onPressed: habilitado ? () => _mostrarDeudas(context, ref) : null,
                ),
              ],
            ),
          ),
        ),

        // ── Mi disponibilidad (HU-07) ─────────────────────────────────────
        _Seccion(titulo: l10n.eventDetailMyAvailability),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                WeeklyAvailabilityGrid(
                  horaInicio: 10,
                  horaFin: 24,
                  seleccionados: miDisponibilidad,
                  onToggle: habilitado ? onToggleSlot : (_) {},
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: habilitado
                        ? () => onAccion(() async {
                            await ref
                                .read(availabilityRepositoryProvider)
                                .guardar(
                                  eventoId: evento.id,
                                  slots: miDisponibilidad
                                      .map((s) =>
                                          (diaSemana: s.diaSemana, bloqueHora: s.bloqueHora))
                                      .toList(),
                                );
                            ref.invalidate(myEventAvailabilityProvider(evento.id));
                          })
                        : null,
                    child: Text(l10n.eventDetailSaveAvailability),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Heatmap del grupo (HU-08/HU-09) ───────────────────────────────
        _Seccion(titulo: l10n.eventDetailAvailability),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: ref.watch(eventHeatmapProvider(evento.id)).when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Text('$err'),
                  data: (slots) => Column(
                    children: [
                      WeeklyAvailabilityGrid(
                        horaInicio: 10,
                        horaFin: 24,
                        totalParticipantes: evento.participantes.length,
                        heatmap: {
                          for (final s in slots)
                            AvailabilitySlot(s.diaSemana, s.bloqueHora): s.disponibles,
                        },
                        // HU-09: tocar un bloque del heatmap confirma el horario.
                        onSlotTap: habilitado && evento.organizador != null
                            ? (slot) => _confirmarHorario(context, ref, slot)
                            : null,
                      ),
                      if (evento.organizador != null) ...[
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
        ),

        // ── Tareas (HU-20 a HU-23) ────────────────────────────────────────
        _Seccion(titulo: l10n.eventDetailTasks),
        ref.watch(eventTasksProvider(evento.id)).when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('$err'),
              data: (tareas) => tareas.isEmpty
                  ? _TextoVacio(l10n.eventDetailNoTasks)
                  : Column(
                      children: [
                        for (final tarea in tareas)
                          _TareaTile(
                            tarea: tarea,
                            participantes: evento.participantes,
                            habilitado: habilitado,
                            onTomar: () => onAccion(() => ref
                                .read(tasksRepositoryProvider)
                                .asignar(eventoId: evento.id, tareaId: tarea.id)),
                            onAsignarA: (participanteId) => onAccion(() => ref
                                .read(tasksRepositoryProvider)
                                .asignar(
                                  eventoId: evento.id,
                                  tareaId: tarea.id,
                                  asignadoA: participanteId,
                                )),
                            onCompletar: () => onAccion(() => ref
                                .read(tasksRepositoryProvider)
                                .completar(eventoId: evento.id, tareaId: tarea.id)),
                          ),
                      ],
                    ),
            ),

        // ── Log de actividad (HU-24) ──────────────────────────────────────
        _Seccion(titulo: l10n.eventDetailActivityLog),
        ref.watch(eventActivityProvider(evento.id)).when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('$err'),
              data: (entradas) => entradas.isEmpty
                  ? _TextoVacio(l10n.eventDetailNoActivity)
                  : Column(
                      children: [
                        for (final entrada in entradas)
                          ActivityFeedItem(
                            icon: iconoDeActividad(entrada.tipo),
                            iconColor: colorDeActividad(entrada.tipo),
                            titulo: textoActividad(l10n, entrada),
                            trailing: DateFormat('dd/MM HH:mm').format(entrada.createdAt),
                          ),
                      ],
                    ),
            ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Future<void> _agregarTarea(BuildContext context, WidgetRef ref) async {
    final titulo = await pedirTituloTarea(context);
    if (titulo == null) return;
    await onAccion(
      () => ref.read(tasksRepositoryProvider).crear(eventoId: evento.id, titulo: titulo),
    );
  }

  Future<void> _agregarGasto(BuildContext context, WidgetRef ref) async {
    final datos = await pedirDatosGasto(context, evento.participantes);
    if (datos == null) return;

    await onAccion(
      () => ref.read(expensesRepositoryProvider).crear(
            eventoId: evento.id,
            descripcion: datos.descripcion,
            montoTotal: datos.monto,
            acreedores: [
              AporteGasto(participanteId: datos.pagadorId, monto: datos.monto),
            ],
            dividirEntre: datos.deudoresIds,
          ),
    );
  }


  Future<void> _mostrarDeudas(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final deudas = await ref.read(eventDebtsProvider(evento.id).future);

    if (!context.mounted) return;

    final deudaId = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                l10n.eventDetailDebts,
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
            ),
            if (deudas.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(l10n.eventDetailNoDebts),
              ),
            for (final deuda in deudas)
              ListTile(
                title: Text('${deuda.deudorNombre} → ${deuda.acreedorNombre}'),
                subtitle: Text('\$${deuda.monto}'),
                trailing: deuda.estaSaldada
                    ? StatusBadge.saldo(SaldoEstado.saldado, l10n.balancesStateSettled)
                    : TextButton(
                        onPressed: () => Navigator.pop(ctx, deuda.id),
                        child: Text(l10n.eventDetailSettle),
                      ),
              ),
          ],
        ),
      ),
    );

    if (deudaId == null) return;
    await onAccion(
      () => ref
          .read(balancesRepositoryProvider)
          .saldar(eventoId: evento.id, deudaId: deudaId),
    );
  }

  Future<void> _confirmarHorario(
    BuildContext context,
    WidgetRef ref,
    AvailabilitySlot slot,
  ) async {
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

    await onAccion(
      () => ref
          .read(availabilityRepositoryProvider)
          .confirmarHorario(eventoId: evento.id, fechaHoraInicio: fecha),
    );
  }
}

class _TareaTile extends StatelessWidget {
  const _TareaTile({
    required this.tarea,
    required this.participantes,
    required this.habilitado,
    required this.onTomar,
    required this.onAsignarA,
    required this.onCompletar,
  });

  final Tarea tarea;
  final List<Participante> participantes;
  final bool habilitado;
  final VoidCallback onTomar;
  final ValueChanged<String> onAsignarA;
  final VoidCallback onCompletar;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      child: ListTile(
        leading: Icon(
          tarea.estaCompletada ? Icons.check_circle : Icons.radio_button_unchecked,
          color: tarea.estaCompletada ? AppColors.success : AppColors.textSecondary,
        ),
        title: Text(tarea.titulo),
        subtitle: Text(tarea.asignadoNombre ?? l10n.eventDetailTaskUnassigned),
        trailing: tarea.estaCompletada
            ? Text(l10n.eventDetailTaskDone)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // HU-22 — asignar a otro participante.
                  if (tarea.estaSinAsignar)
                    PopupMenuButton<String>(
                      enabled: habilitado,
                      icon: const Icon(Icons.person_add_alt, size: 20),
                      tooltip: l10n.eventDetailAssignTo,
                      onSelected: onAsignarA,
                      itemBuilder: (_) => [
                        for (final p in participantes)
                          PopupMenuItem(value: p.id, child: Text(p.nombreDisplay)),
                      ],
                    ),
                  TextButton(
                    onPressed: !habilitado
                        ? null
                        : tarea.estaSinAsignar
                            ? onTomar
                            : onCompletar,
                    child: Text(
                      tarea.estaSinAsignar
                          ? l10n.eventDetailTakeTask
                          : l10n.eventDetailCompleteTask,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion({required this.titulo});

  final String titulo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
      child: Text(
        titulo,
        style:
            Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _TextoVacio extends StatelessWidget {
  const _TextoVacio(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Text(
        texto,
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}
