import 'package:flutter/material.dart';

import 'core/debug/design_catalog_screen.dart';
import 'core/theme/app_theme.dart';

/// Entrypoint de desarrollo — corre SOLO el catálogo de componentes, sin el
/// resto de la app (sesión, routers, providers de red). No es el entrypoint
/// de producción (ese sigue siendo `main.dart`); existe para poder revisar
/// el design system de un vistazo sin loguearse ni tener backend corriendo.
///
///   flutter run -t lib/dev_catalog_main.dart -d chrome
///
/// El mismo catálogo también es alcanzable dentro de la app real con un
/// long-press sobre el título de cualquier `AppHeader`, solo en builds
/// debug (docs/06-design-system.md §6.3).
void main() {
  runApp(MaterialApp(theme: AppTheme.light, home: const DesignCatalogScreen()));
}
