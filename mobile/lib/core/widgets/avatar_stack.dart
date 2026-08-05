import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/initials.dart';

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

  /// Ancho del borde blanco que separa cada avatar del siguiente (`_Avatar`).
  static const _borde = 2.0;

  @override
  Widget build(BuildContext context) {
    final visibles = nombres.take(maxVisible).toList();
    final restantes = nombres.length - visibles.length;
    final overlap = radius * 1.3;

    return SizedBox(
      // Item 3 (Tanda 6) — el contenedor medía exactamente el diámetro del
      // CircleAvatar (`radius * 2`), sin lugar para el borde que dibuja cada
      // avatar por encima; el Stack (que recorta por default) se comía el
      // borde de arriba y de abajo. Sumamos el borde a la altura y sacamos
      // el recorte (no hay nada que este Stack necesite ocultar).
      height: radius * 2 + _borde * 2,
      width: visibles.isEmpty
          ? 0
          : overlap * visibles.length + radius * 0.7 + _borde * 2 + (restantes > 0 ? overlap : 0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < visibles.length; i++)
            Positioned(
              left: i * overlap,
              top: 0,
              child: _Avatar(label: initialsOf(visibles[i]), radius: radius),
            ),
          if (restantes > 0)
            Positioned(
              left: visibles.length * overlap,
              top: 0,
              child: _Avatar(label: '+$restantes', radius: radius, muted: true),
            ),
        ],
      ),
    );
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
