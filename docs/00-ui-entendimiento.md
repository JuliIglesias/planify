# Planify — Entendimiento de la Referencia de UI

> Fuente: capturas de Figma compartidas en el chat (Login, Home, Profile, Balances, Groups, Log de Actividad del Evento, Historial). El MCP de Figma (`127.0.0.1:3845`) no estaba autorizado en esta sesión, así que este análisis es visual sobre las capturas, no una inspección de tokens/auto-layout reales. Recomiendo re-pasar esto por Figma MCP antes de fijar el design system definitivo (Fase 2).

## 1. Sistema de navegación

- **Bottom nav de 4 tabs** (Inicio, Grupos, Balances, Perfil) presente en: Home, Profile, Balances, Groups. Es la navegación de nivel raíz.
- **Historial** y **Log de Actividad del Evento** se ven como pantallas "push" (header con flecha "←" de volver, sin bottom nav visible) → son pantallas de detalle/hijas, no tabs raíz.
  - SUPUESTO: Historial se accede desde Perfil o desde Balances (no queda claro cuál — ver dudas).
  - SUPUESTO: Log de Actividad se accede desde el detalle de un evento dentro de un grupo (el subtítulo "LOS FIBES · ASADO" sugiere breadcrumb Grupo → Evento).
- **FAB (botón flotante)** color coral/rojo presente en Home, Balances y Groups, en la esquina inferior derecha — probablemente una acción de creación contextual (evento / gasto) cuyo comportamiento exacto no es obvio si es el mismo botón o cambia según pantalla.

## 2. Paleta de colores (lectura visual, a confirmar con tokens de Figma)

| Uso | Color aproximado |
|---|---|
| Marca / texto de header / logo | Azul fuerte (indigo/azul puro) |
| Fondo general | Blanco / gris muy claro con tinte azulado |
| Botón primario (Ingresar) | Azul sólido, full width, esquinas redondeadas |
| FAB | Coral / rojo-naranja |
| Montos positivos ("me deben") | Verde |
| Montos negativos ("debo") | Rojo / rosa |
| Badge "NUEVO" | Rojo |
| Badge "PENDIENTE" | Amarillo/ámbar |
| Badge "SALDADO" | Verde |

## 3. Tipografía y estilo de componentes

- Tipografía redondeada tipo geométrica (similar a Poppins/Nunito), consistente con el logotipo "Planify".
- Jerarquía: títulos de pantalla en bold grande, subtítulos en gris medio, montos destacados en bold y color semántico (verde/rojo).
- **Cards** con esquinas muy redondeadas, sombra suave, usadas para: eventos próximos, grupos, saldos por amigo, historial de eventos.
- **Avatares circulares**, frecuentemente apilados/superpuestos en grupos de 3-4 con un "+N" para indicar más miembros (visto en Home "próximos eventos" y en cards de Historial).
- **Badges de estado** (pill shape, color semántico) superpuestos en la esquina de cards o al lado de nombres.
- **Iconografía** simple, outline, en círculos de color pastel de fondo (ver "Actividad reciente" en Home y "Acciones rápidas" en Log de Actividad).
- **Bottom nav**: 4 íconos + label, ítem activo resaltado en azul.

## 4. Pantalla por pantalla

### Login
- Logo Planify + tagline "Juntadas sin estrés"
- Campos: Usuario o Email, Contraseña (con ícono)
- Link "¿Olvidaste tu contraseña?"
- Botón primario "Ingresar"
- Separador "o"
- Botón secundario "Continuar como Anónimo"
- Link "¿No tienes una cuenta? Crear cuenta"
- **Acciones:** login con credenciales, recuperar contraseña, entrar anónimo, ir a registro.

### Home
- Header "Hola, {nombre}!" + campana de notificaciones
- Resumen rápido: "Me deben $X" / "Debo $Y" (2 columnas)
- "Próximos eventos" (horizontal, con "Ver todos") — cards con fecha, nombre de evento, avatares apilados de asistentes
- "Actividad reciente" — feed con ícono + descripción + monto (ej: "Mati saldó su deuda +$450", "Agregaste un gasto -$120", "Nuevo evento creado")
- Bottom nav + FAB "+"
- **Reutiliza:** cards de evento (mismo patrón que Groups), avatares apilados (mismo patrón que Historial), bottom nav.

### Profile
- Header "Perfil" + campana
- Avatar grande editable + nombre
- **"Disponibilidad Semanal"**: grilla L-D x franjas horarias, tocable para marcar bloques libres — corresponde a FR#3 del charter
- "Mis amigos" con contador total (67) — corresponde a FR#13
- Bottom nav
- **Reutiliza:** bottom nav, header con campana.

### Balances
- Header (título parcialmente ilegible en la captura, algo como "balances") + campana
- "BALANCE NETO +$36258.58" grande y centrado — agregación de TODOS los saldos del usuario
- Dos cards resumen: "Me deben $X" (verde) / "Debo $Y" (rojo)
- Tabs de filtro: "Todo" / "Me deben" / "Debo"
- "Saldos por amigo": lista con avatar, nombre, monto, y badge de acción/estado (ej. "SALDAR", "PAGAR" — colores rojo/verde, no 100% legible en la captura)
- FAB (ícono de factura/recibo) — probablemente "agregar gasto" o "saldar deuda"
- Bottom nav
- **Reutiliza:** avatares, badges de estado, bottom nav, patrón de card de Home.

