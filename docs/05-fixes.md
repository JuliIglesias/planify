# Tanda 7 - 12 bugs/UX + reglas de negocio de usernames anónimos

> Orden de implementación acordado con el usuario: B1, B2 (bugs de Flutter,
> reproducidos antes de tocar código) → C1 (regla de negocio en tareas) →
> A1, A2 (layout) → C2, D1, E1 (visuales/menores) → F1, F2 (Amigos) → G1
> (identidad anónima por evento — el más grande, se hizo al final).

## Item G1: Identidad anónima única por evento (username + PIN)

**Diseño completo en `docs/adrs/0003-identidad-anonima-por-evento.md`** —
tercera vuelta sobre el mismo tema (Tanda 1 item 5, Tanda 2 item 1), así
que se documentó como ADR para no reabrir la discusión sin contexto, tal
como pidió el usuario. Reemplaza el mecanismo viejo (auto-sufijo silencioso
en cualquier colisión, contra cualquier evento, para siempre) por tres
reglas confirmadas con el usuario:

1. Solo se entra por link de invitación a un evento puntual + username (sin
   cambios — ya era así, confirmado antes de tocar código).
2. Username + **PIN** (nuevo, mínimo 4 caracteres) son las credenciales:
   reingresar al MISMO evento con las MISMAS credenciales recupera la
   MISMA fila de `Participante` (mismo historial), no crea una nueva.
3. El mismo username **no** sirve para OTRO evento mientras el primero
   sigue activo — se libera cuando ese evento termina (`finalizado` o
   `cancelado`) Y no quedan deudas pendientes de ese evento. Una colisión
   ahora se **rechaza** (con una sugerencia de alternativa), nunca se
   auto-sufija en silencio.

- **Backend:**
  - **Schema:** `Participante.pinHash` (nullable, migración
    `20260805100000_participante_pin_anonimo`).
  - **`ParticipantsService.unirseComoAnonimo`** reescrito de punta a punta:
    gana dos dependencias (`PasswordHasher`, reusa el mismo puerto que las
    contraseñas de cuentas registradas; `DeudaRepository`, para el chequeo
    de deudas pendientes de la regla 3). Reingreso vs. alta nueva se
    distingue buscando primero si YA existe una fila anónima con ese
    username en ESE evento (`findAnonimoPorEventoYUsername`, nuevo); el
    token de sesión se regenera en cada reingreso exitoso (mismo criterio
    que un login, para que un token filtrado no sirva para siempre).
  - **`ParticipanteRepository`** gana `findAnonimoPorEventoYUsername`,
    `listAnonimosPorUsername` y `regenerarTokenSesion`. `resolverUsernameUnico`
    / auto-sufijo se eliminaron del todo.
  - **`POST /participants/anonymous`** ahora exige `pin` en el body.
- **Mobile:** el diálogo de "Continuar como Anónimo" (`login_screen.dart`)
  suma un campo de PIN obligatorio (mínimo 4 caracteres, con
  `AppTextFieldVariant.password` para que no quede a la vista). A
  diferencia de antes (el pedido nunca fallaba), ahora puede rechazarse —
  el mensaje específico del backend (con la sugerencia de username) se
  muestra tal cual llega, no un mensaje genérico.
- **Tests:** backend — `participants.service.test.ts` reescrito
  completamente (14 casos: alta nueva, PIN inválido/faltante, reingreso
  exitoso con mismo `participanteId` y token renovado, PIN incorrecto
  rechazado, colisión con otro evento activo rechazada con sugerencia,
  liberación al finalizar+saldar deudas, liberación al cancelar+saldar
  deudas, bloqueo si el evento no terminó aunque tenga cero deudas,
  bloqueo permanente contra cuentas registradas); `api.test.ts` actualizado
  (8 llamadas a `/participants/anonymous` ahora mandan `pin`). Mobile —
  `login_screen_test.dart`: PIN requerido para habilitar "Confirmar", y que
  un rechazo del backend muestra su mensaje específico (no uno genérico).

# Tanda 6 - Rediseño de navegación y limpieza de features

**Reproducido antes de tocar código** (pedido explícito del usuario): un
swipe completo (más allá del `dismissThreshold` de `flutter_slidable`, no
solo abrir el `ActionPane`) sobre una tarea tira:

