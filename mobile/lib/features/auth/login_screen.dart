import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/generated/app_localizations.dart';
import 'data/auth_repository.dart';
import 'session_controller.dart';

/// Login — mockup "Login" de Figma.
/// HU-41: login del organizador semilla (T-07), sin Cognito todavía.
/// HU-01: el anónimo entra por link de invitación, nunca crea eventos (Duda #19).
/// "Crear cuenta" y "Olvidaste tu contraseña" quedan visibles pero inertes
/// hasta SCRUM-14 (auth completa).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  AppLinks? _appLinks;
  StreamSubscription<Uri>? _sub;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    try {
      _appLinks = AppLinks();
      final initialUri = await _appLinks?.getInitialLink();
      if (initialUri != null) {
        _procesarUri(initialUri);
      }
      _sub = _appLinks?.uriLinkStream.listen((uri) {
        _procesarUri(uri);
      });
    } catch (_) {
      // Ignorar en entornos donde no hay canales de plataforma de deep links (ej. widget tests)
    }
  }

  void _procesarUri(Uri uri) {
    final token = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : uri.host;
    if (token.isNotEmpty) {
      _unirseConToken(token);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _mensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _unirseConToken(String tokenInput) async {
    final cleanToken = tokenInput
        .replaceAll('planify://invite/', '')
        .replaceAll('planify://', '')
        .trim();

    if (cleanToken.isEmpty) return;

    final l10n = AppLocalizations.of(context)!;
    final nombreController = TextEditingController();

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final eventoId = await authRepo.resolverInvitacion(cleanToken);

      if (!mounted) return;

      final unirse = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.eventDetailInviteTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Te invitaron a un evento. Ingresá tu nombre para unirte:'),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: nombreController,
                autofocus: true,
                decoration: const InputDecoration(hintText: 'Tu nombre (ej. Sofía)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () {
                if (nombreController.text.trim().isNotEmpty) {
                  Navigator.pop(ctx, true);
                }
              },
              child: Text(l10n.commonConfirm),
            ),
          ],
        ),
      );

      if (unirse == true && mounted) {
        await ref.read(sessionControllerProvider.notifier).unirseComoAnonimo(
              eventoId: eventoId,
              nombreDisplay: nombreController.text.trim(),
            );
      }
    } catch (err) {
      if (mounted) _mensaje('No se pudo resolver la invitación: $err');
    } finally {
      nombreController.dispose();
    }
  }

  Future<void> _pedirTokenManual() async {
    final l10n = AppLocalizations.of(context)!;
    final tokenController = TextEditingController();

    final token = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unirse por invitación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.loginAnonymousHint),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: tokenController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'ej. planify://invite/f210607e...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, tokenController.text.trim()),
            child: Text(l10n.eventNext),
          ),
        ],
      ),
    );

    tokenController.dispose();

    if (token != null && token.isNotEmpty) {
      await _unirseConToken(token);
    }
  }


  Future<void> _ingresar() async {
    final l10n = AppLocalizations.of(context)!;
    await ref.read(sessionControllerProvider.notifier).loginOrganizador(
          _emailController.text.trim(),
          _passwordController.text,
        );

    if (!mounted) return;
    final estado = ref.read(sessionControllerProvider);
    if (estado.hasError) _mensaje(l10n.loginError);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cargando = ref.watch(sessionControllerProvider).isLoading;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n.appName,
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  l10n.appTagline,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                TextField(
                  controller: _emailController,
                  enabled: !cargando,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: l10n.loginUserOrEmail,
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _passwordController,
                  enabled: !cargando,
                  obscureText: true,
                  onSubmitted: (_) => _ingresar(),
                  decoration: InputDecoration(
                    hintText: l10n.loginPassword,
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _mensaje(l10n.loginComingSoon),
                    child: Text(l10n.loginForgotPassword),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ElevatedButton(
                  onPressed: cargando ? null : _ingresar,
                  child: cargando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(l10n.loginSubmit),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(l10n.loginOr, style: theme.textTheme.bodySmall),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: cargando ? null : _pedirTokenManual,
                  icon: const Icon(Icons.visibility_off_outlined),
                  label: Text(l10n.loginContinueAnonymous),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(l10n.loginNoAccount, style: theme.textTheme.bodySmall),
                    TextButton(
                      onPressed: () => _mensaje(l10n.loginComingSoon),
                      child: Text(l10n.loginCreateAccount),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
