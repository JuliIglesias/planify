import 'package:flutter/material.dart';

import '../../../core/models/models.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/money_format.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Un aporte de un pagador dentro de un gasto (soporta varios — FR7).
typedef AporteInput = ({String participanteId, String monto});

/// Datos con los que se da de alta un gasto (HU-13/HU-14, FR7).
class DatosGasto {
  const DatosGasto({
    required this.descripcion,
    required this.montoTotal,
    required this.acreedores,
    this.deudoresIds,
    this.deudores,
  });

  final String descripcion;
  final String montoTotal;

  /// Uno o varios pagadores, con cuánto puso cada uno (FR7).
  final List<AporteInput> acreedores;
  final List<String>? deudoresIds;
  final List<AporteInput>? deudores;
}

/// Pide descripción, monto, quién(es) pagó(aron) y entre quiénes se divide.
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

  /// Pagadores seleccionados y el monto que puso cada uno (texto editable).
  final Set<String> _acreedores = {};
  final Map<String, TextEditingController> _montoPorAcreedor = {};

  final Set<String> _deudoresSeleccionados = {};
  final Map<String, TextEditingController> _montoPorDeudor = {};

  @override
  void initState() {
    super.initState();
    _descripcionController = TextEditingController();
    _montoController = TextEditingController()..addListener(_alCambiarTotal);

    // Por defecto paga el organizador (o el primero) y se divide entre todos.
    final pagadorInicial = widget.participantes
        .firstWhere((p) => p.esOrganizador, orElse: () => widget.participantes.first)
        .id;
    _acreedores.add(pagadorInicial);
    for (final p in widget.participantes) {
      _montoPorAcreedor[p.id] = TextEditingController();
      _montoPorDeudor[p.id] = TextEditingController();
    }
    _deudoresSeleccionados.addAll(widget.participantes.map((p) => p.id));
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    _montoController.dispose();
    for (final c in _montoPorAcreedor.values) {
      c.dispose();
    }
    for (final c in _montoPorDeudor.values) {
      c.dispose();
    }
    super.dispose();
  }

  double get _total => MoneyFormat.parse(_montoController.text);

  /// Con un solo pagador, su aporte es el total (no hace falta que lo tipee).
  bool get _unSoloPagador => _acreedores.length == 1;

  double _aporteDe(String id) =>
      MoneyFormat.parse(_montoPorAcreedor[id]!.text);

  double get _sumaAportes {
    if (_unSoloPagador) return _total;
    return _acreedores.fold(0.0, (acc, id) => acc + _aporteDe(id));
  }

  double _deudaDe(String id) => MoneyFormat.parse(_montoPorDeudor[id]!.text);

  double get _sumaDeudas =>
      _deudoresSeleccionados.fold(0.0, (acc, id) => acc + _deudaDe(id));

  bool get _usaDeudaManual =>
      _deudoresSeleccionados.any((id) => _montoPorDeudor[id]!.text.isNotEmpty);

  void _alCambiarTotal() => setState(() {});

  void _repartirEntrePagadores() {
    if (_acreedores.isEmpty) return;
    final centavos = (_total * 100).round();
    final n = _acreedores.length;
    final base = centavos ~/ n;
    final resto = centavos - base * n;
    var i = 0;
    for (final id in _acreedores) {
      final montoBase = base / 100;
      final montoExtra = i < resto ? 0.01 : 0.0;
      _montoPorAcreedor[id]!.text =
          MoneyFormat.format((montoBase + montoExtra).toStringAsFixed(2));
      i++;
    }
    setState(() {});
  }

  void _repartirEntreDeudores() {
    if (_deudoresSeleccionados.isEmpty) return;
    final centavos = (_total * 100).round();
    final n = _deudoresSeleccionados.length;
    final base = centavos ~/ n;
    final resto = centavos - base * n;
    var i = 0;
    for (final id in _deudoresSeleccionados) {
      final montoBase = base / 100;
      final montoExtra = i < resto ? 0.01 : 0.0;
      _montoPorDeudor[id]!.text =
          MoneyFormat.format((montoBase + montoExtra).toStringAsFixed(2));
      i++;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final aportado = _sumaAportes;
    final cuadra = (aportado - _total).abs() < 0.005 && _total > 0;

    return AppDialog(
      title: Text(l10n.eventDetailAddExpense),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              controller: _descripcionController,
              autofocus: true,
              decoration: InputDecoration(hintText: l10n.eventDetailExpenseDescription),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              variant: AppTextFieldVariant.money,
              controller: _montoController,
              decoration: InputDecoration(
                hintText: l10n.eventDetailExpenseAmount,
                prefixText: r'$ ',
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ── ¿Quién pagó? (uno o varios acreedores — FR7) ────────────────
            // D1 — solo la selección acá (checkbox + nombre); el monto de
            // cada uno se pide más abajo, después de las dos secciones de
            // selección, para que no quede "perdido" al lado de cada fila.
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.eventDetailWhoPaid,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            for (final p in widget.participantes)
              _FilaSeleccion(
                nombre: p.username,
                seleccionado: _acreedores.contains(p.id),
                onCambio: (checked) => setState(() {
                  if (checked) {
                    _acreedores.add(p.id);
                  } else if (_acreedores.length > 1) {
                    _acreedores.remove(p.id);
                  }
                }),
              ),

            const SizedBox(height: AppSpacing.md),

            // ── ¿Entre quiénes se divide? ────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.eventDetailDivideBetween,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            for (final p in widget.participantes)
              _FilaSeleccion(
                nombre: p.username,
                seleccionado: _deudoresSeleccionados.contains(p.id),
                onCambio: (checked) {
                  setState(() {
                    if (checked) {
                      _deudoresSeleccionados.add(p.id);
                    } else if (_deudoresSeleccionados.length > 1) {
                      _deudoresSeleccionados.remove(p.id);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.eventDetailSelectAtLeastOne)),
                      );
                    }
                  });
                },
              ),

            // ── D1 — montos repartidos por persona, debajo de ambas
            // secciones de selección (no intercalados en cada fila). ──────
            if (!_unSoloPagador) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.eventDetailAmountPerPayer,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  TextButton(
                    onPressed: _total > 0 ? _repartirEntrePagadores : null,
                    child: Text(l10n.eventDetailSplitEqually),
                  ),
                ],
              ),
              for (final id in _acreedores)
                _FilaMonto(
                  nombre: _nombreDe(id),
                  controller: _montoPorAcreedor[id]!,
                  onMonto: () => setState(() {}),
                ),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  l10n.eventDetailContributed(
                    aportado.toStringAsFixed(2),
                    _total.toStringAsFixed(2),
                  ),
                  // "Cuadra" es una validación (¿suma lo mismo que el
                  // total?), no un estado financiero — success/error, no
                  // success/danger (docs/06-design-system.md §3.6).
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cuadra
                            ? context.appSemanticColors.success
                            : Theme.of(context).colorScheme.error,
                      ),
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.eventDetailAmountPerPerson,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton(
                  onPressed: _total > 0 ? _repartirEntreDeudores : null,
                  child: Text(l10n.eventDetailSplitEqually),
                ),
              ],
            ),
            for (final id in _deudoresSeleccionados)
              _FilaMonto(
                nombre: _nombreDe(id),
                controller: _montoPorDeudor[id]!,
                onMonto: () => setState(() {}),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.commonCancel)),
        FilledButton(onPressed: () => _confirmar(l10n), child: Text(l10n.commonAdd)),
      ],
    );
  }

  void _confirmar(AppLocalizations l10n) {
    final total = _total;
    final descripcion = _descripcionController.text.trim();

    if (descripcion.isEmpty || total <= 0 || _deudoresSeleccionados.isEmpty) {
      _error(l10n.eventDetailExpenseInvalid);
      return;
    }
    if (_acreedores.isEmpty) {
      _error(l10n.eventDetailExpenseInvalid);
      return;
    }
    // Con varios pagadores, los aportes tienen que sumar el total (NFR#4).
    if (!_unSoloPagador && (_sumaAportes - total).abs() >= 0.005) {
      _error(l10n.eventDetailPayersMustSum);
      return;
    }

    if (_usaDeudaManual && (_sumaDeudas - total).abs() >= 0.005) {
      _error(l10n.eventDetailPayersMustSum); // Reusamos el mismo mensaje de error o uno genérico
      return;
    }

    final acreedores = <AporteInput>[
      for (final id in _acreedores)
        (
          participanteId: id,
          monto: _unSoloPagador
              ? total.toStringAsFixed(2)
              : _aporteDe(id).toStringAsFixed(2),
        ),
    ];

    final deudores = _usaDeudaManual
        ? <AporteInput>[
            for (final id in _deudoresSeleccionados)
              (
                participanteId: id,
                monto: _deudaDe(id).toStringAsFixed(2),
              ),
          ]
        : null;

    Navigator.pop(
      context,
      DatosGasto(
        descripcion: descripcion,
        montoTotal: total.toStringAsFixed(2),
        acreedores: acreedores,
        deudoresIds: _usaDeudaManual ? null : _deudoresSeleccionados.toList(),
        deudores: deudores,
      ),
    );
  }

  void _error(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  String _nombreDe(String participanteId) => widget.participantes
      .firstWhere((p) => p.id == participanteId)
      .username;
}

