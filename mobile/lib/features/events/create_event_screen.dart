import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/planify_api.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/generated/app_localizations.dart';
import '../home/home_providers.dart';
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

  @override
  void dispose() {
    _nombre.dispose();
    _lugar.dispose();
    _nuevoGrupo.dispose();
    super.dispose();
  }

  bool get _paso1Valido =>
      _nombre.text.trim().isNotEmpty && _lugar.text.trim().isNotEmpty;

  bool get _paso2Valido =>
      _grupoSeleccionadoId != null || _nuevoGrupo.text.trim().isNotEmpty;

  Future<void> _crear() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _creando = true);

    try {
      final eventoId = await ref.read(planifyApiProvider).createEvent(
            nombre: _nombre.text.trim(),
            lugarTexto: _lugar.text.trim(),
            grupoId: _grupoSeleccionadoId,
            nuevoGrupoNombre:
                _grupoSeleccionadoId == null ? _nuevoGrupo.text.trim() : null,
          );

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
