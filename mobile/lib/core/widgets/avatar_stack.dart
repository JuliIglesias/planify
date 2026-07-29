import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Avatares superpuestos con un "+N" al final — patrón repetido en Home,
/// Groups e Historial (docs/00-ui-entendimiento.md §5).
class AvatarStack extends StatelessWidget {
  const AvatarStack({
    super.key,
    required this.nombres,
    this.maxVisible = 3,
    this.radius = 14,
  });

  final List<String> nombres;
  final int maxVisible;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final visibles = nombres.take(maxVisible).toList();
    final restantes = nombres.length - visibles.length;
    final overlap = radius * 1.3;

    return SizedBox(
      height: radius * 2,
      width: visibles.isEmpty
          ? 0
          : overlap * visibles.length + radius * 0.7 + (restantes > 0 ? overlap : 0),
      child: Stack(
        children: [
          for (var i = 0; i < visibles.length; i++)
            Positioned(
              left: i * overlap,
              child: _Avatar(label: _iniciales(visibles[i]), radius: radius),
            ),
          if (restantes > 0)
            Positioned(
              left: visibles.length * overlap,
              child: _Avatar(label: '+$restantes', radius: radius, muted: true),
            ),
        ],
      ),
    );
  }

  static String _iniciales(String nombre) {
    final partes = nombre.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return '?';
    if (partes.length == 1) return partes.first.characters.first.toUpperCase();
    return (partes.first.characters.first + partes[1].characters.first).toUpperCase();
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.label, required this.radius, this.muted = false});

  final String label;
  final double radius;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.surface, width: 2),
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: muted ? AppColors.border : AppColors.primary,
        child: Text(
          label,
          style: TextStyle(
            fontSize: radius * 0.7,
            fontWeight: FontWeight.w600,
            color: muted ? AppColors.textSecondary : Colors.white,
          ),
        ),
      ),
    );
  }
}