/// D1 — una fila de selección de "quién pagó"/"quién debe": checkbox +
/// nombre, sin el monto (que ahora va en un bloque aparte, después de
/// ambas secciones — ver [_FilaMonto]).
class _FilaSeleccion extends StatelessWidget {
  const _FilaSeleccion({
    required this.nombre,
    required this.seleccionado,
    required this.onCambio,
  });

  final String nombre;
  final bool seleccionado;
  final ValueChanged<bool> onCambio;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(nombre),
      value: seleccionado,
      onChanged: (v) => onCambio(v ?? false),
    );
  }
}

/// D1 — una fila del bloque de montos (por pagador o por deudor, según la
/// sección): nombre + input de monto, ya elegida la persona más arriba.
class _FilaMonto extends StatelessWidget {
  const _FilaMonto({
    required this.nombre,
    required this.controller,
    required this.onMonto,
  });

  final String nombre;
  final TextEditingController controller;
  final VoidCallback onMonto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs / 2),
      child: Row(
        children: [
          Expanded(child: Text(nombre)),
          SizedBox(
            width: 90,
            child: AppTextField(
              variant: AppTextFieldVariant.money,
              controller: controller,
              textAlign: TextAlign.end,
              decoration: const InputDecoration(prefixText: r'$ ', isDense: true),
              onChanged: (_) => onMonto(),
            ),
          ),
        ],
      ),
    );
  }
}
