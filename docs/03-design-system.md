# Planify — Mini Design System

> Extraído por lectura visual de las capturas de Figma compartidas (ver [00-ui-entendimiento.md](00-ui-entendimiento.md)). El MCP de Figma no estuvo disponible en esta sesión, así que los valores exactos (hex, spacing en px, familia tipográfica exacta) son **aproximaciones razonables, no tokens reales**. Antes de que el equipo empiece a maquetar en Flutter, alguien debería re-pasar esto por Figma (autorizando el conector) y ajustar los valores — la estructura/nomenclatura de abajo no debería cambiar, los valores puntuales sí podrían.

## 1. Color

```
Primary / Brand      #2A3EFF  (azul fuerte — logo, headers, botón primario, tab activo)
Primary Dark         #1A2BD1  (estados pressed/hover del primario)
Accent / FAB         #FF6B5B  (coral — FAB, badge "NUEVO")
Success / Positivo   #2ECC71  (montos "me deben", badge "SALDADO")
Danger / Negativo    #E74C3C  (montos "debo", badge "PAGAR")
Warning / Pendiente  #F5A623  (badge "PENDIENTE")
Background           #F5F7FF  (fondo general, tinte azulado muy claro)
Surface              #FFFFFF  (cards)
Text Primary         #14162B  (títulos)
Text Secondary       #6B7280  (subtítulos, fechas, texto auxiliar)
Border/Divider       #E5E7F0
```

Uso semántico (no literal): cualquier monto/estado "a favor" del usuario = Success; "en contra" = Danger; "requiere acción, no urgente" = Warning; "novedad" = Accent.

## 2. Tipografía

- Familia: geométrica redondeada (tipo Poppins/Nunito — a confirmar con Figma). En Flutter, usar `google_fonts` con Poppins como default razonable hasta confirmar.
- Escala sugerida (Material 3 roles):

| Rol | Tamaño | Peso |
|---|---|---|
| Display / título de pantalla | 24-28sp | Bold |
| Headline / título de card | 18-20sp | SemiBold |
| Title / nombre en listas | 16sp | Medium |
| Body | 14sp | Regular |
| Caption / metadata (fechas, subtítulos) | 12sp | Regular, color Text Secondary |
| Monto destacado | 22-26sp | Bold, color semántico |

## 3. Espaciado (grid de 4pt)

```
xs = 4dp   sm = 8dp   md = 16dp   lg = 24dp   xl = 32dp
```
- Padding interno de cards: `md` (16dp)
- Separación entre cards en una lista: `sm` (8dp)
- Márgenes de pantalla: `md` (16dp)
- Radio de esquina de cards/botones: 16dp (bastante redondeado, consistente con la estética general)
- Radio de esquina de badges/pills: full (999dp, forma de píldora)

## 4. Componentes base (mapeados a lo detectado en [00-ui-entendimiento.md](00-ui-entendimiento.md) sección 5)

| Componente | Dónde se usa | Notas |
|---|---|---|
| `AppHeader` | Home, Profile, Balances, Groups | Título + ícono de campana (badge de notificación si hay novedades) |
| `BottomNavBar` | Home, Profile, Balances, Groups | 4 ítems: Inicio, Grupos, Balances, Perfil. Ítem activo en Primary. |
| `PrimaryButton` | Ingresar, Agregar Actividad | Full width, fondo Primary, texto blanco, radio 16dp |
| `SecondaryButton` | Continuar como Anónimo | Outline o fondo Surface con borde |
| `FAB` | Home, Balances, Groups | Fondo Accent, ícono blanco, esquina inferior derecha |
| `EventCard` | Home ("próximos eventos"), Groups (evento del grupo), Historial | Variantes: con `StatusBadge`, con contadores (gastos/confirmados/tareas) |
| `AvatarStack` | Home, Groups, Historial | Avatares circulares superpuestos + "+N" si hay más de 3-4 |
| `StatusBadge` | Groups ("NUEVO"), Historial/Balances ("Pagar"/"Pendiente"/"Saldado") | Pill de color semántico, texto corto en mayúsculas |
| `ActivityFeedItem` | Home ("Actividad reciente"), Log de Actividad del evento | Ícono circular + texto + monto/tiempo relativo |
| `BalanceRow` | Balances ("saldos por amigo") | Avatar + nombre + monto + `StatusBadge` |
| `UnreadDot` | Groups (avatar de grupo) | Punto rojo pequeño, indica actividad no leída agregada del grupo |
| `WeeklyAvailabilityGrid` | Profile, y su variante "heatmap" en creación/confirmación de evento | Grilla L-D x bloques horarios, tocable en Profile, solo-lectura + intensidad de color en el heatmap del evento |
| `QuickActionButton` | Vista de evento ("Acciones rápidas") | Ícono + label corto (Gasto, Tarea, Saldar) |

## 5. Íconografía

- Estilo outline, trazo simple, dentro de un círculo de fondo pastel (tono suave del color semántico de la acción).
- Tamaño estándar: 24dp (dentro de círculo de 40dp).

## 6. Accesibilidad (a respetar en la implementación, no visto explícitamente en las capturas)

- Contraste mínimo AA para texto sobre Background/Surface.
- Touch targets mínimos de 48x48dp (botones, ítems de bottom nav, FAB).
- Los `StatusBadge` no deben depender solo del color — acompañar siempre con texto (ya es el patrón visto: "PENDIENTE", "SALDADO", no solo un punto de color).
