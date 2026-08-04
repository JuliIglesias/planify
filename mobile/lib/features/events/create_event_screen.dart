import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'data/ai_events_repository.dart';
import 'data/events_repository.dart';
import 'data/tasks_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/generated/app_localizations.dart';
import '../friends/data/friends_repository.dart';
import '../friends/friend_picker.dart';
import '../home/home_providers.dart';
import '../profile/data/profile_repository.dart';
import 'event_detail_screen.dart';

/// HU-06 — creación de evento en 2 pasos (NFR#3):
///   1. nombre + lugar (texto libre, no geolocalización)
///   2. grupo existente o miembros nuevos → crea grupo (HU-04/HU-05)
/// La fecha NO se elige acá: sale del heatmap de disponibilidad (Duda F4).
class CreateEventScreen extends ConsumerStatefulWidget {
  const CreateEventScreen({super.key});

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  final _nombre = TextEditingController();
  final _lugar = TextEditingController();
  final _nuevoGrupo = TextEditingController();

  int _paso = 0;
  String? _grupoSeleccionadoId;
  bool _creando = false;
  bool _generandoIA = false;
  final List<Persona> _miembros = [];
  final List<String> _tareasSugeridas = [];

  // Item 1 — rango de fechas calendario del evento. Arranca con un default
  // razonable (hoy + 2 semanas) que el organizador puede cambiar; así no
  // hace falta un tercer paso para cumplir NFR#3.
  DateTimeRange _rango = DateTimeRange(
    start: DateTime.now(),
    end: DateTime.now().add(const Duration(days: 14)),
  );

  @override
  void dispose() {
    _nombre.dispose();
    _lugar.dispose();
    _nuevoGrupo.dispose();
    super.dispose();
  }

  bool get _paso1Valido =>
      _nombre.text.trim().isNotEmpty && _lugar.text.trim().isNotEmpty;

  Future<void> _elegirRango() async {
    final hoy = DateTime.now();
    final inicio = DateTime(hoy.year, hoy.month, hoy.day);
    final elegido = await showDateRangePicker(
      context: context,
      firstDate: inicio,
      lastDate: inicio.add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(
        start: _rango.start.isBefore(inicio) ? inicio : _rango.start,
        end: _rango.end.isBefore(inicio) ? inicio.add(const Duration(days: 14)) : _rango.end,
      ),
    );
    if (elegido != null) setState(() => _rango = elegido);
  }

  bool get _paso2Valido =>
      _grupoSeleccionadoId != null || _nuevoGrupo.text.trim().isNotEmpty;

