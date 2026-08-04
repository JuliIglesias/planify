import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/auth_scaffold.dart';
import '../../l10n/generated/app_localizations.dart';
import 'data/auth_repository.dart';
import 'pending_invitation_provider.dart';
import 'register_screen.dart';
import 'session_controller.dart';

/// Login — mockup "Login" de Figma.
/// HU-41: login del organizador semilla (T-07), sin Cognito todavía.
/// HU-01: el anónimo entra por link de invitación, nunca crea eventos (Duda #19).
/// "Crear cuenta" y "Olvidaste tu contraseña" quedan visibles pero inertes
/// hasta SCRUM-14 (auth completa).
///
/// Item 2: el link de invitación NO fuerza el camino anónimo. El token se
/// captura una sola vez, a nivel de toda la app (`_RootRouter` en
/// `main.dart`, vía `pendingInvitationProvider`) y esta pantalla se muestra
/// siempre igual, con sus 3 opciones — la invitación se aplica recién
/// después de elegir una.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _mensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  /// "Continuar como Anónimo": un único paso pidiendo el link de invitación y
  /// el nombre para mostrar (HU-01). El anónimo nunca se crea sin nombre — así
  /// queda registrado como Participante real y aparece en listas de
  /// miembros/gastos/disponibilidad (H-01/H-02).
  Future<void> _continuarComoAnonimo() async {
    final l10n = AppLocalizations.of(context)!;
    // Si ya había un link de invitación pendiente (deep link), se precarga:
    // la persona no tiene que volver a pegarlo.
    final tokenController = TextEditingController(
      text: ref.read(pendingInvitationProvider) ?? '',
    );
    final usernameController = TextEditingController();

    final datos = await showDialog<(String, String)>(
      context: context,
      builder: (ctx) => AppDialog(
        title: Text(l10n.loginContinueAnonymous),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.loginAnonymousHint),
            const SizedBox(height: AppSpacing.md),
            Text(l10n.loginAnonymousLinkLabel),
            const SizedBox(height: AppSpacing.xs),
            AppTextField(
              variant: AppTextFieldVariant.email,
              controller: tokenController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'ej. planify://invite/f210607e...',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.loginAnonymousNameLabel),
            const SizedBox(height: AppSpacing.xs),
            AppTextField(
              controller: usernameController,
              decoration: InputDecoration(hintText: l10n.loginAnonymousNameHint),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () {
              final token = tokenController.text.trim();
              final username = usernameController.text.trim();
              if (token.isNotEmpty && username.isNotEmpty) {
                Navigator.pop(ctx, (token, username));
              }
            },
            child: Text(l10n.commonConfirm),
          ),
        ],
      ),
    );

    // Se difiere al próximo frame: el diálogo todavía puede estar animando
    // su cierre y los TextField siguen usando los controllers en ese frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      tokenController.dispose();
      usernameController.dispose();
    });

    if (datos == null) return;
    await _unirseConTokenYUsername(datos.$1, datos.$2);
  }

  /// Resuelve el token de invitación y une con el username ya recolectado, sin
  /// mostrar ningún diálogo adicional.
  Future<void> _unirseConTokenYUsername(String tokenInput, String username) async {
    final cleanToken = tokenInput
        .replaceAll('planify://invite/', '')
        .replaceAll('planify://', '')
        .trim();
    if (cleanToken.isEmpty) return;

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final eventoId = await authRepo.resolverInvitacion(cleanToken);
      if (!mounted) return;
      await _unirseComoAnonimo(eventoId: eventoId, username: username);
      // El token ya se consumió: si venía de un deep link, no debe quedar
      // pendiente de aplicar de nuevo.
      ref.read(pendingInvitationProvider.notifier).set(null);
    } catch (err) {
      if (mounted) _mensaje('No se pudo resolver la invitación: $err');
    }
  }

  Future<void> _unirseComoAnonimo({
    required String eventoId,
    required String username,
  }) =>
      ref.read(sessionControllerProvider.notifier).unirseComoAnonimo(
            eventoId: eventoId,
            username: username,
          );


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
    final invitacionPendiente = ref.watch(pendingInvitationProvider) != null;

    return AuthScaffold(
      card: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (invitacionPendiente) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              ),
              child: Row(
                children: [
                  const Icon(Icons.mail_outline, color: AppColors.primary, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(l10n.loginPendingInvitation, style: theme.textTheme.bodySmall),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          AppTextField(
            variant: AppTextFieldVariant.email,
            controller: _emailController,
            enabled: !cargando,
            decoration: InputDecoration(
              hintText: l10n.loginUserOrEmail,
              prefixIcon: const Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            variant: AppTextFieldVariant.password,
            controller: _passwordController,
            enabled: !cargando,
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
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: cargando ? null : _ingresar,
              child: cargando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(l10n.loginSubmit),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.loginOr, style: theme.textTheme.bodySmall),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: cargando ? null : _continuarComoAnonimo,
            icon: const Icon(Icons.visibility_off_outlined),
            label: Text(l10n.loginContinueAnonymous),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              ),
            ),
          ),
        ],
      ),
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(l10n.loginNoAccount, style: theme.textTheme.bodySmall),
          TextButton(
            // HU-27 (SCRUM-14): registro real de una cuenta.
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const RegisterScreen()),
            ),
            child: Text(l10n.loginCreateAccount),
          ),
        ],
      ),
    );
  }
}
