import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/models.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/avatar_stack.dart';
import '../../l10n/generated/app_localizations.dart';
import 'data/friends_repository.dart';

/// SCRUM-14 (FR13) — gestión de amigos. Pantalla sin diseño en Figma: sigue el
/// lenguaje visual de las demás (Duda #27), con hoja inferior para buscar y
/// confirmación antes de eliminar.
class FriendsScreen extends ConsumerWidget {
  const FriendsScreen({super.key});

  Future<void> _accion(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() accion,
  ) async {
    try {
      await accion();
      ref.invalidate(friendsProvider);
      ref.invalidate(friendRequestsProvider);
    } catch (err) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$err')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final amigos = ref.watch(friendsProvider);
    final pendientes = ref.watch(friendRequestsProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(l10n.friendsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            tooltip: l10n.friendsAdd,
            onPressed: () => _abrirBuscador(context, ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(friendsProvider);
          ref.invalidate(friendRequestsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // ── Solicitudes recibidas ─────────────────────────────────────
            pendientes.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (lista) => lista.isEmpty
                  ? const SizedBox.shrink()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TituloSeccion(l10n.friendsRequests),
                        for (final s in lista)
                          Card(
                            child: ListTile(
                              leading: AvatarStack(nombres: [s.solicitanteNombre], radius: 18),
                              title: Text(s.solicitanteNombre),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextButton(
                                    onPressed: () => _accion(context, ref,
                                        () => ref.read(friendsRepositoryProvider).eliminar(s.amistadId)),
                                    child: Text(l10n.friendsReject),
                                  ),
                                  FilledButton(
                                    onPressed: () => _accion(context, ref,
                                        () => ref.read(friendsRepositoryProvider).aceptar(s.amistadId)),
                                    child: Text(l10n.friendsAccept),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                    ),
            ),

            // ── Mis amigos ────────────────────────────────────────────────
            _TituloSeccion(l10n.friendsMyFriends),
            amigos.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('$err'),
              data: (lista) => lista.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Text(
                        l10n.friendsNoFriends,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    )
                  : Column(
                      children: [
                        for (final a in lista)
                          Card(
                            child: ListTile(
                              leading: AvatarStack(nombres: [a.nombre], radius: 18),
                              title: Text(a.nombre),
                              trailing: IconButton(
                                icon: const Icon(Icons.person_remove_outlined,
                                    color: AppColors.danger),
                                tooltip: l10n.friendsRemove,
                                onPressed: () => _confirmarEliminar(context, ref, a),
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

  Future<void> _confirmarEliminar(BuildContext context, WidgetRef ref, Amigo amigo) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.friendsRemove),
        content: Text(l10n.friendsRemoveConfirm(amigo.nombre)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.commonCancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.commonConfirm),
          ),
        ],
      ),
    );
    if (confirmado != true) return;
    // Se elimina por el id de la relación (amistadId), que viene en la lista.
    await _accion(
      context,
      ref,
      () => ref.read(friendsRepositoryProvider).eliminar(amigo.amistadId),
    );
  }

  void _abrirBuscador(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _BuscadorAmigos(),
    ).then((_) {
      ref.invalidate(friendsProvider);
      ref.invalidate(friendRequestsProvider);
    });
  }
}

class _TituloSeccion extends StatelessWidget {
  const _TituloSeccion(this.texto);
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        texto,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _BuscadorAmigos extends ConsumerStatefulWidget {
  const _BuscadorAmigos();

  @override
  ConsumerState<_BuscadorAmigos> createState() => _BuscadorAmigosState();
}

class _BuscadorAmigosState extends ConsumerState<_BuscadorAmigos> {
  final _controller = TextEditingController();
  List<UsuarioBuscado> _resultados = [];
  bool _buscando = false;
  bool _busco = false;

  /// Ids a los que ya se les mandó la solicitud en esta sesión de búsqueda,
  /// para reflejarlo sin re-consultar.
  final _enviados = <String>{};

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _buscar() async {
    final termino = _controller.text.trim();
    if (termino.isEmpty) return;
    setState(() => _buscando = true);
    try {
      final resultados = await ref.read(friendsRepositoryProvider).buscar(termino);
      if (mounted) setState(() => _resultados = resultados);
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$err')));
      }
    } finally {
      if (mounted) setState(() {
        _buscando = false;
        _busco = true;
      });
    }
  }

  Future<void> _agregar(UsuarioBuscado u) async {
    try {
      await ref.read(friendsRepositoryProvider).enviarSolicitud(u.id);
      if (mounted) setState(() => _enviados.add(u.id));
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$err')));
      }
    }
  }

  String _etiquetaRelacion(AppLocalizations l10n, UsuarioBuscado u) => switch (u.relacion) {
        'amigo' => l10n.friendsAlreadyFriend,
        'pendiente_enviada' || 'pendiente_recibida' => l10n.friendsPending,
        _ => '',
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.95,
          builder: (context, scrollController) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        autofocus: true,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _buscar(),
                        decoration: InputDecoration(
                          hintText: l10n.friendsSearchHint,
                          prefixIcon: const Icon(Icons.search),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    FilledButton(
                      onPressed: _buscando ? null : _buscar,
                      child: Text(l10n.friendsSearch),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _buscando
                    ? const Center(child: CircularProgressIndicator())
                    : (_busco && _resultados.isEmpty)
                        ? Center(child: Text(l10n.friendsSearchEmpty))
                        : ListView(
                            controller: scrollController,
                            children: [
                              for (final u in _resultados)
                                ListTile(
                                  leading: AvatarStack(nombres: [u.nombre], radius: 18),
                                  title: Text(u.nombre),
                                  subtitle: Text(u.email),
                                  trailing: _enviados.contains(u.id)
                                      ? Text(l10n.friendsRequestSent)
                                      : u.sePuedeAgregar
                                          ? FilledButton(
                                              onPressed: () => _agregar(u),
                                              child: Text(l10n.friendsSendRequest),
                                            )
                                          : Text(_etiquetaRelacion(l10n, u)),
                                ),
                            ],
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
