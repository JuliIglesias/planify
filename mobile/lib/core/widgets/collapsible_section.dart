import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Sección colapsable dentro de una Card (Item 3).
///
/// Cerrada muestra solo el título — evita que una grilla larga (disponibilidad
/// semanal 24hs) obligue a scrollear toda la pantalla para llegar a lo que
/// sigue. Abierta muestra el contenido completo, igual que antes.
class CollapsibleSection extends StatefulWidget {
  const CollapsibleSection({
    super.key,
    required this.titulo,
    required this.child,
    this.initiallyExpanded = false,
    this.trailing,
  });

  final String titulo;
  final Widget child;
  final bool initiallyExpanded;
  final Widget? trailing;

  @override
  State<CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<CollapsibleSection> {
  bool _expandido = false;

  @override
  void initState() {
    super.initState();
    _expandido = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            onTap: () => setState(() => _expandido = !_expandido),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.titulo,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (widget.trailing != null) widget.trailing!,
                  Icon(_expandido ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
          ),
          if (_expandido)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: widget.child,
            ),
        ],
      ),
    );
  }
}
