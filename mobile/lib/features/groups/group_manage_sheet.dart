import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/models.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/generated/app_localizations.dart';
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

            // HU-32 — agregar un amigo registrado
            ListTile(
              leading: const Icon(Icons.person_add_alt_1_outlined),
              title: Text(l10n.groupsAddMember),
              enabled: !_ocupado,
              onTap: () async {
                // Hasta que exista la gestión de amigos completa (SCRUM-14),
                // se agrega por id. Cuando esté, acá va un selector de amigos.
                final usuarioId = await _pedirTexto(
                  context,
                  titulo: l10n.groupsAddMember,
                  label: l10n.groupsFriendId,
                );
                if (usuarioId == null) return;
                await _accion(
                  () => repo.agregarMiembro(grupoId: widget.grupo.id, usuarioId: usuarioId),
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
  final controller = TextEditingController(text: inicial);

  final resultado = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(titulo),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(labelText: label),
        onSubmitted: (valor) => Navigator.pop(ctx, valor),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.commonCancel)),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, controller.text),
          child: Text(l10n.commonSave),
        ),
      ],
    ),
  );

  controller.dispose();
  final limpio = resultado?.trim();
  return (limpio == null || limpio.isEmpty) ? null : limpio;
}
