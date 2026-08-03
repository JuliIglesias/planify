import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/generated/app_localizations.dart';
import 'session_controller.dart';

/// SCRUM-14 — HU-27: registro de una cuenta real.
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

  Future<void> _registrar() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    await ref.read(sessionControllerProvider.notifier).registrar(
          _nombre.text.trim(),
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

    return Scaffold(
      appBar: AppBar(title: Text(l10n.registerTitle), backgroundColor: AppColors.surface),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              TextField(
                controller: _nombre,
                enabled: !cargando,
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
                onSubmitted: (_) => _registrar(),
                decoration: InputDecoration(
                  labelText: l10n.registerPassword,
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: cargando ? null : _registrar,
                  child: cargando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(l10n.registerSubmit),
                ),
              ),
              TextButton(
                onPressed: cargando ? null : () => Navigator.of(context).pop(),
                child: Text(l10n.registerHaveAccount),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
