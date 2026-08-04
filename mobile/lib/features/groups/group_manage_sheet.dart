import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/models.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_text_field.dart';
import '../../l10n/generated/app_localizations.dart';
import '../friends/friend_picker.dart';
import '../home/home_providers.dart';
import 'data/groups_repository.dart';

/// Gestión de miembros del grupo — HU-32/33/34 (Duda #12.2).
/// Es una hoja inferior en vez de una pantalla completa porque son acciones
/// puntuales sobre un grupo que ya se está mirando.
Future<void> mostrarGestionDeGrupo(BuildContext context, GrupoResumen grupo) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _GestionGrupoSheet(grupo: grupo),
  );
}

class _GestionGrupoSheet extends ConsumerStatefulWidget {
  const _GestionGrupoSheet({required this.grupo});

  final GrupoResumen grupo;

  @override
  ConsumerState<_GestionGrupoSheet> createState() => _GestionGrupoSheetState();
}

class _GestionGrupoSheetState extends ConsumerState<_GestionGrupoSheet> {
  bool _ocupado = false;

  Future<void> _accion(Future<void> Function() accion, {bool cerrar = false}) async {
    if (_ocupado) return;
    setState(() => _ocupado = true);

    try {
      await accion();
      if (!mounted) return;
      invalidateListas(ref);
      if (cerrar) Navigator.pop(context);
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
    final repo = ref.read(groupsRepositoryProvider);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                widget.grupo.nombre,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                '${l10n.groupsMembers}: ${widget.grupo.miembros.length}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // HU-34 — renombrar
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(l10n.groupsRename),
              enabled: !_ocupado,
              onTap: () async {
                final nombre = await _pedirTexto(
                  context,
                  titulo: l10n.groupsRename,
                  label: l10n.groupsNewName,
                  inicial: widget.grupo.nombre,
                );
                if (nombre == null) return;
                await _accion(
                  () => repo.renombrar(grupoId: widget.grupo.id, nombre: nombre),
                  cerrar: true,
                );
              },
            ),

            // HU-32 — agregar un amigo registrado (selector de amigos, H-10)
            ListTile(
              leading: const Icon(Icons.person_add_alt_1_outlined),
              title: Text(l10n.groupsAddMember),
              enabled: !_ocupado,
              onTap: () async {
                final elegidos = await elegirAmigos(context, ref);
                if (elegidos == null || elegidos.isEmpty) return;
                await _accion(
                  () => repo.agregarMiembro(
                    grupoId: widget.grupo.id,
                    usuarioId: elegidos.first.id,
                  ),
                  cerrar: true,
                );
              },
            ),

            // HU-33 — abandonar el grupo
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.danger),
              title: Text(
                l10n.groupsLeave,
                style: const TextStyle(color: AppColors.danger),
              ),
              enabled: !_ocupado,
              onTap: () async {
                final confirmado = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(l10n.groupsLeave),
                    content: Text(l10n.groupsLeaveConfirm),
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
                if (confirmado != true) return;
                await _accion(() => repo.abandonar(widget.grupo.id), cerrar: true);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

Future<String?> _pedirTexto(
  BuildContext context, {
  required String titulo,
  required String label,
  String? inicial,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final ctrl = TextEditingController(text: inicial ?? '');

  void cerrar(BuildContext dialogContext, String? resultado) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!dialogContext.mounted) return;
      Navigator.pop(dialogContext, resultado);
    });
  }

  final resultado = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(titulo),
      content: AppTextField(
        controller: ctrl,
        autofocus: true,
        decoration: InputDecoration(labelText: label),
        onSubmitted: (_) => cerrar(ctx, ctrl.text),
      ),
      actions: [
        TextButton(onPressed: () => cerrar(ctx, null), child: Text(l10n.commonCancel)),
        FilledButton(
          onPressed: () => cerrar(ctx, ctrl.text),
          child: Text(l10n.commonSave),
        ),
      ],
    ),
  );
  // El diálogo ya se cerró; liberamos el controller en el siguiente frame.
  WidgetsBinding.instance.addPostFrameCallback((_) => ctrl.dispose());
  final limpio = resultado?.trim();
  return (limpio == null || limpio.isEmpty) ? null : limpio;
}
