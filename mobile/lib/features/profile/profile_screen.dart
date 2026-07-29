import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/avatar_stack.dart';
import '../../core/widgets/weekly_availability_grid.dart';
import '../../l10n/generated/app_localizations.dart';
import '../auth/session_controller.dart';
import '../history/history_screen.dart';

/// Perfil — avatar, disponibilidad semanal y accesos (mockup "Profile").
/// La grilla acá es la preferencia general del usuario; la del evento
/// (HU-07) es la que se manda al backend.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _seleccionados = <AvailabilitySlot>{};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final session = ref.watch(sessionControllerProvider).value;
    final nombre = switch (session) {
      SesionOrganizador(:final nombre) => nombre,
      SesionAnonima(:final nombre) => nombre,
      _ => '',
    };

    return ListView(
      children: [
        AppHeader(titulo: l10n.profileTitle),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: Column(
            children: [
              AvatarStack(nombres: [nombre.isEmpty ? '?' : nombre], radius: 40),
              const SizedBox(height: AppSpacing.sm),
              Text(
                nombre,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.profileWeeklyAvailability,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  WeeklyAvailabilityGrid(
                    horaInicio: 8,
                    horaFin: 24,
                    seleccionados: _seleccionados,
                    onToggle: (slot) => setState(() {
                      if (!_seleccionados.remove(slot)) _seleccionados.add(slot);
                    }),
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
        ),
        const SizedBox(height: AppSpacing.md),
        ListTile(
          leading: const Icon(Icons.history),
          title: Text(l10n.profileHistory),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const HistoryScreen()),
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
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}
