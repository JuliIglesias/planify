/// Grid de 4pt y radios de borde — docs/06-design-system.md §5.
/// Coincide dp==pt entre Material (Android) y HIG (iOS): no hace falta
/// ningún ajuste por plataforma (docs/06-design-system.md §1.1).
abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;

  /// Radio chico — inputs/elementos compactos, dentro de la intersección
  /// Material (8-16dp) / HIG (10-14pt).
  static const radiusSm = 8.0;

  /// Radio "de card" — cards, botones, inputs. Sin cambio de valor respecto
  /// del design system anterior.
  static const cardRadius = 16.0;

  /// Radio grande — contenedores flotantes prominentes (`EventCard`,
  /// `PillToggle`, navbar). Formaliza el "20" que ya se usaba de facto en
  /// 5 lugares sin estar tokenizado (docs/06-design-system.md §2.3).
  static const radiusLg = 20.0;

  /// Radio extra grande — la card flotante de Login/Registro y el logo
  /// redondeado (docs/06-design-system.md §7).
  static const radiusXl = 28.0;

  static const pillRadius = 999.0;

  /// A1 — radio compartido por los contenedores "pill-bar" (navbar y
  /// `PillToggle`): son de la misma familia visual (blanco translúcido,
  /// ítem seleccionado en chip blanco), pero NO son cápsulas completas —
  /// a diferencia de [pillRadius], acá el contenedor es más alto que ancho
  /// por ítem, así que un radio a medio camino (redondea solo las puntas,
  /// se ve como un rectángulo bien redondeado) se ve mejor que forzar
  /// `radio = alto / 2` en cada uno por separado.
  static const barRadius = 24.0;
}
