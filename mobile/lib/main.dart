import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/locale_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/pending_invitation_provider.dart';
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

class PlanifyApp extends ConsumerWidget {
  const PlanifyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // El MVP arranca en español; el usuario puede cambiar a inglés y la
    // preferencia queda guardada (H-13). i18n-ready desde el día 1.
    final locale = ref.watch(localeProvider).value ?? const Locale('es');
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appName,
      theme: AppTheme.light,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const _RootRouter(),
    );
  }
}

/// Decide la pantalla inicial según quién esté usando la app, y escucha los
/// links de invitación durante toda la vida de la app (Item 2).
///
/// Antes el deep link solo se escuchaba dentro de `LoginScreen`, así que
/// abrir un link de invitación con una sesión ya iniciada no hacía nada. Acá
/// arriba se captura el token y se guarda en `pendingInvitationProvider`; se
/// aplica solo si ya hay sesión de organizador, o se deja pendiente para que
/// el Login lo aplique después de elegir Ingresar/Crear cuenta/Anónimo.
class _RootRouter extends ConsumerStatefulWidget {
  const _RootRouter();

  @override
  ConsumerState<_RootRouter> createState() => _RootRouterState();
}

class _RootRouterState extends ConsumerState<_RootRouter> {
  AppLinks? _appLinks;
  StreamSubscription<Uri>? _sub;
  bool _initialUriYaProcesada = false;
  bool _aplicandoInvitacion = false;

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
        _initialUriYaProcesada = true;
        _guardarTokenPendiente(initialUri);
      }

      // getInitialLink() y uriLinkStream pueden disparar los dos para el
      // mismo link de arranque en frío (comportamiento conocido de
      // app_links) — se ignora el primer evento del stream si ya se procesó
      // por getInitialLink, para no pedir la invitación dos veces.
      _sub = _appLinks?.uriLinkStream.listen((uri) {
        if (_initialUriYaProcesada) {
          _initialUriYaProcesada = false;
          return;
        }
        _guardarTokenPendiente(uri);
      });
    } catch (_) {
      // Sin canales de plataforma de deep links (ej. widget tests).
    }
  }

  void _guardarTokenPendiente(Uri uri) {
    final raw = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : uri.host;
    final token = raw
        .replaceAll('planify://invite/', '')
        .replaceAll('planify://', '')
        .trim();
    if (token.isEmpty) return;
    ref.read(pendingInvitationProvider.notifier).set(token);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _aplicarInvitacionPendiente(String token) async {
    if (_aplicandoInvitacion) return;
    _aplicandoInvitacion = true;
    ref.read(pendingInvitationProvider.notifier).set(null);

    try {
      final eventoId = await ref.read(authRepositoryProvider).unirseConInvitacion(token);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => EventDetailScreen(eventoId: eventoId)),
      );
    } catch (_) {
      // Token vencido/inválido: no bloquea el resto de la app.
    } finally {
      _aplicandoInvitacion = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ya había sesión de organizador iniciada: el link se aplica solo, sin
    // pedir nada (criterio de aceptación del Item 2). El camino anónimo se
    // resuelve dentro de LoginScreen, que lee este mismo provider.
    ref.listen<String?>(pendingInvitationProvider, (previous, token) {
      final estado = ref.read(sessionControllerProvider).value;
      if (token != null && estado is SesionOrganizador) {
        _aplicarInvitacionPendiente(token);
      }
    });
    ref.listen<AsyncValue<Session>>(sessionControllerProvider, (previous, next) {
      final token = ref.read(pendingInvitationProvider);
      if (token != null && next.value is SesionOrganizador) {
        _aplicarInvitacionPendiente(token);
      }
    });

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
