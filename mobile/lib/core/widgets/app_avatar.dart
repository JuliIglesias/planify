import 'package:flutter/material.dart';

import '../utils/initials.dart';

/// Avatar circular suelto — foto de red con fallback de iniciales.
/// docs/06-design-system.md §6.1: reemplaza los `CircleAvatar(...)` a mano
/// repetidos en Balances/Amigos/Grupos, y el cálculo de iniciales duplicado.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.nombre,
    this.imageUrl,
    this.radius = 20,
    this.backgroundColor,
    this.foregroundColor,
  });

  /// Usado para las iniciales de fallback y como `semanticsLabel`.
  final String nombre;
  final String? imageUrl;
  final double radius;

  /// Default: `colorScheme.primary`.
  final Color? backgroundColor;

  /// Color de las iniciales de fallback. Default: `colorScheme.onPrimary`
  /// (blanco) — si se pasa un `backgroundColor` claro/pastel (ej. un
  /// estado "inactivo"), hay que pasar también un `foregroundColor` con
  /// contraste (blanco sobre pastel no cumple AA).
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tieneImagen = imageUrl != null && imageUrl!.isNotEmpty;

    return Semantics(
      label: nombre,
      image: true,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? colorScheme.primary,
        backgroundImage: tieneImagen ? NetworkImage(imageUrl!) : null,
        child: tieneImagen
            ? null
            : Text(
                initialsOf(nombre),
                style: TextStyle(
                  fontSize: radius * 0.7,
                  fontWeight: FontWeight.w600,
                  color: foregroundColor ?? colorScheme.onPrimary,
                ),
              ),
      ),
    );
  }
}
