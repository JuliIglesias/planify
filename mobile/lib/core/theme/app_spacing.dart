/// Grid de 4pt — docs/03-design-system.md §3.
abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;

  static const cardRadius = 16.0;
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
