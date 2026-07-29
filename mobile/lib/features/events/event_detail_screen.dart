import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/models/models.dart';
import '../../core/network/planify_api.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/event_card.dart';
import '../../core/widgets/weekly_availability_grid.dart';
import '../../l10n/generated/app_localizations.dart';
import '../home/home_providers.dart';

/// Detalle del evento: disponibilidad + heatmap (HU-07/08/09), asistencia
/// (HU-10), tareas (HU-20..23), gastos (HU-13) y log de actividad (HU-24).
class EventDetailScreen extends ConsumerStatefulWidget {
  const EventDetailScreen({super.key, required this.eventoId});

  final String eventoId;

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  final _miDisponibilidad = <AvailabilitySlot>{};
  bool _guardando = false;

  Future<void> _run(Future<void> Function() accion) async {
    setState(() => _guardando = true);
    try {
      await accion();
      if (mounted) invalidateEventData(ref, widget.eventoId);
    } catch (err) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.commonError}: $err')),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final detalle = ref.watch(eventDetailProvider(widget.eventoId));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(detalle.value?['nombre'] as String? ?? l10n.commonLoading),
      ),
      body: detalle.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => AsyncStateView(
          icon: Icons.cloud_off,
          mensaje: l10n.commonError,
          detalle: l10n.commonErrorHint,
        ),
        data: (evento) => _Contenido(
          evento: evento,
          eventoId: widget.eventoId,
          miDisponibilidad: _miDisponibilidad,
          guardando: _guardando,
          onToggleSlot: (slot) => setState(() {
            if (!_miDisponibilidad.remove(slot)) _miDisponibilidad.add(slot);
          }),
          onRun: _run,
        ),
      ),
    );
  }
}

class _Contenido extends ConsumerWidget {
  const _Contenido({
    required this.evento,
    required this.eventoId,
    required this.miDisponibilidad,
    required this.guardando,
    required this.onToggleSlot,
    required this.onRun,
  });

  final Map<String, dynamic> evento;
  final String eventoId;
  final Set<AvailabilitySlot> miDisponibilidad;
  final bool guardando;
  final ValueChanged<AvailabilitySlot> onToggleSlot;
  final Future<void> Function(Future<void> Function()) onRun;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final api = ref.watch(planifyApiProvider);

    final participantes = ((evento['participantes'] as List<dynamic>?) ?? [])
        .map((p) => Participante.fromJson(p as Map<String, dynamic>))
        .toList();
    final lugar = evento['lugarTexto'] as String? ?? '';
    final fechaIso = evento['fechaHoraInicio'] as String?;
    final fecha = fechaIso != null
        ? DateFormat("EEEE d 'de' MMMM · HH:mm", 'es').format(DateTime.parse(fechaIso))
        : l10n.commonToBeDefined;

    final heatmap = ref.watch(eventHeatmapProvider(eventoId));
    final tareas = ref.watch(eventTasksProvider(eventoId));
    final actividad = ref.watch(eventActivityProvider(eventoId));

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text('$fecha · $lugar', style: theme.textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.md),

