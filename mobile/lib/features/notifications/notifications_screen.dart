import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/event_card.dart';
import '../../core/widgets/pill_toggle.dart';
import '../../l10n/generated/app_localizations.dart';
import '../events/event_detail_screen.dart';
import '../events/widgets/activity_presentation.dart';
import '../friends/friends_screen.dart';
import 'notifications_providers.dart';

enum _Categoria { todo, eventos, gastos }

/// Tipos que cuentan como "Gasto" en el filtro; el resto de lo que cuelga de
/// un evento (tareas, asistencia, disponibilidad) cae bajo "Eventos".
const _tiposDeGasto = {'gasto_agregado', 'deuda_saldada', 'gastos_cerrados'};

/// F2 — tipos que NO cuelgan de ningún evento (ej. una solicitud de
/// amistad): solo aparecen en "Todo", nunca en "Eventos" ni en "Gastos" —
/// aunque no sean de gasto, meterlos en "Eventos" sería engañoso, porque no
/// hay ningún evento al que puedan rutear.
const _tiposSinEvento = {'solicitud_amistad'};

bool _coincideCategoria(_Categoria cat, String tipo) => switch (cat) {
      _Categoria.todo => true,
      _Categoria.gastos => _tiposDeGasto.contains(tipo),
      _Categoria.eventos => !_tiposDeGasto.contains(tipo) && !_tiposSinEvento.contains(tipo),
    };

/// Item 2 (Tanda 6) — pantalla de Notificaciones: se entra desde la campana
/// del Home y desde Perfil. Reusa el mismo feed de actividad que Home
/// (paginado de a 20), agrupado por día, filtrable por Todo/Eventos/Gastos,
/// y cada fila rutea al evento específico de esa actividad.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  _Categoria _categoria = _Categoria.todo;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_alScrollear);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_alScrollear);
    _scrollController.dispose();
    super.dispose();
  }

  void _alScrollear() {
    // Falta menos de una pantalla para el final: pedir la próxima página.
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(notificationsFeedProvider.notifier).cargarMas();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final feed = ref.watch(notificationsFeedProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.notificationsTitle), backgroundColor: AppColors.surface),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: PillToggle<_Categoria>(
              options: [
                (value: _Categoria.todo, label: l10n.notificationsTabAll),
                (value: _Categoria.eventos, label: l10n.notificationsTabEvents),
                (value: _Categoria.gastos, label: l10n.notificationsTabExpenses),
              ],
              selected: _categoria,
              onChanged: (c) => setState(() => _categoria = c),
            ),
          ),
          Expanded(
            child: feed.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => AsyncStateView(
                icon: Icons.cloud_off,
                mensaje: l10n.commonError,
                detalle: l10n.commonErrorHint,
              ),
              data: (f) {
                final filtradas =
                    f.items.where((e) => _coincideCategoria(_categoria, e.tipo)).toList();

                if (filtradas.isEmpty) {
                  return AsyncStateView(
                    icon: Icons.notifications_none,
                    mensaje: l10n.notificationsEmpty,
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  itemCount: filtradas.length + (f.hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= filtradas.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final entrada = filtradas[index];
                    final encabezado = _encabezadoDia(l10n, entrada.createdAt);
                    final encabezadoAnterior = index == 0
                        ? null
                        : _encabezadoDia(l10n, filtradas[index - 1].createdAt);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (encabezado != encabezadoAnterior)
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xs),
                            child: Text(
                              encabezado,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: ActivityFeedItem(
                            icon: iconoDeActividad(entrada.tipo),
                            iconColor: colorDeActividad(entrada.tipo),
                            titulo: textoActividad(l10n, entrada),
                            subtitulo: entrada.eventoNombre,
                            trailing: DateFormat('HH:mm').format(entrada.createdAt),
                            // F2 — una solicitud de amistad no tiene evento
                            // al que rutear; en cambio, lleva a Amigos (ahí
                            // se acepta/rechaza).
                            onTap: entrada.tipo == 'solicitud_amistad'
                                ? () => Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => const FriendsScreen(),
                                      ),
                                    )
                                : entrada.eventoId == null
                                    ? null
                                    : () => Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (_) =>
                                                EventDetailScreen(eventoId: entrada.eventoId!),
                                          ),
                                        ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

String _encabezadoDia(AppLocalizations l10n, DateTime fecha) {
  final ahora = DateTime.now();
  final hoy = DateTime(ahora.year, ahora.month, ahora.day);
  final dia = DateTime(fecha.year, fecha.month, fecha.day);

  if (dia == hoy) return l10n.notificationsToday;
  if (dia == hoy.subtract(const Duration(days: 1))) return l10n.notificationsYesterday;
  return DateFormat('d MMMM', 'es').format(fecha).toUpperCase();
}
