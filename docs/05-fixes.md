# Tanda 6 - Rediseño de navegación y limpieza de features

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