```
A dismissed Slidable widget is still part of the tree.
Make sure to implement the onDismissed handle of the ActionPane and to
immediately remove the Slidable widget from the application once that
handler has fired.
```

Coincide exactamente con la captura del usuario (mensaje literal del
paquete `flutter_slidable`, `dismissal.dart`).

**Causa raíz** (leído el código fuente de `flutter_slidable` 4.0.3): el
`onDismissed` de cada `DismissiblePane` (`onTomar`/`onCompletar`/
`onDescompletar`/`onEliminar` en `_TareaTile`) llamaba a `onAccion`, que
hace `setState(_ocupado=true)` **inmediatamente** — dispara un rebuild ya
mismo — y recién saca la tarea de la lista **después** del round-trip de
red + `invalidateEventData` + refetch. `flutter_slidable` exige que el
ítem salga del árbol **de inmediato** apenas termina la animación de
resize del dismiss (lo dice literalmente el mensaje de error): con la
tarea todavía en la lista, cualquier rebuild posterior de ese mismo
`Slidable` (misma `Key`) vuelve a pasar por un `_SlidableDismissalState`
ya marcado `resized = true`, y explota.

- **`event_detail_screen.dart` (`_Contenido` → `_ContenidoState`):** pasa
  de `ConsumerWidget` a `ConsumerStatefulWidget` para poder llevar un
  estado local, `_tareasEnVueloDeSwipe` (los ids que están a mitad de un
  swipe-to-dismiss). El helper nuevo `_accionDeSwipe(tareaId, accion)`:
  1. esconde la tarea de inmediato (`setState` agregándola al set),
  2. **espera a que se pinte un frame real** con la tarea ya afuera del
     árbol (`SchedulerBinding.instance.endOfFrame`) — sin este paso, si el
     round-trip resuelve muy rápido (pasa siempre con los repos *fake* de
     los tests, que no tienen latencia real) el ciclo completo
     esconder→mostrar puede terminar **antes** de que Flutter llegue a
     pintar un solo frame con la tarea excluida, y el `Element` viejo
     (con `resized` en `true`) nunca se desmonta — se reproduce la misma
     excepción. Se encontró este comportamiento reproduciendo el bug con
     un test instrumentado con `print` en cada paso, no por inspección de
     código solamente.
  3. ejecuta la mutación real vía `onAccion` (mismo mecanismo de
     `_ocupado`/loading/snackbar de error de siempre, sin duplicarlo),
  4. espera a que `eventTasksProvider` tenga el dato **fresco** de verdad
     (`ref.read(...future)`) antes de soltar el escondido — así, cuando la
     tarea reaparece, es un `Slidable` **nuevo** (mismo id/`Key`, pero un
     `Element` recién creado, con `resized` en `false` de nuevo — no el
     mismo que ya se había dismisseado), y trae el estado post-mutación
     (completada/desasignada/eliminada), no uno viejo.
  - `onAsignarA`/`onDesasignar` (que no van atados a un `DismissiblePane`,
    solo a un botón/menú) siguen usando `onAccion` directo, sin pasar por
    este mecanismo — no lo necesitan.
- **C1 (`_TareaTile`):** el `SlidableAction` de "Desasignar" ahora solo se
  ofrece si `!tarea.estaSinAsignar && !esCompletada` — antes se mostraba
  con cualquier tarea asignada, sin mirar si ya estaba completada. El
  swipe-to-dismiss de esa `ActionPane` sigue disparando "Eliminar" en
  cualquier caso (es un solo `DismissiblePane` para todo el pane, por
  diseño ya existente — el gesto de swipe completo siempre borra, tomar
  la acción puntual de "Desasignar" requiere el tap sobre el botón, no el
  swipe completo). Se verificó que el toggle completar/descompletar +
  desasignar/eliminar del Item 5 de la tanda anterior ya estaba
  implementado — este fix se aplicó sobre esa base, sin tener que
  reconstruirla.
- **Tests (`screens_test.dart`):** regresión de B2 — swipe completo sobre
  una tarea sin capturar ninguna excepción de Flutter (con un listener de
  `FlutterError.onError`), y que la llamada `eliminar` se dispare. C1 — dos
  casos: una tarea completada no ofrece "Desasignar" (solo "Eliminar"), y
  una asignada-pero-no-completada sí la ofrece y dispara `desasignar`.

