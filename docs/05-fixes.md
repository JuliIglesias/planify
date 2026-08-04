# Tanda 5 - Mejoras de navegación, componentes reutilizables y UI Mobile

## Item 3: Componente EventCard Unificado
- Se rediseñó el componente `EventCard` en `mobile/lib/core/widgets/event_card.dart` para utilizar `Container` con bordes redondeados, sombras suaves y elevación cero (`elevation: 0`).
- Se añadieron nuevas propiedades como `width`, `topBadge` y `trailing` para aumentar su flexibilidad y permitir su reutilización.
- Se refactorizó `EventoResumenCard` para aprovechar estas nuevas propiedades (`topBadge` para la fecha y el ícono en `trailing`), alineándolo al diseño del carrusel y unificando su estructura sin duplicar componentes.

## Item 1: Home Carrusel y Backend Historial
- **Backend:** Se modificó la consulta en `backend/src/infrastructure/prisma/evento.prisma.repository.ts` (renombrando el método a `listHistoryForUsuario`) para incluir eventos confirmados y pendientes cuya fecha sea menor o igual al final del mes en curso, cumpliendo con la regla de negocio. Se actualizó el repositorio e interfaces para enviar el límite temporal del mes actual.
- **Frontend (Home):** Se actualizó el layout de los "Próximos eventos" en `HomeScreen`. Se pasó de una lista vertical (`Column`) a un carrusel horizontal estático de altura fija usando `ListView.separated`.
- Se añadió un `TextButton` alineado a la derecha que dice "Ver todos" y que navega hacia el `HistoryScreen`.

## Item 2: Navbar Flotante con efecto Glassmorphism
- **AppBottomNav:** Se reemplazó el `NavigationBar` de Material3 por un diseño a medida en `mobile/lib/core/widgets/app_scaffold.dart`.
- El nuevo widget utiliza `ClipRRect` con un `BackdropFilter` de tipo blur y bordes redondeados, además de un sutil borde blanco semitransparente.
- **Estados:** Se creó `_NavItem` para gestionar los íconos inactivos (outline, sin fondo) y activos (filled, con fondo `primary.withOpacity(0.15)`).
- **Integración Scaffold:** Se actualizó `AppShell` activando la propiedad `extendBody: true` del `Scaffold` y desactivando el `SafeArea` inferior para que el fondo del listado fluya orgánicamente por debajo de la Navbar, mejorando notablemente el efecto *glassmorphism*.

## Item 1 (Nuevo): Grupos: Imágenes de perfil en lugar de iniciales
- **Backend:** 
  - Se modificó la interfaz `GrupoRepository` y su implementación en Prisma y fakes reemplazando `rename` por `actualizar` que ahora acepta tanto el nombre como el `avatarUrl`.
  - Se modificó `GroupsService` para que el endpoint de actualización maneje también el `avatarUrl`.
- **Frontend:**
  - Se actualizó el modelo `GrupoResumen` para parsear y almacenar el campo `avatarUrl`.
  - En `mobile/lib/features/groups/groups_screen.dart`, el widget `_CarruselDeGrupos` ahora renderiza un `NetworkImage` en el `CircleAvatar` si existe el `avatarUrl`, dejando las iniciales como fallback.
  - En `group_manage_sheet.dart`, se añadió una opción "Cambiar imagen" en el menú contextual que permite ingresar la URL de la imagen. Se agregó el texto traducido en `app_es.arb`.

## Item 2: Grupos: Badge de notificaciones
- **Frontend:**
  - En `mobile/lib/features/groups/groups_screen.dart`, se actualizó el widget `UnreadDot` en `_CarruselDeGrupos` pasando la propiedad `mostrarNumero: true`.
  - Esto habilita el comportamiento estilo WhatsApp que muestra el contador de eventos nuevos no leídos dentro del globo verde (o rojo dependiendo del tema) de notificaciones del grupo.

## Item 3: Eventos: Pills con resumen de incidentes (Actualización de Cards)
- **Backend:**
  - Se actualizó el mapper de `eventos` de `GroupsService.resumenPara` para incluir la propiedad `necesitaDecisionRango: boolean` que determina si un evento está pendiente de confirmación de fecha habiendo agotado sus prórrogas.
