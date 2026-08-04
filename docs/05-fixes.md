# Planify — Registro de correcciones (Fase 2)

> Qué se corrigió, cómo, y cómo se validó. Cada entrada referencia el hallazgo
> de [04-auditoria.md](04-auditoria.md). Los tests de regresión del backend viven
> en `backend/test/audit-regression.test.ts`; los de mobile, en las suites
> existentes marcadas con el ID del hallazgo.

## Estado de verificación (se actualiza en cada corrida)

| Chequeo | Antes | Después |
|---|---|---|
| Backend Jest | 70 | 84 ✅ |
| Backend `tsc` | ✅ | ✅ |
| Backend `eslint .` (ampliado) | 2 err | 0 ✅ |
| Mobile `flutter test` | 26 | 29 ✅ |
| Mobile `flutter analyze` | 2 info | 0 ✅ |

---

## H-01 — Los miembros del grupo ahora se vuelven participantes del evento (Bloqueante)

**Causa raíz:** la participación en el evento estaba desacoplada de la pertenencia
al grupo. Al crear un evento solo se creaba el `Participante` organizador.

**Fix (causa raíz, en el punto de integración):**
- `EventoRepository.CrearEventoData` lleva ahora `otrosMiembros`, y
  `createWithOrganizer` los crea como participantes (registrados, sin confirmar)
  en la **misma transacción** (`evento.prisma.repository.ts`).
- `EventsService.crear` trae los miembros del grupo (`GrupoRepository.listMiembros`,
  nuevo) y se los pasa, excluyendo al organizador. Vale para grupo nuevo (HU-04) y
  grupo reutilizado (HU-05).
