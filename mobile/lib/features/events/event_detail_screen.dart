import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';


import '../../core/models/models.dart';
import '../../core/theme/app_semantic_colors.dart';
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
        backgroundColor: Theme.of(context).colorScheme.surface,
        // Item 2 — el nombre se movió al body (ver `_Contenido`): el AppBar
        // lo forzaba a una sola línea con "...", perdiendo nombres largos.
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
            // C2 — antes era una rueda dentada (ícono de "configuración"
            // genérica); esta pantalla en realidad abre disponibilidad y
            // confirmación de asistencia, no ajustes del evento en general,
            // así que un calendario con un tilde comunica mejor qué hay ahí.
            icon: const Icon(Icons.event_available_outlined),
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
              // Mismo par primaryContainer/onPrimaryContainer que el
              // banner de invitación pendiente de Login y el de
              // compensación de Balances.
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: SelectableText(
                  inviteLink,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(ctx).colorScheme.onPrimaryContainer,
                  ),
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
          // Acción destructiva — colorScheme.error, no el rojo financiero
          // (mismo criterio que "Abandonar grupo"/"Cerrar sesión").
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
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

class _Contenido extends ConsumerStatefulWidget {
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
  ConsumerState<_Contenido> createState() => _ContenidoState();
}

class _ContenidoState extends ConsumerState<_Contenido> {
  /// B2 — tareas que están a mitad de un swipe-to-dismiss: `flutter_slidable`
  /// exige que el widget salga del árbol de inmediato apenas termina la
  /// animación de resize del dismiss (si no, tira "A dismissed Slidable
  /// widget is still part of the tree"). Como la mutación real es async
  /// (red + `invalidateEventData` + refetch), no podemos esperar a que
  /// vuelva para sacar la tarea de la lista: la escondemos acá apenas se
  /// dispara el gesto, y recién la soltamos cuando `eventTasksProvider` ya
  /// tiene el dato fresco — así el tile no reaparece con estado viejo, y
  /// cuando reaparece es literalmente un widget nuevo (con `resized` en
  /// `false` de nuevo), no el mismo que ya se había dismisseado.
  final Set<String> _tareasEnVueloDeSwipe = {};

