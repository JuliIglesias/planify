import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_semantic_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/money_format.dart';
import '../../core/widgets/app_icon_badge.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/event_card.dart';
import '../../core/widgets/pill_toggle.dart';
import '../../core/widgets/status_badge.dart';
import '../../l10n/generated/app_localizations.dart';
import '../events/widgets/activity_presentation.dart';
import '../home/home_providers.dart';
import 'person_detail_sheet.dart';

enum _Filtro { todo, meDeben, debo }

/// Riverpod 3 sacó StateProvider; para estado local simple se usa un Notifier.
class _FiltroBalance extends Notifier<_Filtro> {
  @override
  _Filtro build() => _Filtro.todo;

  void set(_Filtro filtro) => state = filtro;
}

final _filtroBalanceProvider =
    NotifierProvider<_FiltroBalance, _Filtro>(_FiltroBalance.new);

/// Balances — balance neto + saldos por amigo (mockup "Balances").
class BalancesScreen extends ConsumerWidget {
  const BalancesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final balance = ref.watch(balanceProvider);
    final filtro = ref.watch(_filtroBalanceProvider);
    // A2 — ídem Home/Grupos/Perfil: altura real de la navbar + margen.
    final bottomPad = ref.watch(bottomNavHeightProvider) + AppSpacing.md;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(balanceProvider),
      child: ListView(
        padding: EdgeInsets.only(bottom: bottomPad),
        children: [
          AppHeader(titulo: l10n.balancesTitle),
          balance.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => AsyncStateView(
              icon: Icons.cloud_off,
              mensaje: l10n.commonError,
              detalle: l10n.commonErrorHint,
            ),
            data: (b) {
              final semantic = context.appSemanticColors;
              final netoPositivo = !b.balanceNeto.trim().startsWith('-');

              final saldosFiltrados = b.saldos.where((s) {
                return switch (filtro) {
                  _Filtro.todo => true,
                  _Filtro.meDeben => s.estado == 'pendiente',
                  _Filtro.debo => s.estado == 'pagar',
                };
              }).toList();

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: Column(
                      children: [
                        // `labelMedium` ya usa el gris secundario del tema.
                        Text(l10n.balancesNet, style: Theme.of(context).textTheme.labelMedium),
                        Text(
                          '${netoPositivo ? '+' : ''}\$${MoneyFormat.format(b.balanceNeto)}',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: netoPositivo ? semantic.success : semantic.danger,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Row(
                      children: [
                        Expanded(
                          child: _MiniResumen(
                            label: l10n.balancesOwedToMe,
                            monto: b.meDeben,
                            // Item 4 — mismo ícono/color que "deuda saldada"
                            // en el feed de actividad (plata a favor).
                            color: colorDeActividad('deuda_saldada'),
                            icono: iconoDeActividad('deuda_saldada'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _MiniResumen(
                            label: l10n.balancesIOwe,
                            monto: b.debo,
                            // Item 4 — mismo ícono/color que "gasto agregado"
                            // en el feed de actividad (plata en contra).
                            color: colorDeActividad('gasto_agregado'),
                            icono: iconoDeActividad('gasto_agregado'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: PillToggle<_Filtro>(
                      options: [
                        (value: _Filtro.todo, label: l10n.balancesAll),
                        (value: _Filtro.meDeben, label: l10n.balancesOwedToMe),
                        (value: _Filtro.debo, label: l10n.balancesIOwe),
                      ],
                      selected: filtro,
                      onChanged: (f) => ref.read(_filtroBalanceProvider.notifier).set(f),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        l10n.balancesPerFriend,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (saldosFiltrados.isEmpty)
                    AsyncStateView(
                      icon: Icons.account_balance_wallet_outlined,
                      mensaje: l10n.balancesEmpty,
                      detalle: l10n.balancesEmptyHint,
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: Column(
                        children: [
                          for (final saldo in saldosFiltrados)
                            BalanceRow(
                              nombre: saldo.username,
                              monto: '\$${MoneyFormat.format(saldo.monto)}',
                              estado: switch (saldo.estado) {
                                'pagar' => SaldoEstado.pagar,
                                'pendiente' => SaldoEstado.pendiente,
                                _ => SaldoEstado.saldado,
                              },
                              estadoLabel: switch (saldo.estado) {
                                'pagar' => l10n.balancesYouOwe,
                                'pendiente' => l10n.balancesOweYou,
                                _ => l10n.balancesStateSettled,
                              },
                              // FR9 — el monto de la fila ya viene compensado
                              // entre eventos; el detalle muestra el desglose.
                              onTap: () => mostrarDetalleConPersona(context, saldo.id),
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Item 4 (Tanda 6) — cards de resumen con ícono + color, reusando los
/// mismos que ya identifican a "gasto agregado"/"deuda saldada" en el feed
/// de actividad, para que un mismo concepto se vea igual en toda la app.
class _MiniResumen extends StatelessWidget {
  const _MiniResumen({
    required this.label,
    required this.monto,
    required this.color,
    required this.icono,
  });

  final String label;
  final String monto;
  final Color color;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            // AppIconBadge (docs/06-design-system.md §6.1/§6.2) — mismo
            // patrón "ícono en círculo pastel" que QuickActionButton y
            // ActivityFeedItem, antes copiado acá con un CircleAvatar a mano.
            AppIconBadge(icon: icono, color: color, size: 36, iconSize: 18),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.labelSmall),
                  Text(
                    '\$${MoneyFormat.format(monto)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
