import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';


import '../../core/models/models.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/money_format.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/event_card.dart';
import '../../core/widgets/quick_action_button.dart';
import '../../core/widgets/status_badge.dart';
import '../../l10n/generated/app_localizations.dart';
import '../auth/session_controller.dart';
import '../friends/friend_picker.dart';
import '../groups/data/groups_repository.dart';
import '../home/home_providers.dart';
import 'data/events_repository.dart';
import 'data/expenses_repository.dart';
import 'data/tasks_repository.dart';
import 'event_config_screen.dart';
import 'widgets/expense_dialog.dart';
import 'widgets/activity_presentation.dart';
import 'widgets/task_dialogs.dart';
import '../balances/data/balances_repository.dart';

/// Detalle del evento (Item 4) — feed de actividad tipo chat: acciones
/// rápidas, tareas (HU-20..23), gastos y deudas (HU-13..19) y log de
/// actividad (HU-24). Asistencia y disponibilidad viven en la pantalla de
/// Configuración aparte (`EventConfigScreen`, ícono de engranaje del AppBar).
class EventDetailScreen extends ConsumerStatefulWidget {
  const EventDetailScreen({super.key, required this.eventoId});

  final String eventoId;

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
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
    final esAnonimo = ref.watch(sessionControllerProvider).value is SesionAnonima;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(detalle.value?.nombre ?? l10n.commonLoading),
        actions: [
          // Item 1 — un anónimo no tiene bottom nav ni Perfil: sin esto no
          // había forma de cerrar sesión para entrar a otro evento con un
          // username distinto.
          if (esAnonimo)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: l10n.profileLogout,
              onPressed: () =>
                  ref.read(sessionControllerProvider.notifier).cerrarSesion(),
            ),
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            tooltip: l10n.eventDetailInviteTitle,
            onPressed: !(detalle.value?.estaCancelado ?? false) ? _invitar : null,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.eventConfigTitle,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => EventConfigScreen(eventoId: widget.eventoId),
              ),
            ),
          ),
          if ((detalle.value?.soyOrganizador ?? false) && !(detalle.value?.estaCancelado ?? false))
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
          ocupado: _ocupado,
          onAccion: _accion,
          onInvitar: _invitar,
        ),
      ),
    );
  }

  /// Item 6 — agregar gente al evento tiene dos vías: amigos ya guardados
  /// (directo, sin link) o compartir el link de invitación.
  Future<void> _invitar() async {
    final l10n = AppLocalizations.of(context)!;

    final opcion = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_search_outlined),
              title: Text(l10n.eventDetailAddFriends),
              onTap: () => Navigator.pop(ctx, 'amigos'),
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: Text(l10n.eventDetailShareLink),
              onTap: () => Navigator.pop(ctx, 'link'),
            ),
          ],
        ),
      ),
    );

    if (!mounted || opcion == null) return;
    if (opcion == 'amigos') {
      await _agregarAmigosGuardados();
    } else {
      await _compartirLink();
    }
  }

  /// Se agregan directo, sin pedirles aceptación: mismo criterio que ya usa
  /// "Agregar amigo" en la gestión de grupo (`GroupsService.agregarMiembro`),
  /// que es lo que se termina llamando acá — ya son amigos dentro de la app.
  Future<void> _agregarAmigosGuardados() async {
    final l10n = AppLocalizations.of(context)!;
    final evento = ref.read(eventDetailProvider(widget.eventoId)).value;
    if (evento == null) return;

    final elegidos = await elegirAmigos(context, ref, multiple: true);
    if (elegidos == null || elegidos.isEmpty || !mounted) return;

    await _accion(() async {
      for (final amigo in elegidos) {
        await ref
            .read(groupsRepositoryProvider)
            .agregarMiembro(grupoId: evento.grupoId, usuarioId: amigo.id);
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.eventDetailFriendsAdded(elegidos.length))),
      );
    }
  }

  Future<void> _compartirLink() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final token = await ref.read(eventsRepositoryProvider).crearInvitacion(widget.eventoId);
      final inviteLink = 'planify://invite/$token';
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (ctx) => AppDialog(
          title: Text(l10n.eventDetailInviteTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.eventDetailInviteHint),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: SelectableText(
                  inviteLink,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.commonCancel),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.copy, size: 18),
              label: Text(l10n.eventDetailCopyLink),
              onPressed: () async {
                // Se captura el messenger antes del await para no usar el
                // BuildContext cruzando un gap async (H-12).
                final messenger = ScaffoldMessenger.of(context);
                await Clipboard.setData(ClipboardData(text: inviteLink));
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  messenger.showSnackBar(
                    SnackBar(content: Text(l10n.eventDetailLinkCopied)),
                  );
                }
              },
            ),
          ],
        ),
      );
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$err')));
      }
    }
  }

  Future<void> _confirmarCancelacion() async {
    final l10n = AppLocalizations.of(context)!;

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AppDialog(
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
    required this.ocupado,
    required this.onAccion,
    required this.onInvitar,
  });

  final DetalleEvento evento;
  final bool ocupado;
  final Future<void> Function(Future<void> Function()) onAccion;
  final VoidCallback onInvitar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    final fecha = evento.fechaHoraInicio != null
        ? DateFormat("EEEE d 'de' MMMM · HH:mm", 'es').format(evento.fechaHoraInicio!)
        : l10n.commonToBeDefined;

    final habilitado = !ocupado && !evento.estaCancelado;

    // Pull-to-refresh: si alguien se une al evento (anónimo por link) después de
    // abrir esta pantalla, el organizador puede refrescar y verlo (H-02).
    return RefreshIndicator(
      onRefresh: () async {
        invalidateEventData(ref, evento.id);
        await ref.read(eventDetailProvider(evento.id).future);
      },
      child: ListView(
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

        const SizedBox(height: AppSpacing.md),

        // ── Acciones rápidas (mockup "Log de Actividad") ──────────────────
        _Seccion(titulo: l10n.eventDetailQuickActions),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                QuickActionButton(
                  icon: Icons.person_add_outlined,
                  label: l10n.eventDetailInvite,
                  color: AppColors.primary,
                  onPressed: habilitado ? onInvitar : null,
                ),
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
                              onDescompletar: () => onAccion(() => ref
                                  .read(tasksRepositoryProvider)
                                  .descompletar(eventoId: evento.id, tareaId: tarea.id)),
                              onDesasignar: () => onAccion(() => ref
                                  .read(tasksRepositoryProvider)
                                  .desasignar(eventoId: evento.id, tareaId: tarea.id)),
                              onEliminar: () => onAccion(() => ref
                                  .read(tasksRepositoryProvider)
                                  .eliminar(eventoId: evento.id, tareaId: tarea.id)),
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
                        // Item 2 — varios "saldó su deuda" seguidos del
                        // mismo actor se fusionan nombrando a todas las
                        // contrapartes en una sola línea.
                        for (final grupo in agruparLogDeEvento(entradas))
                          ActivityFeedItem(
                            icon: iconoDeActividad(grupo.entrada.tipo),
                            iconColor: colorDeActividad(grupo.entrada.tipo),
                            titulo: textoActividadLogAgrupada(l10n, grupo),
                            trailing:
                                DateFormat('dd/MM HH:mm').format(grupo.entrada.createdAt),
                          ),
                      ],
                    ),
            ),
        const SizedBox(height: AppSpacing.xl),
      ],
      ),
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
    // Traer la lista más fresca antes de abrir el diálogo: alguien pudo unirse
    // (anónimo por link) después de que se cargó la pantalla (H-02). Si el
    // refetch falla, se usa lo que ya estaba en memoria.
    var participantes = evento.participantes;
    try {
      ref.invalidate(eventDetailProvider(evento.id));
      participantes = (await ref.read(eventDetailProvider(evento.id).future)).participantes;
    } catch (_) {
      // Sin red: seguimos con la lista actual en vez de bloquear la carga.
    }
    if (!context.mounted) return;

    final datos = await pedirDatosGasto(context, participantes);
    if (datos == null) return;

    await onAccion(
      () => ref.read(expensesRepositoryProvider).crear(
            eventoId: evento.id,
            descripcion: datos.descripcion,
            montoTotal: datos.montoTotal,
            acreedores: [
              for (final a in datos.acreedores)
                AporteGasto(participanteId: a.participanteId, monto: a.monto),
            ],
            deudores: datos.deudores?.map(
              (d) => AporteGasto(participanteId: d.participanteId, monto: d.monto),
            ).toList(),
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
                subtitle: Text('\$${MoneyFormat.format(deuda.monto)}'),
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
}

class _TareaTile extends StatelessWidget {
  const _TareaTile({
    required this.tarea,
    required this.participantes,
    required this.habilitado,
    required this.onTomar,
    required this.onAsignarA,
    required this.onCompletar,
    required this.onDescompletar,
    required this.onDesasignar,
    required this.onEliminar,
  });

  final Tarea tarea;
  final List<Participante> participantes;
  final bool habilitado;
  final VoidCallback onTomar;
  final ValueChanged<String> onAsignarA;
  final VoidCallback onCompletar;
  final VoidCallback onDescompletar;
  final VoidCallback onDesasignar;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final esTomar = tarea.estaSinAsignar;
    final esCompletada = tarea.estaCompletada;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Slidable(
        key: ValueKey(tarea.id),
        enabled: habilitado,
        startActionPane: ActionPane(
          motion: const ScrollMotion(),
          dismissible: DismissiblePane(
            onDismissed: esTomar
                ? onTomar
                : (esCompletada ? onDescompletar : onCompletar),
          ),
          children: [
            SlidableAction(
              onPressed: (_) => esTomar
                  ? onTomar()
                  : (esCompletada ? onDescompletar() : onCompletar()),
              backgroundColor: esCompletada ? Colors.orange : AppColors.success,
              foregroundColor: Colors.white,
              icon: esCompletada ? Icons.undo : Icons.check,
              label: esCompletada ? 'Deshacer' : (esTomar ? 'Tomar' : 'Completar'),
            ),
          ],
        ),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          dismissible: DismissiblePane(
            onDismissed: onEliminar,
          ),
          children: [
            SlidableAction(
              onPressed: (_) => onEliminar(),
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Eliminar',
            ),
            if (!tarea.estaSinAsignar)
              SlidableAction(
                onPressed: (_) => onDesasignar(),
                backgroundColor: Colors.grey.shade600,
                foregroundColor: Colors.white,
                icon: Icons.person_off,
                label: 'Desasignar',
              ),
          ],
        ),
        child: ListTile(
          leading: Icon(
            tarea.estaCompletada ? Icons.check_circle : Icons.radio_button_unchecked,
            color: tarea.estaCompletada ? AppColors.success : AppColors.textSecondary,
          ),
          title: Text(tarea.titulo),
          subtitle: Text(tarea.asignadoNombre ?? l10n.eventDetailTaskUnassigned),
          trailing: tarea.estaCompletada
              ? Text(l10n.eventDetailTaskDone)
              : (tarea.estaSinAsignar
                  ? PopupMenuButton<String>(
                      enabled: habilitado,
                      icon: const Icon(Icons.person_add_alt, size: 20),
                      tooltip: l10n.eventDetailAssignTo,
                      onSelected: onAsignarA,
                      itemBuilder: (_) => [
                        for (final p in participantes)
                          PopupMenuItem(value: p.id, child: Text(p.nombreDisplay)),
                      ],
                    )
                  : const SizedBox.shrink()),
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
