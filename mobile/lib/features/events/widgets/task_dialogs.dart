import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';

/// HU-20 — pide el título de una tarea nueva.
/// Está afuera de la pantalla para que el detalle del evento no crezca sin
/// control y para poder testear el diálogo por separado.
Future<String?> pedirTituloTarea(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final controller = TextEditingController();

  final resultado = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.eventDetailAddTask),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(hintText: l10n.eventDetailTaskTitle),
        onSubmitted: (valor) => Navigator.pop(ctx, valor),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.commonCancel)),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, controller.text),
          child: Text(l10n.commonAdd),
        ),
      ],
    ),
  );

  controller.dispose();

  final limpio = resultado?.trim();
  return (limpio == null || limpio.isEmpty) ? null : limpio;
}
