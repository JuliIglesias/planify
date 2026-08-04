import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/generated/app_localizations.dart';
import 'data/friends_repository.dart';

/// Selector de amigos (HU-31/32). Reemplaza el viejo input de UUID a mano (H-10)
/// y habilita elegir miembros al crear un evento (H-05).
///
/// Devuelve las personas elegidas, o `null` si se cancela. `multiple` decide si
/// se pueden elegir varias; `excluir` oculta a los que ya están (ej. miembros
/// actuales del grupo).
Future<List<Persona>?> elegirAmigos(
  BuildContext context,
  WidgetRef ref, {
  bool multiple = false,
  Set<String> excluir = const {},
}) {
  return showModalBottomSheet<List<Persona>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _FriendPickerSheet(multiple: multiple, excluir: excluir),
  );
}

class _FriendPickerSheet extends ConsumerStatefulWidget {
  const _FriendPickerSheet({required this.multiple, required this.excluir});

  final bool multiple;
  final Set<String> excluir;

  @override
  ConsumerState<_FriendPickerSheet> createState() => _FriendPickerSheetState();
}

class _FriendPickerSheetState extends ConsumerState<_FriendPickerSheet> {
  final Map<String, Persona> _seleccionados = {};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final amigos = ref.watch(friendsProvider);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                l10n.friendsPickTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Flexible(
              child: amigos.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, _) => Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text('$err'),
                ),
                data: (lista) {
                  final visibles =
                      lista.where((p) => !widget.excluir.contains(p.id)).toList();
                  if (visibles.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Text(l10n.friendsEmpty, textAlign: TextAlign.center),
                    );
                  }
                  return ListView(
                    shrinkWrap: true,
                    children: [
                      for (final amigo in visibles)
                        if (widget.multiple)
                          // Item 3 — `CheckboxListTile` ya hace clickeable
                          // toda la fila por defecto (no solo el checkbox);
                          // acá se suma el email como una sola unidad
                          // visual con el username.
                          CheckboxListTile(
                            title: Text(amigo.username),
                            subtitle: amigo.email != null
                                ? Text(amigo.email!,
                                    style: const TextStyle(color: AppColors.textSecondary))
                                : null,
                            value: _seleccionados.containsKey(amigo.id),
                            onChanged: (v) => setState(() {
                              if (v == true) {
                                _seleccionados[amigo.id] = amigo;
                              } else {
                                _seleccionados.remove(amigo.id);
                              }
                            }),
                          )
                        else
                          ListTile(
                            leading: const Icon(Icons.person_outline),
                            title: Text(amigo.username),
                            subtitle: amigo.email != null
                                ? Text(amigo.email!,
                                    style: const TextStyle(color: AppColors.textSecondary))
                                : null,
                            onTap: () => Navigator.pop(context, [amigo]),
                          ),
                    ],
                  );
                },
              ),
            ),
            if (widget.multiple)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _seleccionados.isEmpty
                        ? null
                        : () => Navigator.pop(context, _seleccionados.values.toList()),
                    child: Text(
                      l10n.friendsPickConfirm(_seleccionados.length),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}
