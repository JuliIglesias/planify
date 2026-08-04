import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_text_field.dart';
import '../../l10n/generated/app_localizations.dart';
import 'data/friends_repository.dart';
import 'friend_profile_screen.dart';

final _requestsProvider = FutureProvider<List<SolicitudAmistad>>(
  (ref) => ref.watch(friendsRepositoryProvider).solicitudesPendientes(),
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
      if (mounted) messenger.showSnackBar(SnackBar(content: Text(okMsg)));
    } catch (err) {
      if (mounted) messenger.showSnackBar(SnackBar(content: Text('$err')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final amigos = ref.watch(friendsProvider);
    final requests = ref.watch(_requestsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.friendsTitle), backgroundColor: AppColors.surface),
      body: ListView(
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
            ListTile(
              // Item 3 — toda la fila envía la solicitud, no solo el botón;
              // el botón se queda como indicador visual de la acción.
              onTap: () => _accion(
                () => ref.read(friendsRepositoryProvider).enviarSolicitud(p.id),
                l10n.friendsRequestSent,
              ),
              leading: const Icon(Icons.person_outline),
              title: Text(p.username),
              // El email en gris ayuda a confirmar que es la persona
              // correcta, como una sola unidad visual con el username.
              subtitle: p.email != null
                  ? Text(p.email!, style: const TextStyle(color: AppColors.textSecondary))
                  : null,
              trailing: TextButton(
                onPressed: () => _accion(
                  () => ref.read(friendsRepositoryProvider).enviarSolicitud(p.id),
                  l10n.friendsRequestSent,
                ),
                child: Text(l10n.friendsAdd),
              ),
            ),
          if (_busquedaCtrl.text.trim().length >= 2 && !_buscando && _resultados.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(l10n.friendsNoResults),
            ),

          // ── Solicitudes pendientes ─────────────────────────────────────
          requests.maybeWhen(
            data: (lista) => lista.isEmpty
                ? const SizedBox.shrink()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.md),
                      Text(l10n.friendsRequests,
                          style: Theme.of(context).textTheme.titleMedium),
                      for (final s in lista)
                        ListTile(
                          // Item 3 — toda la fila acepta, no solo el botón.
                          onTap: () => _accion(
                            () => ref.read(friendsRepositoryProvider).aceptar(s.amistadId),
                            l10n.friendsAccept,
                          ),
                          leading: const Icon(Icons.person_add_alt),
                          title: Text(s.de.username),
                          subtitle: s.de.email != null
                              ? Text(s.de.email!,
                                  style: const TextStyle(color: AppColors.textSecondary))
                              : null,
                          trailing: FilledButton(
                            onPressed: () => _accion(
                              () => ref.read(friendsRepositoryProvider).aceptar(s.amistadId),
                              l10n.friendsAccept,
                            ),
                            child: Text(l10n.friendsAccept),
                          ),
                        ),
                    ],
                  ),
            orElse: () => const SizedBox.shrink(),
          ),

          // ── Amigos ─────────────────────────────────────────────────────
          const SizedBox(height: AppSpacing.md),
          Text(l10n.friendsTitle, style: Theme.of(context).textTheme.titleMedium),
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
                    child: Text(l10n.friendsEmpty,
                        style: const TextStyle(color: AppColors.textSecondary)),
                  )
                : Column(
                    children: [
                      for (final p in lista)
                        ListTile(
                          // Item 4 — toca cualquier parte de la fila para
                          // ver el perfil de solo lectura de ese amigo.
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => FriendProfileScreen(usuarioId: p.id),
                            ),
                          ),
                          leading: const Icon(Icons.person, color: AppColors.primary),
                          title: Text(p.username),
                          // Item 3 — email en gris debajo del username, como
                          // una sola unidad visual.
                          subtitle: p.email != null
                              ? Text(p.email!,
                                  style: const TextStyle(color: AppColors.textSecondary))
                              : null,
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
