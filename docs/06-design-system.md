# Planify — Design System v2 (Fase 1: auditoría + propuesta)

> Reemplaza los valores "aproximados por lectura de Figma" de
> [03-design-system.md](03-design-system.md) por la paleta oficial de marca
> (6 hex exactos, provistos por el usuario — no inferidos de ninguna imagen) y
> formaliza en `ColorScheme`/`ThemeData` lo que hoy vive repartido en
> ~15 archivos. **No se tocó código en esta fase.** Todo lo de abajo es
> propuesta, a la espera de aprobación explícita.
>
> **v2 (2026-08-05):** actualizado tras feedback del usuario en dos puntos
> con impacto real en la arquitectura del design system:
> 1. **Cambio de alcance de plataforma** — el mobile ya no es "Android con
>    notas de iOS por si acaso": es **Flutter multiplataforma de punta a
>    punta**, mantenido para que compilar iOS a futuro sea solo build, no
>    rediseño (ver §1, reescrita entera, y nota agregada en
>    [00-entendimiento.md](00-entendimiento.md) §8). El código sigue siendo
>    uno solo — esto no implica pantallas ni componentes distintos por
>    plataforma, sino diseñar los tokens compartidos para que ninguno
>    dependa de una convención exclusivamente Android.
> 2. **Respuestas del usuario a las 4 ambigüedades de la v1** (antigua §9) —
>    incorporadas en §3 (paleta) y §6.3 (catálogo). La sección de
>    ambigüedades pasa a ser un registro de decisiones confirmadas + los
>    puntos nuevos que introduce el cambio de alcance.

## Índice