# Tanda 6 - Rediseño de navegación y limpieza de features

## Item 3: Historial de eventos — línea de tiempo y bug de avatares

**Causa del recorte de avatares:** `AvatarStack` medía su `SizedBox` exactamente
`radius * 2` — el diámetro puro del `CircleAvatar`, sin dejar lugar al borde
blanco de 2px que dibuja cada avatar por encima (`Border.all` en `_Avatar`).
Como `Stack` recorta por default (`Clip.hardEdge`), el borde de arriba y de
abajo de cada avatar quedaba cortado.

- **`core/widgets/avatar_stack.dart`:** el `SizedBox` ahora mide
  `radius * 2 + borde * 2` (alto y ancho), y el `Stack` pasa a
  `clipBehavior: Clip.none` — no hay nada que este stack decorativo necesite
  ocultar, así que sacar el recorte de raíz es más robusto que ajustar solo
  el número.
- **`history_screen.dart` — línea de tiempo:** nuevo widget interno
  `_TimelineRail` — un punto (`AppColors.primary`) a la altura del
  encabezado de cada mes, con una barra vertical (`AppColors.border`) que
  ocupa exactamente la altura de las cards de ESE mes vía `IntrinsicHeight`.
  Como los tramos van uno debajo del otro sin espacio entre sí, la barra se
  ve continua a lo largo de toda la lista, agrupando visualmente por mes tal
  como pide la referencia.
- **Jerarquía tipográfica:** el encabezado de mes usaba `labelSmall` (11sp,
  por docs/guidelines) — demasiado chico para ser el título de cada grupo,
  sobre todo ahora que ancla la línea de tiempo. Pasa a `titleMedium` bold
  en `AppColors.primary`, la misma jerarquía que ya usan los encabezados de
  sección de Home ("Próximos eventos", "Actividad reciente"). El resto de la
  vista (título/subtítulo de cada card) es `EventCard`, compartido con Home
  y Groups, así que no se tocó para no afectar esas pantallas fuera de
  alcance de este item.
- **Tests:** `widgets_test.dart` — el contenedor de `AvatarStack` ahora mide
  más que `radius * 2` y su `Stack` no recorta. `screens_test.dart` — un
  `IntrinsicHeight` (tramo de línea de tiempo) por mes distinto, y el
  encabezado de mes con tamaño/peso mayores a los de antes.

## Item 1: Navbar — estilos, textos siempre visibles y bug de layout

**Causa raíz del corte (confirmada antes de tocar CSS):** no era un ancho
fijo hardcodeado. `AppBottomNav` armaba un `Row` con
`mainAxisAlignment.spaceEvenly` cuyos 4 `_NavItem` NO eran flexibles: cada uno
se dimensionaba por su contenido intrínseco (ícono + padding, y el texto solo
aparecía si estaba seleccionado). Con el texto oculto la mayoría del tiempo,
el ancho combinado entraba de casualidad; apenas el texto pasa a estar
siempre visible (este mismo item), el ancho combinado de los 4 ítems supera
el ancho disponible y Flutter overflowea el `Row` sin wrappear ni encoger
nada — se ve como la barra cortada, sin poder hacer scroll para verla
completa. Se agregó un test (`app_bottom_nav_test.dart`) que renderiza la
navbar en una pantalla de 320px de ancho y falla si hay una excepción de
layout, para que esta regresión no vuelva.

- **`mobile/lib/core/widgets/app_scaffold.dart` (`AppBottomNav`):**
  - Se sacó el `BackdropFilter`/blur (glassmorphism): ahora es un contenedor
    con `AppColors.surface.withValues(alpha: 0.92)` — blanco fijo, translúcido
    pero sin desenfoque.
  - Cada `_NavItem` ahora va envuelto en `Expanded` (el fix del bug) y es una
    `Column` (ícono arriba, texto siempre debajo, antes era un `Row` que solo
    mostraba el texto si estaba seleccionado).
  - Colores: ítems no seleccionados usan el nuevo token `AppColors.inactiveBlue`
    ("celestito"), el seleccionado usa `AppColors.primary`.
  - El ítem seleccionado tiene un "pill" de fondo blanco (`AppColors.surface`,
    opaco) con una sombra sutil para diferenciarse del contenedor
    translúcido de fondo.
