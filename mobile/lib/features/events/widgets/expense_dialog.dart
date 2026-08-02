import 'package:flutter/material.dart';

import '../../../core/models/models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Datos con los que se da de alta un gasto (HU-13/HU-14, FR7).
///
/// Soporta **varios acreedores** (cada uno con cuánto puso) y **varios
/// deudores** (los ids entre los que se divide en partes iguales; el backend
/// reparte los centavos sobrantes para garantizar la exactitud de NFR#4).
class DatosGasto {
  const DatosGasto({
    required this.descripcion,
    required this.monto,
    required this.acreedores,
    required this.dividirEntre,
  });

  final String descripcion;
  final String monto;
  final List<({String participanteId, String monto})> acreedores;
  final List<String> dividirEntre;
}

/// Convierte "1.234,56" o "1234.56" a centavos enteros, igual criterio que el
/// backend (`toCents`), para que la validación del cliente y la del servidor
/// coincidan y no se rechace un gasto que "cerraba".
int _aCentavos(String texto) {
  final limpio = texto.trim().replaceAll(',', '.');
  final valor = double.tryParse(limpio) ?? 0;
  return (valor * 100).round();
}

String _formatoMonto(int centavos) => (centavos / 100).toStringAsFixed(2);

/// Hoja para cargar un gasto. Es una hoja inferior (Duda #27) porque es una
/// acción sobre un evento que ya se está mirando.
Future<DatosGasto?> pedirDatosGasto(
  BuildContext context,
  List<Participante> participantes,
) {
  if (participantes.isEmpty) return Future.value(null);

  return showModalBottomSheet<DatosGasto>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _ExpenseSheet(participantes: participantes),
  );
}

class _ExpenseSheet extends StatefulWidget {
  const _ExpenseSheet({required this.participantes});

  final List<Participante> participantes;

  @override
  State<_ExpenseSheet> createState() => _ExpenseSheetState();
}

class _ExpenseSheetState extends State<_ExpenseSheet> {
  final _descripcion = TextEditingController();
  final _montoTotal = TextEditingController();

  /// Un controlador de monto por participante, creado una vez y liberado al
  /// cerrar. Solo se leen los de quienes están marcados como pagadores.
  late final Map<String, TextEditingController> _montoPagador = {
    for (final p in widget.participantes) p.id: TextEditingController(),
  };

  final _pagadores = <String>{};
  late final _dividirEntre = <String>{...widget.participantes.map((p) => p.id)};

  @override
  void initState() {
    super.initState();
    // Caso más común (un solo pagador): al tipear el total, si hay exactamente
    // un pagador marcado, su aporte es el total.
    _montoTotal.addListener(_sincronizarPagadorUnico);
  }

  @override
  void dispose() {
    _descripcion.dispose();
    _montoTotal.dispose();
    for (final c in _montoPagador.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _sincronizarPagadorUnico() {
    if (_pagadores.length == 1) {
      _montoPagador[_pagadores.first]!.text = _montoTotal.text.trim();
    }
    setState(() {});
  }

  void _togglePagador(String id, bool marcado) {
    setState(() {
      if (marcado) {
        _pagadores.add(id);
      } else {
        _pagadores.remove(id);
        _montoPagador[id]!.clear();
      }
      // Con un único pagador, su aporte es el total: se autocompleta.
      if (_pagadores.length == 1) {
        _montoPagador[_pagadores.first]!.text = _montoTotal.text.trim();
      }
    });
  }

  void _repartirEntrePagadores() {
    if (_pagadores.isEmpty) return;
    final total = _aCentavos(_montoTotal.text);
    final n = _pagadores.length;
    final base = total ~/ n;
    var resto = total - base * n;
    for (final id in _pagadores) {
      final extra = resto > 0 ? 1 : 0;
      resto -= extra;
      _montoPagador[id]!.text = _formatoMonto(base + extra);
    }
    setState(() {});
  }

  int get _totalCents => _aCentavos(_montoTotal.text);

  int get _sumaPagadores =>
      _pagadores.fold(0, (acc, id) => acc + _aCentavos(_montoPagador[id]!.text));

  bool get _valido =>
      _descripcion.text.trim().isNotEmpty &&
      _totalCents > 0 &&
      _pagadores.isNotEmpty &&
      _sumaPagadores == _totalCents &&
      _dividirEntre.isNotEmpty;

  void _confirmar() {
    final l10n = AppLocalizations.of(context)!;
    if (!_valido) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.eventDetailExpenseInvalid)),
      );
      return;
    }

    Navigator.pop(
      context,
      DatosGasto(
        descripcion: _descripcion.text.trim(),
        monto: _formatoMonto(_totalCents),
        acreedores: [
          for (final id in _pagadores)
            (participanteId: id, monto: _formatoMonto(_aCentavos(_montoPagador[id]!.text))),
        ],
        dividirEntre: _dividirEntre.toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final diferencia = _totalCents - _sumaPagadores;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (context, scrollController) => ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Text(
                l10n.eventDetailAddExpense,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _descripcion,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(hintText: l10n.eventDetailExpenseDescription),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _montoTotal,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: l10n.eventDetailExpenseAmount,
                  prefixText: r'$ ',
                ),
              ),

              // ── Quién pagó (varios acreedores, FR7) ──────────────────────
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.eventDetailWhoPaid,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (_pagadores.length > 1)
                    TextButton(
                      onPressed: _repartirEntrePagadores,
                      child: Text(l10n.eventDetailSplitEqually),
                    ),
                ],
              ),
              for (final p in widget.participantes)
                _FilaPagador(
                  nombre: p.nombreDisplay,
                  marcado: _pagadores.contains(p.id),
                  // Con un único pagador el aporte es el total: no hace falta editarlo.
                  mostrarMonto: _pagadores.contains(p.id) && _pagadores.length > 1,
                  controller: _montoPagador[p.id]!,
                  onChanged: (v) => _togglePagador(p.id, v),
                  onMontoChanged: () => setState(() {}),
                ),
              if (_pagadores.length > 1 && diferencia != 0)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    diferencia > 0
                        ? l10n.eventDetailExpenseRemaining(_formatoMonto(diferencia))
                        : l10n.eventDetailExpenseExtra(_formatoMonto(-diferencia)),
                    style: theme.textTheme.bodySmall?.copyWith(color: AppColors.danger),
                  ),
                ),

              // ── Entre quiénes se divide (varios deudores, FR7) ───────────
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.eventDetailSplitAmong,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              for (final p in widget.participantes)
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: _dividirEntre.contains(p.id),
                  title: Text(p.nombreDisplay),
                  onChanged: (v) => setState(() {
                    if (v ?? false) {
                      _dividirEntre.add(p.id);
                    } else {
                      _dividirEntre.remove(p.id);
                    }
                  }),
                ),

              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.commonCancel),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _valido ? _confirmar : null,
                      child: Text(l10n.commonAdd),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilaPagador extends StatelessWidget {
  const _FilaPagador({
    required this.nombre,
    required this.marcado,
    required this.mostrarMonto,
    required this.controller,
    required this.onChanged,
    required this.onMontoChanged,
  });

  final String nombre;
  final bool marcado;
  final bool mostrarMonto;
  final TextEditingController controller;
  final ValueChanged<bool> onChanged;
  final VoidCallback onMontoChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            value: marcado,
            title: Text(nombre),
            onChanged: (v) => onChanged(v ?? false),
          ),
        ),
        if (mostrarMonto)
          SizedBox(
            width: 110,
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => onMontoChanged(),
              decoration: const InputDecoration(prefixText: r'$ ', isDense: true),
            ),
          ),
      ],
    );
  }
}