- **Frontend:**
  - Se actualizó la clase `EventoDeGrupo` en `models.dart` para incluir y parsear `necesitaDecisionRango`.
  - Se extendió el widget `EventCard` para aceptar una lista opcional de `EventCardPill` (que contiene etiqueta, ícono, color de fondo y color de texto).
  - En `groups_screen.dart`, el widget `_EventoDeGrupoCard` ahora construye pills de colores pastel e íconos descriptivos para confirmaciones, tareas, gastos e incidentes urgentes, logrando el diseño esperado.

## Item 4: Eventos: Badges de actividad dentro de la Card
- **Backend:**
  - Se modificó la interfaz `EventoDeGrupo` para exponer el contador de `noLeidos` para cada evento individual dentro de la lista de eventos activos.
- **Frontend:**
  - Se actualizó `EventoDeGrupo` en `models.dart` para incluir y parsear `noLeidos`.
  - En `groups_screen.dart`, el widget `_EventoDeGrupoCard` agrega dinámicamente un pill celeste/azul con ícono `Icons.chat_bubble_outline` indicando "N mensajes nuevos" si `noLeidos > 0`.

---

# Fase 5 — 5 mejoras de producto (rango de fechas, rango horario, visual, amigos)

> Cada item con su propia branch/PR y su test, pedidos por el usuario en un
> mismo lote de 5. Orden de implementación (por dependencias, confirmado
> con el usuario): 1 (rango de fechas) → 5 (rango horario, depende del 1)
> → 2 (visual, independiente) → 3 (visual, independiente) → 4 (perfil de
> amigo, depende de que 1 y 5 ya existan). Items 1, 2 y 5 ya se habían
> mergeado (PRs #16/#17/#18) antes de que este archivo perdiera su
> historial en el merge de "Tanda 5" (PR #20, no relacionado) — sus
> entradas se reconstruyen más abajo a partir del registro original.

## Item 3 — Fila de amigos clickeable + email visible junto al username

**Causa raíz:** en la lista de amigos ya agregados (`/friends`) y en las
solicitudes pendientes (`/friends/requests`), el backend nunca mandaba el
email — solo viajaba en los resultados de búsqueda. Sin el dato, esas dos
listas no podían mostrarlo aunque la UI quisiera. En las filas con un botón
de acción (enviar solicitud, aceptar), el `ListTile` no tenía `onTap`
propio: solo el botón (`TextButton`/`FilledButton`) respondía al toque.

**Fix (backend):**
- `AmistadRepository.listAmigos` y `SolicitudAmistad.de` pasan de
  `PersonaRef` a `PersonaBusqueda` (el mismo tipo que ya usaba `buscar()`,
  con `email`) — cambio acotado a estos dos puntos, sin tocar el
  `PersonaRef` genérico que siguen usando actor de actividad, asignado de
  tarea, deudor/acreedor, etc.
- `PrismaAmistadRepository.listAmigos`/`listSolicitudesRecibidas` agregan
  `email: true` al `select` de Prisma.

**Fix (mobile):**
- `friends_screen.dart`: el `ListTile` de cada resultado de búsqueda y de
  cada solicitud pendiente gana `onTap` (misma acción que ya disparaba el
  botón) — toda la fila responde, el botón se queda como indicador visual.
  La lista de "mis amigos" (sin botón ni acción) ahora también muestra el
  email en gris debajo del username.
- `friend_picker.dart`: se agrega el email como `subtitle` en las dos
  variantes (selección única y múltiple). La variante múltiple usa
  `CheckboxListTile`, que en Flutter **ya** hace clickeable toda la fila
  por defecto (no solo el checkbox) — no hubo que cambiar su lógica de
  tap, solo sumarle el email.

**Validación:**
- Backend: `scrum14.test.ts` — el test de flujo completo de amigos ahora
  también verifica que el email viaje en `solicitudesPendientes()` y en
  `listar()` (antes)/(después) de aceptar.
- Mobile: `friends_screen_test.dart` — 3 tests nuevos: tocar el nombre (no
  el botón) de un resultado envía la solicitud; tocar el nombre de una
  solicitud la acepta y se ve el email de quien la mandó; la lista de
  amigos ya agregados muestra el email. `screens_test.dart` — el test
  existente de "agregar amigo guardado al evento" se amplía para verificar
  que el selector (`CheckboxListTile`) también muestra el email.
  `flutter analyze` limpio, suite completa en verde.

## Item 1 (reconstruido) — Rango de fechas calendario del evento

El organizador elige un rango de fechas calendario (`rangoInicio`/
`rangoFin`) al crear el evento, junto a nombre y lugar (2 pasos, NFR#3). Si
el rango vence sin confirmar un horario, se extiende 2 semanas
automáticamente **una única vez** (tope confirmado con el usuario) y se
notifica a los participantes vía el sistema de actividad/push existente.
Agotada la extensión, el detalle del evento expone `necesitaDecisionRango`
para avisar que el organizador tiene que decidir a mano (confirmar horario
o cancelar — controles ya existentes, sin flujo nuevo).

- **Backend:** `Evento` gana `rangoInicio`/`rangoFin`/`extensionesRango`.
  `EventsService.chequearExtensionRango` corre lazy desde `GET
  /events/:id` (mismo patrón que `listUpcoming/listPast` con `ahora: Date`,
  H-09) — sin cron. `EventsQueryService.detalle` deriva
  `necesitaDecisionRango` en cada lectura.
- **Mobile:** `CreateEventScreen` suma un selector de rango de fechas
  (`showDateRangePicker`) al paso 1 existente, default hoy→hoy+14 días.
  `EventConfigScreen` muestra el rango vigente y el banner de aviso.
- **Decisiones confirmadas con el usuario:** sí notificar al extender; tope
  de 1 extensión automática (no 3, no ilimitado); la disponibilidad
  semanal del perfil se proyecta sobre cada fecha calendario dentro del
  rango, sin cambiar el modelo de `DisponibilidadSlot` (día-de-semana +
  hora, no fecha exacta).

## Item 5 (reconstruido) — Horario del evento como rango, no como slot único

El organizador elige hora de inicio y hora de fin (no un instante). Todos
los slots del rango se pintan como "horario fijado" en el heatmap, y ve en
vivo cuánta gente está libre para **todo** el rango propuesto (no un
bloque suelto) mientras elige la hora de fin.

- **Backend:** `Evento.fechaHoraFin` (nuevo, nullable — eventos previos se
  leen como rango de una hora, sin backfill). `AvailabilityService.
  confirmarHorario` valida `fechaHoraFin > fechaHoraInicio`.
  `DisponibilidadRepository.disponiblesEnRango(eventoId, diaSemana,
  bloqueHoraInicio, bloqueHoraFin)` (nuevo) cuenta participantes libres en
  **todos** los bloques del rango (intersección, no unión), mismo criterio
  de exclusión que el heatmap normal ("No voy" no cuenta). Expuesto en
  `GET /events/:id/availability/range`.
- **Mobile:** `WeeklyAvailabilityGrid.slotFijado` (un slot) →
  `slotsFijados` (`Set<AvailabilitySlot>`). `EventConfigScreen`: tocar un
  bloque del heatmap abre un selector de hora de fin con la disponibilidad
  en vivo (`FutureBuilder`) antes de confirmar.
- **Decisión confirmada:** no se validó el horario confirmado contra el
  rango de fechas del Item 1 (evita acoplar dos features independientes;
  el "próximo día de semana" calculado ya cae casi siempre dentro del
  rango típico).

## Item 2 (reconstruido) — Header del evento: nombre completo + lugar/fecha prominentes

**Mockup confirmado con el usuario antes de implementar** (implica
reordenar el header): el nombre sale del `AppBar` (que lo truncaba a una
sola línea con "...") y pasa a ser el primer bloque del body, con
`headlineSmall` (la misma escala que ya usa "Nuevo evento") y wrap a 2
líneas. Lugar y fecha se separan en líneas propias con ícono
(`Icons.place_outlined`, `Icons.calendar_today_outlined`) y tipografía
`bodyLarge` en color primario, en vez de ir concatenados en una sola
oración chica y gris.
