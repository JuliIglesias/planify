import 'package:flutter/material.dart';

import '../theme/app_semantic_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_avatar.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/app_dialog.dart';
import '../widgets/app_icon_badge.dart';
import '../widgets/app_logo.dart';
import '../widgets/app_person_row.dart';
import '../widgets/app_text_field.dart';
import '../widgets/avatar_stack.dart';
import '../widgets/event_card.dart';
import '../widgets/pill_toggle.dart';
import '../widgets/quick_action_button.dart';
import '../widgets/status_badge.dart';
import '../widgets/unread_dot.dart';

/// Catálogo interno de componentes — solo para revisión visual durante el
/// desarrollo del design system (Fase 2). NO se enruta desde `main.dart` en
/// producción; se llega acá con un long-press sobre el título de
/// [AppHeader] en un build debug (docs/06-design-system.md §6.3).
///
/// Todavía no está "conectado a las pantallas": esta pantalla solo existe
/// para mostrar los componentes juntos, ninguna pantalla real de la app usa
/// nada de acá todavía (eso es Fase 3).
class DesignCatalogScreen extends StatefulWidget {
  const DesignCatalogScreen({super.key});

  @override
  State<DesignCatalogScreen> createState() => _DesignCatalogScreenState();
}

class _DesignCatalogScreenState extends State<DesignCatalogScreen> {
  String _toggleValue = 'todo';
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Design System — Catálogo')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const _SectionTitle('Paleta — ColorScheme'),
          const _ColorSwatches(),
          const SizedBox(height: AppSpacing.lg),

          const _SectionTitle('Tipografía'),
          const _TypographySamples(),
          const SizedBox(height: AppSpacing.lg),

          const _SectionTitle('AppLogo'),
          const Row(children: [AppLogo(size: 64), SizedBox(width: AppSpacing.md), AppLogo(size: 96)]),
          const SizedBox(height: AppSpacing.lg),

