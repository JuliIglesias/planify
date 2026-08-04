import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../home/home_providers.dart';
import '../data/expenses_repository.dart';
import 'expense_dialog.dart';

/// Item 4 (Tanda 6) — FAB contextual de la pantalla de Gastos: en vez de
/// crear un evento (eso queda para Home y Grupos), arranca el flujo de
/// "nuevo gasto": elegir a qué evento activo pertenece y completar el mismo
/// diálogo que ya se usa desde el detalle de un evento (`pedirDatosGasto`).
Future<void> iniciarCrearGastoRapido(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context)!;
  final eventos = await ref.read(upcomingEventsProvider.future);

  if (!context.mounted) return;
  if (eventos.isEmpty) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.expensesNoEventsToPick)));
    return;
  }

  final elegido = await showModalBottomSheet<EventoResumen>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _SelectorDeEvento(eventos: eventos),
  );
  if (elegido == null || !context.mounted) return;

  final datos = await pedirDatosGasto(context, elegido.participantes);
  if (datos == null || !context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  try {
    await ref.read(expensesRepositoryProvider).crear(
          eventoId: elegido.id,
          descripcion: datos.descripcion,
          montoTotal: datos.montoTotal,
          acreedores: [
            for (final a in datos.acreedores)
              AporteGasto(participanteId: a.participanteId, monto: a.monto),
          ],
          deudores: datos.deudores
              ?.map((d) => AporteGasto(participanteId: d.participanteId, monto: d.monto))
              .toList(),
          dividirEntre: datos.deudoresIds,
        );
    invalidateEventData(ref, elegido.id);
  } catch (err) {
    messenger.showSnackBar(SnackBar(content: Text('$err')));
  }
}

class _SelectorDeEvento extends StatelessWidget {
  const _SelectorDeEvento({required this.eventos});

  final List<EventoResumen> eventos;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              l10n.expensesPickEventTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final evento in eventos)
                  ListTile(
                    leading: const Icon(Icons.event_outlined, color: AppColors.primary),
                    title: Text(evento.nombre),
                    subtitle: Text(evento.lugarTexto),
                    onTap: () => Navigator.pop(context, evento),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}