- **`AppColors.inactiveBlue`** (`core/theme/app_colors.dart`) — token nuevo,
  reusado también por el toggle de Gastos (Item 4) para que ambos componentes
  compartan la misma línea visual.
- **Tests:** `app_bottom_nav_test.dart` — los 4 textos siempre visibles, sin
  overflow en una pantalla angosta (320px), colores correctos por selección,
  y que tocar un tab dispara `onTap` con el índice correcto.

## Item 4: Gastos (Saldos) — FAB contextual, toggle y cards de resumen

- **FAB contextual (`app_shell.dart`):** el FAB global creaba siempre un
  evento. Ahora es contextual por índice de tab: en Gastos (`_index == 2`,
  la pantalla "Saldos"/`BalancesScreen`) llama a
  `iniciarCrearGastoRapido(context, ref)`; en el resto sigue abriendo
  `CreateEventScreen`.
- **`quick_expense_sheet.dart` (nuevo):** como "nuevo gasto" no tiene un
  evento implícito (a diferencia de crearlo desde el detalle de un evento),
  primero muestra una hoja para elegir a cuál de los eventos activos del
  usuario pertenece (`upcomingEventsProvider`), y recién ahí reutiliza el
  mismo diálogo de siempre (`pedirDatosGasto`) con los participantes de ese
  evento. Si no hay eventos activos, avisa en vez de abrir un diálogo vacío.
- **Toggle (`PillToggle`, nuevo en `core/widgets/pill_toggle.dart`):** widget
  genérico con la misma estructura visual que la Navbar del Item 1 (blanco
  translúcido, opción no seleccionada en `AppColors.inactiveBlue`, la
  seleccionada con chip blanco + texto `AppColors.primary`). Reemplaza el
  `SegmentedButton` de Material en `balances_screen.dart`.
- **Cards de resumen (`_MiniResumen` en `balances_screen.dart`):** ahora
  llevan un `CircleAvatar` con ícono y color, reusando literalmente
  `iconoDeActividad`/`colorDeActividad` de `activity_presentation.dart`:
  "Me deben" toma el ícono/color de `deuda_saldada` (`Icons.price_check`,
  verde) y "Debo" el de `gasto_agregado` (`Icons.receipt_long`, rojo) — el
  mismo lenguaje visual que ya usa el feed de actividad de los eventos.
- **Tests:** `screens_test.dart` — cards con los íconos esperados y el
  toggle filtrando la lista; `AppShell` con el FAB abriendo "Crear evento"
  en Home pero arrancando el flujo de gasto (no un evento) en Gastos.

## Item 2: Pantalla de Notificaciones, accesos y redirección al evento

