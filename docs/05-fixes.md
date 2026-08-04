# Tanda 6 - Rediseño de navegación y limpieza de features

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
