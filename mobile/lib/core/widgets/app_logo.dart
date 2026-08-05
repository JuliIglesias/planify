import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Logo de marca con esquinas redondeadas — docs/06-design-system.md §7.
/// El archivo fuente (`assets/logo.png`) tiene esquinas cuadradas de
/// fábrica; este widget las redondea con `AppSpacing.radiusLg` (20dp),
/// consistente con `EventCard`/`PillToggle`.
///
/// NOTA: componente de librería, todavía no conectado a ninguna pantalla
/// (Fase 2). Se usa en Login/Registro y en el header de Home recién en
/// Fase 3, junto con el resto de esas pantallas.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Image.asset(
        'assets/logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}