1. [Guidelines aplicables (Android + iOS)](#1-guidelines-aplicables-android--ios)
2. [Inventario del estado actual](#2-inventario-del-estado-actual)
3. [Propuesta — paleta como `ColorScheme` M3](#3-propuesta--paleta-como-colorscheme-m3)
4. [Propuesta — tipografía](#4-propuesta--tipografía)
5. [Propuesta — espaciado y radios](#5-propuesta--espaciado-y-radios)
6. [Propuesta — componentes reutilizables](#6-propuesta--componentes-reutilizables)
7. [Propuesta — logo](#7-propuesta--logo)
8. [Propuesta — ícono de la app](#8-propuesta--ícono-de-la-app)
9. [Decisiones confirmadas y puntos nuevos a confirmar](#9-decisiones-confirmadas-y-puntos-nuevos-a-confirmar)

---

## 1. Guidelines aplicables (Android + iOS)

Leídos completos [android-guidelines.md](guidelines/android-guidelines.md) e
[ios-guidelines.md](guidelines/ios-guidelines.md). **Cambio de alcance
confirmado por el usuario (2026-08-05):** el mobile ya no es Android-only —
es Flutter multiplataforma de punta a punta, un solo código, para que una
build iOS futura sea solo compilar, no rediseñar. Eso cambia el criterio de
esta sección respecto de la v1: ya no alcanza con "Material normativo, iOS
como nota" — el design system tiene que definirse en la **intersección**
de ambas guías donde coinciden, y elegir explícitamente qué hacer donde
divergen, en vez de ignorar iOS.

Importante: esto **no** significa construir dos variantes de cada pantalla.
Significa que los tokens compartidos (color, tipografía, spacing, radios)
no pueden asumir una convención exclusivamente Android, y que hay un puñado
de comportamientos (no de estilos) donde Flutter ya resuelve la diferencia
por plataforma automáticamente — hay que verificar que nada de lo custom-
built de Planify lo pise sin querer.

### 1.1 Fundamentos compartidos — ya conviven sin conflicto

Donde ambas guías esencialmente piden lo mismo, no hay decisión que tomar:

| Convención | Material (Android) | HIG (iOS) | Zona compartida elegida |
|---|---|---|---|
| Escala tipográfica | 57/45/36/32/28/24/22/16/14/16/14/12/14/12/11 sp | 34/28/22/20/17/17/16/15/13/12/11 pt | Se usa la escala M3 (ya implementada, ver §4) — el body 16sp de Material cae dentro del rango 15-17pt que HIG considera "cuerpo", así que se lee nativo en ambas |
| Tamaño táctil mínimo | 48×48 dp | 44×44 pt | **48dp** para todo — es el mayor de los dos, cumple ambos umbrales sin condicionales por plataforma. A verificar por pantalla en Fase 3 (no auditado sistemáticamente todavía) |
| Grilla de espaciado | múltiplos de 8dp | múltiplos de 8pt (misma escala 4/8/16/24/32/48/64) | Ya existe `AppSpacing` (§5) — coincide dp==pt en ambas guías, no hace falta ningún ajuste por plataforma |
| Radio de bordes | 8/12/16/20/28 dp | 10-14pt (componentes nativos) | Los radios "de card" (12-16) caen en la intersección real de ambas. Los radios grandes (20/28, usados por `EventCard`/tarjetas flotantes) son una elección de marca por fuera de lo "nativo" de cualquiera de las dos — igual de legítimo en Android que en iOS, porque Planify no imita chrome nativo, tiene un lenguaje visual propio |
| Padding de cards | 16dp | 16pt | Idéntico — ya consistente en los componentes core |
| Contraste AA (4.5:1) | Sí | Sí | Ídem en ambas — se verifica al fijar los roles del `ColorScheme` (§3) |
| Elevación / sombra sutil en vez de sombra dura | Material 3 favorece superficies planas | HIG pide elevación "mínima/sutil" | Ya se usa (`elevation: 0-1` + `BoxShadow` alpha bajo) — coincide en ambas guías, ninguna pide sombras marcadas |

### 1.2 Lo que Flutter ya adapta solo por plataforma (verificado, no hace falta tocar nada)

- **Gesto de "volver" (swipe-back en iOS).** `ThemeData.pageTransitionsTheme`
  por default de Flutter ya mapea `TargetPlatform.iOS` a
  `CupertinoPageTransitionsBuilder` (swipe desde el borde + transición
  deslizante nativa) sin ninguna configuración adicional, **mientras nada
  pise ese default**. Se verificó: `AppTheme.light` (`app_theme.dart`) no
  define `pageTransitionsTheme`, así que este comportamiento ya está
  activo tal cual, sin cambios. Se re-confirma explícitamente en Fase 2 al
  tocar `ThemeData`, para no romperlo por accidente.
- **Safe area (notch, Dynamic Island, home indicator, gesture bar de
  Android).** Ya se usa `SafeArea` de forma consistente — es la misma API
  para ambas plataformas, Flutter resuelve los insets reales del SO.
- **Fuente de íconos.** Los `Icons.xxx` de Material se dibujan desde una
  fuente empaquetada con la app — se ven idénticos en Android e iOS (no
  hace falta un set "SF Symbols" aparte; esa es una preocupación de apps
  nativas, no de Flutter).
- **Dynamic Type / escalado de texto de accesibilidad.** Ya respetado por
  default vía `MediaQuery.textScaler` mientras no se hardcodeen tamaños en
  `px` fuera de `TextTheme` — se mantiene como criterio de revisión en
  Fase 3 (no usar `fontSize:` a mano suelto).

### 1.3 Dónde el sistema de Planify ya no imita a ninguna plataforma nativa (y eso está bien)

`AppBottomNav` (navbar flotante tipo pill) y `EventCard` (radio 20, sombra
propia) no son ni el `NavigationBar` de Material ni el `CupertinoTabBar` de
iOS — son un lenguaje visual de marca construido en tandas anteriores. Esto
es una ventaja para multiplataforma: al no imitar el chrome nativo de
ninguno de los dos, no hay nada que "se vea raro" en el otro sistema
operativo — el mismo diseño se ve igual de intencional en los dos. Se
mantiene tal cual.

### 1.4 Brecha real encontrada: no existe carpeta `ios/` en el proyecto

`mobile/` hoy solo tiene scaffold nativo de `android/` — no hay
`mobile/ios/`. Esto significa que, aunque el código Dart ya sea
multiplataforma por diseño, **el proyecto no se puede compilar para iOS
todavía** (falta el proyecto Xcode/Runner que Flutter genera). Antes de
generar assets de ícono para iOS (§8) hace falta correr
`flutter create --platforms=ios .` dentro de `mobile/` (regenera solo el
scaffold nativo faltante, no toca `lib/`). Se propone como primer paso de
Fase 2 — confirmar en §9 antes de ejecutarlo, porque agrega archivos de
proyecto Xcode nuevos (bundle identifier, `Info.plist`, etc.) que conviene
que el usuario revise una vez generados.

---

## 2. Inventario del estado actual

### 2.1 Colores hardcodeados fuera del token central

`AppColors` (`mobile/lib/core/theme/app_colors.dart`) ya centraliza la
mayoría de los colores como constantes estáticas, pero **no está integrado
al `ColorScheme` de `ThemeData`** — `AppTheme.light` solo usa
`ColorScheme.fromSeed(seedColor: AppColors.primary, ...)` para 3 roles
(`primary`/`surface`/`error`) y el resto de la UI referencia
`AppColors.xxx` directo, widget por widget, en vez de `Theme.of(context).colorScheme.xxx`.
Eso es exactamente lo que Material 3 desaconseja (guideline §13: "usar roles
semánticos en lugar de colores hardcodeados").

Además, **8 literales `Color(0x...)` sueltos fuera de `app_colors.dart`**,
todos en el mismo archivo:

| Archivo | Líneas | Valores | Uso |
|---|---|---|---|
| `features/groups/groups_screen.dart` | 252-253 | `0xFFFFEBEE`/`0xFFC62828` | Pill "Decisión pendiente" (rojo claro/oscuro) |
| `features/groups/groups_screen.dart` | 265-266 | `0xFFE8F5E9`/`0xFF2E7D32` | Pill "confirmados" (verde claro/oscuro) |
| `features/groups/groups_screen.dart` | 272-273 | `0xFFFFF8E1`/`0xFFF57F17` | Pill "tareas pendientes" (ámbar claro/oscuro) |
| `features/groups/groups_screen.dart` | 279-280 | `0xFFFFECEB`/`0xFFD84315` | Pill "gastos" (coral claro/oscuro) |

Ninguno de estos 8 valores existe en `AppColors`; son tonos Material
"de catálogo" (los pares light/dark de Google's Material palette) pegados a
mano, no derivados de la paleta de marca. Se reemplazan por contenedores
tonales del `ColorScheme` nuevo (§3) o por constructores semánticos del pill
(§6, `EventCardPill.success/.warning/.danger/.info`).

También hay uso de **colores de Material puro sin pasar por ningún token**:

| Archivo | Uso |
|---|---|
| `features/events/event_detail_screen.dart:665` | `Colors.orange` (estado de tarea) — no existe en la paleta |
| `features/events/event_detail_screen.dart:690` | `Colors.grey.shade600` |
| `core/widgets/app_scaffold.dart`, `auth_scaffold.dart`, `event_card.dart`, `pill_toggle.dart` | `Colors.black.withValues(alpha: ...)` para sombras — aceptable (es sombra, no color de marca), pero sin tokenizar el alpha se repiten 5 valores distintos (0.04/0.08/0.08/0.08/0.1) para lo que conceptualmente es "una sombra sutil" en todos los casos |

### 2.2 Componentes duplicados en vez de reutilizables

Ya existe una base de componentes compartidos (`core/widgets/`, construida
en tandas anteriores — ver [05-fixes.md](05-fixes.md) Tanda 5-7). El
inventario de abajo distingue **qué ya existe y solo necesita re-tema** vs.
**qué está genuinamente duplicado y hace falta extraer**.

**Ya existen (Fase 2 los re-estiliza con la paleta nueva, no los reconstruye):**

| Componente | Archivo | Cubre el pedido de... |
|---|---|---|
| `AppTextField` | `core/widgets/app_text_field.dart` | "AppTextField" |
| `AppDialog` | `core/widgets/app_dialog.dart` | "AppModal" (ya es ancho completo −16px) |
| `EventCard` (+ `BalanceRow`, `ActivityFeedItem`) | `core/widgets/event_card.dart` | "AppCard" (evento) |
| `StatusBadge` | `core/widgets/status_badge.dart` | "AppBadge" |
| `PillToggle` | `core/widgets/pill_toggle.dart` | "AppSegmentedToggle" (Todo/Me deben/Debo, y Notificaciones) |
| `AvatarStack` | `core/widgets/avatar_stack.dart` | Avatares superpuestos (no cubre avatar suelto, ver abajo) |
| `AuthScaffold` | `core/widgets/auth_scaffold.dart` | Chrome de Login/Registro |
| `UnreadDot`, `CollapsibleSection`, `QuickActionButton` | `core/widgets/` | — |

**Genuinamente duplicados — sin componente propio hoy:**

| Patrón repetido | Dónde aparece | Detalle |
|---|---|---|
| Avatar circular suelto (con iniciales de fallback) | `balances_screen.dart`, `friend_profile_screen.dart`, `groups_screen.dart` (`_iniciales`, reimplementado 2 veces con la misma lógica), `avatar_stack.dart` (internamente) | `CircleAvatar(...)` a mano 5 veces; el cálculo de iniciales (`_iniciales`) está copiado, no compartido |
| Fila "persona" (avatar + nombre + subtítulo + acción/trailing) | `friends_screen.dart` (3 variantes: mis amigos, solicitudes recibidas, solicitudes enviadas), `friend_picker.dart` (selección única y múltiple), `friend_profile_screen.dart` | Cada pantalla arma su propio `ListTile`/`CheckboxListTile` con el mismo layout conceptual |
| Botones de acción (primario/secundario/peligro) | 12 archivos usan `ElevatedButton`/`FilledButton`/`OutlinedButton`/`TextButton` directo, algunos con `style:` a mano repitiendo color/radio/alto | No hay un wrapper único — el estilo global de `elevatedButtonTheme` cubre el caso feliz, pero variantes (outline, texto, "peligro" en rojo para cancelar/eliminar) se resuelven ad-hoc por pantalla |
| Ícono dentro de círculo pastel | `QuickActionButton` (evento), `ActivityFeedItem` (feed), `_MiniResumen` de `balances_screen.dart` (Tanda 6 Item 4) | Mismo patrón visual (`Container` circular 40-44dp + `Icon` + color con alpha 0.12) reimplementado 3 veces con leves diferencias de tamaño |
| Card/contenedor blanco genérico (no-evento) | `person_detail_sheet.dart`, secciones de `profile_screen.dart`, `event_config_screen.dart` | `Container`/`Card` con `AppColors.surface` + radio + padding a mano, sin componente compartido |

### 2.3 Inconsistencias de radio, padding y tipografía

**Radios de borde** — literales fuera de `AppSpacing` encontrados por grep:

| Valor | Archivo:línea | ¿Debería ser? |
|---|---|---|
| `20` | `event_card.dart:64,77`, `evento_resumen_card.dart:28`, `pill_toggle.dart:43`, `app_scaffold.dart:221` (navbar) | Consistente *entre sí* (5 usos), pero no tokenizado — se propone `AppSpacing.radiusLg = 20` |
| `28` | `auth_scaffold.dart:68` (card flotante de Login/Registro) | Único uso — se propone `AppSpacing.radiusXl = 28` |
| `12` | `create_event_screen.dart:356` | Coincide con el rango Material (8-16) pero no usa `cardRadius`(16) ni ningún token — revisar si es intencional o descuido |
| `8` | `event_detail_screen.dart:222` | Ídem — sin token |
| `3`, `4` | `friend_profile_screen.dart:218`, `weekly_availability_grid.dart:198` | Radios muy chicos (probablemente celdas del heatmap / detalle visual fino) — no tokenizar, son casos de detalle, no de card/botón |

**Conclusión:** el radio "20" es de facto un segundo tier consistente entre
`EventCard`/`PillToggle`/navbar (contenedores flotantes prominentes) que
convive con `cardRadius`(16, cards internas/inputs/botones) sin estar
declarado como tal. Se formaliza en §5.

**Tipografía:** no se encontraron `fontSize:` hardcodeados fuera de
`TextTheme` — buena señal, la escala M3 ya se respeta en todos lados vía
`theme.textTheme.xxx`. La inconsistencia es de **uso**, no de escala: por
ejemplo, encabezados de sección usan a veces `titleMedium` bold y a veces
`headlineSmall` bold para jerarquías visualmente similares entre pantallas
(ya corregido una vez para Historial en Tanda 6 Item 3 — ver
[05-fixes.md](05-fixes.md)). Se deja como criterio de revisión pantalla por
pantalla en Fase 3, no amerita un token nuevo.

**Padding:** consistente en los componentes core (`AppSpacing.md`=16 para
cards/inputs, siguiendo la guideline). No se encontraron paddings sueltos
fuera de la escala 4/8/16/24/32.

---

## 3. Propuesta — paleta como `ColorScheme` M3

### 3.1 Los 6 colores dados

```
Azul primario   #296CF2   →  marca / acción principal
Azul secundario #92C2FC   →  acción secundaria, más suave
Azul claro      #DBEAFE   →  contenedor/fondo de elementos "sobre" primario
Azul fondo      #ECF4FF   →  fondo general de pantalla
Rojo/coral      #FF6B6B   →  acento — llama la atención (FAB, "nuevo", errores)
Azul oscuro     #3E579C   →  texto sobre fondos claros/celestes
```

### 3.2 Mapeo a `ColorScheme` (Material 3, light) — v2, con las decisiones confirmadas

> Actualizado con las respuestas del usuario a la v1 (antigua §9): `error`
> deja de reusar el coral de `tertiary` (pasa a ser un rojo propio, menos
> vívido); `success`/`warning` se mantienen conceptualmente pero se afinan
> para no quedar tan brillantes contra la paleta nueva; el texto de cuerpo
> **no** pasa a azul — solo los títulos.

```dart
ColorScheme(
  brightness: Brightness.light,

  primary:               Color(0xFF296CF2), // Azul primario
  onPrimary:              Colors.white,
  primaryContainer:      Color(0xFFDBEAFE), // Azul claro
  onPrimaryContainer:    Color(0xFF3E579C), // Azul oscuro — también el color de TÍTULOS (§3.4)

  secondary:             Color(0xFF92C2FC), // Azul secundario — uso principal: COMO contenido (ícono/texto) sobre blanco, no como fondo (§3.4b)
  onSecondary:           Color(0xFF3E579C), // Azul oscuro — SOLO para el caso raro de usar `secondary` como fondo relleno; nunca blanco (confirmado)
  secondaryContainer:    Color(0xFFECF4FF), // Azul fondo
  onSecondaryContainer:  Color(0xFF3E579C),

  tertiary:              Color(0xFFFF6B6B), // Rojo/coral — acento puro (FAB, "nuevo"), SIN cambios
  onTertiary:            Colors.white,
  tertiaryContainer:     <derivado, tinte ~12% de #FF6B6B sobre blanco>,
  onTertiaryContainer:   <derivado, tono oscuro de #FF6B6B>,

  error:                 Color(0xFFCC5A5A), // NUEVO — rojo propio, menos vívido que el acento (§3.4)
  onError:               Colors.white,
  errorContainer:        <derivado, tinte ~12% de #FF6B6B sobre blanco>,
  onErrorContainer:      <derivado, tono oscuro de #CC5A5A>,

  surface:               Colors.white,       // cards, sheets, diálogos
  onSurface:             Color(0xFF14162B), // texto de cuerpo — SIGUE siendo el gris-casi-negro actual, sin cambio (confirmado)
  surfaceContainerHighest: Color(0xFFDBEAFE), // fills de inputs, chips no seleccionados
  onSurfaceVariant:      Color(0xFF6B7280), // texto secundario/caption — sin cambio (confirmado)
  outline:               Color(0xFFDBEAFE), // bordes/divisores
)
```

`scaffoldBackgroundColor` (fondo de pantalla, fuera del `ColorScheme` porque
el rol `background`/`onBackground` está deprecado en M3 desde 2023 —
Flutter lo mantiene por compatibilidad pero la guía oficial pide no
poblarlo) = `#ECF4FF` (Azul fondo), directo en `ThemeData`, igual que hoy
hace `AppColors.background`.

### 3.4 Título vs. cuerpo — el matiz que confirmó el usuario

**Confirmado:** el texto de cuerpo (párrafos, listas, inputs) se queda en
el gris-casi-negro de siempre (`onSurface`/`onSurfaceVariant`, sin cambio de
valor). El **azul oscuro** (`#3E579C`) se usa específicamente para
**títulos** — de sección (Home "Próximos eventos"), de card (`EventCard`,
`AppHeader.titulo`), de página (encabezados de pantalla). Esto **no** es un
rol nuevo de `ColorScheme`: se implementa aplicando `colorScheme.onPrimaryContainer`
(que ya es `#3E579C`, §3.2) como color por default de los estilos
`displayLarge…titleSmall` del `TextTheme` en `AppTheme.light`, dejando
`bodyLarge…labelSmall` con el `onSurface` gris de siempre. Es decir: la
distinción título/cuerpo se resuelve a nivel de tipografía (qué rol de
`TextTheme` se usa), no a nivel de qué `ColorScheme` se aplica — un solo
`ColorScheme`, dos comportamientos de color según el *rol tipográfico*.

### 3.4b `secondary` — uso confirmado: contenido sobre blanco, no fondo relleno

**Confirmado por el usuario:** el azul secundario (`#92C2FC`) es un celeste
muy claro — sobre él, letras blancas no tienen contraste utilizable. Su uso
ideal **no** es como fondo de un botón/chip relleno (el caso que
`onSecondary` cubre, y por eso `onSecondary` es azul oscuro y no blanco,
§3.2), sino **directamente como color de contenido** (ícono o texto) puesto
sobre blanco/superficies claras — el ejemplo que dio el usuario es
literalmente el caso que ya existe en el código: el color de los ítems
**no seleccionados** de `AppBottomNav` (hoy `AppColors.inactiveBlue =
#A6B6EF`, Tanda 6 Item 1) y de `PillToggle`. Se confirma: `secondary`
(`colorScheme.secondary`) **reemplaza** a `AppColors.inactiveBlue` — mismo
rol, valor ligeramente distinto (de `#A6B6EF` a `#92C2FC`), ahora integrado
al `ColorScheme` en vez de ser una constante aparte. Se aplica en Fase 2 al
re-tematizar `AppBottomNav`/`PillToggle` (§6.2).

### 3.5 `error` vs. `tertiary`/acento — ya no comparten hex

En la v1 se proponía reusar el coral (`#FF6B6B`) tanto para `tertiary`
(acento — FAB, "nuevo") como para `error`, por no tener un 7° hex de marca.
El usuario prefirió un rojo de error distinto y menos vívido, así que ya no
hace falta esa solución de compromiso: `tertiary` se queda exactamente en
`#FF6B6B` (sin cambios — sigue siendo el acento visual fuerte para FAB y
badges de novedad) y `error` pasa a ser un rojo aparte, apagado a propósito
para no competir visualmente con el acento. Propuesto: **`#CC5A5A`**
(mismo tono/familia que el coral pero con la saturación y el brillo
reducidos — no es un rojo "de catálogo" al azar, es una versión atenuada
del mismo rojo de marca). Ajustable si preferís otro tono — es el único hex
de la propuesta que no viene de los 6 dados ni de un derivado tonal directo,
así que decime si lo preferís más oscuro/claro antes de Fase 2.

### 3.6 `success`/`warning`/`danger` — se mantienen como 3 tokens propios, armonizados

**Confirmado:** se quedan conceptualmente (verde = a favor/saldado, ámbar =
pendiente, rojo = debo/pagar) pero el usuario pidió que no queden "tan
brillantes" contra la paleta nueva, más azulada y menos saturada que la de
v1. Al no ser roles nativos de `ColorScheme` (M3 no define
"success"/"warning"/un segundo rojo semántico), se implementan como una
**extensión de tema** (`ThemeExtension<AppSemanticColors>`, ver §6.1) en vez
de constantes sueltas — así siguen viviendo "dentro" del tema central
(`Theme.of(context).extension<AppSemanticColors>()`), que es lo más cerca
que permite la API de Flutter de "agregarlos al ColorScheme" cuando el rol
no existe ahí. Valores propuestos (ajustables):

| Token | Valor v1 (sin tocar) | Valor v2 propuesto (armonizado) |
|---|---|---|
| `success` | `#2ECC71` (verde saturado) | `#3FA873` (mismo verde, ~15% menos saturado/brillante) |
| `warning` | `#F5A623` (ámbar saturado) | `#E3A94A` (mismo ámbar, ~10% más apagado) |
| `danger` | `#E74C3C` | **sin cambio** — ver corrección abajo |

**Corrección sobre la v2 anterior:** ahí proponía unificar `danger`
(`SaldoEstado.pagar`, "debo" en Balances) con el `error` nuevo de
formularios (`#CC5A5A`, §3.5). **El usuario lo rechazó explícitamente: el
rojo de "debo" no puede ser el mismo que el de error.** Quedan como **tres**
rojos con roles distintos y visualmente distinguibles entre sí, no dos:

| Token | Valor | Semántica |
|---|---|---|
| `tertiary` (`colorScheme.tertiary`) | `#FF6B6B` | Acento — FAB, "nuevo", llamado de atención puntual (sin cambios) |
| `error` (`colorScheme.error`) | `#CC5A5A` | Validación de formularios / estados de error técnico |
| `danger` (`AppSemanticColors.danger`) | `#E74C3C` (sin cambio — ya era visualmente distinto de los otros dos, no hacía falta tocarlo) | Estado financiero negativo — "debo"/"pagar" en Balances/Historial |

Los tres son de la misma familia (rojo) pero con suficiente diferencia de
tono/saturación para no confundirse entre sí en la misma pantalla (ej. un
`AppButton` variante `danger` para "Eliminar" vs. un monto "debo" en rojo
en la misma vista de Balances).

### 3.3 Por qué esta asignación

- **`primary`/`secondary`/`primaryContainer` calcan literal los 3 azules**
  dados por nombre (primario→primary, secundario→secondary, claro→container):
  es el mapeo más directo posible, cero ambigüedad.
- **`onPrimaryContainer` = azul oscuro, reusado además como color de
  títulos** (§3.4): el usuario etiquetó ese color explícitamente
  "(textos)", y confirmó que aplica a títulos de sección/card/página — no
  al texto de cuerpo, que se queda gris (confirmado, ya no es ambigüedad).
- **`tertiary` = coral, sin cambios**: el usuario lo etiquetó "(acento)",
  que es exactamente la semántica del rol `tertiary` en M3 (contraste con
  primary/secondary, para FAB y llamados de atención puntuales) — reemplaza
  a `AppColors.accent` (`#FF6B5B`, casi idéntico al nuevo `#FF6B6B`, así que
  visualmente el cambio es mínimo). Ya no comparte hex con `error` (§3.5).
- **`error` = rojo propio derivado (`#CC5A5A`)**, no el coral: confirmado
  por el usuario — quería un rojo "no tan brillante", distinto del acento.
  Ver §3.5 para el detalle y la invitación a ajustar el tono exacto.
- **`tertiaryContainer`/`errorContainer`**: **derivados** algorítmicamente
  (tintado hacia blanco, técnica estándar de paletas tonales de Material —
  el mismo mecanismo que `ColorScheme.fromSeed` usa para generar los 13
  tonos de cada color semilla), no un hex "inventado" sin criterio.
- **`outline` = azul claro** (`#DBEAFE`): ya se usaba un tono muy similar
  (`AppColors.border = #E5E7F0`) para separadores — el azul claro dado
  cumple la misma función y además une visualmente bordes/inputs/containers
  bajo un solo hex.

---

## 4. Propuesta — tipografía

La escala actual (`docs/03-design-system.md` §2, implementada en
`AppTheme.light` vía `GoogleFonts.poppinsTextTheme(base.textTheme)`) **ya
hereda los tamaños M3 nativos de Flutter** (`ThemeData().textTheme`), que
coinciden exactamente con la tabla de `android-guidelines.md` §1. No hace
falta redefinir tamaños. Se propone:

- **Mantener Poppins** (ya confirmado como "razonable" en 03-design-system,
  nunca se contradijo con Figma real — el MCP de Figma nunca estuvo
  disponible, sigue siendo la mejor aproximación disponible).
- **Formalizar el uso por rol** (hoy es implícito/por convención, no
  documentado en ningún lado central):

| Rol de `TextTheme` | Uso | Peso | Color (confirmado, §3.4) |
|---|---|---|---|
| `headlineSmall` | Título de pantalla (`AppHeader.titulo`, título de Login/Registro) | Bold | Azul oscuro (`onPrimaryContainer`) |
| `titleMedium` | Encabezado de sección (Home "Próximos eventos"), título de `EventCard` | Bold/w700 | Azul oscuro |
| `titleSmall` | Nombre en filas de lista (`BalanceRow`, filas de amigos) | Medium/w500 | Azul oscuro por default de tier — **a confirmar por pantalla en Fase 3**: un nombre de fila (ej. "Juan Pérez" en Amigos) es más "dato" que "título"; si se ve sobrecargado de azul en listas largas, se puede bajar puntualmente a `onSurface` sin tocar el token global |
| `bodyMedium` | Texto de cuerpo general | Regular | Gris-casi-negro (`onSurface`), sin cambio |
| `bodySmall` | Subtítulos, fechas, metadata | Regular | Gris secundario (`onSurfaceVariant`), sin cambio |
| `labelSmall` | Badges/pills, captions chicas | w600, letter-spacing 0.4 (ya así en `StatusBadge`) | Color del pill (semántico), no del tema base |

- **Color de texto (confirmado):** los tres tiers de "título" (`display*`,
  `headline*`, `title*`) pasan a `colorScheme.onPrimaryContainer` (azul
  oscuro); los tiers de "cuerpo" (`body*`, `label*`) se quedan en
  `colorScheme.onSurface`/`onSurfaceVariant` (gris-casi-negro, sin cambio).
  Ya no es una ambigüedad abierta — ver §3.4.

---

## 5. Propuesta — espaciado y radios

`AppSpacing` (`4/8/16/24/32`) ya coincide con la guideline. Se propone
completarla y tokenizar los radios que hoy son literales (§2.3):

```dart
abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;  // nuevo — "bloques grandes" de la guideline, sin uso hoy pero documentado

  static const radiusSm = 8.0;    // nuevo — inputs chicos, radio "12" hoy suelto se revisa caso a caso
  static const cardRadius = 16.0; // = radiusMd — cards, botones, inputs (sin cambio de valor)
  static const radiusLg = 20.0;   // nuevo — formaliza el "20" ya usado por EventCard/PillToggle/navbar
  static const radiusXl = 28.0;   // nuevo — formaliza el "28" de la card flotante de Auth
  static const pillRadius = 999.0;
  static const barRadius = 24.0;  // sin cambio (A1, Tanda 7)
}
```

No se propone tocar `barRadius` (24) — ya tiene su propia justificación
documentada (Tanda 7, Item A1: familia visual "pill-bar", distinta de
`pillRadius` a propósito). El logo redondeado (§7) usa `radiusLg` (20) para
leerse como ícono moderno tipo "squircle", consistente con `EventCard`.

---

## 6. Propuesta — componentes reutilizables

### 6.1 Nuevos (no existen hoy)

| Widget | Archivo propuesto | Props principales | Reemplaza |
|---|---|---|---|
| `AppButton` | `core/widgets/app_button.dart` | `label`, `onPressed`, `variant` (`primary`\|`secondary`\|`outlined`\|`text`\|`danger`), `icon`, `loading` (spinner + disabled), `fullWidth` (default `true`) | `ElevatedButton`/`FilledButton`/`OutlinedButton`/`TextButton` sueltos en 12 archivos. La variante `danger` (confirmar/cancelar acciones destructivas — eliminar, abandonar grupo) usa `colorScheme.error` (`#CC5A5A`, §3.5) — **no** el `AppSemanticColors.danger` financiero (§3.6), que es un token distinto para montos "debo" |
| `AppAvatar` | `core/widgets/app_avatar.dart` | `nombre` (para iniciales), `imageUrl`, `radius`, `backgroundColor` | `CircleAvatar` a mano (5 usos) + `_iniciales` duplicado |
| `AppPersonRow` | `core/widgets/app_person_row.dart` | `nombre`, `subtitulo` (email, estado), `avatarUrl`, `trailing` (widget: botón/badge/nada), `onTap` | Filas de `friends_screen.dart`, `friend_picker.dart`, `friend_profile_screen.dart` |
| `AppIconBadge` | `core/widgets/app_icon_badge.dart` | `icon`, `color`, `size` (default 40) | Círculo pastel duplicado en `QuickActionButton`, `ActivityFeedItem`, `_MiniResumen` de Balances |
| `AppCard` | `core/widgets/app_card.dart` | `child`, `padding` (default `md`), `onTap` | Contenedores blancos ad-hoc en `person_detail_sheet.dart`, `profile_screen.dart`, `event_config_screen.dart` |
| `AppSemanticColors` (`ThemeExtension`) | `core/theme/app_semantic_colors.dart` | `success`, `onSuccess`, `warning`, `onWarning` (+ sus containers) — registrada en `ThemeData.extensions` | `AppColors.success`/`AppColors.warning` sueltos (§3.6) — pasan a vivir dentro del tema en vez de como constantes estáticas aparte |

### 6.2 Ya existen — solo se re-tematizan en Fase 2 (no se reconstruyen)

| Widget | Cambio en Fase 2 |
|---|---|
| `AppTextField` | Ninguno funcional — el estilo visual (borde/relleno) sale de `inputDecorationTheme`, que sí cambia con la paleta nueva |
| `AppDialog` | Ninguno — ya cumple "ancho completo −16px" |
| `EventCard` / `BalanceRow` / `ActivityFeedItem` | Colores hardcodeados (`AppColors.xxx`) → roles de `colorScheme`; radio `20` → `AppSpacing.radiusLg`; el ícono-en-círculo interno de `ActivityFeedItem` pasa a usar `AppIconBadge` (nuevo) |
| `StatusBadge` | Colores → roles; se agregan constructores semánticos `EventCardPill.success/.warning/.danger/.info` en `event_card.dart` para eliminar los 8 `Color(0x...)` de `groups_screen.dart` (§2.1) |
| `PillToggle` | Colores → roles |
| `AvatarStack` | Sin cambios de API — internamente puede reusar `AppAvatar` para no duplicar el dibujo de un avatar individual |
| `AuthScaffold` | El logo placeholder (`Icons.autorenew`) se reemplaza por el logo real (§7); colores → roles |
| `UnreadDot`, `CollapsibleSection`, `QuickActionButton` | Colores → roles; `QuickActionButton` reusa `AppIconBadge` internamente |

### 6.3 Catálogo/storybook (Fase 2, punto 4)

**Confirmado con el usuario:** el orden es primero construir la librería de
componentes + el catálogo como archivos propios (Fase 2, completa, sin
tocar ninguna pantalla existente), y **recién en Fase 3** reemplazar lo
viejo pantalla por pantalla — exactamente el orden que ya establecía la
consigna original, ahora re-confirmado explícitamente. El objetivo declarado
es una modernización completa de UX/UI de la app, no solo consistencia de
tokens — eso no cambia el plan técnico de abajo, pero sí el criterio de
"terminado" de Fase 3: además de reemplazar colores/componentes, cada
pantalla debe quedar visualmente pulida con el lenguaje nuevo, no solo
funcionalmente equivalente.

Mecanismo: ruta de debug nueva (no enrutada desde `main.dart` en
producción), montada vía un ítem oculto de acceso (ej. long-press en una
fila de Perfil, visible solo en builds debug vía `kDebugMode`) que renderiza
todos los componentes de §6.1/6.2 juntos, con sus variantes, para revisión
visual de una sola pantalla — sin tener que tocar ni revertir `main.dart`
en cada corrida de desarrollo.

---

## 7. Propuesta — logo

El archivo `mobile/assets/logo.png` (sin declarar en `pubspec.yaml` todavía)
tiene esquinas cuadradas de fábrica. Se propone:

1. **Declarar el asset** en `pubspec.yaml` (`assets: - assets/logo.png`).
2. **Login/Registro:** reemplazar el placeholder vectorial actual
   (`Icons.autorenew` dentro de `_AuthLogo`, `auth_scaffold.dart:100-122`,
   marcado como pendiente desde Tanda 6 Item 6 — "en cuanto esté el archivo
   en `mobile/assets/logo.png`... reemplazar el `Icon` por un
   `Image.asset(...)`") por `Image.asset('assets/logo.png')` recortado con
   `ClipRRect(borderRadius: BorderRadius.circular(AppSpacing.radiusLg))`
   (20dp — §5) dentro del mismo círculo blanco con sombra que ya existe.
3. **Pantalla adicional para reforzar marca — propuesta: Home
   (`AppHeader`).** Justificación: Home es la pantalla a la que se vuelve
   más seguido (es la raíz de la navegación, el tab por default) — reforzar
   marca ahí impacta en cada apertura de la app, no una sola vez como un
   splash. Construir un splash screen nativo es alcance nuevo no pedido en
   ningún lado (hoy `main.dart` va directo a `_RootRouter`, sin pantalla de
   carga con logo) y agrega una pantalla más para mantener sin beneficio
   claro sobre tocar un componente que ya es compartido. Se propone
   `AppHeader` (usado en Home/Groups/Balances/Perfil) con un flag
   `showLogo: bool = false`, activado **solo en Home**, que agrega el logo
   redondeado (24dp) a la izquierda del título — no se agrega a las otras 3
   pantallas para no saturar visualmente headers secundarios.
4. **Radio consistente:** `AppSpacing.radiusLg` (20dp) en ambos usos (Login
   y Home), mismo criterio que `EventCard`/`PillToggle` (§5) — nunca un
   círculo perfecto salvo el círculo blanco contenedor que ya existe en
   Auth (eso se mantiene, es el "marco", no el logo en sí).

---

## 8. Propuesta — ícono de la app

Hoy los 5 `ic_launcher.png` (`mipmap-hdpi`…`mipmap-xxxhdpi`) son el ícono
default de Flutter, y **no existe ningún asset de ícono para iOS**
(consistente con que tampoco existe la carpeta `mobile/ios/`, §1.4). Con el
cambio de alcance a multiplataforma, se confirma generar ícono para
**ambas** plataformas en el mismo paso:

- **Herramienta:** [`flutter_launcher_icons`](https://pub.dev/packages/flutter_launcher_icons)
  (estándar del ecosistema, ya sugerido por el usuario) como `dev_dependency`
  nueva en `pubspec.yaml`. Soporta Android e iOS desde la misma
  configuración.
- **Configuración propuesta** (`flutter_launcher_icons.yaml` o sección en
  `pubspec.yaml`):
  ```yaml
  flutter_launcher_icons:
    android: true
    image_path: "assets/logo.png"
    adaptive_icon_background: "#ECF4FF"   # Azul fondo
    adaptive_icon_foreground: "assets/logo.png"
    min_sdk_android: 21

    ios: true
    image_path_ios: "assets/logo.png"
    remove_alpha_ios: true   # Apple rechaza íconos con canal alfa — se aplana a blanco
  ```
- **Por qué no hace falta pre-redondear el PNG para ninguna de las dos
  plataformas:** a diferencia del uso *dentro* de la app (§7, donde Flutter
  no aplica ninguna máscara y hay que hacer `ClipRRect` a mano), tanto el
  ícono adaptativo de Android (`adaptive_icon_foreground`/`background`, API
  26+) como el ícono de iOS reciben el redondeado del propio sistema
  operativo en tiempo de instalación/renderizado (Android aplica la máscara
  del launcher — círculo, squircle, etc. según OEM —, iOS aplica su squircle
  estándar sobre cualquier ícono cuadrado del `AppIcon.appiconset`).
  `flutter_launcher_icons` genera además el ícono Android "legacy"
  redondeado para API <26 automáticamente. Se reemplazan los 5
  `ic_launcher.png` existentes (todas las densidades) y se crea el set de
  iOS (`Assets.xcassets/AppIcon.appiconset`, todas las resoluciones) en el
  mismo paso.
- **Precondición (§1.4):** el target de iOS solo se puede generar una vez
  que exista `mobile/ios/` — si para cuando se ejecute esto esa carpeta
  todavía no se generó, el primer paso de Fase 2 es
  `flutter create --platforms=ios .`, confirmado en §9.

---

## 9. Decisiones confirmadas y puntos nuevos a confirmar

### 9.1 Ya resueltas (respuesta del usuario, 2026-08-05)

1. **`error`** — rojo propio, no tan brillante, distinto del acento
   (`tertiary`). Propuesto `#CC5A5A` (§3.5) — **valor concreto todavía
   ajustable**, es el único hex de toda la propuesta que no viene
   directo de los 6 colores de marca ni de un derivado tonal mecánico.
2. **Texto de cuerpo vs. títulos** — el cuerpo se queda gris-casi-negro
   (sin cambios); los títulos de sección/card/página pasan a azul oscuro
   (`#3E579C`). Resuelto vía `TextTheme` (§3.4), no vía `ColorScheme.onSurface`
   como se planteaba en la v1.
3. **`success`/`warning`** — se mantienen conceptualmente, armonizados
   (menos brillantes) contra la paleta nueva. Propuesto `#3FA873`/`#E3A94A`
   (§3.6) — **valores concretos todavía ajustables**, mismo criterio que
   el punto 1.
4. **Catálogo (Fase 2) antes que aplicación a pantallas (Fase 3)** —
   confirmado, es el orden que ya establecía la consigna original (§6.3).
   Objetivo explícito: modernizar la app completa en UX/UI, no solo
   consistencia de tokens.

### 9.2 Introducidas por el cambio de alcance a multiplataforma — resueltas (2026-08-05, ronda 2)

5. **Generar `mobile/ios/`** (§1.4) — **resuelto: bundle id placeholder por
   ahora**, ajustable cuando llegue el momento de firmar/publicar en App
   Store (fuera de alcance actual — el charter sigue apuntando a Play
   Store como publicación real, §00-entendimiento.md). Se corre
   `flutter create --platforms=ios .` como primer paso técnico de Fase 2,
   con el bundle identifier default que genera Flutter
   (`com.example.planify`) sin tocarlo más.
6. **`secondary` (`#92C2FC`) — uso confirmado.** No es que `onSecondary`
   deba ser un azul claro (relectura de tu comentario, aclarada en §3.4b):
   el punto es que `secondary` en sí mismo es un celeste muy claro, así que
   (a) nunca se le pone texto/ícono blanco encima si se usa como fondo
   relleno — por eso `onSecondary` sigue siendo azul oscuro, sin cambios
   respecto de la v2 anterior — y (b) su uso *ideal* no es como fondo
   relleno sino directamente como color de contenido sobre blanco, el caso
   concreto que diste: los ítems no seleccionados de la bottom nav. Ya
   aplicado en §3.4b, reemplaza a `AppColors.inactiveBlue`.
7. **`danger` (Balances, "debo"/"pagar") — resuelto: NO se unifica con
   `error`.** Quedan tres rojos distintos (`tertiary`/acento, `error`/
   formularios, `danger`/financiero) — corregido en §3.6, revertí la
   unificación que había propuesto en la ronda anterior.

---

**Esperando tu aprobación ("APROBADO, avanzá a fase 2") o ajustes sobre
cualquiera de los puntos de §3–§9 antes de tocar código.**
