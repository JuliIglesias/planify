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

---

# Fase 5 — 5 mejoras de producto (rango de fechas, rango horario, visual, amigos)

> Cada item con su propia branch/PR y su test, pedidos por el usuario en un
> mismo lote de 5 (Items 1, 5, 2, 3 y 4 — ver también la branch de Item 3
> para la reconstrucción completa de las entradas 1/2/5, perdidas cuando
> este archivo se reemplazó en un merge no relacionado).

## Item 4 — Perfil de amigo: disponibilidad comparada + eventos/grupos en común

Tocar un amigo desde "Mis amigos" abre su perfil de solo lectura: foto,
username, email, un heatmap de disponibilidad semanal comparado **solo
entre esa dupla** (a diferencia de "Coincidencias con amigos", HU-B4, que
agrega a todos los amigos), y las listas de eventos y grupos que se
comparten con esa persona.

**Confirmado con el usuario antes de implementar:** el heatmap distingue 4
estados con color propio — coincidimos, solo yo libre, solo el amigo
libre, ninguno libre — sin reusar `AppColors.warning` (reservado para "el
horario fijado por el organizador" de un evento, Item 5 de la fase
anterior).

**Fix (backend):**
- `FriendProfileService` (nuevo, `modules/friends/friend-profile.service.ts`):
  autoriza con `AmistadRepository.findEntre` (solo entre amigos con
  amistad `aceptada`, en cualquier sentido); arma el heatmap comparado
  reutilizando `ProfileAvailabilityRepository.slotsDeUsuarios([yo, amigo])`
  y clasificando cada bloque en `ambos`/`soloYo`/`soloAmigo` (los bloques
  sin nadie libre directamente no se incluyen, mismo criterio que el
  heatmap normal); intersecta grupos vía `GrupoRepository.listByUsuario`
  de ambos, y eventos vía `ParticipanteRepository.listByUsuario` de ambos
  (por `eventoId`, sin depender de rangos de fecha).
- Nuevo endpoint `GET /friends/:id/profile`.

**Fix (mobile):**
- `WeeklyAvailabilityGrid` gana `colorResolver`/`semanticsLabelResolver`
  opcionales (con prioridad sobre el heatmap/slot-fijado normal) en vez de
  duplicar todo el widget para el modo de 4 colores — la grilla base
  (headers, filas, accesibilidad) se reutiliza tal cual.
- `FriendProfileScreen` (nueva): encabezado con avatar (foto o iniciales),
  username, email; heatmap comparado con una leyenda de texto debajo (el
  color nunca va solo, design system §6); listas de eventos y grupos en
  común con sus estados vacíos.
- `FriendsScreen`: la fila de "Mis amigos" gana `onTap` → navega al perfil.
- `Persona` gana `avatarUrl` (nullable, solo viaja en el perfil de amigo).

**Validación:**
- Backend: `friend-profile.service.test.ts` (nuevo) — rechaza ver el
  perfil de alguien que no es amigo (incluida una solicitud todavía
  pendiente); funciona sin importar quién inició la amistad; devuelve
  username/email/avatarUrl; el heatmap distingue los 3 estados con datos
  (y excluye disponibilidad de un tercero, regresión); eventos y grupos
  en común filtran correctamente (excluyen los que son solo de uno).
  Backend 122→129, `tsc --noEmit` y `eslint .` limpios.
- Mobile: `friend_profile_screen_test.dart` (nuevo) — encabezado con
  username/email; leyenda con los 4 estados (incluido el username del
  amigo interpolado); eventos/grupos en común y sus estados vacíos.
  `friends_screen_test.dart` — tocar un amigo abre su perfil. Mobile
  77→82, `flutter analyze` limpio.