- `GroupsService.agregarMiembro` materializa al nuevo amigo como participante de
  todos los eventos activos del grupo (Duda #12.2: "visibilidad de todos los
  eventos"), vía `ParticipanteRepository.createParaUsuario` (nuevo, **idempotente**).

**Validación:** `audit-regression.test.ts` → 4 casos: crear reutilizando grupo,
crear con miembros sueltos, sumar amigo a grupo con evento activo, e idempotencia.
Backend 70→74 tests.

## H-02 — Lista de participantes fresca al asignar un gasto (Bloqueante)

**Causa raíz:** `eventDetailProvider` cachea y el detalle no tenía forma de
refrescarse; un participante que se unía después no aparecía en el diálogo de gasto.

**Fix:**
- `RefreshIndicator` en el detalle del evento (pull-to-refresh) —
  `event_detail_screen.dart`.
- `_agregarGasto` invalida y **re-lee** `eventDetailProvider` antes de abrir el
  diálogo, así toma la lista más fresca (con fallback a la cacheada si no hay red).

**Validación:** las suites de detalle de evento siguen verdes; el refetch usa el
mismo provider ya cubierto por tests. (La reproducción end-to-end real queda para
la corrida con backend + DB, ver H-07.)

## H-04 — "Soy organizador" lo decide quién mira, no la lista (Alto)

**Causa raíz:** la UI usaba "existe un organizador en la lista" (`organizador != null`),
que es siempre verdadero, para mostrar cancelar / cerrar gastos / confirmar horario.
Cualquier participante (incluido el anónimo) las veía y le daban 401.

**Fix (causa raíz):**
- El backend `eventsQuery.detalle(eventoId, participanteId)` ahora calcula y
  devuelve `soyOrganizador` y `miParticipanteId` a partir del participante que hace
  la request (que el guard ya conoce). La ruta `GET /events/:id` le pasa
  `req.participanteId`.
- El modelo mobile `DetalleEvento` parsea esos campos; la pantalla usa
  `evento.soyOrganizador` en vez del getter `organizador` (eliminado).

**Validación:** `audit-regression.test.ts` (organizador ve true, anónimo false);
`screens_test.dart` "un anónimo no ve las acciones de organizador (H-04)". Backend
74→75, mobile 26→27.

## H-06 — La UI de gasto ahora soporta varios acreedores (Alto, FR7)

**Causa raíz:** el diálogo tenía un único dropdown "quién pagó".

**Fix:** `expense_dialog.dart` reescrito. Sección "¿Quién pagó?" con checkboxes
por participante; con un solo pagador, su aporte es el total (sin tipear); con
varios, cada uno tiene su monto, hay botón "Repartir" (en partes iguales) y un
indicador "Aportado: X de Y" que valida que los aportes sumen el total antes de
confirmar (NFR#4). El repo mobile ya soportaba `List<AporteGasto>`; se eliminó el
`DropdownButtonFormField` deprecado (cierra el 2º lint de H-12). Nuevas claves i18n
ES/EN: `eventDetailSplitEqually`, `eventDetailPayersMustSum`, `eventDetailContributed`.

**Validación:** `flutter analyze` sin issues; suites de detalle verdes (27).

## H-09 — Próximos y Historial se parten por fecha, no solo por estado (Medio)

**Causa raíz:** los listados filtraban solo por estado; un `confirmado` aparecía a
la vez en Próximos e Historial.

**Fix:** `EventoRepository.listUpcomingForUsuario/listPastForUsuario` reciben `ahora`
(de un `Clock` inyectado en `EventsQueryService`). Próximos = `planificacion` o
`confirmado` con fecha nula/futura; Historial = `finalizado`/`cancelado` o
`confirmado` con fecha pasada. Implementado en Prisma y en el fake (que antes
devolvía `[]`, ahora filtra de verdad por membresía + estado + fecha).

**Validación:** `audit-regression.test.ts` (pasado→historial, futuro→próximos,
sin-fecha→próximos, y que el futuro NO esté en historial). Backend 75→76.

## H-11 — Lint (CORRECCIÓN de la auditoría) + ampliación de cobertura (Medio)

**Corrección honesta:** el hallazgo original decía "CI backend en rojo". Al
verificar el comando **real** del workflow (`npm run lint` = `eslint "src/**/*.ts"`)
resultó que **salía 0 (verde)**: solo linteaba `src`, no el config ni los tests.
Los 2 errores que había visto eran al correr `eslint .` (todo). Así que el CI **no
estaba en rojo** por lint. Se corrige la nota en [04-auditoria.md](04-auditoria.md).

**Mejora igual:** (1) `eslint.config.js` desactiva `no-require-imports` para `*.js`
(config CommonJS legítimo); (2) se usan las vars `anonimo1/anonimo2` en un assert de
`api.test.ts`; (3) el script pasa a `eslint .` para lintear también tests y config.
Resultado: `eslint .` limpio (0).

## H-03 — Cifrado en tránsito (Alto, NFR#7)

**Fix (infra, listo para usar):** se agrega un reverse proxy **Caddy** delante del
backend en `docker-compose.yml` + `infra/Caddyfile`, que termina TLS. Con
`CADDY_DOMAIN=localhost` usa certificado interno (dev); con un dominio real saca y
renueva el certificado de Let's Encrypt automáticamente. El `api_client` documenta
apuntar a `https://<dominio>` en producción. (El certificado real depende del
dominio/*deploy*, no del código — ver [06-estado-final.md](06-estado-final.md).)

## H-07 — docker-compose aplica migración + seed (Alto)

**Fix:** servicio one-shot `migrate` (usa el stage `build` de la imagen, que tiene
el CLI de Prisma, ts-node y el código fuente) corre `prisma migrate deploy` + `npm
run seed`; `backend` depende de `migrate` con `service_completed_successfully`. El
seed hace `process.exit(0)` explícito para no colgar el contenedor. Así, un
`docker compose up --build` deja la base migrada y sembrada sola.

## H-12 — `flutter analyze` en verde (Medio)

`use_build_context_synchronously` (copiar link): se captura el `ScaffoldMessenger`
antes del `await`. `DropdownButtonFormField.value` deprecado: eliminado al rehacer
el diálogo de gasto (H-06). **`flutter analyze`: sin issues.**

## SCRUM-14 — Auth completa + amigos + gestión de miembros (resuelve H-05, H-10, H-13, H-16)

**Backend (nuevo, testeado — `scrum14.test.ts`, 8 tests):**
- **Registro (HU-27):** `POST /auth/register` valida email/único/contraseña, crea `Usuario`, devuelve token. `login` ahora normaliza el email.
- **Recuperación (HU-29):** `POST /auth/reset/request` (siempre 200, no filtra si el email existe; en dev devuelve el token, en prod se envía por email) + `POST /auth/reset/confirm`. El token es un JWT firmado (sin tabla nueva).
- **Perfil (HU-30):** `GET/PATCH /me/profile` (nombre, avatar, idioma con validación es|en).
- **Amigos (HU-31):** `AmistadRepository` + `FriendsService`: `GET /users/search`, `GET /friends`, `GET /friends/requests`, `POST /friends/request`, `POST /friends/:id/accept`. Solicitud→aceptación, sin auto-agregarse ni duplicar, y solo el receptor acepta.
- **Gestión de miembros (HU-32):** ya existía `agregarMiembro`; con H-01 el amigo agregado se vuelve participante de los eventos activos.

**Mobile (nuevo):**
- `FriendsRepository` + **selector de amigos reutilizable** (`friend_picker.dart`).
- **H-10:** la gestión de grupo ("Agregar amigo") usa el selector en vez de pedir un UUID a mano.
- **H-05:** el paso 2 del wizard de creación permite elegir miembros (chips) para el grupo nuevo → se pasan como `miembroUsuarioIds`.
- **H-16:** Perfil ahora tiene "Mis amigos" (pantalla de amigos: buscar, solicitar, aceptar, listar) — sección que faltaba respecto del mockup.
- **H-13:** selector de idioma ES/EN en Perfil (`localeProvider` persistido); la app dejó de estar clavada en `es`.
- Pantalla de **registro** conectada al "Crear cuenta" del Login (antes inerte).

**Validación:** backend 76→84; mobile `flutter analyze` sin issues, 27 tests verdes.

> **Nota de recuperación de contraseña:** el token se genera y valida en el backend; **falta el envío por email** (depende de un proveedor tipo SES/SendGrid, integración externa). Ver [06-estado-final.md](06-estado-final.md).

## SCRUM-15 — Notificaciones push (HU-35)

**Backend (nuevo, testeado — `api.test.ts`):**
- Ports `PushNotifier` y `DeviceRegistry` (domain). Implementaciones por defecto: `ConsolePushNotifier` (loguea) e `InMemoryDeviceRegistry`. **Se reemplazan por SNS/Pinpoint tocando solo `container.ts`.**
- `NotificationsService`: `registrarDevice` + `notificarActividad` (notifica a los participantes registrados del evento, salvo el actor).
- Se dispara desde `ActivityLogService.registrar` (un solo lugar, best-effort: si el push falla, la actividad igual se registra). Inyección opcional por interfaz → los tests que no prueban push no cambian.
- Endpoint `POST /notifications/register-device` (antes 501) → 201.

**Validación:** test end-to-end: se registra un device, un anónimo confirma asistencia y el organizador (otro participante) recibe el push. + 401 sin auth.

> **Pendiente (externo):** el **envío real** por SNS/Pinpoint y la **recepción** en el dispositivo (SDK FCM/APNs) requieren credenciales AWS y setup de plataforma. El SLA de NFR#8 (<60s) aplica mientras el ambiente demo esté encendido. Ver [06-estado-final.md](06-estado-final.md).

## SCRUM-17 — IA de auto-generación de eventos (HU-42/43/44b)

**Backend (nuevo, testeado — `api.test.ts`):**
- Port `EventGenerator` (domain). Dos implementaciones: **`HeuristicEventGenerator`** (offline: extrae nombre, lugar tras "en", personas tras "con", y tareas típicas por palabra clave) y **`GeminiEventGenerator`** (llama a Gemini con salida JSON; ante cualquier error **cae al heurístico** — nunca bloquea, HU-42). El container usa Gemini si `GEMINI_API_KEY` está seteada, si no el heurístico.
- `AiEventsService.generarDesdeTexto`: devuelve un **borrador editable** (nunca auto-crea) + matchea los nombres mencionados contra los **amigos** del organizador (HU-43).
- Endpoint `POST /events/generate-from-text` (antes 501) → 200 con el borrador.

**Mobile:** botón "Generar con IA" en el paso 1 del wizard → describe el evento → pre-llena nombre + lugar, agrega los amigos matcheados como miembros, avisa los no matcheados, y al crear el evento crea las **tareas sugeridas** (HU-44b). Nuevas claves i18n ES/EN.

**Validación:** test verifíca borrador (nombre "asado", lugar "juli", tareas, Sofía matchea, Pedro no) + 400 sin descripción. Backend 84→87; mobile analyze sin issues.

> **Pendiente (externo):** para usar Gemini real hace falta setear `GEMINI_API_KEY` (acceso gratuito de la facultad, Duda #21). Sin la key, la app **funciona igual** con el generador heurístico.

## Extras finales — H-14, H-17, HU-B4, HU-B5

Backend 87→**90** tests; mobile analyze sin issues, 27 tests. Nueva migración
`20260802120000_perfil_disponibilidad_ubicaciones` (2 tablas).

- **H-14 — Disponibilidad de perfil al backend:** tabla `disponibilidad_perfil` +
  `ProfileAvailabilityService` + `GET/PUT /me/availability`. El provider mobile
  ahora sincroniza con el backend con **caché local de fallback** (si no hay red
  o es sesión anónima). Pre-llena la disponibilidad del evento como antes.
- **HU-B4 — Coincidencias entre amigos:** `GET /me/availability/friend-matches`
  arma un heatmap de la disponibilidad de perfil del usuario + sus amigos.
  Pantalla mobile "Coincidencias con amigos" (Perfil → grilla heatmap).
- **HU-B5 — Ubicaciones favoritas:** tabla `ubicaciones_favoritas` + CRUD
  `/me/locations`. En el paso 1 de creación de evento se pueden **elegir**
  ubicaciones guardadas o **guardar** la actual.
- **H-17 — Badge de no-leídos:** `unreadTotalProvider` suma `/me/unread`; la
  campana del `AppHeader` muestra un `Badge` con el total (0 = sin badge).

**Validación:** `extras.test.ts` (disponibilidad de perfil con validación de
rangos y reemplazo; coincidencias que cuentan por bloque; ubicaciones con
ownership). Mobile: analyze limpio, 27 tests.

---

# Fase 3 — 5 issues de UX/funcionalidad reportados por el usuario

> Cada item tiene su propia branch/PR. Se implementan en orden 5 → 2 → 1 → 3 → 4
> porque el 2 reutiliza el paso de username del 5, y el 4 reestructura la
> pantalla de evento apoyándose en el 1 (carrusel de grupos) y el 3 (grillas
> colapsables).

## Item 5 — "Continuar como Anónimo" ahora pide un username en un solo paso

**Causa raíz:** el botón "Continuar como Anónimo" (`login_screen.dart`) abría
un diálogo pidiendo el **link de invitación** (`_pedirTokenManual`) y, recién
después de resolverlo, un **segundo diálogo separado** pedía el nombre
(`_unirseConToken`) — dos pasos secuenciales con títulos distintos ("Unirse
por invitación" y luego "Invitar al evento"), lo cual coincide con el hallazgo
[H-08](04-auditoria.md#h-08) (el botón se desvía del mockup/HU-01). El dato de
`nombreDisplay` en sí **ya era obligatorio** antes de crear la sesión anónima
(el fix de [H-01](#h-01-los-miembros-del-grupo-ahora-se-vuelven-participantes-del-evento-bloqueante)/[H-02](#h-02-lista-de-participantes-fresca-al-asignar-un-gasto-bloqueante)
sigue vigente y no se tocó), pero la experiencia de "dos diálogos seguidos"
es la raíz de la confusión reportada.

**Fix:**
- `_continuarComoAnonimo` (antes `_pedirTokenManual`) muestra **un único
  diálogo** con dos campos — link de invitación y nombre — y solo cierra
  cuando ambos están completos. Resuelve la invitación y crea la sesión
  anónima sin ningún paso intermedio adicional.
- `_unirseConToken` (usado por el deep link, ver Item 2) se simplificó para
  pedir solo el nombre, ya que el token viaja en la URI.
- **Bug real encontrado al testear:** los `TextEditingController` de ambos
  diálogos se disponían sincrónicamente apenas el `await showDialog` volvía,
  pero el diálogo todavía estaba animando su cierre y el `TextField` seguía
  usando el controller en ese frame → `TextEditingController was used after
  being disposed`. Estaba latente en el código original (nadie lo había
  testeado end-to-end). Se corrige difiriendo el `dispose()` a
  `WidgetsBinding.instance.addPostFrameCallback`.
- Nuevas claves i18n ES/EN: `loginAnonymousLinkLabel`, `loginAnonymousNameLabel`,
  `loginAnonymousNameHint`.

**Validación:** `login_screen_test.dart` — 2 tests nuevos: el diálogo único
pide link+nombre y crea la sesión (`FakeAuthRepository.llamadas` contiene
`anonimo:evt-1:Sofía`), y no se puede confirmar sin nombre. Mobile 27→29,
`flutter analyze` limpio.

## Item 2 — El link de invitación ya no fuerza el modo anónimo

**Causa raíz (mobile):** `LoginScreen` escuchaba los deep links en su propio
`initState`. Como solo se monta cuando `SinSesion()`, abrir un link **con
sesión ya iniciada no hacía absolutamente nada** (el listener ni existía). Y
apenas resolvía el token, saltaba derecho a pedir nombre y crear una sesión
anónima — nunca se veía el Login con sus 3 opciones (Ingresar/Crear
cuenta/Anónimo), pese a que HU-01 las pide todas visibles.

**Causa raíz (backend):** no existía ningún endpoint para que un usuario
**registrado** se uniera a un evento/grupo por su cuenta a través de un link
de invitación — solo estaba el camino anónimo (`POST
/participants/anonymous`). "Iniciar sesión con cuenta existente y quedar
unido con la cuenta real" no era implementable sin esto.

**Fix (backend):**
- `GroupsService.unirsePorInvitacion(token, usuarioId)` (nuevo): resuelve la
  invitación vía `InvitationsService.resolver` (ahora inyectado en
  `GroupsService`), y si el usuario no es miembro del grupo del evento, lo
  suma y materializa como participante de sus eventos activos — reutiliza
  exactamente la lógica de [H-01](#h-01-los-miembros-del-grupo-ahora-se-vuelven-participantes-del-evento-bloqueante)
  (`agregarMiembro`), ahora extraída a `materializarParticipantesActivos`.
  Si ya era miembro, es idempotente: solo asegura el participante de *ese*
  evento puntual.
- `POST /invitations/:token/join` (nuevo), detrás de `soloOrganizador` (=
  cualquier usuario autenticado, no solo el organizador del evento).

**Fix (mobile):**
- El listener de deep links se mueve de `LoginScreen` a `_RootRouter`
  (`main.dart`), que vive durante toda la vida de la app. El token capturado
  se guarda en `pendingInvitationProvider` (nuevo) — no se actúa sobre él de
  inmediato.
- `_RootRouter` escucha ese provider y el estado de sesión: si ya hay
  `SesionOrganizador` (dentro de la misma corrida de la app), aplica la
  invitación sola vía `AuthRepository.unirseConInvitacion` (nuevo método →
  `POST /invitations/:token/join`) y navega al evento — sin pedir nada.
- `LoginScreen` vuelve a mostrarse siempre igual (sus 3 opciones), con un
  aviso opcional si hay una invitación pendiente (`loginPendingInvitation`).
  Si la persona elige Ingresar o Crear cuenta, la invitación se aplica sola
  en cuanto la sesión pasa a `SesionOrganizador` (mismo mecanismo de arriba,
  sin código adicional en el formulario). Si elige "Continuar como Anónimo",
  el diálogo del Item 5 precarga el link ya capturado.
- **Bug real corregido de paso:** `getInitialLink()` y `uriLinkStream` de
  `app_links` pueden disparar los dos para el mismo link de arranque en frío
  — es la causa más probable del "pide el nombre dos veces" reportado. Se
  ignora el primer evento del stream si ya se procesó por `getInitialLink`.

**Pendiente, fuera de alcance de este item (anotado, no corregido):**
`SessionController.build()` solo restaura la sesión desde `TokenStorage`
para el camino anónimo (`anonEventId` + `participantToken`); un organizador
logueado **no** recupera sesión al reabrir la app después de matarla del
todo (no hay endpoint de "quién soy" cacheado localmente). Mientras la app
sigue corriendo, la sesión de organizador sí persiste en memoria y el
criterio de aceptación de este item se cumple; el caso "app killeada + abrir
un link" con un organizador ya logueado se degrada al login normal (no es
una regresión: hoy ya no hay forma de restaurar esa sesión, con o sin link).

**Validación:**
- Backend: `tasks-groups.service.test.ts` — 3 tests nuevos
  (`unirsePorInvitacion`: usuario nuevo queda miembro y participante real, no
  anónimo; reusar el link siendo ya miembro es idempotente; token inexistente
  rechaza). Backend 90→93.
- Mobile: `main_test.dart` (nuevo) — con sesión de organizador ya iniciada,
  una invitación pendiente se aplica sola y no aparece ningún diálogo.
  `login_screen_test.dart` — 3 tests nuevos: el aviso aparece/no aparece según
  haya invitación pendiente, y el diálogo de anónimo precarga el link. Mobile
  29→33, `flutter analyze` limpio.

## Item 1 — Carrusel de grupos + eventos que ya no se pisan entre sí

**Investigación pedida por el usuario antes del fix:** el enunciado suponía
que había un bug de estado (una variable global de "eventos visibles" que se
sobreescribía al cambiar de grupo). **No era eso.** `GroupsScreen` no tenía
carrusel de ningún tipo, y cada card de grupo mostraba **un único** evento
(`GrupoResumen.proximoEvento`, nullable, singular) — nunca existió una lista
de "eventos visibles por grupo" que se pudiera pisar. Es una feature a
construir, no un bug de caché.

**Alcance real (hallazgo durante la implementación):** para armar el
carrusel + drill-down hacía falta que el backend expusiera **todos** los
eventos activos de un grupo, no solo el próximo. Sí hacía falta tocar el
backend (como se había anticipado), pero **no** un endpoint nuevo: alcanzó
con ampliar la respuesta que ya existía.

**Fix (backend):**
- `ResumenGrupo.proximoEvento` (un evento o `null`) → `ResumenGrupo.eventos`
  (lista de **todos** los eventos activos del grupo, cada uno con
  confirmados/tareas pendientes/gastos — mismo shape que antes, ahora por
  cada evento en vez de solo el próximo). `GroupsService.resumenPara` pide
  los contadores en batch para todos los eventos activos de todos los grupos
  (sigue evitando el N+1).
- `noLeidos`/`tieneEventoNuevo` no cambian: se siguen calculando sobre TODOS
  los eventos del grupo (activos e históricos), como ya establecía la
  Duda #2 — no solo los que ahora se listan.

**Fix (mobile):**
- `GroupsScreen` ahora arma un **carrusel horizontal de avatares de grupo**
  arriba (iniciales del nombre, punto de no leídos, badge NUEVO si
  corresponde) y, debajo, las cards de los eventos del grupo **seleccionado**
  (`grupoSeleccionadoProvider`, un `Notifier<String?>`).
- **Por qué cambiar de grupo no pisa nada:** `groupsOverviewProvider` trae
  TODOS los grupos con sus eventos en un solo fetch (ya cacheado por
  Riverpod). Seleccionar otro grupo no dispara ningún request nuevo — solo
  cambia qué parte de esos mismos datos, ya en memoria, se renderiza. No hay
  estado por-grupo que sobrescribir porque no hay una sola variable
  compartida: cada `GrupoResumen.eventos` vive en su propio lugar dentro de
  la lista.
- Se extrajo `EventoResumenCard` (antes `_EventoCard`, privada de Home) a
  `core/widgets/` para no duplicarla. Groups usa su propia card
  (`_EventoDeGrupoCard`) porque necesita los chips de tareas
  pendientes/gastos que `EventoResumen` (el de Home) no trae —
  `EventoDeGrupo` sí, porque sale de `ResumenGrupo.eventos`.
- Bug menor corregido de paso: `EventoResumen.grupoNombre` se parseaba de
  `json['grupo']['nombre']` (anidado) pero el backend siempre mandó
  `grupoNombre` plano — el campo daba `null` siempre. Ahora se agrega
  `EventoResumen.grupoId` (plano, nuevo) y se corrige el parseo de
  `grupoNombre`.

**Validación:**
- Backend: `tasks-groups.service.test.ts` — 3 tests nuevos (`eventos` trae
  todos los activos de un grupo, no solo el próximo; excluye
  finalizados/cancelados; los eventos de un grupo no se mezclan con los de
  otro). Backend 93→96.
- Mobile: `screens_test.dart` — reescrita la suite de `GroupsScreen`: arranca
  en el primer grupo con sus eventos, **tocar otro grupo cambia los eventos y
  volver al primero los conserva intactos** (el criterio de aceptación
  literal del item), y un grupo sin eventos activos muestra el estado vacío.
  Mobile 33→35, `flutter analyze` limpio.

## Item 3 — Disponibilidad: 24hs completas + secciones colapsables

**Causa raíz:** `WeeklyAvailabilityGrid` (componente propio, sin librería de
por medio) es la misma grilla en dos pantallas: Perfil arrancaba en `horaInicio: 8`
(faltaban 00-07h) y el detalle de evento en `horaInicio: 10` (faltaban 00-09h)
para "Mi disponibilidad" y el heatmap del grupo. Al estar embebidas en un
`ListView`/`Column` normal, competían por espacio con el resto de la
pantalla — de ahí el scroll largo.

**Decisión de diseño (aclarada por el usuario, distinta de mi primera
propuesta de dropdowns por franja horaria):** no se reemplaza la grilla
semanal por dropdowns de horario. Se agrega un **acordeón**: "Mi
disponibilidad" y "Disponibilidad del grupo" arrancan **cerradas** (solo se
ve el título) y al tocarlas se abren mostrando la grilla semanal con heatmap
tal cual está hoy — se gana espacio en pantalla sin perder la vista.

**Fix:**
- `CollapsibleSection` (nuevo, `core/widgets/`): título + contenido
  colapsable dentro de una `Card`, con `initiallyExpanded` configurable.
- `EventDetailScreen`: "Mi disponibilidad" y "Disponibilidad" (heatmap del
  grupo) pasan de `Card` fija a `CollapsibleSection`, **cerradas por
  defecto** (la pantalla ya tiene mucho contenido — asistencia, acciones
  rápidas, tareas, log). `horaInicio` pasa de `10` a `0` en ambas.
- `ProfileScreen`: "Disponibilidad Semanal" pasa a `CollapsibleSection` con
  `initiallyExpanded: true` (es el contenido principal de esa sección, no
  tiene sentido arrancar cerrada). `horaInicio` pasa de `8` a `0`.
- **Bug de test infra corregido de paso:** `appDePrueba` montaba la pantalla
  directamente como `home:` de `MaterialApp`, sin `Scaffold`. Nunca había
  hecho falta porque ninguna pantalla testeada hasta ahora usaba `ListTile`
  (que exige un ancestro `Material`) — `ProfileScreen` sí, y es la primera
  vez que se testea. Se envuelve `pantalla` en `Scaffold(body: SafeArea(...))`,
  igual que hace `AppShell` en producción.

**Validación:**
- `widgets_test.dart` — 2 tests nuevos de `CollapsibleSection`: arranca
  cerrada y se abre/cierra al tocar el título; `initiallyExpanded` la muestra
  abierta desde el arranque.
- `profile_screen_test.dart` (nuevo) — la grilla cubre 00h a 23h y no hace
  falta tocar nada para verla (arranca expandida).
- `screens_test.dart` — el test de guardar disponibilidad (HU-07) ahora abre
  la sección antes de tocar la grilla (documenta que arranca cerrada en el
  detalle de evento).
- Mobile 35→38, `flutter analyze` limpio.

## Item 4 — Pantalla del evento: feed de actividad + Configuración separada

**Diseño confirmado con el usuario antes de tocar código** (3 preguntas
respondidas): pantalla nueva completa (no modal), acceso por ícono de
engranaje en el AppBar del feed, saldos se quedan como acción rápida (no se
mueven a Configuración). También se confirmó omitir "Sondeo" (no existe como
feature ni en backend ni en mobile — no se agrega un botón sin funcionalidad
real detrás).

**Cómo estaba antes:** `EventDetailScreen` era una única pantalla larga con
TODO junto, en este orden: fecha/lugar, tarjeta de asistencia, acciones
rápidas, "Mi disponibilidad", heatmap del grupo, tareas, log de actividad.

**Fix:**
- `EventDetailScreen` queda como el **feed** (tipo chat/log, mockup "Log de
  Actividad"): fecha/lugar, acciones rápidas (Invitar, Gasto, Tarea, Saldar),
  tareas (HU-20..23) y log de actividad (HU-24). Nada de esto se movió de
  lugar ni cambió de comportamiento.
- `EventConfigScreen` (nueva, `event_config_screen.dart`): asistencia
  (HU-10), "Mi disponibilidad" (HU-07) y "Disponibilidad del grupo"
  (HU-08/HU-09) — las tres secciones que se sacaron del feed, tal cual
  estaban (mismas `CollapsibleSection` del Item 3, acá `initiallyExpanded:
  true` porque es todo el contenido de la pantalla). Pantalla nueva completa,
  no modal — se llega con un push normal, igual que `FriendsScreen`/
  `HistoryScreen`.
- Acceso: ícono de engranaje (`Icons.settings_outlined`) al lado del de
  invitar, en el AppBar del feed.
- El estado de "mi disponibilidad" (`_miDisponibilidad`, antes en
  `_EventDetailScreenState`) se movió íntegro a `EventConfigScreen`: ya no
  tiene sentido que lo cargue una pantalla que no la muestra.

**Validación:**
- `screens_test.dart` (`EventDetailScreen`) — reescrita: ya no hay asistencia
  ni disponibilidad en el feed (`findsNothing`), el ícono de engranaje abre
  Configuración, y "evento cancelado deshabilita las acciones" pasa a
  chequear el `onPressed` de una `QuickActionButton` (antes tocaba el botón
  de asistencia, que ya no está acá).
- `event_config_screen_test.dart` (nuevo) — asistencia + las dos
  disponibilidades ya expandidas sin tocar nada; confirmar asistencia llama
  al repositorio; guardar disponibilidad envía los bloques; un no-organizador
  no ve el hint de confirmar horario.
- Mobile 38→41, `flutter analyze` limpio.

---

# Fase 4 — 6 mejoras más reportadas por el usuario

> Mismo formato que la Fase 3: cada item con su propia branch/PR y su test.
> Orden de implementación sugerido por el usuario: 4 → 1 → 3 → 6 → 2 → 5.

## Item 4 — "No voy" no se veía guardado + no excluía del heatmap grupal

**Investigación pedida antes del fix — no era el bug que se sospechaba.**
Se revisó de punta a punta: mobile llama `responderAsistencia(confirma:
false)` correctamente, el backend persiste `'rechazado'` bien (ya había un
test en `events.service.test.ts` que lo cubre y seguía en verde), y no hay
ningún cableado cruzado entre los botones "Voy"/"No voy". **La causa real:
la UI nunca mostraba cuál era la respuesta actual** — los dos botones se
veían siempre idénticos sin importar qué habías contestado, lo que daba la
sensación de que "No voy" no quedaba guardado.

Lo que sí era un gap real y sin implementar: el heatmap de disponibilidad
del grupo **contaba a todos los participantes por igual**, sin importar su
respuesta de asistencia — quien decía "No voy" igual sumaba en el mapa de
calor si había cargado horarios antes de responder.

**Fix (mobile) — mostrar el estado actual:**
- `EventConfigScreen`: los botones de asistencia pasan de
  `TextButton`/`FilledButton` fijos a `_BotonAsistencia`, que se resalta
  (relleno + ✓) cuando es la respuesta guardada (`evento.miParticipanteId`
  contra `evento.participantes`) y queda en outline cuando no.
- Se probó primero con `SegmentedButton<bool>` (M3, selección visual
  automática) pero sus segmentos internos no son tappeables de forma
  confiable con `WidgetTester.tap` sobre el texto — se volvió a dos botones
  independientes con estado manual, más simple y 100% testeable.

**Fix (backend) — excluir del heatmap:**
- `PrismaDisponibilidadRepository.heatmapForEvento`: el `groupBy` ahora
  filtra `participante: { estadoAsistencia: { not: 'rechazado' } }` (join
  contra `Participante`). Es un filtro en tiempo de consulta, no un estado
  que se guarda aparte — por eso volver a "Voy" hace que sus horarios
  cuenten de nuevo sin ningún paso extra.
- `FakeDisponibilidadRepository` (test) ahora recibe una referencia a
  `FakeParticipanteRepository` para poder replicar el mismo filtro en los
  tests con fakes.

**Validación:**
- Backend: `availability.service.test.ts` (nuevo) — cuenta disponibilidad de
  quien no respondió/confirmó; excluye a quien dijo "No voy"; un bloque
  donde solo había disponibilidad de un "No voy" desaparece del heatmap;
  volver a "Voy" reincorpora sus horarios. Backend 96→100.
- Mobile: `event_config_screen_test.dart` — 2 tests nuevos: tocar "No voy"
  llama al repositorio con `confirma:false`; el botón que refleja la
  respuesta actual queda resaltado (ícono ✓) y el otro no. Mobile 41→43,
  `flutter analyze` limpio.

## Item 1 — Un anónimo ahora puede cerrar sesión para entrar a otro evento

**Verificación pedida antes del fix.** El modelo confirmado por el usuario:
el anónimo tiene un único evento asociado por sesión, identificado por el
username que eligió al entrar (por link o por el botón "Continuar como
Anónimo" — los dos ya convergen en el mismo diálogo desde la Fase 3). Para
entrar a OTRO evento con otro username hay que cerrar sesión primero y
volver a entrar desde el Login.

**El gap real: un anónimo no tenía ninguna forma de cerrar sesión.**
`cerrarSesion()` (en `SessionController`) ya existía y funcionaba, pero el
único lugar que lo invocaba era el `ListTile` de "Cerrar sesión" en
`ProfileScreen` — y `ProfileScreen` solo es alcanzable a través de
`AppShell` (bottom nav), que `_RootRouter` solo muestra para
`SesionOrganizador`. Una sesión anónima renderiza `EventDetailScreen`
directo, sin bottom nav ni Perfil: no había ningún camino de vuelta al
Login.

**Fix:** ícono de "Salir" (`Icons.logout`) en el AppBar de
`EventDetailScreen`, visible solo cuando `sessionControllerProvider` es
`SesionAnonima`. Llama a `cerrarSesion()`; `_RootRouter` reacciona solo al
cambio de sesión y muestra el Login (mismo mecanismo que ya usa para
aplicar invitaciones pendientes, Fase 3 — no hizo falta lógica de
navegación nueva).

**Validación:**
- `screens_test.dart` — el ícono aparece con sesión anónima y no con
  organizador; tocarlo borra el token guardado.
- `main_test.dart` — test end-to-end sobre `PlanifyApp`: con una sesión
  anónima restaurada del dispositivo, tocar el ícono de salir devuelve a la
  pantalla de Login.
- Mobile 43→45, `flutter analyze` limpio.

## Item 3 — Búsqueda de amigos: email para desambiguar (sin campo username)

**Hallazgo importante, contradice la premisa del pedido.** El flujo
"roto/circular" que describía el usuario (buscador en Perfil, mensaje de
"agregalo desde el perfil", nada implementado del otro lado) **no existe en
el código actual**. `FriendsScreen` ya tiene, en una sola pantalla: buscador
(por nombre o email), botón "Agregar", sección de solicitudes pendientes
con "Aceptar", y la lista de amigos — se llega ahí desde Perfil → "Mis
amigos". Es exactamente lo que pedía el item. Es probable que el feedback
sea de antes de SCRUM-14 (ver [H-16](04-auditoria.md), que agregó "Mis
amigos" a Perfil porque antes no existía nada). No se tocó esa estructura.

**Lo que sí se implementó — email para desambiguar, sin campo `username`.**
Se confirmó con el usuario: no hace falta un `username` único (evita la
migración + pantalla para definirlo que hubiera hecho falta). En cambio, la
búsqueda (que ya buscaba por nombre o email) ahora también **devuelve el
email** en cada resultado, y la pantalla lo muestra en gris debajo del
nombre para diferenciar resultados con nombres parecidos.

**Fix (backend):**
- Nuevo tipo `PersonaBusqueda extends PersonaRef` (con `email`), **solo**
  para `UsuarioRepository.search()` — no se tocó el `PersonaRef` genérico
  que ya usan actor de actividad, asignado de tarea, deudor/acreedor, etc.,
  para no filtrar el email a lugares donde no hace falta.
- `PrismaUsuarioRepository.search`: agrega `email` al `select`.

**Fix (mobile):**
- `Persona.email` (nullable — solo viene en resultados de búsqueda, no en
  la lista de amigos ni en solicitudes pendientes).
- `FriendsScreen`: cada resultado de búsqueda muestra el email como
  `subtitle` en gris (`AppColors.textSecondary`).

**Validación:**
- Backend: `scrum14.test.ts` — el resultado de búsqueda trae el email;
  buscar directamente por fragmento de email también encuentra a la
  persona. Backend 100 tests (se ampliaron aserciones de un test existente,
  no se sumaron `it()` nuevos).
- Mobile: `friends_screen_test.dart` (nuevo, la pantalla no tenía ningún
  test hasta ahora) — el email aparece en gris debajo del resultado;
  enviar solicitud llama al repositorio; una solicitud pendiente se ve y se
  acepta en la misma pantalla. Mobile 45→48, `flutter analyze` limpio.

## Item 6 — Agregar gente al evento: amigos guardados + copiar link

**Hallazgo: el botón de copiar ya existía.** El diálogo de "Invitar"
(`_invitar` en `event_detail_screen.dart`) ya tenía un `FilledButton.icon`
de "Copiar enlace" que copia al portapapeles y muestra una confirmación —
no había que agregarlo. Lo que sí faltaba de verdad era la otra vía: sumar
un amigo ya guardado directo al evento, sin pasar por un link.

**Confirmado con el usuario:** agregar un amigo directo al evento **no**
pide aceptación — se suma de una, igual que ya hace `agregarMiembro` al
sumar un amigo a un grupo (Fase 3, H-10).

**Fix:**
- El ícono de invitar ahora abre un selector con dos opciones: "Agregar
  amigos guardados" (nuevo) y "Compartir link de invitación" (el diálogo de
  siempre, sin cambios).
- "Agregar amigos guardados" reutiliza el selector de amigos ya existente
  (`elegirAmigos`, `friend_picker.dart` — el mismo que ya se usa al crear
  un evento y al gestionar un grupo) y por cada elegido llama a
  `GroupsService.agregarMiembro` (el endpoint `POST /groups/:id/members`
  ya existía — **no hizo falta ningún endpoint nuevo**, solo el `grupoId`
  del evento, que el backend ya devolvía en `/events/:id` pero mobile no
  parseaba). Como agregar a alguien al grupo lo materializa como
  participante de todos sus eventos activos (H-01), automáticamente queda
  sumado a este evento y a cualquier otro evento activo que comparta grupo
  — es el mismo comportamiento que ya tiene "Agregar amigo" en gestión de
  grupo, ahora accesible también desde el evento.
- `DetalleEvento.grupoId` (nuevo campo, plano — mismo patrón que
  `EventoResumen.grupoId` del Item 1).

**Validación:** `screens_test.dart` — el selector ofrece las dos opciones;
elegir un amigo llama a `agregarMiembro` con el `grupoId` correcto y
muestra la confirmación; "Compartir link" sigue mostrando el botón de
copiar (regresión, documenta que ya existía). Mobile 48→51, `flutter
analyze` limpio.

## Item 2 — Actividad reciente: tope de 5 + agrupación

**Definición confirmada con el usuario** (dos reglas distintas según la
pantalla):
- **Home ("Actividad reciente"):** se agrupan entradas consecutivas del
  mismo actor + mismo tipo + **mismo evento**, sin nombrar a nadie más que
  el actor ("Mati saldó su deuda (×3)"). Cada grupo cuenta como **una sola**
  entrada dentro del tope de 5.
- **Log de un evento puntual (`EventDetailScreen`):** ahí sí interesa con
  quién — varias `deuda_saldada` seguidas del mismo actor se fusionan
  nombrando a todas las contrapartes ("Marcos saldó cuentas con Sofía y
  Juan"). No tiene tope de 5 (es el historial completo de ESE evento, no un
  resumen).

**Fix (backend):** `DebtsService.saldar()` (HU-18, el "saldar" puntual
desde el evento) ahora resuelve y guarda el nombre de la contraparte en el
payload (`contraparteNombre`) — antes solo llevaba `deudaId` y `monto`, no
alcanzaba para armar "con quién". `saldarTodo` (compensación cruzada, HU-19)
no se tocó: ya registra una sola entrada agregada por evento afectado.

**Fix (mobile), todo en `activity_presentation.dart`** (el archivo
compartido de formateo de actividad, mismo lugar que ya usan Home y el
evento):
- `agruparActividades(entradas, {limite: 5})` — agrupa por actor+tipo+evento
  consecutivos, cortando en `limite` grupos **sin perder una racha que
  sigue después del corte**: una entrada que ya no entra como grupo nuevo
  igual puede fusionarse con el último grupo visible, así el tope de 5
  líneas no le "come" una racha al usuario que ya estaba mostrando.
  `textoActividadAgrupada` agrega el sufijo "(×N)" cuando corresponde, y
  `home_screen.dart` oculta el monto puntual (`trailing`) de una línea
  agrupada — no tiene sentido mostrar un solo monto para varias.
- `agruparLogDeEvento(entradas)` — agrupa solo `deuda_saldada` consecutivas
  del mismo actor (sin importar tope ni evento, ya está scopeado a uno) y
  junta los nombres de las contrapartes. `textoActividadLogAgrupada` arma
  la frase con la nueva clave `activityDebtSettledWith`.

**Validación:**
- Backend: `api.test.ts` — el payload de `deuda_saldada` al saldar una
  deuda puntual incluye `contraparteNombre`. Backend 100 tests (se amplió
  un test existente).
- Mobile: `activity_grouping_test.dart` (nuevo, tests de lógica pura) — 7
  casos: agrupa consecutivos iguales; no agrupa si se interrumpe con
  otro tipo/actor; no agrupa entre eventos distintos; nunca pasa de 5
  grupos pero sigue fusionando el último; el log del evento nombra
  contrapartes; una sola deuda no cambia el texto; tipos distintos no se
  agrupan entre sí. Más 2 tests de integración en `screens_test.dart`
  (Home muestra "(×3)" sin monto y sin perder la actividad distinta;
  el log del evento nombra a las dos contrapartes). Mobile 51→60,
  `flutter analyze` limpio.

## Item 5 — El horario fijado por el organizador se distingue en el heatmap

**Color reutilizado del design system, sin agregar uno nuevo.**
`AppColors.warning` (#F5A623, ámbar) ya existía en
[03-design-system.md](03-design-system.md) — es el mismo que usa el badge
"PENDIENTE". Se reutiliza tal cual para el bloque fijado, en vez de
introducir un color nuevo que rompiera la paleta ya definida.

**Fix:**
- `WeeklyAvailabilityGrid` (`core/widgets/`) recibe un nuevo parámetro
  opcional `slotFijado: AvailabilitySlot?`. Esa celda puntual se pinta con
  `AppColors.warning` y muestra un ícono de estrella (`Icons.star`) centrado
  en vez del conteo de disponibles — se nota que es EL horario, no solo un
  bloque con buena disponibilidad.
- `EventConfigScreen._slotFijado`: traduce `evento.fechaHoraInicio` (una
  fecha real) al `AvailabilitySlot` (día de la semana + hora) que usa la
  grilla — es el cálculo inverso del que ya hacía `_confirmarHorario` para
  ir de slot a fecha. Solo se muestra si `evento.estado == 'confirmado'`
  y hay fecha (un evento en planificación no tiene horario fijado todavía).

**Validación:**
- `widgets_test.dart` — 2 tests nuevos: con `slotFijado` se ve la estrella y
  no el conteo; sin `slotFijado` no aparece ninguna estrella.
- `event_config_screen_test.dart` — 2 tests nuevos: un evento `confirmado`
  con `fechaHoraInicio` muestra la estrella en el heatmap; uno sin
  confirmar no muestra ninguna. Se agregó `fechaHoraInicio` como parámetro
  de `FakeEventsRepository.detalleDeEjemplo` para poder armar el caso.
- Mobile 60→64, `flutter analyze` limpio.

---

# Fase 5 — 5 mejoras de producto (rango de fechas, rango horario, visual, amigos)

> Cada item con su propia branch/PR y su test. Orden de implementación
> (por dependencias, confirmado con el usuario): 1 (rango de fechas) → 5
> (rango horario, depende del 1) → 2 (visual, independiente) → 3 (visual,
> independiente) → 4 (perfil de amigo, depende de que 1 y 5 ya existan para
> que la disponibilidad comparada tenga sentido).

## Item 1 — Rango de fechas calendario del evento

**Modelo de datos, ver [ADR 0001](adrs/0001-rango-fechas-evento.md).**
`Evento` gana `rangoInicio`/`rangoFin` (obligatorios) y `extensionesRango`
(contador). Migración `20260804090000_evento_rango_fechas` con backfill
para los eventos ya existentes (`rangoInicio = createdAt`,
`rangoFin = createdAt + 14 días`).

**Fix (backend):**
- `EventsService.crear` ahora exige `rangoInicio`/`rangoFin` (HU-06):
  valida que sean fechas válidas, que `rangoInicio <= rangoFin` y que
  `rangoFin` no esté en el pasado. Pasa a depender de `Clock` (antes no lo
  necesitaba).
- `EventsService.chequearExtensionRango(eventoId)` (nuevo): si el evento
  sigue en `planificacion` y `ahora > rangoFin`, extiende `rangoFin` 14
  días (`extenderRango`, nuevo en `EventoRepository`) y registra actividad
  `rango_extendido` (nuevo `ActivityType`, notifica a los participantes vía
  el mismo `ActivityLogService`/`NotificationsService` de siempre — sin
  infraestructura nueva). **Tope de 1 extensión automática** (confirmado
  con el usuario): alcanzado el tope, no extiende más.
- Se llama de forma lazy desde `GET /events/:id` (mismo patrón que
  `listUpcoming/listPast` con `ahora: Date`, H-09) — no hay cron.
- `EventsQueryService.detalle` agrega `necesitaDecisionRango: boolean`
  (derivado, no persistido): true cuando el rango venció y ya se usó la
  única extensión, para que la UI avise que el organizador tiene que
  decidir a mano. No hace falta un flujo nuevo para "decidir": confirmar un
  horario o cancelar el evento ya eran posibles con los controles
  existentes.

**Fix (mobile):**
- `CreateEventScreen`: el paso 1 (nombre + lugar) gana un selector de rango
  de fechas (`showDateRangePicker`), con default hoy→hoy+14 días editable
  — sigue siendo "2 pasos" (NFR#3), no se agregó un paso nuevo.
- `DetalleEvento` gana `rangoInicio`/`rangoFin`/`necesitaDecisionRango`.
  `EventConfigScreen` muestra "Buscando horario entre X e Y" mientras el
  evento está en planificación, y un banner de aviso cuando
  `necesitaDecisionRango` es true.
- `activity_presentation.dart`: nuevo caso `rango_extendido` (ícono
  calendario, texto sin nombrar actor porque lo dispara el sistema, no una
  persona).

**Decisiones confirmadas con el usuario antes de implementar:** sí
notificar al extender (reutilizando el sistema de actividad/push
existente); tope de **1** extensión automática (no 3, no ilimitado); la
disponibilidad semanal del perfil se proyecta día por día sobre cada fecha
calendario dentro del rango del evento — sin cambiar el modelo de
`DisponibilidadSlot` (sigue siendo día-de-semana + hora, no fecha exacta).

**Validación:**
- Backend: `events.service.test.ts` — nuevo describe "extensión automática
  del rango": no toca el rango si no venció; extiende 14 días y notifica
  si venció; no extiende un evento ya confirmado; deja de extender después
  del tope. Más un test de rango inválido (`rangoInicio > rangoFin`,
  `rangoFin` en el pasado). Se actualizaron los tests existentes de
  creación de evento (`events.service.test.ts`, `audit-regression.test.ts`,
  `api.test.ts`) para pasar un rango válido. Backend 100→105,
  `tsc --noEmit` y `eslint .` limpios.
- Mobile: `create_event_screen_test.dart` (nuevo) — el rango por defecto es
  visible en el paso 1; crear el evento manda el rango elegido al
  repositorio. `event_config_screen_test.dart` — 2 tests nuevos: un evento
  en planificación muestra su rango vigente; un evento con
  `necesitaDecisionRango` muestra el banner de aviso. Mobile 64→68,
  `flutter analyze` limpio.