  Future<void> _crear() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _creando = true);

    try {
      final creandoGrupoNuevo = _grupoSeleccionadoId == null;
      final eventoId = await ref.read(eventsRepositoryProvider).crear(
            nombre: _nombre.text.trim(),
            lugarTexto: _lugar.text.trim(),
            rangoInicio: _rango.start,
            rangoFin: _rango.end,
            grupoId: _grupoSeleccionadoId,
            nuevoGrupoNombre: creandoGrupoNuevo ? _nuevoGrupo.text.trim() : null,
            // HU-04 (H-05): al crear un grupo nuevo se pueden elegir miembros;
            // el backend los suma al grupo y los vuelve participantes del evento.
            miembroUsuarioIds: creandoGrupoNuevo && _miembros.isNotEmpty
                ? _miembros.map((p) => p.id).toList()
                : null,
          );

      // HU-44b: crear las tareas que sugirió la IA (best-effort).
      for (final titulo in _tareasSugeridas) {
        try {
          await ref.read(tasksRepositoryProvider).crear(eventoId: eventoId, titulo: titulo);
        } catch (_) {
          // Si falla una tarea sugerida, no bloquea la creación del evento.
        }
      }

      if (!mounted) return;
      ref.invalidate(upcomingEventsProvider);
      ref.invalidate(groupsOverviewProvider);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => EventDetailScreen(eventoId: eventoId)),
      );
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.eventCreateError}: $err')),
      );
      setState(() => _creando = false);
    }
  }

  // HU-42/43/44b — describir el evento y que la IA arme un borrador editable.
  Future<void> _generarConIA() async {
    final l10n = AppLocalizations.of(context)!;
    final ctrl = TextEditingController();
    final descripcion = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.eventAiTitle),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(hintText: l10n.eventAiHint),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.commonCancel)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: Text(l10n.eventAiGenerate),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (descripcion == null || descripcion.isEmpty || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _generandoIA = true);
    try {
      final borrador = await ref.read(aiEventsRepositoryProvider).generar(descripcion);
      if (!mounted) return;
      setState(() {
        _nombre.text = borrador.nombre;
        _lugar.text = borrador.lugar;
        _tareasSugeridas
          ..clear()
          ..addAll(borrador.tareasSugeridas);
        for (final a in borrador.amigosSugeridos) {
          if (!_miembros.any((m) => m.id == a.id)) _miembros.add(a);
        }
      });
      if (borrador.nombresSinMatch.isNotEmpty) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.eventAiUnmatched(borrador.nombresSinMatch.join(', ')))),
        );
      }
    } catch (err) {
      if (mounted) messenger.showSnackBar(SnackBar(content: Text('$err')));
    } finally {
      if (mounted) setState(() => _generandoIA = false);
    }
  }

  // HU-B5 — elegir una ubicación favorita o guardar la actual.
  Future<void> _gestionarUbicaciones() async {
    final l10n = AppLocalizations.of(context)!;
    final repo = ref.read(profileRepositoryProvider);

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Consumer(
        builder: (ctx, refSheet, _) {
          final favs = refSheet.watch(favoriteLocationsProvider);
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(l10n.eventSavedPlaces,
                      style: Theme.of(ctx).textTheme.titleMedium),
                ),
                favs.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: CircularProgressIndicator(),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text('$e'),
                  ),
                  data: (lista) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final u in lista)
                        ListTile(
                          leading: const Icon(Icons.place_outlined),
                          title: Text(u.etiqueta),
                          subtitle: Text(u.texto),
                          onTap: () {
                            _lugar.text = u.texto;
                            setState(() {});
                            Navigator.pop(ctx);
                          },
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              await repo.eliminarUbicacion(u.id);
                              refSheet.invalidate(favoriteLocationsProvider);
                            },
                          ),
                        ),
                      if (_lugar.text.trim().isNotEmpty)
                        ListTile(
                          leading: const Icon(Icons.bookmark_add_outlined),
                          title: Text(l10n.eventSavePlace),
                          onTap: () async {
                            final etiqueta = await _pedirEtiqueta();
                            if (etiqueta == null) return;
                            await repo.crearUbicacion(etiqueta, _lugar.text.trim());
                            refSheet.invalidate(favoriteLocationsProvider);
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<String?> _pedirEtiqueta() async {
    final l10n = AppLocalizations.of(context)!;
    final ctrl = TextEditingController();
    final res = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.eventSavePlace),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(hintText: l10n.eventPlaceLabelHint),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.commonCancel)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
    ctrl.dispose();
    return (res == null || res.isEmpty) ? null : res;
  }

  Future<void> _elegirMiembros() async {
    final elegidos = await elegirAmigos(
      context,
      ref,
      multiple: true,
      excluir: _miembros.map((p) => p.id).toSet(),
    );
    if (elegidos == null) return;
    setState(() {
      for (final p in elegidos) {
        if (!_miembros.any((m) => m.id == p.id)) _miembros.add(p);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final grupos = ref.watch(groupsOverviewProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(l10n.eventCreateTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: _paso == 0 ? 0.5 : 1.0,
              backgroundColor: AppColors.border,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              _paso == 0 ? l10n.eventStep1Title : l10n.eventStep2Title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            Expanded(
              child: SingleChildScrollView(
                child: _paso == 0
                    ? Column(
                        children: [
                          // HU-42: describir el evento y que la IA lo pre-arme.
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _generandoIA || _creando ? null : _generarConIA,
                              icon: _generandoIA
                                  ? const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.auto_awesome, size: 18),
                              label: Text(l10n.eventAiButton),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextField(
                            controller: _nombre,
                            autofocus: true,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              labelText: l10n.eventNameLabel,
                              hintText: l10n.eventNameHint,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextField(
                            controller: _lugar,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              labelText: l10n.eventPlaceLabel,
                              hintText: l10n.eventPlaceHint,
                            ),
                          ),
                          // HU-B5 — ubicaciones favoritas reutilizables.
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: _creando ? null : _gestionarUbicaciones,
                              icon: const Icon(Icons.bookmark_border, size: 18),
                              label: Text(l10n.eventSavedPlaces),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          // Item 1 — rango de fechas calendario dentro del
                          // cual se busca el horario (distinto del horario
                          // puntual, que sigue saliendo del heatmap).
                          InkWell(
                            onTap: _creando ? null : _elegirRango,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.sm),
                              child: Row(
                                children: [
                                  const Icon(Icons.date_range_outlined,
                                      color: AppColors.primary),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(l10n.eventDateRangeLabel,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                    color: AppColors
                                                        .textSecondary)),
                                        Text(
                                          _formatearRango(_rango),
                                          style: theme.textTheme.bodyLarge,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right,
                                      color: AppColors.textSecondary),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            children: [
                              const Icon(Icons.info_outline,
                                  size: 16, color: AppColors.textSecondary),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: Text(
                                  l10n.eventDateComesLater,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.eventExistingGroup,
                              style: theme.textTheme.titleSmall),
                          const SizedBox(height: AppSpacing.sm),
                          grupos.when(
                            loading: () =>
                                const Center(child: CircularProgressIndicator()),
                            error: (_, __) => Text(l10n.commonError),
                            data: (lista) => RadioGroup<String>(
                              groupValue: _grupoSeleccionadoId,
                              onChanged: (v) => setState(() {
                                _grupoSeleccionadoId = v;
                                _nuevoGrupo.clear();
                              }),
                              child: Column(
                                children: [
                                  for (final grupo in lista)
                                    RadioListTile<String>(
                                      value: grupo.id,
                                      title: Text(grupo.nombre),
                                      subtitle: Text('${grupo.miembros.length}'),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const Divider(height: AppSpacing.xl),
                          Text(l10n.eventNewGroup, style: theme.textTheme.titleSmall),
                          const SizedBox(height: AppSpacing.sm),
                          TextField(
                            controller: _nuevoGrupo,
                            onChanged: (_) => setState(() {
                              if (_nuevoGrupo.text.isNotEmpty) {
                                _grupoSeleccionadoId = null;
                              }
                            }),
                            decoration: InputDecoration(
                              labelText: l10n.eventNewGroupName,
                            ),
                          ),
                          // HU-04 (H-05): elegir miembros para el grupo nuevo.
                          if (_grupoSeleccionadoId == null) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: _creando ? null : _elegirMiembros,
                                icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                                label: Text(l10n.groupsAddMember),
                              ),
                            ),
                            if (_miembros.isNotEmpty)
                              Wrap(
                                spacing: AppSpacing.xs,
                                children: [
                                  for (final m in _miembros)
                                    Chip(
                                      label: Text(m.nombre),
                                      onDeleted: _creando
                                          ? null
                                          : () => setState(() => _miembros.remove(m)),
                                    ),
                                ],
                              ),
                          ],
                        ],
                      ),
              ),
            ),

            Row(
              children: [
                if (_paso == 1)
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _creando ? null : () => setState(() => _paso = 0),
                      child: Text(l10n.eventBack),
                    ),
                  ),
                if (_paso == 1) const SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _creando
                        ? null
                        : _paso == 0
                            ? (_paso1Valido ? () => setState(() => _paso = 1) : null)
                            : (_paso2Valido ? _crear : null),
                    child: _creando
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_paso == 0 ? l10n.eventNext : l10n.eventCreate),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Item 1 — "1 ago – 20 ago" para mostrar el rango elegido sin ocupar lugar.
String _formatearRango(DateTimeRange rango) {
  final formato = DateFormat('d MMM', 'es');
  return '${formato.format(rango.start)} – ${formato.format(rango.end)}';
}