        // Asistencia (HU-10)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(child: Text(l10n.eventDetailAttendance)),
                TextButton(
                  onPressed: guardando
                      ? null
                      : () => onRun(() =>
                          api.setAttendance(eventoId: eventoId, confirma: false)),
                  child: Text(l10n.eventDetailNotGoing),
                ),
                const SizedBox(width: AppSpacing.xs),
                FilledButton(
                  onPressed: guardando
                      ? null
                      : () => onRun(
                          () => api.setAttendance(eventoId: eventoId, confirma: true)),
                  child: Text(l10n.eventDetailGoing),
                ),
              ],
            ),
          ),
        ),

        // Mi disponibilidad (HU-07)
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
                  onToggle: onToggleSlot,
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: guardando
                        ? null
                        : () => onRun(() => api.submitAvailability(
                              eventoId: eventoId,
                              slots: miDisponibilidad
                                  .map((s) => (
                                        diaSemana: s.diaSemana,
                                        bloqueHora: s.bloqueHora,
                                      ))
                                  .toList(),
                            )),
                    child: Text(l10n.eventDetailSaveAvailability),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Heatmap del grupo (HU-08/HU-09)
        _Seccion(titulo: l10n.eventDetailAvailability),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: heatmap.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Text(l10n.commonError),
              data: (slots) => WeeklyAvailabilityGrid(
                horaInicio: 10,
                horaFin: 24,
                totalParticipantes: participantes.length,
                heatmap: {
                  for (final s in slots)
                    AvailabilitySlot(s.diaSemana, s.bloqueHora): s.disponibles,
                },
              ),
            ),
          ),
        ),

        // Tareas (HU-20 a HU-23)
        _Seccion(titulo: l10n.eventDetailTasks),
        tareas.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Text(l10n.commonError),
          data: (lista) => Column(
            children: [
              if (lista.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    l10n.eventDetailNoTasks,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              for (final tarea in lista)
                Card(
                  child: ListTile(
                    leading: Icon(
                      tarea.estado == 'completado'
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: tarea.estado == 'completado'
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                    title: Text(tarea.titulo),
                    subtitle: Text(
                      tarea.asignadoNombre ?? l10n.eventDetailTaskUnassigned,
                    ),
                    trailing: tarea.estado == 'completado'
                        ? Text(l10n.eventDetailTaskDone)
                        : TextButton(
                            onPressed: guardando
                                ? null
                                : () => onRun(() => tarea.estado == 'no_asignado'
                                    ? api.assignTask(
                                        eventoId: eventoId, tareaId: tarea.id)
                                    : api.completeTask(
                                        eventoId: eventoId, tareaId: tarea.id)),
                            child: Text(tarea.estado == 'no_asignado'
                                ? l10n.eventDetailTakeTask
                                : l10n.eventDetailCompleteTask),
                          ),
                  ),
                ),
            ],
          ),
        ),

        // Acciones rápidas (mockup "Log de Actividad")
        _Seccion(titulo: l10n.eventDetailQuickActions),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: guardando ? null : () => _mostrarDialogoGasto(context, ref),
                icon: const Icon(Icons.receipt_long_outlined, size: 18),
                label: Text(l10n.eventDetailAddExpense),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: guardando ? null : () => _mostrarDialogoTarea(context, ref),
                icon: const Icon(Icons.check_box_outlined, size: 18),
                label: Text(l10n.eventDetailAddTask),
              ),
            ),
          ],
        ),

        // Log de actividad (HU-24)
        _Seccion(titulo: l10n.eventDetailActivityLog),
        actividad.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Text(l10n.commonError),
          data: (entradas) => entradas.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    l10n.eventDetailNoActivity,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (final entrada in entradas)
                      ActivityFeedItem(
                        icon: _iconoActividad(entrada.tipo),
                        iconColor: _colorActividad(entrada.tipo),
                        titulo: _textoActividad(l10n, entrada),
                        trailing: DateFormat('dd/MM HH:mm').format(entrada.createdAt),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Future<void> _mostrarDialogoTarea(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final api = ref.read(planifyApiProvider);

    final titulo = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.eventDetailAddTask),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: l10n.eventDetailTaskTitle),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text(l10n.commonAdd),
          ),
        ],
      ),
    );

    if (titulo != null && titulo.trim().isNotEmpty) {
      await onRun(() => api.createTask(eventoId: eventoId, titulo: titulo.trim()));
    }
  }

  Future<void> _mostrarDialogoGasto(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final descripcion = TextEditingController();
    final monto = TextEditingController();
    final api = ref.read(planifyApiProvider);

    // El pagador por defecto es el organizador del evento; en una iteración
    // futura se elige de una lista (HU-13 con múltiples acreedores).
    final participantes = ((evento['participantes'] as List<dynamic>?) ?? [])
        .map((p) => Participante.fromJson(p as Map<String, dynamic>))
        .toList();
    final pagador = participantes.firstWhere(
      (p) => p.esOrganizador,
      orElse: () => participantes.first,
    );

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.eventDetailAddExpense),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descripcion,
              autofocus: true,
              decoration: InputDecoration(hintText: l10n.eventDetailExpenseDescription),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: monto,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(hintText: l10n.eventDetailExpenseAmount),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.commonAdd),
          ),
        ],
      ),
    );

    if (confirmado == true &&
        descripcion.text.trim().isNotEmpty &&
        monto.text.trim().isNotEmpty) {
      await onRun(() => api.createExpense(
            eventoId: eventoId,
            descripcion: descripcion.text.trim(),
            montoTotal: monto.text.trim(),
            pagadorParticipanteId: pagador.id,
          ));
    }
  }

  static IconData _iconoActividad(String tipo) => switch (tipo) {
        'gasto_agregado' => Icons.receipt_long,
        'deuda_saldada' => Icons.price_check,
        'tarea_creada' || 'tarea_asignada' => Icons.checklist,
        'tarea_completada' => Icons.task_alt,
        'horario_confirmado' => Icons.event_available,
        'evento_cancelado' => Icons.event_busy,
        'participante_se_unio' => Icons.person_add,
        _ => Icons.bolt,
      };

  static Color _colorActividad(String tipo) => switch (tipo) {
        'gasto_agregado' => AppColors.danger,
        'deuda_saldada' || 'tarea_completada' => AppColors.success,
        'evento_cancelado' => AppColors.danger,
        'horario_confirmado' => AppColors.primary,
        _ => AppColors.warning,
      };

  static String _textoActividad(AppLocalizations l10n, ActividadLog entrada) {
    final actor = entrada.actorNombre;
    return switch (entrada.tipo) {
      'evento_creado' => l10n.activityEventCreated(actor),
      'horario_confirmado' => l10n.activityScheduleConfirmed(actor),
      'gasto_agregado' => l10n.activityExpenseAdded(actor),
      'deuda_saldada' => l10n.activityDebtSettled(actor),
      'tarea_creada' => l10n.activityTaskCreated(actor),
      'tarea_asignada' => l10n.activityTaskAssigned(actor),
      'tarea_completada' => l10n.activityTaskCompleted(actor),
      'participante_se_unio' => l10n.activityJoined(actor),
      'asistencia_confirmada' => l10n.activityAttendance(actor),
      'disponibilidad_cargada' => l10n.activityAvailability(actor),
      'evento_cancelado' => l10n.activityCancelled(actor),
      _ => actor,
    };
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
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}
