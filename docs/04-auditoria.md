# Planify — Auditoría completa del estado del código (Fase 1)

> **Fecha:** 2026-08-02 · **Alcance:** todo el repositorio (`backend/`, `mobile/`, `infra/`, `.github/`, `docs/`).
> **Método:** lectura de código de punta a punta (UI → lógica → persistencia → cableado), comparación contra el Project Charter ([00-entendimiento.md](00-entendimiento.md)), las 17 épicas de Jira (traídas en vivo el 2026-08-02), el plan ([01-plan-de-ejecucion.md](01-plan-de-ejecucion.md)) y las decisiones ([02-decisiones.md](02-decisiones.md)); ejecución real de tests, typecheck, lint y análisis; y foco explícito en los **puntos de integración entre features**.
>
> **Regla aplicada:** no se confió en el estado declarado por Jira ni por el plan. Cada ítem se verificó contra el código. Donde el plan dice "✅ Implementado" pero el código dice otra cosa, gana el código y queda documentado.

---

## 0. Resumen ejecutivo

- **La app compila y los tests pasan** (backend: 70 tests / 5 suites; mobile: 26 tests). `tsc` del backend pasa. **Pero el CI quedaría en rojo** en ambos pipelines (eslint del backend + `flutter analyze`), y **nada se ejecutó nunca contra una base de datos real** — todo está validado con *fakes* en memoria, que por diseño no ven los bugs de integración entre módulos.
- **El núcleo del MVP (acceso anónimo, evento en 2 pasos, disponibilidad + heatmap, confirmación, gastos + motor de deudas, log de actividad, historial, balances con compensación cruzada) está construido y es de buena calidad.** El motor de deudas (NFR#4) es sólido y está bien testeado.
- **El hallazgo de calibración (anónimo que no aparece al asignar un gasto) es real como *clase* de bug**, y su causa raíz está identificada en dos formas concretas (una de caché/staleness y una estructural). Ver [H-01](#h-01) y [H-02](#h-02).
- **Falta implementar bloques enteros comprometidos en Jira:** autenticación completa / amigos (SCRUM-14), notificaciones (SCRUM-15), IA de auto-generación (SCRUM-17) y todos los despliegues a Play Store (SCRUM-18/19/20/21). Detalle en §4.

**Conteo de hallazgos:** 2 bloqueantes · 5 altos · 6 medios · 6 bajos = **19 hallazgos**. Cobertura de backlog implementada estimada: **~55–60 % del alcance comprometido** (núcleo MVP ~85 %; auth/notif/IA/deploys ~0–15 %). Detalle en §5.

---

## 1. Realidad de Jira vs. plan vs. código

**Traído en vivo de `planify2026.atlassian.net` (proyecto SCRUM) el 2026-08-02:**

- Existen **17 épicas** (SCRUM-5 … SCRUM-21) con sus fechas de inicio/fin. **Las fechas coinciden exactamente con el plan.** No se modificó ninguna.
- **Las 17 épicas están en estado "Tareas por hacer" (To Do), todas con `description: null`.** O sea: Jira **no refleja** el avance real del código (que tiene 8 épicas sustancialmente implementadas) y **no contiene las historias HU-XX** — las HU-01…HU-48 viven **solo** en el plan, nunca se cargaron como issues en Jira.
- **SCRUM-1 a SCRUM-4** siguen siendo los ítems de ejemplo (`Tarea 1/2/3`, `Subtarea 2.1`) — basura de plantilla. SCRUM-2 y SCRUM-3 figuran "En curso". El plan ya recomendaba borrarlos.
- SCRUM-22 ("Tarea de prueba") efectivamente ya no existe (borrada, como decía [Duda #20](02-decisiones.md)).

**Consecuencia para la trazabilidad:** la columna "Estado en Jira" es uniformemente **"To Do"** para todo, y por lo tanto **inútil como fuente de verdad de avance**. Este documento reconstruye el estado real desde el código. Ver [H-18](#h-18) sobre la higiene de Jira.

---

## 2. Matriz de trazabilidad — Charter → Épica Jira → Estado real en código

Leyenda de estado real: ✅ implementado y probado · 🟡 parcial/incompleto · 🐞 implementado pero con bug · 🔴 no implementado · ⚪ backlog opcional.

### Requerimientos funcionales

| # (Charter) | Requerimiento | Épica (estado Jira) | Estado real en **código** | Evidencia / hallazgo |
|---|---|---|---|---|
| FR1 | Cuenta anónima | SCRUM-7 (To Do) | 🟡 | Se une por **link de invitación**; no hay "anónimo sin evento". Persistido OK como `Participante`. [H-08](#h-08) |
| FR2 | Creación de eventos | SCRUM-8 (To Do) | 🟡 | Wizard 2 pasos ✅, pero el paso 2 no deja elegir miembros sueltos. [H-05](#h-05) |
| FR3 | Disponibilidad semanal | SCRUM-9 (To Do) | ✅/🟡 | Disponibilidad por evento ✅ (grilla + heatmap). La de Perfil es **solo local**. [H-14](#h-14) |
| FR4 | Confirmación de asistencia | SCRUM-10 (To Do) | ✅ | Backend + UI OK. |
| FR5 | Creación de grupos | SCRUM-8 (To Do) | 🟡 | Grupo se crea solo con el organizador; sus miembros no se vuelven participantes. [H-01](#h-01) |
| FR6 | Invitación a evento | SCRUM-7 (To Do) | ✅/🟡 | Deep link + token manual ✅. `usosMaximos`/expiración no se aplican. [H-15](#h-15) |
| FR7 | Gastos (multi-acreedor y deudor) | SCRUM-11 (To Do) | 🟡 | **Backend** soporta multi-acreedor; **UI** solo un pagador. [H-06](#h-06) |
| FR8 | Registro de tareas | SCRUM-12 (To Do) | ✅ | CRUD + estados OK. Menor: completar no valida asignado. |
| FR9 | Deudas entre eventos | SCRUM-11 (To Do) | ✅ | Compensación cruzada + saldar en cascada, bien testeado. |
| FR10 | Chat por grupo (→ log actividad) | SCRUM-13 (To Do) | ✅ | Feed automático + no-leídos. Reinterpretado ([Duda #9](02-decisiones.md)). |
| FR11 | Registro de cuenta | SCRUM-14 (To Do) | 🔴 | "Crear cuenta" es inerte ("próximamente"). |
| FR12 | Gestión de identidad | SCRUM-14 (To Do) | 🔴 | Sin editar perfil/avatar, sin recuperar contraseña. [H-16](#h-16) |
| FR13 | Gestión de amigos | SCRUM-14 (To Do) | 🔴 | Sin sistema de amigos; "agregar miembro" pide un UUID a mano. [H-10](#h-10) |
| FR14 | Notificaciones | SCRUM-15 (To Do) | 🔴 | Endpoint **501**; campana decorativa. |
| FR15 | Coincidencias disp. entre amigos | — (backlog) | ⚪ | No implementado (opcional). |
| FR16 | Ubicaciones usuales | — (backlog) | 🟡 | Texto libre (como se decidió); favoritos = backlog. |
| FR17 | Historial | SCRUM-16 (To Do) | 🐞 | Agrupa por mes + estado de saldo ✅, pero un evento `confirmado` aparece en Próximos **y** en Historial. [H-09](#h-09) |
| FR18 | IA auto-generación de eventos | SCRUM-17 (To Do) | 🔴 | Endpoint **501**; sin cliente Gemini. |

### Requerimientos no funcionales

| # | Requerimiento | Estado real | Evidencia / hallazgo |
|---|---|---|---|
| NFR1 | Lanzamiento en Play Store | 🔴 | Sin firma de release ni build; AWS sin provisionar. |
| NFR2 | Restricción por tipo de usuario | 🟡 | Backend con guards ✅. **UI** muestra acciones de organizador a cualquier participante. [H-04](#h-04) |
| NFR3 | Evento en 2 pasos | ✅ | `create_event_screen.dart`. |
| NFR4 | Exactitud financiera | ✅ | `debt-engine.ts` en centavos enteros, `toCents` vía string, 17+ tests. |
| NFR5 | Guidelines Android/iOS | ✅ | Material 3 + design system. iOS fuera de alcance. |
| NFR6 | Multi-idioma | ✅/🟡 | ES/EN **paridad total** (143 claves). App fija en `es`, sin selector. [H-13](#h-13) |
| NFR7 | Cifrado en tránsito y reposo | 🟡 | Reposo en dispositivo (secure storage) ✅. **Sin HTTPS/TLS** (`baseUrl` es `http://`). [H-03](#h-03) |
| NFR8 | Notificaciones 99 % < 60 s | 🔴 | Notificaciones no implementadas. |
| NFR9 | 2.000 concurrentes/día | ⚪ | Objetivo de diseño, sin prueba de carga ([Duda #11](02-decisiones.md)). |

### Requerimientos de proyecto (selección verificable)

| # | Requerimiento | Estado real | Nota |
|---|---|---|---|
| RP7 | Probar cada funcionalidad incrementalmente | ✅ | 70 tests backend + 26 mobile (con *fakes*, sin DB). |
| RP8 | Publicar versión funcional y documentada | 🟡 | Documentada sí; desplegada no; sin correr contra DB real. [H-07](#h-07) |
| DoD | CI (lint + build + test) en verde | 🐞 | Backend CI: **verde** (ver corrección en [H-11](#h-11)). Mobile CI: **rojo** — `flutter analyze` sale ≠0 por 2 *infos* [H-12](#h-12). |

---

## 3. Hallazgos detallados

> Cada hallazgo: **ID · Módulo · Descripción (qué se rompe y cuándo) · Severidad · Causa raíz · Épica Jira · Estado**.

### Bloqueantes

<a id="h-01"></a>
#### H-01 — Los miembros de un grupo nunca se vuelven participantes del evento
- **Módulo:** backend `events.service.ts` + `participante.prisma.repository.ts` · mobile `create_event_screen.dart`.
- **Descripción:** al crear un evento (con grupo nuevo o reutilizando uno existente), **solo el organizador** se crea como `Participante`. Los demás miembros del grupo quedan como `MiembroGrupo` pero **no** como participantes del evento. Como la lista para asignar gastos/tareas, confirmar asistencia y cargar disponibilidad sale de `Participante` (`listByEvento`), esas personas **no aparecen** en ninguna de esas pantallas. No existe ningún endpoint ni flujo que materialice a un miembro registrado como participante (el `crearParticipantGuard` **exige** un participante ya existente, no lo crea).
- **Severidad:** **Bloqueante** para el producto completo (juntada entre gente registrada: no se les puede asignar un gasto). El MVP "organizador + anónimos por link" sí funciona, por eso los tests con *fakes* no lo detectan.
- **Causa raíz:** la participación en el evento está **desacoplada** de la pertenencia al grupo, y no hay ningún punto de integración que las una. Es la forma estructural del bug de calibración (el mismo síntoma que el anónimo, pero para miembros registrados).
- **Jira:** SCRUM-8 / SCRUM-11. **Estado: incompleto/roto.**

<a id="h-02"></a>
#### H-02 — Lista de participantes cacheada: un recién unido no aparece al asignarle un gasto
- **Módulo:** mobile `home_providers.dart` (`eventDetailProvider`) + `event_detail_screen.dart`.
- **Descripción:** `eventDetailProvider` es un `FutureProvider` (cachea, sin `autoDispose`) y la pantalla de detalle **no tiene pull-to-refresh** ni polling. Secuencia que reproduce el hallazgo de calibración: el organizador abre el evento (se cachean los participantes: solo él) → un invitado entra como anónimo por el link → el organizador, **sin** hacer ninguna acción que invalide el provider, toca "Agregar gasto" → el diálogo se arma con `evento.participantes` **cacheado** → **el anónimo recién unido no está en la lista**. Coincide con el síntoma reportado ("queda logueado pero no aparece al asignarle un gasto").
- **Severidad:** **Bloqueante** (rompe un flujo central en el uso real; el backend y el parseo son correctos, por eso "funciona" en aislamiento).
- **Causa raíz:** estado compartido entre dos features (unión de participante ↔ detalle de evento) que solo se sincroniza cuando el que mira ejecuta una acción; falta invalidación por evento entrante o un `RefreshIndicator` en el detalle.
- **Jira:** SCRUM-7 ↔ SCRUM-11 (integración). **Estado: roto (integración).**
- **Nota de verificación:** con el backend actual, un anónimo unido por link **sí** aparece si la vista se refresca (hay test verde que lo cubre: `api.test.ts` "dividirEntre" con dos anónimos). Es decir: el bug **no** está en el backend ni en el parseo, sino en la **frescura del estado en la UI**.

### Altos

<a id="h-03"></a>
#### H-03 — Sin cifrado en tránsito (NFR#7): la API viaja por HTTP plano
- **Módulo:** mobile `core/network/api_client.dart` · infra.
- **Descripción:** `baseUrl` es `http://10.0.2.2:3000` (y el despliegue documentado apunta a `http://<ec2-host>:3000`). Datos sensibles que el charter marca explícitamente (disponibilidad semanal, historial de gastos, tokens de sesión) viajan **en claro**. `app.ts` usa `helmet()` y `cors()` pero eso no aporta TLS.
- **Severidad:** **Alto** (incumple un NFR explícito y expone tokens).
- **Causa raíz:** no hay terminación TLS (reverse proxy / certificado) porque AWS no está provisionado; la app tampoco fuerza `https`.
- **Jira:** transversal (SCRUM-6 / SCRUM-18). **Estado: incompleto (depende de infra).**

<a id="h-04"></a>
#### H-04 — La UI muestra acciones de organizador a cualquier participante (incl. anónimo)
- **Módulo:** mobile `core/models/models.dart` (`DetalleEvento.organizador`) + `event_detail_screen.dart`.
- **Descripción:** `DetalleEvento.organizador` devuelve `participantes.where((p) => p.esOrganizador).firstOrNull` — el organizador **del evento**, sin importar **quién** está mirando. La pantalla usa `evento.organizador != null` para mostrar el menú "Cancelar evento" / "Cerrar gastos" y el hint "tocá para confirmar el horario". Como el organizador siempre está en la lista, **un participante anónimo ve y puede tocar esas acciones**. El backend las rechaza con 401 (guard `soloOrganizador`), así que **no es una brecha de seguridad**, pero es un bug de permisos en la UI (NFR#2) y una UX rota: tocar una acción central devuelve un error confuso.
- **Severidad:** **Alto** (NFR#2 + acciones centrales que fallan para no-organizadores).
- **Causa raíz:** el modelo de detalle no lleva "quién soy yo en este evento"; no se compara el `participanteId` propio contra `esOrganizador`.
- **Jira:** SCRUM-8 / SCRUM-10 / NFR#2. **Estado: roto (UI).**

<a id="h-05"></a>
#### H-05 — HU-04 (elegir miembros individuales) no existe en la UI
- **Módulo:** mobile `create_event_screen.dart`.
- **Descripción:** el paso 2 solo permite elegir un grupo existente **o** tipear el nombre de un grupo nuevo. **No hay selector de miembros.** `EventsRepository.crear` y el backend **sí** aceptan `miembroUsuarioIds` (plumbing completo), pero el wizard nunca lo envía. Resultado: un grupo "nuevo" se crea siempre con un solo miembro (el organizador).
- **Severidad:** **Alto** (historia comprometida HU-04 sin UI; combinado con [H-01](#h-01) deja los eventos con un único participante real salvo anónimos).
- **Causa raíz:** falta la pantalla/selector de miembros (y depende de FR13 amigos, [H-10](#h-10), para tener a quién elegir).
- **Jira:** SCRUM-8. **Estado: incompleto.**

<a id="h-06"></a>
#### H-06 — FR7 a medias: la UI de gasto solo admite un pagador
- **Módulo:** mobile `events/widgets/expense_dialog.dart`.
- **Descripción:** el diálogo tiene un único `DropdownButton` de "quién pagó" → arma `acreedores` con **un** aporte. El charter (FR7) pide **múltiples acreedores**; el backend lo soporta y valida sumas, pero la UI no lo expone.
- **Severidad:** **Alto** (requerimiento funcional incompleto; ya reconocido en [04-notas-de-implementacion.md](04-notas-de-implementacion.md) §6).
- **Causa raíz:** falta el selector multi-acreedor con montos por persona.
- **Jira:** SCRUM-11 (HU-13). **Estado: incompleto.**

<a id="h-07"></a>
#### H-07 — Nada corrió nunca contra una base de datos real
- **Módulo:** infra / backend `prisma`.
- **Descripción:** la migración `20260728000000_init` (14 tablas + 5 enums, consistente con el schema) **nunca se aplicó**; `docker-compose.yml` levanta Postgres + backend pero **no ejecuta `prisma migrate deploy` ni el seed** al arrancar (la DB quedaría vacía). Toda la validación es con *fakes* en memoria. Los bugs de integración ([H-01](#h-01), [H-02](#h-02)) son justamente los que este vacío oculta.
- **Severidad:** **Alto** (riesgo de que el "todo verde" no represente el comportamiento real).
- **Causa raíz:** falta un paso de arranque (migrate + seed) en compose/Dockerfile y una corrida E2E real. AWS sin provisionar.
- **Jira:** SCRUM-6 / SCRUM-18. **Estado: incompleto.**

### Medios

<a id="h-08"></a>
#### H-08 — "Continuar como Anónimo" exige un token; se desvía del mockup/HU-01
- **Módulo:** mobile `login_screen.dart` (`_pedirTokenManual`).
- **Descripción:** el botón "Continuar como Anónimo" del mockup, que sugiere entrar sin más, abre un diálogo que **pide un token de invitación**. Es coherente con [Duda #19](02-decisiones.md) (el anónimo no crea eventos, solo se une) y hasta hay un test que lo afirma, pero **no coincide** con el AC literal de HU-01 ("se ofrece Continuar como Anónimo en Login; genera Participante…") ni con el mockup. Es una decisión de diseño razonable no documentada como tal.
- **Severidad:** **Medio** (desviación de spec/UX, no bug).
- **Causa raíz:** reinterpretación correcta pero no registrada en decisiones. **Jira:** SCRUM-7. **Estado: funciona, desviación de spec.**

<a id="h-09"></a>
#### H-09 — Próximos vs. Historial se parten por estado, no por fecha
- **Módulo:** backend `evento.prisma.repository.ts` (`listUpcomingForUsuario` / `listPastForUsuario`).
- **Descripción:** "Próximos" = estado ∈ {planificacion, confirmado}; "Historial" = {finalizado, cancelado, **confirmado**}. Un evento `confirmado` aparece **en las dos pantallas** a la vez, sin mirar `fechaHoraInicio`. Además, un evento cuya fecha ya pasó pero sigue `confirmado`/`planificacion` nunca "cae" a pasado por tiempo.
- **Severidad:** **Medio** (duplicación e inconsistencia semántica en Home/Historial).
- **Causa raíz:** no hay partición por fecha (`fechaHoraInicio < now`) entre próximo y pasado. **Jira:** SCRUM-16. **Estado: bug/incompleto.**

<a id="h-10"></a>
#### H-10 — Gestión de amigos (FR13) inexistente; "agregar miembro" pide un UUID a mano
- **Módulo:** mobile `group_manage_sheet.dart` · backend `groups.service.ts`.
- **Descripción:** no hay sistema de amigos ni directorio de usuarios. "Agregar miembro" abre un `TextField` para tipear un `usuarioId` (UUID) — inusable en la práctica (nadie conoce el UUID de otro). La sección "Mis amigos" del mockup de Perfil **no está**. HU-32/33/34 están cableadas pero solo la de renombrar/abandonar es usable.
- **Severidad:** **Medio** (FR13 comprometido; bloquea de hecho a [H-05](#h-05)). **Jira:** SCRUM-14. **Estado: no implementado.**

<a id="h-11"></a>
#### H-11 — Lint incompleto (CORREGIDO en Fase 2: el CI **no** estaba en rojo)
- **Módulo:** `backend/eslint.config.js`, `package.json` (script `lint`).
- **Descripción original (imprecisa):** se reportó "CI backend en rojo" porque `eslint .` daba 2 errores (el `eslint.config.js` usa `require()`, que su propia regla prohíbe) + 2 *warnings* en `api.test.ts`.
- **Corrección (verificada en Fase 2):** el comando **real** del workflow es `npm run lint` = `eslint "src/**/*.ts"`, que **solo lintea `src`** y **salía 0 (verde)**. Los errores aparecían solo al lintear *todo* (`eslint .`), que el CI no hacía. **El CI del backend NO estaba en rojo por lint.** El hallazgo se rebaja a "lint con cobertura incompleta".
- **Severidad:** **Bajo** (calidad, no CI). **Jira:** SCRUM-6. **Estado (Fase 2): corregido** — regla desactivada para `*.js`, vars usadas, y script ampliado a `eslint .` (ahora limpio y cubre tests + config).

<a id="h-12"></a>
#### H-12 — CI del mobile en rojo (`flutter analyze`)
- **Módulo:** mobile `event_detail_screen.dart:182`, `expense_dialog.dart:100` + `.github/workflows/mobile-ci.yml`.
- **Descripción:** `flutter analyze` reporta 2 *infos* (`use_build_context_synchronously` y `DropdownButtonFormField.value` deprecado → usar `initialValue`) y **sale con código ≠ 0**, así que el paso "Analyze" del workflow falla → **pipeline en rojo**.
- **Severidad:** **Medio** (DoD; fix trivial). **Jira:** SCRUM-6. **Estado: roto (CI).**

<a id="h-13"></a>
#### H-13 — App fija en español, sin selector, pese a EN completo
- **Módulo:** mobile `main.dart` (`locale: Locale('es')`).
- **Descripción:** los `.arb` ES/EN tienen **paridad total (143 claves, solo `appName` idéntico)** — NFR#6 muy bien resuelto — pero la app fuerza `es` y no hay switcher, así que el inglés no es alcanzable por el usuario. Coherente con [F5](02-decisiones.md) (MVP en ES), pero conviene exponer un selector para el producto final.
- **Severidad:** **Medio** (NFR#6 alcanzable solo en ES). **Jira:** SCRUM-14/transversal. **Estado: incompleto.**

### Bajos

<a id="h-14"></a>
#### H-14 — Disponibilidad de Perfil solo en local
- **Módulo:** mobile `profile_availability_provider.dart`. La grilla de Perfil (FR3) se guarda en `secure storage` del dispositivo, **nunca** en el backend (no hay endpoint de disponibilidad de perfil). Pre-llena la del evento. No sincroniza entre dispositivos. **Severidad:** Bajo. **Estado:** incompleto (por diseño MVP).

<a id="h-15"></a>
#### H-15 — Invitaciones sin límite de usos ni expiración efectiva
- **Módulo:** backend `invitations.service.ts`. `crear` no setea `expiraEn` ni `usosMaximos`; `resolver` solo chequea `expiraEn` (siempre null) y nunca cuenta usos. Un link sirve para siempre y para infinitos usos. **Severidad:** Bajo. **Estado:** incompleto.

<a id="h-16"></a>
#### H-16 — Perfil sin avatar editable ni edición de nombre (FR12)
- **Módulo:** mobile `profile_screen.dart`. El mockup muestra "avatar grande editable" y nombre; la implementación muestra iniciales no editables y no permite editar el nombre. **Severidad:** Bajo. **Estado:** no implementado.

<a id="h-17"></a>
#### H-17 — Brechas de UI vs. mockups (varias, menores)
- **Módulo:** mobile varios. (a) La campana de `AppHeader` es **decorativa** (un `Icon`, sin `onPressed`). (b) El **carrusel de avatares de grupos** del mockup de Groups no está (solo cards). (c) El **detalle de evento no tiene pull-to-refresh** (agrava [H-02](#h-02)). (d) **No hay vista de lista de gastos** (solo un contador y las deudas resultantes; existe `GET /events/:id/expenses` sin consumir). (e) El FAB es genérico "crear evento" en Home/Groups/Balances (el mockup insinuaba acciones distintas por pantalla). **Severidad:** Bajo. **Estado:** incompleto.

<a id="h-18"></a>
#### H-18 — Higiene de Jira y trazabilidad fuera de Jira
- **Módulo:** proceso. Las 17 épicas están en "To Do" (no reflejan avance), **no hay historias HU-XX cargadas** (solo en el plan), y **SCRUM-1..4** (ejemplos) siguen ahí. La trazabilidad real vive solo en `docs/`. **Severidad:** Bajo (proceso). **Estado:** a corregir en Jira.

<a id="h-19"></a>
#### H-19 — `docs/ui-reference/` no existe
- **Módulo:** docs. La consigna de auditoría pedía comparar contra capturas en `docs/ui-reference/`; ese directorio **no está** en el repo. La comparación de UI se hizo contra [00-ui-entendimiento.md](00-ui-entendimiento.md) (análisis textual de los mockups de Figma). **Severidad:** Bajo (proceso/insumo faltante). **Estado:** insumo ausente.

---

## 4. Backlog pendiente de implementación completa

Todo lo que está comprometido en Jira/plan y **no** está terminado en el código (más allá de los bugs de §3). Ordenado por prioridad del backlog.

### Comprometido en Jira (no opcional)

1. **SCRUM-14 — Autenticación / usuarios (FR11/12/13).** No implementado salvo el login del organizador semilla. Falta: registro real (Cognito), login de usuarios registrados, recuperación de contraseña, edición de perfil/avatar (HU-30), **gestión de amigos** (HU-31) y hacer usable la gestión de miembros de grupo (HU-32/33/34 hoy pide UUID). → [H-10](#h-10), [H-16](#h-16).
2. **SCRUM-15 — Notificaciones (FR14, HU-35, NFR#8).** Endpoint `POST /notifications/register-device` devuelve **501**. Falta: integración SNS/Pinpoint, registro de device, disparo desde `ActivityLogService.registrar` (hay un `TODO` marcado), y la campana funcional.
3. **SCRUM-17 — IA de auto-generación de eventos (FR18, HU-42/43/44b).** Endpoint `POST /events/generate-from-text` devuelve **501**. Falta: módulo `ai-events`, cliente **Gemini**, prompt con salida JSON, pre-llenado del wizard, matching de nombres contra amigos, sugerencia de tareas, y fallback manual.
4. **SCRUM-18/19/20/21 — Despliegues a Play Store (NFR#1).** Nada desplegado. Falta: firma de release (hoy sin `signingConfig`), ficha de Play Console, build de release, provisioning AWS (EC2+RDS+Cognito+SNS), aplicar migración + seed contra RDS, y HTTPS/TLS ([H-03](#h-03)).
5. **Completar FR7 (multi-acreedor en UI)** y **HU-04 (selector de miembros)** — [H-06](#h-06), [H-05](#h-05).
6. **SCRUM-16 / SCRUM-8** — arreglar la partición Próximos/Historial por fecha ([H-09](#h-09)) y la propagación grupo→participantes ([H-01](#h-01)).
7. **CI en verde** (backend eslint + mobile analyze) y **corrida E2E real** contra Docker/DB ([H-11](#h-11), [H-12](#h-12), [H-07](#h-07)).

### Backlog opcional (sin épica ni fecha en Jira — solo si sobra tiempo)

- **HU-B1** mensajería libre dentro del evento · **HU-B2** geolocalización + Google Maps · **HU-B4** coincidencias de disponibilidad entre amigos fuera de un evento · **HU-B5** ubicaciones usuales como favoritos. Ninguno iniciado (esperado).

---

## 5. Resumen cuantitativo

### Hallazgos por severidad

| Severidad | Cantidad | IDs |
|---|---|---|
| 🔴 Bloqueante | 2 | H-01, H-02 |
| 🟠 Alto | 5 | H-03, H-04, H-05, H-06, H-07 |
| 🟡 Medio | 6 | H-08, H-09, H-10, H-11, H-12, H-13 |
| 🔵 Bajo | 6 | H-14, H-15, H-16, H-17, H-18, H-19 |
| **Total** | **19** | |

### Hallazgos por módulo

| Módulo | Hallazgos |
|---|---|
| Mobile — eventos/gastos (integración) | H-01, H-02, H-04, H-05, H-06, H-17 |
| Mobile — auth/perfil/grupos | H-08, H-10, H-13, H-14, H-16 |
| Backend — queries/invitaciones | H-09, H-15 |
| Infra / CI / despliegue | H-03, H-07, H-11, H-12 |
| Proceso (Jira / insumos) | H-18, H-19 |

### Cobertura del backlog implementada (estimación por épica, contra código real)

| Épica | Feature | Cobertura real |
|---|---|---|
| SCRUM-7 | Acceso anónimo | ~90 % |
| SCRUM-8 | Eventos + grupos | ~70 % (H-01, H-05) |
| SCRUM-9 | Disponibilidad + heatmap | ~90 % |
| SCRUM-10 | Confirmación asistencia | ~95 % |
| SCRUM-11 | Gastos + motor de deudas | ~80 % (H-06, H-02) |
| SCRUM-12 | Tareas | ~90 % |
| SCRUM-13 | Log de actividad | ~90 % |
| SCRUM-16 | Historial | ~80 % (H-09) |
| SCRUM-6 | Setup infra + CI | ~60 % (CI rojo, sin AWS/DB real) |
| SCRUM-14 | Auth/usuarios/amigos | ~15 % |
| SCRUM-18 | Deploy MVP | ~10 % |
| SCRUM-15 | Notificaciones | ~0 % |
| SCRUM-17 | IA auto-generación | ~0 % |
| SCRUM-19/20/21 | Despliegues 2/3/final | ~0 % |

- **Núcleo funcional del MVP (SCRUM-7 a 13 + 16):** ~**85 %** implementado (con los bugs de integración de §3).
- **Alcance total comprometido (17 épicas):** ~**55–60 %** implementado en código.

### Estado de la verificación automática (corrida real 2026-08-02)

| Chequeo | Resultado |
|---|---|
| Backend `npm test` (Jest) | ✅ 70/70 (5 suites) |
| Backend `tsc --noEmit` | ✅ OK |
| Backend `eslint` | ❌ 2 errores (+2 warnings) → [H-11](#h-11) |
| Mobile `flutter test` | ✅ 26/26 |
| Mobile `flutter analyze` | ❌ 2 infos → [H-12](#h-12) |
| Migración aplicada / corrida contra DB real | ❌ nunca → [H-07](#h-07) |

> **Advertencia metodológica:** los 96 tests corren con *fakes* en memoria que implementan las interfaces de repositorio. Validan cada pantalla/servicio en aislamiento, **no** los puntos de integración entre features. Por eso H-01 y H-02 conviven con "todo verde".

---

## 6. Recomendación de priorización para la Fase 2

1. **H-01 + H-02** (bloqueantes de integración) — arreglar la propagación grupo→participantes y la frescura del detalle. Es el corazón del hallazgo de calibración.
2. **H-04** (permisos en UI) y **H-11/H-12** (CI en verde) — baratos y de alto impacto en calidad/DoD.
3. **H-07 + H-03** — corrida E2E real (Docker + migrate + seed) y TLS; sin esto no se puede confiar en el resto.
4. **H-05 + H-06 + H-09** — completar FR7 (multi-acreedor), HU-04 (miembros) y la partición Próximos/Historial.
5. **Backlog mayor:** SCRUM-14 (auth+amigos), SCRUM-15 (notificaciones), SCRUM-17 (IA), SCRUM-18-21 (despliegues).
6. **Bajos y proceso:** H-13/14/15/16/17 + higiene de Jira (H-18).

> **Pendiente de tu decisión (Fase 2):** confirmá si querés que arranque por este orden o si repriorizás algo antes de que toque código. No avanzo a corregir hasta tu "APROBADO, avanzá a fase 2".