**Duda resuelta antes de implementar:** el payload de actividad ya traía
`eventoId` (backend en `data.eventoId` del push, y el modelo mobile
`ActividadLog.eventoId` ya lo parseaba) — no hizo falta tocar el modelo ni
la API para el ruteo. Lo que sí faltaba era la paginación pedida ("20
actividades a la vez"), que no existía en absoluto.

- **Backend — paginación por cursor:** `LogActividadRepository.listRecientesPorEventos`
  ahora acepta un `before?: Date` opcional (trae solo entradas más viejas que
  esa fecha). `ActivityLogService.recientesDe(usuarioId, before?)` y la ruta
  `GET /me/activity` (ahora acepta `?before=<ISO>`) lo exponen sin romper el
  contrato existente: sigue devolviendo un array plano — el cliente infiere
  "hay más páginas" cuando la página recibida viene completa (20 entradas).
  Se valida que `before` sea una fecha ISO válida (400 si no).
- **`NotificationsScreen` (nueva, `features/notifications/`):** tabs
  Todo/Eventos/Gastos (con el mismo `PillToggle` de los Items 1/4),
  agrupada por día ("HOY"/"AYER"/fecha), reutilizando `ActivityFeedItem`,
  `iconoDeActividad`/`colorDeActividad`/`textoActividad` — mismo feed que ya
  alimenta a Home, sin duplicar presentación. `notifications_providers.dart`
  maneja el estado paginado (`NotificationsFeed{items, hasMore}`) y pide la
  próxima página (`cargarMas()`) cuando el scroll llega cerca del final.
- **Accesos:** la campana de `AppHeader` (antes un ícono estático) ahora es
  un `IconButton` que abre `NotificationsScreen`; se sumó un ítem
  "Notificaciones" en `profile_screen.dart`.
- **Redirección al evento:** `ActivityFeedItem` ganó un `onTap` opcional.
  Tanto en Home (`home_screen.dart`) como en `NotificationsScreen`, cada fila
  rutea a `EventDetailScreen(eventoId: ...)` (deshabilitado si la entrada no
  trae `eventoId`, ej. `rango_extendido` que es del sistema).
- **Tests:** backend — `activity-feed-pagination.test.ts` (servicio +
  endpoint, primera/segunda página sin solapar, cursor inválido → 400).
  Mobile — `notifications_test.dart` (paginación del provider, filtro por
  tab, tap→navegación, estado vacío) y casos nuevos en `screens_test.dart`
  (tap en Home rutea al evento, campana abre Notificaciones, acceso desde
  Perfil).

## Item 6: Auth — Login/Registro como card blanca flotante

**Pendiente (bloqueado por mí, no por código):** el ícono oficial de la app
(`image_aedb4c.png` de la referencia) se pegó en el chat, no existe como
archivo en el repo, y no tengo forma de extraer el adjunto a disco. El
usuario prefirió pasarlo él mismo. Mientras tanto, `_AuthLogo` en
`auth_scaffold.dart` usa un ícono vectorial placeholder (`Icons.autorenew`,
en el azul de la marca) dentro del mismo círculo blanco con sombra que
tendría el logo real — apenas esté el archivo en
`mobile/assets/logo.png` (+ su entrada en `pubspec.yaml`), reemplazar el
`Icon` por un `Image.asset(...)` es el único cambio que hace falta.

- **`core/widgets/auth_scaffold.dart` (nuevo):** chrome compartido por Login
  y Registro — fondo `AppColors.background` (celeste clarito), logo +
  "Planify" + tagline arriba, y una card blanca flotante (bordes de 28,
  sombra suave) con el contenido de cada pantalla adentro. Acepta un
  `footer` opcional para lo que va debajo de la card (ej. "¿No tenés cuenta?
  Crear cuenta") y un `showBackButton` para Registro.
- **`login_screen.dart`:** se sacó el `Scaffold` propio; ahora es
  `AuthScaffold(card: ..., footer: ...)`. Mismo contenido y mismo orden de
  campos que antes (los tests de `login_screen_test.dart` que dependen del
  orden de los `TextField` siguen pasando sin tocarlos).
- **`register_screen.dart`:** se sacó el `AppBar` (con su flecha de volver
  implícita) — ahora usa el `BackButton` manual de `AuthScaffold`
  (`showBackButton: true`) y un título ("Crear cuenta") dentro de la propia
  card, para diferenciarse visualmente de Login.
- **Tests:** se agregaron casos puntuales en `login_screen_test.dart` y
  `register_screen_test.dart` para la estructura nueva (sin `AppBar`, con/sin
  `BackButton` según corresponda, logo+tagline visibles); todos los tests
  preexistentes de ambas pantallas siguen pasando tal cual, sin modificarlos.

## Item 5: Foto de grupo nativa + limpieza de "Disponibilidad entre amigos"

**Contexto de la duda planteada:** se encontraron dos features distintas
bajo el nombre "disponibilidad": (1) la disponibilidad semanal *personal* en
Perfil (H-14), que además pre-llena la disponibilidad de un evento nuevo, y
(2) el heatmap de "coincidencias con TODOS los amigos" (HU-B4). Se acordó con
el usuario: (1) se mantiene intacta, (2) se elimina — no como algo global de
Perfil, sino re-scopeada a los miembros de un grupo puntual, accesible desde
el menú de 3 puntos del grupo. La comparación 1-a-1 con un solo amigo (fuera
de un grupo) queda pendiente para una tanda futura (no existía en el código:
se verificó que `FriendsScreen` no tenía ningún tap-action ni endpoint propio).

- **Backend — `ProfileAvailabilityService`:** se le sacó la dependencia de
  `AmistadRepository` y el método `coincidenciasConAmigos` (y la ruta
  `GET /me/availability/friend-matches`). Ahora solo expone `obtener`/`guardar`
  de la disponibilidad semanal individual.
- **Backend — `GroupsService`:** ganó dos métodos nuevos, ambos protegidos por
  el mismo `exigirMiembro` que ya usan `actualizar`/`abandonar`:
  - `disponibilidadDeGrupo(grupoId, usuarioId)` — arma el heatmap con
    `ProfileAvailabilityRepository.slotsDeUsuarios` pero usando
    `GrupoRepository.listMiembros(grupoId)` en vez de la lista de amigos.
    Nueva ruta: `GET /groups/:id/availability-matches`.
  - `actualizarImagen(grupoId, usuarioId, archivo)` — sube el archivo a S3 vía
    el nuevo puerto `ImageStorageRepository` y persiste la URL resultante como
    `avatarUrl` del grupo. Nueva ruta: `POST /groups/:id/avatar` (multipart,
    campo `imagen`, hasta 5MB, vía `multer` con `memoryStorage`).
- **Backend — `ImageStorageRepository` (`domain/repositories/image-storage.repository.ts`):**
  puerto nuevo con un único método `subir(carpeta, buffer, mimeType) → url`.
  Implementación real: `S3ImageStorageRepository`
  (`infrastructure/aws/s3-image-storage.repository.ts`), usando
  `@aws-sdk/client-s3`. No fija ACL en el `PutObject` porque muchos buckets
  modernos tienen las ACLs deshabilitadas por default (Object Ownership =
  "Bucket owner enforced"): el acceso público a las imágenes se resuelve con
  una bucket policy configurada en AWS, fuera de este código.
- **Infra — "homónimo" local del bucket:** se agregó el servicio `localstack`
  a `infra/docker-compose.yml` (imagen `localstack/localstack:3`, solo
  `SERVICES=s3`), con un script de init (`infra/localstack-init/01-create-bucket.sh`)
  que crea el bucket apenas el contenedor queda "healthy". Es la MISMA clase
  `S3ImageStorageRepository` para AWS real y para LocalStack: lo único que
  cambia es la config (`AWS_S3_ENDPOINT` + `AWS_S3_FORCE_PATH_STYLE`), inyectada
  desde variables de entorno en `container.ts`. Se probó end-to-end contra un
  LocalStack real levantado en este entorno (subida + lectura por la URL
  pública devuelta, HTTP 200).
- **Mobile — imagen nativa:** se agregó `image_picker` a `pubspec.yaml`. En
  `group_manage_sheet.dart`, "Cambiar imagen" ahora llama a
  `ImagePicker().pickImage(source: ImageSource.gallery)` y sube los bytes con
  `GroupsRepository.subirImagen` (multipart vía `dio`/`FormData`), en vez de
  pedir una URL de texto (se eliminó el diálogo y la key `groupsImageUrl`).
- **Mobile — disponibilidad de grupo:** pantalla nueva
  `group_availability_screen.dart` (mismo heatmap que la vieja
  `FriendMatchesScreen`, ahora alimentada por
  `GroupsRepository.disponibilidadDeGrupo`), con un ítem nuevo "Ver
  disponibilidad del grupo" en `group_manage_sheet.dart`. Se borró
  `friend_matches_screen.dart` y el método `coincidenciasConAmigos` de
  `ProfileRepository`; el ListTile correspondiente se sacó de
  `profile_screen.dart`. La grilla personal "Disponibilidad Semanal" de
  Perfil (y su pre-llenado en `event_config_screen.dart`) no se tocó.
- **Tests:** `tasks-groups.service.test.ts` (membresía + agregado correcto
  scopeado al grupo, subida de imagen), `api.test.ts` (multipart real vía
  supertest `.attach()` + guard de membresía en ambas rutas nuevas),
  `extras.test.ts` (se sacó el test de HU-B4 global). Mobile:
  `screens_test.dart` cubre que Perfil ya no ofrece el matching global pero
  conserva la grilla personal, que `GroupAvailabilityScreen` pinta el heatmap
  scopeado, y que "Cambiar imagen" ya no abre un diálogo de texto.

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
