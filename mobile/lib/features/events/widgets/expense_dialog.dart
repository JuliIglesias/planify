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
    required this.deudoresIds,
  });

  final String descripcion;
  final String monto;
  final String pagadorId;
  final List<String> deudoresIds;
}

/// Pide descripción, monto, quién pagó y entre quiénes se divide el costo.
Future<DatosGasto?> pedirDatosGasto(
  BuildContext context,
  List<Participante> participantes,
) async {
  if (participantes.isEmpty) return null;

  return showDialog<DatosGasto>(
    context: context,
    builder: (ctx) => _ExpenseDialog(participantes: participantes),
  );
}

class _ExpenseDialog extends StatefulWidget {
  const _ExpenseDialog({required this.participantes});

  final List<Participante> participantes;

  @override
  State<_ExpenseDialog> createState() => _ExpenseDialogState();
}

class _ExpenseDialogState extends State<_ExpenseDialog> {
  late final TextEditingController _descripcionController;
  late final TextEditingController _montoController;
  late String _pagadorId;
  late final Set<String> _deudoresSeleccionados;

  @override
  void initState() {
    super.initState();
    _descripcionController = TextEditingController();
    _montoController = TextEditingController();

    _pagadorId = widget.participantes
        .firstWhere(
          (p) => p.esOrganizador,
          orElse: () => widget.participantes.first,
        )
        .id;

    _deudoresSeleccionados = <String>{for (final p in widget.participantes) p.id};
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    _montoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.eventDetailAddExpense),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _descripcionController,
              autofocus: true,
              decoration: InputDecoration(hintText: l10n.eventDetailExpenseDescription),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _montoController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: l10n.eventDetailExpenseAmount,
                prefixText: r'$ ',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String>(
              value: _pagadorId,
              decoration: InputDecoration(labelText: l10n.eventDetailWhoPaid),
              items: [
                for (final p in widget.participantes)
                  DropdownMenuItem(value: p.id, child: Text(p.nombreDisplay)),
              ],
              onChanged: (valor) {
                if (valor != null) {
                  setState(() => _pagadorId = valor);
                }
              },
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.eventDetailDivideBetween,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.xs),
            Column(
              children: [
                for (final p in widget.participantes)
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(p.nombreDisplay),
                    value: _deudoresSeleccionados.contains(p.id),
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          _deudoresSeleccionados.add(p.id);
                        } else {
                          if (_deudoresSeleccionados.length > 1) {
                            _deudoresSeleccionados.remove(p.id);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.eventDetailSelectAtLeastOne)),
                            );
                          }
                        }
                      });
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.commonCancel)),
        FilledButton(
          onPressed: () {
            final texto = _montoController.text.trim().replaceAll(',', '.');
            final valor = double.tryParse(texto);
            if (_descripcionController.text.trim().isEmpty ||
                valor == null ||
                valor <= 0 ||
                _deudoresSeleccionados.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.eventDetailExpenseInvalid)),
              );
              return;
            }
            Navigator.pop(
              context,
              DatosGasto(
                descripcion: _descripcionController.text.trim(),
                monto: valor.toStringAsFixed(2),
                pagadorId: _pagadorId,
                deudoresIds: _deudoresSeleccionados.toList(),
              ),
            );
          },
          child: Text(l10n.commonAdd),
        ),
      ],
    );
  }
}