          const _SectionTitle('AppButton'),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              SizedBox(
                width: 260,
                child: AppButton(label: 'Primario', onPressed: () {}),
              ),
              SizedBox(
                width: 260,
                child: AppButton(
                  label: 'Secundario',
                  variant: AppButtonVariant.secondary,
                  onPressed: () {},
                ),
              ),
              SizedBox(
                width: 260,
                child: AppButton(
                  label: 'Outlined',
                  variant: AppButtonVariant.outlined,
                  onPressed: () {},
                ),
              ),
              SizedBox(
                width: 260,
                child: AppButton(label: 'Texto', variant: AppButtonVariant.text, onPressed: () {}),
              ),
              SizedBox(
                width: 260,
                child: AppButton(
                  label: 'Eliminar',
                  variant: AppButtonVariant.danger,
                  icon: Icons.delete_outline,
                  onPressed: () {},
                ),
              ),
              const SizedBox(
                width: 260,
                child: AppButton(label: 'Deshabilitado', onPressed: null),
              ),
              const SizedBox(
                width: 260,
                child: AppButton(label: 'Cargando', onPressed: null, loading: true),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          const _SectionTitle('AppTextField'),
          AppTextField(
            controller: _textController,
            decoration: const InputDecoration(labelText: 'Nombre del evento'),
          ),
          const SizedBox(height: AppSpacing.sm),
          const AppTextField(
            variant: AppTextFieldVariant.password,
            decoration: InputDecoration(labelText: 'PIN'),
          ),
          const SizedBox(height: AppSpacing.lg),

          const _SectionTitle('AppCard'),
          AppCard(
            onTap: () {},
            child: const Text('AppCard — contenedor blanco genérico, tocable.'),
          ),
          const SizedBox(height: AppSpacing.lg),

          const _SectionTitle('AppAvatar / AvatarStack'),
          Row(
            children: const [
              AppAvatar(nombre: 'Juan Pérez'),
              SizedBox(width: AppSpacing.sm),
              AppAvatar(nombre: 'Ana', radius: 28),
              SizedBox(width: AppSpacing.md),
              AvatarStack(nombres: ['Juan Pérez', 'Ana López', 'Carlos Ruiz', 'Marta Díaz']),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          const _SectionTitle('AppPersonRow'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                AppPersonRow(
                  nombre: 'Juan Pérez',
                  subtitulo: 'juan.perez@mail.com',
                  trailing: TextButton(onPressed: () {}, child: const Text('Aceptar')),
                ),
                const Divider(height: 1),
                const AppPersonRow(nombre: 'Ana López', subtitulo: 'Pendiente'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          const _SectionTitle('AppIconBadge'),
          Builder(builder: (context) {
            final colors = context.appSemanticColors;
            final colorScheme = Theme.of(context).colorScheme;
            return Row(
              children: [
                AppIconBadge(icon: Icons.receipt_long, color: colors.danger),
                const SizedBox(width: AppSpacing.sm),
                AppIconBadge(icon: Icons.price_check, color: colors.success),
                const SizedBox(width: AppSpacing.sm),
                AppIconBadge(icon: Icons.event_available, color: colorScheme.primary),
                const SizedBox(width: AppSpacing.sm),
                QuickActionButton(
                  icon: Icons.add_card,
                  label: 'Gasto',
                  color: colorScheme.tertiary,
                  onPressed: () {},
                ),
              ],
            );
          }),
          const SizedBox(height: AppSpacing.lg),

          const _SectionTitle('StatusBadge / EventCardPill'),
          Builder(builder: (context) {
            final colorScheme = Theme.of(context).colorScheme;
            return Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                StatusBadge.saldo(SaldoEstado.pagar, 'Pagar'),
                StatusBadge.saldo(SaldoEstado.pendiente, 'Pendiente'),
                StatusBadge.saldo(SaldoEstado.saldado, 'Saldado'),
                StatusBadge.nuevo('Nuevo'),
                StatusBadge(label: 'Error', color: colorScheme.error),
              ],
            );
          }),
          const SizedBox(height: AppSpacing.lg),

          const _SectionTitle('UnreadDot'),
          const Row(
            children: [
              UnreadDot(cantidad: 1),
              SizedBox(width: AppSpacing.md),
              UnreadDot(cantidad: 12, mostrarNumero: true),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          const _SectionTitle('PillToggle'),
          PillToggle<String>(
            options: const [
              (value: 'todo', label: 'Todo'),
              (value: 'deben', label: 'Me deben'),
              (value: 'debo', label: 'Debo'),
            ],
            selected: _toggleValue,
            onChanged: (v) => setState(() => _toggleValue = v),
          ),
          const SizedBox(height: AppSpacing.lg),

          const _SectionTitle('EventCard'),
          EventCard(
            titulo: 'Cumpleaños de Ana',
            subtitulo: 'Sábado 12 de septiembre · 20:00 · Casa de Ana',
            participantes: const ['Juan Pérez', 'Ana López', 'Carlos Ruiz'],
            monto: r'$4.500',
            montoLabel: 'Te deben',
            pills: [
              EventCardPill.success(label: '5 confirmados', icon: Icons.people_outline, context: context),
              EventCardPill.warning(label: '2 tareas', icon: Icons.assignment_outlined, context: context),
              EventCardPill.danger(
                label: 'Decisión pendiente',
                icon: Icons.warning_amber_outlined,
                context: context,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          const _SectionTitle('AppDialog'),
          AppButton(
            label: 'Abrir diálogo de ejemplo',
            variant: AppButtonVariant.outlined,
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => AppDialog(
                title: const Text('Título del modal'),
                content: const Text('Ancho completo −16px, mismo criterio en toda la app.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                  FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Confirmar')),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _ColorSwatches extends StatelessWidget {
  const _ColorSwatches();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = context.appSemanticColors;

    final swatches = <(String, Color)>[
      ('primary', colorScheme.primary),
      ('secondary', colorScheme.secondary),
      ('primaryContainer', colorScheme.primaryContainer),
      ('secondaryContainer', colorScheme.secondaryContainer),
      ('tertiary (acento)', colorScheme.tertiary),
      ('error', colorScheme.error),
      ('danger (financiero)', semantic.danger),
      ('success', semantic.success),
      ('warning', semantic.warning),
      ('surface', colorScheme.surface),
      ('scaffoldBackground', Theme.of(context).scaffoldBackgroundColor),
      ('onPrimaryContainer (títulos)', colorScheme.onPrimaryContainer),
      ('onSurface (cuerpo)', colorScheme.onSurface),
    ];

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final (label, color) in swatches)
          Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(color: Colors.black12),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 72,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _TypographySamples extends StatelessWidget {
  const _TypographySamples();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('headlineSmall — título de pantalla', style: t.headlineSmall),
        Text('titleMedium — encabezado de sección', style: t.titleMedium),
        Text('titleSmall — nombre en fila de lista', style: t.titleSmall),
        Text('bodyMedium — texto de cuerpo', style: t.bodyMedium),
        Text('bodySmall — subtítulo/metadata', style: t.bodySmall),
        Text('labelSmall — badges/captions', style: t.labelSmall),
      ],
    );
  }
}
