import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_person_row.dart';
import '../../core/widgets/app_text_field.dart';
import '../../l10n/generated/app_localizations.dart';
import 'data/friends_repository.dart';
import 'friend_profile_screen.dart';

final _requestsProvider = FutureProvider<List<SolicitudAmistad>>(
  (ref) => ref.watch(friendsRepositoryProvider).solicitudesPendientes(),
);

/// F1 — solicitudes que envié yo, todavía sin aceptar.
final _sentRequestsProvider = FutureProvider<List<SolicitudEnviada>>(
  (ref) => ref.watch(friendsRepositoryProvider).solicitudesEnviadas(),
);

/// SCRUM-14 — HU-31: pantalla de amigos (buscar y agregar, aceptar, listar).
class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  final _busquedaCtrl = TextEditingController();
  List<Persona> _resultados = [];
  bool _buscando = false;

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  Future<void> _buscar(String q) async {
    if (q.trim().length < 2) {
      setState(() => _resultados = []);
      return;
    }
    setState(() => _buscando = true);
    try {
      final res = await ref.read(friendsRepositoryProvider).buscar(q.trim());
      if (mounted) setState(() => _resultados = res);
    } catch (_) {
      if (mounted) setState(() => _resultados = []);
    } finally {
      if (mounted) setState(() => _buscando = false);
    }
  }

  Future<void> _accion(Future<void> Function() accion, String okMsg) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await accion();
      ref.invalidate(friendsProvider);
      ref.invalidate(_requestsProvider);
      ref.invalidate(_sentRequestsProvider);
      if (mounted) messenger.showSnackBar(SnackBar(content: Text(okMsg)));
    } catch (err) {
      if (mounted) messenger.showSnackBar(SnackBar(content: Text('$err')));
    }
  }

  // F1 — mismo patrón de pull-to-refresh que Home (`home_screen.dart`):
  // refresca amigos, solicitudes recibidas y enviadas de una.
  Future<void> _refrescar() async {
    ref.invalidate(friendsProvider);
    ref.invalidate(_requestsProvider);
    ref.invalidate(_sentRequestsProvider);
    await Future.wait([
      ref.read(friendsProvider.future),
      ref.read(_requestsProvider.future),
      ref.read(_sentRequestsProvider.future),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final amigos = ref.watch(friendsProvider);
    final requests = ref.watch(_requestsProvider);
    final sentRequests = ref.watch(_sentRequestsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.friendsTitle),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      // F1 — pull-to-refresh, mismo patrón/componente que Home.
      body: RefreshIndicator(
        onRefresh: _refrescar,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            AppTextField(
              variant: AppTextFieldVariant.email,
              controller: _busquedaCtrl,
              onChanged: _buscar,
              decoration: InputDecoration(
                hintText: l10n.friendsSearchHint,
                prefixIcon: const Icon(Icons.search),
              ),
            ),
            if (_buscando)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Center(child: CircularProgressIndicator()),
              ),
            for (final p in _resultados)
              // AppPersonRow (docs/06-design-system.md §6.1) reemplaza el
              // ListTile a mano — mismo patrón repetido 4 veces en esta
              // pantalla (hallazgo de Fase 1 §2.2).
              AppPersonRow(
                nombre: p.username,
                subtitulo: p.email,
                avatarUrl: p.avatarUrl,
                // Item 3 — toda la fila envía la solicitud, no solo el botón;
                // el botón se queda como indicador visual de la acción.
                onTap: () => _accion(
                  () =>
                      ref.read(friendsRepositoryProvider).enviarSolicitud(p.id),
                  l10n.friendsRequestSent,
                ),
                trailing: TextButton(
                  onPressed: () => _accion(
                    () => ref
                        .read(friendsRepositoryProvider)
                        .enviarSolicitud(p.id),
                    l10n.friendsRequestSent,
                  ),
                  child: Text(l10n.friendsAdd),
                ),
              ),
            if (_busquedaCtrl.text.trim().length >= 2 &&
                !_buscando &&
                _resultados.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(l10n.friendsNoResults),
              ),

            // ── F1 — solicitudes pendientes: recibidas y enviadas, cada una
            // en su propia sección para que se puedan distinguir de un
            // vistazo (antes solo existían las recibidas). ──────────────────
            requests.maybeWhen(
              data: (lista) => lista.isEmpty
                  ? const SizedBox.shrink()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          '${l10n.friendsRequests} · ${l10n.friendsRequestsReceived}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        for (final s in lista)
                          AppPersonRow(
                            nombre: s.de.username,
                            subtitulo: s.de.email,
                            avatarUrl: s.de.avatarUrl,
                            // Item 3 — toda la fila acepta, no solo el botón.
                            onTap: () => _accion(
                              () => ref
                                  .read(friendsRepositoryProvider)
                                  .aceptar(s.amistadId),
                              l10n.friendsAccept,
                            ),
                            trailing: FilledButton(
                              onPressed: () => _accion(
                                () => ref
                                    .read(friendsRepositoryProvider)
                                    .aceptar(s.amistadId),
                                l10n.friendsAccept,
                              ),
                              child: Text(l10n.friendsAccept),
                            ),
                          ),
                      ],
                    ),
              orElse: () => const SizedBox.shrink(),
            ),

            sentRequests.maybeWhen(
              data: (lista) => lista.isEmpty
                  ? const SizedBox.shrink()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          '${l10n.friendsRequests} · ${l10n.friendsRequestsSent}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        for (final s in lista)
                          AppPersonRow(
                            nombre: s.para.username,
                            subtitulo: s.para.email,
                            avatarUrl: s.para.avatarUrl,
                            trailing: Text(
                              l10n.friendsPending,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ),
                      ],
                    ),
              orElse: () => const SizedBox.shrink(),
            ),

            // ── Amigos ─────────────────────────────────────────────────────
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.friendsTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            amigos.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text('$err'),
              ),
              data: (lista) => lista.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      // `bodyMedium` (default de Text sin estilo) es el gris
                      // de cuerpo del tema — se agrega el override para el
                      // gris SECUNDARIO que pedía el diseño original.
                      child: Text(
                        l10n.friendsEmpty,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    )
                  : Column(
                      children: [
                        for (final p in lista)
                          AppPersonRow(
                            nombre: p.username,
                            subtitulo: p.email,
                            avatarUrl: p.avatarUrl,
                            // Item 4 — toca cualquier parte de la fila para
                            // ver el perfil de solo lectura de ese amigo.
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    FriendProfileScreen(usuarioId: p.id),
                              ),
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