### Groups
- Header "Groups" + campana
- Fila de avatares circulares de grupos (carrusel), uno con badge de notificación (punto rojo)
- Cards de grupo, cada una con: nombre, badge opcional ("NUEVO"), fecha/hora/lugar del próximo evento, contador de gastos nuevos, contador de confirmados/pendientes
  - "Asado de los Viernes" — NUEVO, 4 gastos nuevos, 10 confirmadas
  - "Fútbol 5" — 2 tareas pendientes, 8 confirmados
  - "Salida al Cine" — 3 confirmados, sin gastos pendientes
- FAB + bottom nav
- **Reutiliza:** avatares, badges, cards, bottom nav.
- **Nota de modelo de datos:** cada card de grupo muestra info de UN evento próximo asociado — sugiere que un Grupo "contiene" eventos, y la card en esta pantalla es un resumen del evento activo/próximo del grupo, no del grupo en sí.

### Log de Actividad del Evento
- Header con back arrow, título "Log de Actividad", subtítulo "LOS FIBES · ASADO" (Grupo · Evento)
- Feed cronológico: avatar + descripción + tiempo relativo
  - "Marcos Silva agregó un gasto: $4.500 (Carne)"
  - "Sofía Martínez se asignó la tarea: Comprar hielo"
  - "Juan Pérez saldó su deuda con Marcos"
  - "Lucas creó la tarea: Pedir las pizzas"
- Sección "Acciones rápidas": 3 botones (Gasto, Tarea, **Sondeo**)
- Botón "+ Agregar Actividad" (azul, full width)
- **Reutiliza:** avatares, patrón de feed similar a "Actividad reciente" de Home.
- **Duda de producto:** "Sondeo" no aparece en ningún FR del charter — ver lista de dudas.

### Historial
- Header con back arrow, título "Historial de eventos"
- Agrupado por mes ("ESTE MES", "ABRIL", ...)
- Cards de evento pasado: nombre, badge de estado ("PENDIENTE" ámbar / "SALDADO" verde), fecha completa, avatares, monto ("Por pagar $X" / "Tu aporte $X")
- **Reutiliza:** cards, avatares, badges — mismo lenguaje visual que Balances y Groups.

## 5. Patrones repetidos → candidatos a componentes compartidos

1. **EventCard** — usada en Home ("próximos eventos"), Groups (evento asociado al grupo) e Historial (evento pasado), con variantes de badge/estado.
2. **AvatarStack** — grupo de avatares superpuestos + contador "+N", usado en Home, Groups, Historial.
3. **StatusBadge** — pill de color semántico con texto corto ("NUEVO", "PENDIENTE", "SALDADO", y los de Balances). Necesita un enum único de estados (ver sección 6).
4. **ActivityFeedItem** — ícono + texto + monto/tiempo, usado en "Actividad reciente" (Home) y "Log de Actividad" (evento).
5. **BalanceRow** — avatar + nombre + monto + badge, usado en Balances ("saldos por amigo").
6. **AppHeader** — título + campana de notificaciones, consistente en las 4 pantallas raíz.
7. **BottomNav** — 4 ítems, consistente en las 4 pantallas raíz.
8. **PrimaryButton / SecondaryButton** — botón azul full-width (Ingresar, Agregar Actividad) vs. botón outline/secundario (Continuar como Anónimo).
9. **FAB** — mismo estilo visual en Home, Balances, Groups; posible diferencia de ícono/acción según contexto.

## 6. Estados visibles en la UI (reglas de negocio implícitas, no explícitas en el charter)

| Estado visto | Dónde | Significado inferido | Transición inferida |
|---|---|---|---|
| **NUEVO** | Badge en card de Grupo (Groups) | ¿Grupo recién creado? ¿Evento recién creado dentro del grupo? ¿Actividad no vista? | Desconocida — no se ve qué lo dispara ni cuándo desaparece |
| **PENDIENTE** | Badge en card de evento (Historial) | Evento pasado con saldos sin cerrar | ¿Pasa a SALDADO cuando todos los deudores pagan? |
| **SALDADO** | Badge en card de evento (Historial) | Evento pasado con todas las deudas resueltas | Estado terminal presumible |
| Badges en "Saldos por amigo" (Balances) | Balances | Posibles acciones/estado por deuda individual (ej. "SALDAR" / "PAGAR") — texto no 100% legible en la captura | Requiere confirmación visual con Figma o el usuario |
| Punto de notificación en avatar de grupo | Groups | Actividad no leída en ese grupo | Desaparece al abrir el grupo (supuesto) |

**Conclusión:** el charter no define una máquina de estados para "evento" (¿Planificado → Confirmado → Pasado/Pendiente → Saldado → Archivado?) ni para "gasto/deuda" individual. La UI sugiere al menos 2-3 estados de evento y un estado de deuda persona-a-persona, pero las transiciones exactas no están definidas en ningún documento — es una de las dudas de mayor impacto (ver lista de preguntas).
