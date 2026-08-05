import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/auth_scaffold.dart';
import '../../l10n/generated/app_localizations.dart';
import 'session_controller.dart';

/// SCRUM-14 — HU-27: registro de una cuenta real.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    await ref.read(sessionControllerProvider.notifier).registrar(
          _username.text.trim(),
          _email.text.trim(),
          _password.text,
        );
    if (!mounted) return;
    final estado = ref.read(sessionControllerProvider);
    if (estado.hasError) {
      messenger.showSnackBar(SnackBar(content: Text('${estado.error}')));
    } else {
      // El _RootRouter ya muestra el shell; cerramos esta pantalla.
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cargando = ref.watch(sessionControllerProvider).isLoading;

    return AuthScaffold(
      showBackButton: true,
      card: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.registerTitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _username,
            enabled: !cargando,
            decoration: InputDecoration(
              labelText: l10n.registerName,
              prefixIcon: const Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            variant: AppTextFieldVariant.email,
            controller: _email,
            enabled: !cargando,
            decoration: InputDecoration(
              labelText: l10n.registerEmail,
              prefixIcon: const Icon(Icons.mail_outline),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            variant: AppTextFieldVariant.password,
            controller: _password,
            enabled: !cargando,
            onSubmitted: (_) => _registrar(),
            decoration: InputDecoration(
              labelText: l10n.registerPassword,
              prefixIcon: const Icon(Icons.lock_outline),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: l10n.registerSubmit,
            onPressed: cargando ? null : _registrar,
            loading: cargando,
          ),
        ],
      ),
      footer: TextButton(
        onPressed: cargando ? null : () => Navigator.of(context).pop(),
        child: Text(l10n.registerHaveAccount),
      ),
    );
  }
}
