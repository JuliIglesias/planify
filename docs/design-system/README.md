# Catálogo del design system — documentación exportable

Este directorio guarda el catálogo de componentes como documentación
persistente (pedido explícito del usuario tras aprobar la Fase 2 — ver
[05-fixes.md](../05-fixes.md)), separado del catálogo real en código
(`mobile/lib/core/debug/design_catalog_screen.dart`, que es la fuente de
verdad — esto es una copia de referencia/documentación).

## Archivos

- **`catalog.html`** — recreación visual autocontenida (HTML+CSS inline, sin
  dependencias externas) del catálogo de componentes, con los mismos hex,
  tamaños y radios que el código Dart real. Se puede abrir directo en el
  navegador. Es la misma página que se publicó como artifact durante la
  Fase 2 — acá queda versionada en el repo en vez de depender de un link
  que puede expirar.
- **`tokens.json`** — los tokens de color/tipografía/spacing/radios en
  formato compatible con el plugin **[Tokens Studio for
  Figma](https://tokens.studio/)** (también sigue la convención básica
  `$value`/`$type` del [W3C Design Tokens Community
  Group](https://design-tokens.github.io/community-group/format/), por si
  se necesita portar a otra herramienta).

## Cómo llevarlo a Figma

No pude conectar el conector de Figma en esta sesión (no está autorizado —
requiere que alguien lo habilite desde `claude mcp` o `/mcp` en una sesión
interactiva, o desde la configuración de conectores de claude.ai). El
camino que sí quedó listo:

1. En Figma, instalar el plugin **Tokens Studio for Figma** (gratuito,
   marketplace de plugins de Figma).
2. `Tokens Studio → Import → From File/Folder` y elegir `tokens.json`.
3. Aplicar los tokens importados a estilos de Figma (`Apply to document` /
   `Create styles` desde el propio plugin) — quedan como Color Styles y
   Text Styles nativos de Figma, no solo como valores del plugin.
4. Para los componentes en sí (no solo los tokens): `catalog.html` sirve
   como referencia visual 1:1 mientras se arman los componentes a mano en
   Figma (no hay una forma automática de convertir HTML a componentes
   nativos de Figma sin el plugin/conector correspondiente).

Si en algún momento se autoriza el conector de Figma en una sesión de
Claude Code, puedo reconstruir esto directamente como archivo de Figma real
(variables, componentes con variantes, etc.) en vez de este puente vía
tokens — avisame cuando esté disponible.
