import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Punto rojo de actividad sin leer (mockup "Groups").
/// A partir de 1 no leído muestra el punto; con [contador] visible, el número.
class UnreadDot extends StatelessWidget {
  const UnreadDot({super.key, required this.cantidad, this.mostrarNumero = false});

  final int cantidad;
  final bool mostrarNumero;

  @override
  Widget build(BuildContext context) {
    if (cantidad <= 0) return const SizedBox.shrink();

    if (!mostrarNumero) {
      return Semantics(
        label: 'Hay actividad sin leer',
        child: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppColors.danger,
            shape: BoxShape.circle,
          ),
        ),
      );
    }

    return Semantics(
      label: '$cantidad novedades sin leer',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        constraints: const BoxConstraints(minWidth: 20),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          cantidad > 99 ? '99+' : '$cantidad',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
