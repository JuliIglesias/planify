import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/generated/app_localizations.dart';
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _mensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
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
                  // El anónimo necesita un link de invitación: sin evento al que
                  // unirse, este botón no tiene a dónde llevarlo (Duda #19).
                  onPressed:
                      cargando ? null : () => _mensaje(l10n.loginAnonymousHint),
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
