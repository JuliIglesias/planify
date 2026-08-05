import 'package:flutter/material.dart';

/// Ícono dentro de un círculo pastel (color con alpha bajo) — patrón
/// repetido en `QuickActionButton`, `ActivityFeedItem` y el resumen de
/// Balances (docs/06-design-system.md §2.2/§6.1). Consolida las 3 copias en
/// un único widget.
class AppIconBadge extends StatelessWidget {
  const AppIconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 40,
    this.iconSize,
  });

  final IconData icon;
  final Color color;

  /// Diámetro del círculo.
  final double size;

  /// Default: `size * 0.5`.
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: iconSize ?? size * 0.5, color: color),
    );
  }
}
