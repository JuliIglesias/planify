import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/models/models.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/app_text_field.dart';
import '../../l10n/generated/app_localizations.dart';
import '../friends/friend_picker.dart';
import '../home/home_providers.dart';
import 'data/groups_repository.dart';
import 'group_availability_screen.dart';

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
              // `bodySmall` ya usa el gris secundario del tema.
              child: Text(
                '${l10n.groupsMembers}: ${widget.grupo.miembros.length}',
                style: theme.textTheme.bodySmall,
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
                  () => repo.actualizar(grupoId: widget.grupo.id, nombre: nombre),
                  cerrar: true,
                );
              },
            ),

            // Cambiar imagen — Item 5 (Tanda 6): abre la galería nativa del
            // dispositivo en vez de pedir una URL de texto.
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: Text(l10n.groupsUpdateImage),
              enabled: !_ocupado,
              onTap: () async {
                final imagen = await ImagePicker().pickImage(source: ImageSource.gallery);
                if (imagen == null) return;
                final bytes = await imagen.readAsBytes();
                await _accion(
                  () => repo.subirImagen(
                    grupoId: widget.grupo.id,
                    bytes: bytes,
                    nombreArchivo: imagen.name,
                  ),
                  cerrar: true,
                );
              },
            ),

            // Ver disponibilidad del grupo — Item 5 (Tanda 6): heatmap
            // scopeado a los miembros de ESTE grupo (ya no "todos los
            // amigos", eso se eliminó de Perfil).
            ListTile(
              leading: const Icon(Icons.event_available_outlined),
              title: Text(l10n.groupsSeeAvailability),
              trailing: const Icon(Icons.chevron_right),
              enabled: !_ocupado,
              onTap: () {
                final navigator = Navigator.of(context);
                navigator.pop();
                navigator.push(
                  MaterialPageRoute<void>(
                    builder: (_) => GroupAvailabilityScreen(grupoId: widget.grupo.id),
                  ),
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

            // HU-33 — abandonar el grupo. Acción destructiva —
            // `colorScheme.error`, no el rojo financiero (mismo criterio que
            // "Cerrar sesión" en Perfil, docs/06-design-system.md §3.6).
            ListTile(
              leading: Icon(Icons.logout, color: theme.colorScheme.error),
              title: Text(
                l10n.groupsLeave,
                style: TextStyle(color: theme.colorScheme.error),
              ),
              enabled: !_ocupado,
              onTap: () async {
                final confirmado = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AppDialog(
                    title: Text(l10n.groupsLeave),
                    content: Text(l10n.groupsLeaveConfirm),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(l10n.commonCancel),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Theme.of(ctx).colorScheme.error,
                        ),
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
    builder: (ctx) => AppDialog(
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
