import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/generated/app_localizations.dart';
import 'session_controller.dart';

/// Registro de cuenta — FR11 (HU-27). Al crear la cuenta queda logueado, así que
/// el router raíz lo lleva directo al shell; por eso al terminar se cierra esta
/// pantalla (que se abrió sobre el Login).
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nombre = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _nombre.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  bool get _valido =>
      _nombre.text.trim().isNotEmpty &&
      _email.text.trim().isNotEmpty &&
      _password.text.length >= 6;

  Future<void> _crear() async {
    final l10n = AppLocalizations.of(context)!;
    await ref.read(sessionControllerProvider.notifier).registrar(
          nombre: _nombre.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
        );

    if (!mounted) return;
    final estado = ref.read(sessionControllerProvider);
    if (estado.hasError) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.registerError)));
    } else {
      // La sesión ya es de organizador: se cierra el registro y el router
      // muestra el shell que quedó debajo.
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cargando = ref.watch(sessionControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(l10n.registerTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nombre,
                enabled: !cargando,
                textCapitalization: TextCapitalization.words,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: l10n.registerName,
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _email,
                enabled: !cargando,
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: l10n.registerEmail,
                  prefixIcon: const Icon(Icons.mail_outline),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _password,
                enabled: !cargando,
                obscureText: true,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _valido ? _crear() : null,
                decoration: InputDecoration(
                  labelText: l10n.registerPassword,
                  helperText: l10n.registerPasswordHint,
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: cargando || !_valido ? null : _crear,
                child: cargando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(l10n.registerSubmit),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.registerPrivacyHint,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
