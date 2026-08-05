import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/avatar_stack.dart';
import '../../core/widgets/collapsible_section.dart';
import '../../core/widgets/weekly_availability_grid.dart';
import '../../l10n/generated/app_localizations.dart';
import '../auth/session_controller.dart';
import '../friends/friends_screen.dart';
import '../history/history_screen.dart';
import '../notifications/notifications_screen.dart';

import 'profile_availability_provider.dart';

/// Perfil — avatar, disponibilidad semanal y accesos (mockup "Profile").
/// La grilla acá es la preferencia general del usuario; la del evento
/// (HU-07) se inicializa a partir de esta preferencia.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final session = ref.watch(sessionControllerProvider).value;
    final profileAvailAsync = ref.watch(profileAvailabilityProvider);
    final seleccionados = profileAvailAsync.value ?? const <AvailabilitySlot>{};
    final username = switch (session) {
      SesionOrganizador(:final username) => username,
      SesionAnonima(:final username) => username,
      _ => '',
    };
    // A2 — ídem Home/Grupos/Saldos: altura real de la navbar + margen.
    final bottomPad = ref.watch(bottomNavHeightProvider) + AppSpacing.md;

    return ListView(
      padding: EdgeInsets.only(bottom: bottomPad),
      children: [
        AppHeader(titulo: l10n.profileTitle),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: Column(
            children: [
              AvatarStack(nombres: [username.isEmpty ? '?' : username], radius: 40),
              const SizedBox(height: AppSpacing.sm),
              Text(
                username,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: CollapsibleSection(
            titulo: l10n.profileWeeklyAvailability,
            initiallyExpanded: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WeeklyAvailabilityGrid(
                  horaInicio: 0,
                  horaFin: 24,
                  seleccionados: seleccionados,
                  onToggle: (slot) {
                    final nuevos = Set<AvailabilitySlot>.from(seleccionados);
                    if (!nuevos.remove(slot)) nuevos.add(slot);
                    ref.read(profileAvailabilityProvider.notifier).guardar(nuevos);
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.profileAvailabilityHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.md),
        // FR13 — "Mis amigos" (H-16: faltaba respecto del mockup de Perfil).
        ListTile(
          leading: const Icon(Icons.people_outline),
          title: Text(l10n.friendsTitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const FriendsScreen()),
          ),
        ),
        // NFR#6 — cambiar idioma (H-13).
        ListTile(
          leading: const Icon(Icons.language),
          title: Text(l10n.profileLanguage),
          trailing: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'es', label: Text('ES')),
              ButtonSegment(value: 'en', label: Text('EN')),
            ],
            selected: {ref.watch(localeProvider).value?.languageCode ?? 'es'},
            onSelectionChanged: (s) =>
                ref.read(localeProvider.notifier).cambiar(s.first),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.history),
          title: Text(l10n.profileHistory),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const HistoryScreen()),
          ),
        ),
        // Item 2 (Tanda 6) — segundo acceso a Notificaciones (el otro es la
        // campana del Home).
        ListTile(
          leading: const Icon(Icons.notifications_none),
          title: Text(l10n.profileNotifications),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.logout, color: AppColors.danger),
          title: Text(
            l10n.profileLogout,
            style: const TextStyle(color: AppColors.danger),
          ),
          onTap: () => ref.read(sessionControllerProvider.notifier).cerrarSesion(),
        ),
      ],
    );
  }
}