  Future<void> _accionDeSwipe(String tareaId, Future<void> Function() accion) async {
    setState(() => _tareasEnVueloDeSwipe.add(tareaId));
    // `flutter_slidable` exige que el Slidable dismisseado desaparezca del
    // árbol EN EL FRAME SIGUIENTE al dismiss, no "eventualmente" — si el
    // round-trip de red resuelve muy rápido (o de forma sincrónica, como con
    // un repo fake en tests), el ciclo completo add→remove puede terminar
    // antes de que Flutter llegue a pintar un solo frame con la tarea ya
    // afuera, y el Element viejo (con `resized` en `true`) nunca se
    // desmonta: sigue estando ahí para el próximo rebuild → misma excepción
    // de siempre. Esperar el fin del frame actual garantiza que ese frame
    // "tarea afuera" se pinte de verdad antes de seguir.
    await SchedulerBinding.instance.endOfFrame;
    try {
      await widget.onAccion(accion);
      // `onAccion` ya invalidó el provider; esperamos a que el refetch
      // realmente termine antes de volver a mostrar la tarea, para no
      // mostrarla un instante con el estado viejo.
      await ref.read(eventTasksProvider(widget.evento.id).future);
    } finally {
      if (mounted) setState(() => _tareasEnVueloDeSwipe.remove(tareaId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final semantic = context.appSemanticColors;
    final evento = widget.evento;

    final fecha = evento.fechaHoraInicio != null
        ? DateFormat("EEEE d 'de' MMMM · HH:mm", 'es').format(evento.fechaHoraInicio!)
        : l10n.commonToBeDefined;

    final habilitado = !widget.ocupado && !evento.estaCancelado;

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
        // ── Nombre, lugar y fecha (Item 2) ──────────────────────────────
        // El nombre nunca se corta (hasta 2 líneas); lugar y fecha son de
        // los datos más importantes de la pantalla, así que llevan la
        // misma jerarquía que el nombre de cualquier card (bodyLarge,
        // color primario) en vez de quedar como texto secundario perdido.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                evento.nombre,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (evento.estaCancelado) ...[
              const SizedBox(width: AppSpacing.sm),
              // Estado negativo general — colorScheme.error, no el rojo
              // financiero (cancelar un evento no es un monto "debo").
              StatusBadge(label: l10n.eventDetailCancelled, color: theme.colorScheme.error),
            ] else if (evento.estaFinalizado) ...[
              const SizedBox(width: AppSpacing.sm),
              StatusBadge.saldo(SaldoEstado.saldado, l10n.balancesStateSettled),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _InfoRow(icon: Icons.place_outlined, texto: evento.lugarTexto),
        const SizedBox(height: AppSpacing.xs),
        _InfoRow(icon: Icons.calendar_today_outlined, texto: fecha),

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
                  color: theme.colorScheme.primary,
                  onPressed: habilitado ? widget.onInvitar : null,
                ),
                QuickActionButton(
                  icon: Icons.receipt_long_outlined,
                  label: l10n.eventDetailAddExpense,
                  color: semantic.danger,
                  onPressed: habilitado ? () => _agregarGasto(context) : null,
                ),
                QuickActionButton(
                  icon: Icons.check_box_outlined,
                  label: l10n.eventDetailAddTask,
                  color: semantic.warning,
                  onPressed: habilitado ? () => _agregarTarea(context) : null,
                ),
                QuickActionButton(
                  icon: Icons.price_check,
                  label: l10n.eventDetailSettle,
                  color: semantic.success,
                  onPressed: habilitado ? () => _mostrarDeudas(context) : null,
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
              data: (todasLasTareas) {
                // B2 — las que están a mitad de un swipe-to-dismiss no se
                // pintan: así el tile sale del árbol de inmediato, como
                // exige `flutter_slidable`, en vez de esperar al refetch.
                final tareas = todasLasTareas
                    .where((t) => !_tareasEnVueloDeSwipe.contains(t.id))
                    .toList();
                return tareas.isEmpty
                    ? _TextoVacio(l10n.eventDetailNoTasks)
                    : Column(
                        children: [
                          for (final tarea in tareas)
                            _TareaTile(
                              tarea: tarea,
                              participantes: evento.participantes,
                              habilitado: habilitado,
                              onTomar: () => _accionDeSwipe(
                                  tarea.id,
                                  () => ref
                                      .read(tasksRepositoryProvider)
                                      .asignar(eventoId: evento.id, tareaId: tarea.id)),
                              onAsignarA: (participanteId) => widget.onAccion(() => ref
                                  .read(tasksRepositoryProvider)
                                  .asignar(
                                    eventoId: evento.id,
                                    tareaId: tarea.id,
                                    asignadoA: participanteId,
                                  )),
                              onCompletar: () => _accionDeSwipe(
                                  tarea.id,
                                  () => ref
                                      .read(tasksRepositoryProvider)
                                      .completar(eventoId: evento.id, tareaId: tarea.id)),
                              onDescompletar: () => _accionDeSwipe(
                                  tarea.id,
                                  () => ref
                                      .read(tasksRepositoryProvider)
                                      .descompletar(eventoId: evento.id, tareaId: tarea.id)),
                              onDesasignar: () => widget.onAccion(() => ref
                                  .read(tasksRepositoryProvider)
                                  .desasignar(eventoId: evento.id, tareaId: tarea.id)),
                              onEliminar: () => _accionDeSwipe(
                                  tarea.id,
                                  () => ref
                                      .read(tasksRepositoryProvider)
                                      .eliminar(eventoId: evento.id, tareaId: tarea.id)),
                            ),
                        ],
                      );
              },
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

  Future<void> _agregarTarea(BuildContext context) async {
    final titulo = await pedirTituloTarea(context);
    if (titulo == null) return;
    await widget.onAccion(
      () => ref
          .read(tasksRepositoryProvider)
          .crear(eventoId: widget.evento.id, titulo: titulo),
    );
  }

  Future<void> _agregarGasto(BuildContext context) async {
    // Traer la lista más fresca antes de abrir el diálogo: alguien pudo unirse
    // (anónimo por link) después de que se cargó la pantalla (H-02). Si el
    // refetch falla, se usa lo que ya estaba en memoria.
    var participantes = widget.evento.participantes;
    try {
      ref.invalidate(eventDetailProvider(widget.evento.id));
      participantes =
          (await ref.read(eventDetailProvider(widget.evento.id).future)).participantes;
    } catch (_) {
      // Sin red: seguimos con la lista actual en vez de bloquear la carga.
    }
    if (!context.mounted) return;

    final datos = await pedirDatosGasto(context, participantes);
    if (datos == null) return;

    await widget.onAccion(
      () => ref.read(expensesRepositoryProvider).crear(
            eventoId: widget.evento.id,
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


  Future<void> _mostrarDeudas(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final deudas = await ref.read(eventDebtsProvider(widget.evento.id).future);

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
                title: Text('${deuda.deudorUsername} → ${deuda.acreedorUsername}'),
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
    await widget.onAccion(
      () => ref
          .read(balancesRepositoryProvider)
          .saldar(eventoId: widget.evento.id, deudaId: deudaId),
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
    final theme = Theme.of(context);
    final semantic = context.appSemanticColors;

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
              // "Deshacer" (descompletar) → warning; el resto de estados
              // positivos ya usan `success` en toda la app.
              backgroundColor: esCompletada ? semantic.warning : semantic.success,
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
            // Eliminar — acción destructiva: colorScheme.error, no el rojo
            // financiero.
            SlidableAction(
              onPressed: (_) => onEliminar(),
              backgroundColor: theme.colorScheme.error,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Eliminar',
            ),
            // C1 — una tarea completada no se puede desasignar: primero hay
            // que descompletarla (swipe/tap en "Deshacer" del otro extremo).
            if (!tarea.estaSinAsignar && !esCompletada)
              SlidableAction(
                onPressed: (_) => onDesasignar(),
                backgroundColor: theme.colorScheme.onSurfaceVariant,
                foregroundColor: Colors.white,
                icon: Icons.person_off,
                label: 'Desasignar',
              ),
          ],
        ),
        child: ListTile(
          leading: Icon(
            tarea.estaCompletada ? Icons.check_circle : Icons.radio_button_unchecked,
            color: tarea.estaCompletada ? semantic.success : theme.colorScheme.onSurfaceVariant,
          ),
          title: Text(tarea.titulo),
          subtitle: Text(tarea.asignadoUsername ?? l10n.eventDetailTaskUnassigned),
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
                          PopupMenuItem(value: p.id, child: Text(p.username)),
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

/// Item 2 — lugar y fecha con ícono, en su propia línea y con jerarquía de
/// texto primario (antes iban concatenados en una sola oración chica y
/// gris, como si fueran secundarios).
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.texto});

  final IconData icon;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: AppSpacing.xs),
        // `bodyLarge` ya usa el gris de cuerpo del tema — sin override.
        Expanded(
          child: Text(texto, style: Theme.of(context).textTheme.bodyLarge),
        ),
      ],
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
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Text(texto, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}
