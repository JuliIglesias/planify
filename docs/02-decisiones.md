# Planify — Bitácora de decisiones (Fase 1)

> Se completa a medida que el usuario responde cada duda planteada en la Fase 1 de análisis. Formato: pregunta → decisión → justificación → fecha.

## Duda #1 — Jerarquía Grupo ↔ Evento
**Pregunta:** ¿Un evento siempre pertenece a un grupo, o puede ser standalone?
**Decisión:** Opción A. Un Grupo tiene N Eventos (relación 1:N, Grupo es contenedor persistente). No existen eventos sin grupo.
**Justificación:** Coincide con lo que ya muestra la UI (Groups → card de grupo con evento asociado, Log de Actividad con breadcrumb Grupo·Evento).
**Fecha:** 2026-07-28

## Duda #2 — Máquina de estados de Evento y de Deuda
**Pregunta:** ¿Cuáles son todos los estados posibles y sus transiciones?
**Decisión:**
- **Estado de balance/evento (3 estados), usados tanto en Balances como en Historial (mismo comportamiento en ambas pantallas):**
  - **Pagar** — el usuario debe plata (a alguien del evento).
  - **Pendiente** — a el usuario le deben plata y todavía no le pagaron.
  - **Saldado** — no hay deudas pendientes, ni propias ni de terceros hacia el usuario.
- **Badge "NUEVO" en Groups** = hay un evento nuevo dentro de ese grupo (no es sobre el grupo en sí).
- **Icono de notificación arriba a la derecha del avatar de grupo (Groups)** = actividades nuevas sin leer, agregadas de TODOS los eventos que contiene ese grupo.
- **Badge de un evento individual** (si el grupo ya existía) = cantidad de actividades sin leer de ESE evento puntual.
- **Cancelación de evento:** un evento SÍ se puede cancelar, únicamente por el owner/creador del evento. No existe estado "archivado".
**Justificación:** Definido por el usuario para eliminar ambigüedad de la UI (badges) antes de diseñar el modelo de datos.
**Fecha:** 2026-07-28
**Nota:** la representación física en BD (enum, columna de estado, tabla de eventos no leídos, etc.) se define en Fase 2 — esto es la regla de negocio conceptual.

## Duda #3 — Algoritmo de cálculo de balance/deudas
**Pregunta:** ¿Ledger simple (Opción A) o netting/simplificación tipo Splitwise (Opción B)?
**Decisión:** Opción B — simplificación de deudas (el sistema optimiza quién le paga a quién).
**Justificación:** Decisión explícita del usuario, contraria a mi recomendación original (que era A por simplicidad). Impacta el diseño del cálculo de deudas — a validar cuidadosamente en Fase 2 el algoritmo elegido para no comprometer NFR#4 (exactitud financiera).
**Fecha:** 2026-07-28

## Duda #4 — "Sondeo" en Acciones Rápidas / vista de evento
**Pregunta:** ¿Qué es la sección de acciones rápidas y qué son las "actividades"?
**Decisión:**
- Las acciones rápidas viven **dentro de la vista de un evento**: generar gastos, saldar gastos, crear actividades/tareas.
- **Actividad/Tarea** = ítem de trabajo necesario para el evento (ej. comprar carne, papa, huevo, lechuga, tomate para un asado). Un miembro del grupo la "toma" (se auto-asigna), comprometiéndose a resolverla antes del evento.
- **Estados de una tarea (3):** No asignado → Pendiente (asignada, no completada) → Completado.
**Justificación:** Aclaración funcional del usuario — redefine el alcance de FR8 "Registro de tareas".
**Fecha:** 2026-07-28

