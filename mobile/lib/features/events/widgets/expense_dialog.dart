import 'package:flutter/material.dart';

import '../../../core/models/models.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Datos con los que se da de alta un gasto (HU-13).
class DatosGasto {
  const DatosGasto({
    required this.descripcion,
    required this.monto,
    required this.pagadorId,
  });

  final String descripcion;
  final String monto;
  final String pagadorId;
}

/// Pide descripción, monto y quién pagó.
/// Por ahora un solo pagador; el charter contempla varios acreedores (FR7),
/// que queda como mejora dentro de SCRUM-11.
Future<DatosGasto?> pedirDatosGasto(
  BuildContext context,
  List<Participante> participantes,
) async {
  if (participantes.isEmpty) return null;

  final l10n = AppLocalizations.of(context)!;
  final descripcion = TextEditingController();
  final monto = TextEditingController();

  var pagadorId = participantes
      .firstWhere(
        (p) => p.esOrganizador,
        orElse: () => participantes.first,
      )
      .id;

  final resultado = await showDialog<DatosGasto>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(l10n.eventDetailAddExpense),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descripcion,
              autofocus: true,
              decoration: InputDecoration(hintText: l10n.eventDetailExpenseDescription),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: monto,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: l10n.eventDetailExpenseAmount,
                prefixText: r'$ ',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String>(
              initialValue: pagadorId,
              decoration: InputDecoration(labelText: l10n.eventDetailWhoPaid),
              items: [
                for (final p in participantes)
                  DropdownMenuItem(value: p.id, child: Text(p.nombreDisplay)),
              ],
              onChanged: (valor) => setState(() => pagadorId = valor ?? pagadorId),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.commonCancel)),
          FilledButton(
            onPressed: () {
              final texto = monto.text.trim().replaceAll(',', '.');
              final valor = double.tryParse(texto);
              if (descripcion.text.trim().isEmpty || valor == null || valor <= 0) {
                // Validación mínima acá: el backend vuelve a validar que los
                // aportes cierren con el total (NFR#4).
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text(l10n.eventDetailExpenseInvalid)),
                );
                return;
              }
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!ctx.mounted) return;
                Navigator.pop(
                  ctx,
                  DatosGasto(
                    descripcion: descripcion.text.trim(),
                    monto: valor.toStringAsFixed(2),
                    pagadorId: pagadorId,
                  ),
                );
              });
            },
            child: Text(l10n.commonAdd),
          ),
        ],
      ),
    ),
  );

  descripcion.dispose();
  monto.dispose();
  return resultado;
}
