import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/session_controller.dart';
import 'features/events/event_detail_screen.dart';
import 'features/home/app_shell.dart';
import 'l10n/generated/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Necesario para formatear fechas en español (DateFormat con locale 'es').
  await initializeDateFormatting('es');
  runApp(const ProviderScope(child: PlanifyApp()));
}

class PlanifyApp extends StatelessWidget {
  const PlanifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appName,
      theme: AppTheme.light,
      // El MVP sale en español; el inglés se completa más adelante
      // (docs/02-decisiones.md Duda #15/F5), pero la arquitectura queda i18n-ready.
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const _RootRouter(),
    );
  }
}

/// Decide la pantalla inicial según quién esté usando la app:
/// organizador logueado → shell con bottom nav; anónimo con evento guardado →
/// directo a su evento (seguimiento F1); nadie → login.
class _RootRouter extends ConsumerWidget {
  const _RootRouter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);

    return session.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const LoginScreen(),
      data: (estado) => switch (estado) {
        SesionOrganizador() => const AppShell(),
        SesionAnonima(:final eventoId) => EventDetailScreen(eventoId: eventoId),
        SinSesion() => const LoginScreen(),
      },
    );
  }
}
