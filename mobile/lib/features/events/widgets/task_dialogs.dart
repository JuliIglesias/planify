import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';

/// HU-20 — pide el título de una tarea nueva.
/// Está afuera de la pantalla para que el detalle del evento no crezca sin
/// control y para poder testear el diálogo por separado.
Future<String?> pedirTituloTarea(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;

  final resultado = await showDialog<String>(
    context: context,
    builder: (ctx) => _TaskTitleDialog(l10n: l10n),
  );

  final limpio = resultado?.trim();
  return (limpio == null || limpio.isEmpty) ? null : limpio;
}

class _TaskTitleDialog extends StatefulWidget {
  const _TaskTitleDialog({required this.l10n});

  final AppLocalizations l10n;

  @override
  State<_TaskTitleDialog> createState() => _TaskTitleDialogState();
}

class _TaskTitleDialogState extends State<_TaskTitleDialog> {
  String _titulo = '';

  void _submit() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pop(context, _titulo);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;

    return AlertDialog(
      title: Text(l10n.eventDetailAddTask),
      content: TextFormField(
        autofocus: true,
        initialValue: _titulo,
        decoration: InputDecoration(hintText: l10n.eventDetailTaskTitle),
        onChanged: (valor) => _titulo = valor,
        onFieldSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.commonAdd)),
      ],
    );
  }
}