## Duda #5 — Alcance de autenticación en el MVP
**Pregunta:** ¿El MVP lanza solo con anónimo, o con auth completa también? ¿Cómo persiste un usuario anónimo?
**Decisión:**
- El **MVP inicial** (a desarrollar en el primer mes del proyecto) tiene **solo acceso anónimo**.
- Login/registro completo (cuenta registrada) es parte del **producto final**, a entregar al cierre del último sprint del proyecto.
- Un usuario anónimo persiste mediante el **nombre de usuario que eligió para ese evento puntual**. Esa identidad vive **solo hasta que el evento se finaliza o cancela**. Un evento se finaliza cuando se saldan todos los gastos.
**Justificación:** Coincide con la prioridad #1 del charter (creación de cuenta anónima) y con la conclusión de factibilidad (priorizar el flujo central en el MVP).
**Fecha:** 2026-07-28
**Seguimiento F1 (resuelto):** el usuario anónimo persiste mediante el **ID del evento guardado en local storage** del dispositivo. Si entra a través de un link de invitación, ese link lo lleva directo al evento (mismo mecanismo). **Fecha:** 2026-07-28
**Seguimiento F2 (resuelto):** el usuario aclaró que se refirió mal — **no se agrega un sprint 4**. El cronograma a respetar es el original del Project Charter: 3 sprints, con el hito de Finalización de MVP el 09/09 (dentro del sprint 2, según el requerimiento de proyecto #1: "MVP al inicio de la 2da semana del 2do sprint"). El resto de las funcionalidades (auth completa, gastos, etc.) se completan a lo largo de los 3 sprints, cerrando en el hito de Finalización de proyecto (12/11). **Fecha:** 2026-07-28

## Duda #6 — Tipos de usuario y permisos
**Pregunta:** ¿Qué puede/no puede hacer cada tipo de usuario?
**Decisión:**
- **Miembro normal** (de un evento, vía pertenencia al grupo): cargar gastos, crear tareas/actividades, asignarse o asignar tareas a otro, saldar su cuenta y la de otros, confirmar asistencia, confirmar horarios disponibles.
- **Admin/organizador de un evento**: todos los permisos de miembro + **cerrar gastos** + **cancelar el evento** (exclusivo del owner/creador).
- **Anónimo**: igual a un miembro normal, EXCEPTO que no puede ser admin de un evento y no pertenece a un grupo fijo/persistente (ver Duda #5 — su identidad es scoped al evento).
**Justificación:** Definido por el usuario. Resuelve NFR#2 (restricción de funcionalidades por tipo de usuario).
**Fecha:** 2026-07-28

## Duda #7 — Stack mobile
**Pregunta:** ¿Flutter (Opción A) o Kotlin nativo (Opción B)?
**Decisión:** Opción A — Flutter.
**Justificación:** Coincide con la línea de presupuesto "Capacitación Flutter" y con mi recomendación.
**Fecha:** 2026-07-28

## Duda #8 — Backend / hosting (REVISADA — decisión final)
**Pregunta original:** ¿BaaS tipo Firebase (Opción A) o backend propio (Opción B)?
**Decisión inicial (2026-07-28):** Opción A — Firebase. **Revertida** tras aclarar el usuario que el objetivo del proyecto prioriza el aprendizaje del equipo de desarrollo (estudiantes con poca experiencia) por sobre el costo/velocidad, y que "producción" en este contexto es una demo a los profesores, no un producto real con usuarios conectándose a cualquier hora.
**Decisión final:** **Backend propio en AWS con EC2 + RDS (Postgres)**, no serverless (Lambda/DynamoDB) ni Firebase.
- **RDS Postgres** (no DynamoDB): elegido porque el algoritmo de simplificación de deudas (Duda #3, opción B) necesita transacciones ACID/relacionales para garantizar la exactitud financiera de NFR#4.
- **Auth y notificaciones:** se sugiere apoyarse en **Cognito** (auth) y **SNS/Pinpoint** (push) como servicios gestionados complementarios — no le suman superficie de aprendizaje "de infraestructura" a EC2/RDS y evitan reinventar auth/notificaciones desde cero. Marcado como **SUPUESTO** de baja fricción — avisar si se prefiere manejar auth/notificaciones también dentro del EC2 propio.
- **Ambientes:**
  - Un ambiente **"demo/principal"**: se prende para testing del equipo de dirección y para las demos a los profesores; el resto del tiempo puede estar apagado. No hay compromiso de disponibilidad 24/7.
  - Ambientes de **desarrollo/staging efímeros**: se prenden para testing cuando hay un merge/PR de los alumnos, luego se apagan. Rol natural para el "Agente CI/CD" ya contemplado en el charter.
- **Mecanismo de encendido/apagado:** recomendado algo simple dado el nivel de experiencia del equipo — arranque manual (consola AWS/CLI) antes de testing/demo, o un scheduler simple (EventBridge + Lambda / AWS Instance Scheduler) más adelante si se automatiza. Los datos persisten en los volúmenes EBS/RDS entre apagados (no se pierde información); nota operativa: RDS reinicia automáticamente si queda detenida más de 7 días seguidos.
**Justificación:** decisión pedagógica explícita del usuario — prioriza que los estudiantes aprendan EC2/RDS/redes/despliegue "de verdad" por sobre la conveniencia de una BaaS. Contexto académico (demo a profesores, no producto real 24/7) hace viable apagar el ambiente fuera de testing/demos sin el riesgo que tendría en un producto real.
**Impacto en otras decisiones:** la Duda #10 (notificaciones push) pasa de FCM a SNS/Pinpoint. NFR#8 del charter (99% de notificaciones entregadas en <60s) debe leerse como aplicable solo durante las ventanas en que el ambiente está encendido (testing/demo) — no como una garantía 24/7, dado que el backend no está siempre activo. Vale la pena aclarar esto en el informe final para que no se malinterprete como incumplimiento.
**Fecha:** 2026-07-28

## Duda #9 — Naturaleza del "chat" (FR10)
**Pregunta:** ¿Chat de mensajería libre o algo distinto, dada la exclusión de "mensajería avanzada en tiempo real"?
**Decisión:** El "chat" del evento **no es mensajería de texto libre entre usuarios** — es un **feed/log automático** que muestra todas las interacciones y updates del evento: asignaciones de tareas, creación de tareas, gastos hechos/saldados, horarios disponibles cargados, etc. Es, en efecto, la pantalla "Log de Actividad del Evento" ya vista en la UI.
**Justificación:** Redefine FR10 del charter — no hay campo de texto libre para que los usuarios escriban mensajes entre sí.
**Fecha:** 2026-07-28
**Seguimiento F3 (resuelto):** confirmado — es solo un log de actividades del evento, sin mensajería libre. **Backlog opcional** (solo si sobra tiempo tras completar todo lo planeado en el charter): agregar mensajería libre dentro de los eventos. **Fecha:** 2026-07-28

## Duda #10 — Notificaciones push (actualizada por revisión de Duda #8)
**Decisión:** SNS/Pinpoint (AWS), consistente con la decisión final de backend en AWS (Duda #8). Reemplaza la mención anterior a FCM directo.
**Fecha:** 2026-07-28

## Duda #11 — NFR#9 (2.000 usuarios concurrentes/día)
**Decisión:** Es un **objetivo de diseño** (la arquitectura debe estar preparada conceptualmente), no una meta a validar con testing de carga real en este proyecto académico.
**Fecha:** 2026-07-28

## Duda #12 — Creación de evento en 2 pasos
**Pregunta:** ¿Cuáles son los 2 pasos?
**Decisión:**
- **Paso 1:** nombre del evento + dónde es (texto libre, no geolocalización real — ej. "Casa de Juli").
- **Paso 2:** elegir un grupo existente (con sus miembros), O elegir miembros individuales por separado — esta segunda vía crea un grupo nuevo con esos miembros y pide un nombre para el grupo nuevo.
**Justificación:** Definido por el usuario.
**Fecha:** 2026-07-28
**Seguimiento F4 (resuelto):** confirmado — la fecha/hora **no** se define en el paso 1 de creación. Se define después de que los miembros cargan sus horarios disponibles: se genera un **mapa de calor de horarios (heatmap de disponibilidad)** y a partir de ahí se selecciona un rango horario, o al menos el horario de inicio del evento. **Fecha:** 2026-07-28

## Duda #12.2 — Nuevo requerimiento: gestión de miembros de grupo (surgido en esta conversación, no estaba en el charter original)
**Decisión:** Se necesita una sección para editar miembros y nombre de un grupo:
- Un usuario puede **abandonar** un grupo.
- Un miembro del grupo puede **añadir a un amigo REGISTRADO** (no anónimo) al grupo, dándole visibilidad de todos los eventos del grupo.
**Justificación:** Gap detectado por el usuario durante esta revisión — se incorpora como nuevo requerimiento funcional para el backlog de Fase 2 (relacionado con FR13 "Gestión de amigos" y FR5 "Creación de grupos").
**Fecha:** 2026-07-28

## Duda #13 — IA in-app (FR18) vs. Agentes IA de desarrollo
**Decisión:** Confirmado — son cosas distintas. FR18 (auto-generación de eventos) es una feature de producto de baja prioridad/post-MVP; los "Agentes IA" (UI/UX, Backend, QA, CI/CD, Contexto) son herramientas del proceso de desarrollo del equipo, no features visibles al usuario final.
**Fecha:** 2026-07-28

## Duda #14 — Ubicaciones usuales (FR16)
**Decisión:** Texto libre para el MVP y el producto final planeado. Como **backlog opcional** (solo si sobra tiempo tras cumplir todo lo planeado en el charter): agregar sección de geolocalización en el evento que muestre un mapa, y al tocarlo abra Google Maps para navegar hasta el lugar cuando se acerca la fecha del evento.
**Fecha:** 2026-07-28

## Duda #15 — Multi-idioma (NFR#6)
**Decisión:** Español e inglés. Se debe implementar con arquitectura de internacionalización (archivos/constantes de texto) desde el inicio, para no acoplar los textos al código.
**Fecha:** 2026-07-28
**Seguimiento F5 (resuelto):** el **MVP sale solo en español**. El inglés se completa en la segunda parte del proyecto (producto final, en el último sprint), aprovechando que la arquitectura queda i18n-ready desde el día 1. **Fecha:** 2026-07-28

## Duda #16 — Moneda
**Decisión:** Pesos argentinos (ARS) únicamente, sin soporte multi-moneda.
**Fecha:** 2026-07-28

## Duda #17 — Cifrado en reposo (NFR#7)
**Decisión:** El enfoque más simple mientras sea suficientemente seguro — TLS en tránsito + cifrado en reposo delegado al proveedor de infraestructura (nativo de la BaaS elegida), sin cifrado de aplicación custom ni gestión propia de claves.
**Fecha:** 2026-07-28

## Duda #18 — Backend framework (revisión post-Fase 2)
**Pregunta:** cambiar NestJS por Node.
**Decisión:** **Node.js + Express (TypeScript)**, reemplaza a NestJS en toda la arquitectura. Arquitectura en capas (routes → controllers → services) organizada por convención de carpetas, sin DI/decoradores.
**Justificación:** pedido directo del usuario — más minimalista, curva de aprendizaje más simple para un equipo júnior.
**Fecha:** 2026-07-28

## Duda #20 — Alineación del backlog con las épicas reales de Jira (`planify2026.atlassian.net`, proyecto SCRUM)
**Contexto:** el usuario ya tenía 17 épicas cargadas en Jira con fechas de inicio/fin propias. Se pidió adaptar el backlog de [01-plan-de-ejecucion.md](01-plan-de-ejecucion.md) a esas épicas, sin cambiar ninguna fecha sin consultar antes.
**Decisiones:**
- **Los tiempos de cada épica/tarea son asistidos por IA** (el equipo + herramientas de IA), por lo que no deberían insumir tanto tiempo como una estimación tradicional — aplica a **todas** las épicas y tareas futuras, no solo a Setup de Infraestructura. Esto reduce (no elimina) el riesgo que había marcado sobre SCRUM-6 (2 días para todo el setup de infra).
- **SCRUM-6 "Setup de Infraestructura" (13-14/08) es la fecha real** — **prevalece sobre el hito "21/08" del Project Charter**, que queda desactualizado en ese punto puntual.
- **FR18 "IA para auto-generación de eventos" (SCRUM-17, 29/10-11/11) pasa a ser OBLIGATORIA**, ya no backlog opcional — con la salvedad de que **es lo primero que se cae si hay atraso** en el proyecto. Alcance funcional definido por el usuario: el usuario le escribe a la IA un mensaje en lenguaje natural describiendo el evento que quiere organizar, y la IA genera automáticamente el evento (nombre, lugar), las tareas/actividades sugeridas, y arma el grupo/participantes mencionados.
- **Mapeo de épicas sin ticket propio:**
  - **Grupos** (creación implícita) → dentro de **SCRUM-8 "Creación de eventos"**.
  - **SCRUM-13 "Chat de grupo"** se reinterpreta como **"chat/log de eventos"** — es el log de actividad y updates dentro de un evento (coincide con [Duda #9](#duda-9--naturaleza-del-chat-fr10)), no un chat de grupo separado.
  - **Gestión de amigos y miembros de grupo** (gap de [Duda #12.2](#duda-122--nuevo-requerimiento-gestión-de-miembros-de-grupo-surgido-en-esta-conversación-no-estaba-en-el-charter-original)) → dentro de **SCRUM-14 "Autenticación / usuarios"**.
  - **Internacionalización (ES/EN):** no es una épica propia — se implementa bien desde el día 1 **dentro de cada épica** (sin strings hardcodeados), no como pase final de traducción.
  - **Testing y documentación:** no es una épica final — va **dentro de cada épica y tarea** (Definition of Done ya lo contemplaba así). El cierre/informe final sí aterriza en **SCRUM-21 "Despliegue Android Final"**, por ser la última épica y coincidir con el hito de fin de proyecto.
- **SCRUM-22 "Tarea de prueba"** — confirmado que era un ticket de prueba, **el usuario ya lo borró** de Jira. Se excluye de toda referencia futura.
**Justificación:** mantener una única fuente de verdad de fechas (Jira) y evitar una épica de backlog "IA de eventos" fantasma que en realidad ya tiene compromiso de fecha real.
**Fecha:** 2026-07-28

## Duda #21 — Proveedor de IA para SCRUM-17 (auto-generación de eventos)
**Pregunta:** qué API/modelo usar para el parseo de lenguaje natural (mensaje del usuario → evento + grupo + tareas).
**Decisión:** **Gemini** (Google) — acceso gratuito a través de la facultad.
**Justificación:** costo $0 real contra el presupuesto de $30/6 meses para IA/APIs, en vez de pagar por un proveedor externo (se había sugerido Anthropic/Claude como opción, pero el usuario ya tiene Gemini gratis).
**Fecha:** 2026-07-28

## Duda #22 — Aclaración: todo lo que está en Jira es alcance comprometido, no backlog
**Contexto:** en mi resumen anterior usé frases como "fuera del MVP" para las épicas posteriores a SCRUM-18, lo cual podía confundirse con "opcional".
**Aclaración del usuario:**
- El **MVP inicial cierra en la segunda semana del Sprint 2, es decir el 09/09** (coincide con el vencimiento de SCRUM-9 "Gestión de disponibilidad" en Jira — ya estaba bien reflejado, solo se confirma explícitamente).
- **Todas las épicas que están cargadas en Jira (SCRUM-11 en adelante) son parte comprometida del proyecto, NO son backlog opcional.** "Backlog" solo aplica a las 4 historias que quedaron *sin* épica ni fecha en Jira (HU-B1 mensajería libre, HU-B2 geolocalización, HU-B4 coincidencias de disponibilidad entre amigos, HU-B5 ubicaciones usuales como favoritos) — esas sí son las únicas verdaderamente opcionales/"si sobra tiempo".
**Impacto:** se corrige el lenguaje del plan para no dar a entender que gastos, tareas, log de actividad, historial, auth completa, notificaciones o la IA (SCRUM-17) son prescindibles — son compromiso real del proyecto con fecha en Jira, al mismo nivel que el MVP.
**Fecha:** 2026-07-28

## Duda #19 — ¿Quién crea eventos en el MVP si el anónimo no puede? (gap detectado por el usuario tras cerrar Fase 2)
**Pregunta:** [Duda #6](#duda-6--tipos-de-usuario-y-permisos) decía que el anónimo no puede ser *admin* de un evento, pero el usuario aclaró después que el anónimo directamente **no puede crear eventos**. Esto contradecía [Duda #5](#duda-5--alcance-de-autenticación-en-el-mvp) ("el MVP inicial solo tiene anónimo"), porque la primera historia del MVP es justamente crear un evento — ¿quién lo hace entonces?
**Decisión:** Para el MVP se usa **un usuario organizador "fake"**: una fila de `Usuario` con email + contraseña **precargada por seed** (no hay pantalla de registro real ni Cognito conectado todavía), que es quien crea los eventos del MVP. Los usuarios anónimos se unen a esos eventos vía link de invitación ([Duda F1](#duda-5--alcance-de-autenticación-en-el-mvp)), igual que estaba planeado.
**Justificación:** evita construir todo el flujo de autenticación real (Cognito, registro, recuperación de contraseña) antes de tiempo, sin bloquear la historia central del MVP (creación de evento). El resto de auth completa sigue en Sprint 3 sin cambios.
**Impacto:**
- Resuelve además la "nota de diseño" abierta sobre el grupo transitorio para anónimos ([01-plan-de-ejecucion.md §3](01-plan-de-ejecucion.md)): ya no aplica, porque en el MVP el organizador siempre es un `Usuario` real (aunque sea de seed), nunca un anónimo.
- La pantalla de Login se construye visualmente completa (coincide con el mockup), pero en el MVP solo funciona contra las credenciales del usuario semilla — "Crear cuenta" y "¿Olvidaste tu contraseña?" quedan visualmente presentes pero inertes/"próximamente" hasta Sprint 3.
- Se agrega tarea técnica: script de seed que crea el/los usuario(s) organizador(es) fake en la base al levantar el ambiente.
**Fecha:** 2026-07-28

## Duda #23 — Desacoplamiento y principios SOLID (revisión de arquitectura)
**Pedido del usuario:** "desacoplar de manera tal que si en un futuro hay que cambiar algo se haga desde un solo lugar y sea fácil de encontrar", siguiendo SOLID.

**Contexto:** la primera implementación tenía los servicios importando `prisma` directamente y una única clase `PlanifyApi` en mobile con todos los endpoints. Funcionaba, pero cambiar el ORM, el proveedor de auth o el cliente HTTP obligaba a tocar decenas de archivos, y los tests necesitaban base de datos.

**Decisión:** arquitectura en capas con inversión de dependencias.

*Backend:*
- `src/domain/` — entidades propias (sin tipos de Prisma) e interfaces de repositorio, una por agregado (segregación de interfaces).
- `src/infrastructure/` — único lugar que conoce Prisma, bcrypt y JWT.
- `src/modules/` — servicios como clases que reciben sus dependencias por constructor.
- `src/container.ts` — composition root: el único archivo que decide qué implementación concreta usa cada servicio.
- Comandos y consultas separados (`EventsService` vs `EventsQueryService`) para que ninguna clase crezca sin control.

*Mobile:*
- Un repositorio por feature (interfaz + implementación Dio) en vez de una clase única.
- `TokenStorage` como interfaz propia, para no quedar atados a la API de `flutter_secure_storage`.
- `ApiException` traduce los errores de red: las pantallas nunca ven un `DioException`.

**Justificación:** el objetivo declarado del proyecto es que los estudiantes aprendan buenas prácticas ([Duda #8 revisada](#duda-8--backend--hosting-revisada--decisión-final)). Además habilita algo concreto: **los tests corren sin base de datos ni red**, usando los fakes de `backend/test/fakes.ts` y `mobile/test/helpers/fake_repositories.dart`.

**Costo aceptado:** más archivos y una capa extra de indirección. Se mitiga con la tabla "dónde tocar según qué cambie" en [01-plan-de-ejecucion.md §4](01-plan-de-ejecucion.md) y la receta paso a paso en [04-notas-de-implementacion.md §5.7](04-notas-de-implementacion.md).

**Fecha:** 2026-07-28

## Duda #24 — Documentar las trabas técnicas para el equipo de desarrollo
**Pedido del usuario:** "todo paso difícil que te encontraste me gustaría que lo documentes para tomarlo en cuenta para cuando se lo dé a los chicos", y desarrollar en el orden de los sprints/épicas, de a pasos chicos.

**Decisión:** se crea [`docs/04-notas-de-implementacion.md`](04-notas-de-implementacion.md) como bitácora viva de trampas concretas: qué pasó, por qué, cómo se resolvió. Cubre versiones de dependencias que rompen, gotchas de Flutter/Express/Prisma, decisiones de arquitectura explicadas y una receta para agregar funcionalidad nueva.

**Compromiso:** cada vez que alguien pierda más de ~20 minutos con un problema de herramientas o entorno, se agrega una entrada. Es el documento con más valor práctico para alguien que recién arranca.

**Fecha:** 2026-07-28
