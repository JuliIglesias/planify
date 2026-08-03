# Planify — Estado final (cierre de Fase 2)

> **Fecha:** 2026-08-02. Cierre de la corrección e implementación posterior a la
> auditoría ([04-auditoria.md](04-auditoria.md)). El detalle técnico de cada
> corrección está en [05-fixes.md](05-fixes.md).

## 1. Resumen

Se corrigieron **todos los hallazgos de la auditoría** (2 bloqueantes, 5 altos,
6 medios, 6 bajos) y se implementaron las **épicas comprometidas que faltaban**:
SCRUM-14 (auth completa + amigos), SCRUM-15 (notificaciones) y SCRUM-17 (IA de
auto-generación). Todo con tests.

**Verificación automática (corrida final):**

| Chequeo | Resultado |
|---|---|
| Backend `npm test` (Jest) | ✅ **90** tests / 8 suites |
| Backend `tsc --noEmit` | ✅ |
| Backend `npm run lint` (`eslint .`, ampliado a tests+config) | ✅ 0 |
| Mobile `flutter test` | ✅ **27** tests |
| Mobile `flutter analyze` | ✅ 0 issues |

> Sigue valiendo la advertencia de la auditoría: los tests usan *fakes* en
> memoria. La corrida contra una base real ya es posible sin pasos manuales
> (`docker compose up` migra y siembra solo — H-07), pero **no se pudo ejecutar
> en este entorno** (sin Docker). Es el primer paso del checklist de §5.

## 2. Qué se implementó

### Correcciones (ver [05-fixes.md](05-fixes.md) para el detalle)
- **H-01 / H-02 (bloqueantes):** los miembros del grupo ahora se vuelven
  participantes del evento; la lista de participantes se refresca al asignar un
  gasto (pull-to-refresh + refetch). Es la causa raíz del bug de calibración.
- **H-04:** el "soy organizador" lo decide el backend según quién mira; el
  anónimo ya no ve acciones de organizador.
- **H-06:** la UI de gasto soporta varios acreedores (FR7).
- **H-03 / H-07:** TLS con Caddy delante del backend; `docker compose` migra y
  siembra solo.
- **H-09:** Próximos/Historial se parten por fecha, no solo por estado.
- **H-08, H-11, H-12, H-13, H-05, H-10, H-16:** ver 05-fixes.

### Épicas nuevas
- **SCRUM-14 — Auth completa + amigos:** registro (HU-27), login (HU-28),
  recuperación de contraseña (HU-29, token backend), perfil (HU-30), amigos
  (HU-31: buscar/solicitar/aceptar/listar), agregar amigo a grupo con selector
  (HU-32). Mobile: pantalla de amigos, selector reutilizable, registro,
  selector de idioma ES/EN.
- **SCRUM-15 — Notificaciones:** ports `PushNotifier`/`DeviceRegistry`, disparo
  desde el log de actividad, endpoint de registro de device.
- **SCRUM-17 — IA:** generación de un borrador editable desde texto libre, con
  fallback heurístico offline y Gemini opcional; matching de amigos; creación de
  tareas sugeridas. Mobile: botón "Generar con IA" en el wizard.
- **SCRUM-18 (prep):** firma de release Android desde `key.properties`
  (git-ignored), con `key.properties.example`.

## 3. Qué queda pendiente y por qué

Casi todo lo pendiente depende de **recursos externos** (cuentas, credenciales,
infra), no de código:

| Ítem | Estado | Por qué |
|---|---|---|
| Correr contra DB real / provisionar AWS (EC2+RDS) | ⏳ | Requiere la cuenta AWS del equipo. El código y el `docker compose` ya lo dejan listo (migra+siembra solo). |
| **Envío/recepción real de push** (SNS/Pinpoint + SDK FCM) | ⏳ | El backend notifica detrás de una interfaz; falta el proveedor real (credenciales AWS) y el SDK de push en el dispositivo. |
| **Gemini real** (SCRUM-17) | ⏳ (opcional) | Setear `GEMINI_API_KEY` (acceso gratuito de la facultad). **Sin la key la feature funciona igual** con el generador heurístico. |
| Recuperación de contraseña — **envío del email** | ⏳ | El token se genera/valida; falta un proveedor de correo (SES/SendGrid) para enviarlo. En dev el endpoint devuelve el token. |
| Publicación en **Play Store** (SCRUM-18-21) | ⏳ | Requiere cuenta de Google Play (USD 25) + keystore real. La firma y el build ya están cableados. |
| TLS con certificado real | ⏳ | Caddy saca el certificado solo con un **dominio** real; en local usa uno interno. |

**Implementado en el cierre final (antes documentado como deuda):**
- **H-14** disponibilidad de perfil persistida en el backend (con caché local).
- **H-17** badge de no-leídos en la campana.
- **HU-B4** coincidencias de disponibilidad entre amigos (heatmap).
- **HU-B5** ubicaciones favoritas reutilizables al crear eventos.

**Único que queda como deuda menor:**
- **H-15:** las invitaciones no aplican `usosMaximos`/expiración (requiere un
  contador de usos). Hoy un link sirve indefinidamente.

**Backlog opcional aún no hecho** (nunca comprometido — "si sobra tiempo"):
HU-B1 mensajería libre, HU-B2 mapa/Google Maps (requiere `url_launcher` +
config de plataforma).

## 4. Estado real por épica (libro de Jira — NO modificado en esta fase)

> Por pedido del usuario, en esta fase **no se tocó Jira** (salvo las
> transiciones ya hechas antes del pedido, que el usuario ajusta manualmente).
> Esta tabla es la referencia de en qué estado **correspondería** dejar cada
> épica según el código real.

| Épica | Estado que correspondería | Nota |
|---|---|---|
| SCRUM-5 Capacitación | Listo | Material en docs (proceso). |
| SCRUM-6 Setup infra | En curso | CI verde, docker migra+siembra, TLS listo; falta AWS real. |
| SCRUM-7 Acceso anónimo | Listo | + fix de integración. |
| SCRUM-8 Creación eventos | Listo | + H-01/H-05 (miembros → participantes, selector). |
| SCRUM-9 Disponibilidad | Listo | |
| SCRUM-10 Asistencia | Listo | |
| SCRUM-11 Gastos + deudas | Listo | + H-06 multi-acreedor. |
| SCRUM-12 Tareas | Listo | |
| SCRUM-13 Log de actividad | Listo | + dispara notificaciones. |
| SCRUM-14 Auth/usuarios/amigos | Listo* | *Falta solo el envío del email de recuperación (externo). |
| SCRUM-15 Notificaciones | En curso | Backend + endpoint listos; falta SNS/FCM real. |
| SCRUM-16 Historial | Listo | + H-09 partición por fecha. |
| SCRUM-17 IA | Listo* | *Funciona con heurístico; Gemini real requiere API key. |
| SCRUM-18 Deploy MVP | En curso | Firma + docker + TLS listos; falta cuenta Play Store + AWS. |
| SCRUM-19/20/21 Despliegues | Por hacer | Dependen de la publicación real. |

> **SCRUM-1..4** siguen siendo ítems de ejemplo de plantilla — conviene borrarlos.

## 5. Checklist de verificación manual (para probar la app)

**Preparar el ambiente:**
1. `docker compose -f infra/docker-compose.yml up --build` — levanta Postgres,
   aplica la migración, siembra el organizador y arranca el backend (y el proxy
   TLS). Verificá en los logs `migrate` que diga "Usuario organizador semilla listo".
2. Correr la app apuntando al backend: `flutter run --dart-define=PLANIFY_API_URL=http://10.0.2.2:3000`
   (emulador) o a `https://<dominio>` si usás el proxy.

**Flujo central (organizador):**
- [ ] Login con `organizador@planify.test` / `planify-mvp-2026`.
- [ ] Crear un evento en 2 pasos. Probar el botón **"Generar con IA"** con
      "asado en casa de Juli con Marcos" → se pre-llena nombre/lugar.
- [ ] En el paso 2, crear un grupo nuevo y **elegir miembros** (si ya tenés amigos).
- [ ] Abrir el evento: cargar disponibilidad, ver el heatmap, confirmar un horario.
- [ ] Agregar un gasto con **varios pagadores** y validar que la suma cierre.
- [ ] Ver la deuda resultante y saldarla; ver el evento pasar a "saldado".
- [ ] Ver el **log de actividad** del evento y la actividad reciente en Home.

**Amigos y perfil (SCRUM-14):**
- [ ] Perfil → **Mis amigos** → buscar por nombre/email, enviar solicitud.
- [ ] Con otra cuenta (registrala desde **Crear cuenta**), aceptar la solicitud.
- [ ] Cambiar el **idioma** ES/EN en Perfil y ver la app traducirse.
- [ ] Agregar un amigo a un grupo desde el menú del grupo (selector, no UUID).

**Anónimo (integración — el bug de calibración):**
- [ ] Como organizador, generar un link de invitación del evento.
- [ ] En otra sesión/dispositivo, "Continuar como Anónimo" → pegar el link → unirse.
- [ ] Como organizador, **refrescar** el evento (pull-to-refresh) y confirmar que
      el anónimo **aparece** al asignarle un gasto. ✅ (era H-01/H-02)
- [ ] Como anónimo, confirmar que **NO** ve "Cancelar evento"/"Cerrar gastos". ✅ (H-04)

**Casos borde:**
- [ ] Evento cancelado: deshabilita acciones; el anónimo pierde acceso.
- [ ] Evento con un solo participante: se puede crear pero el gasto solo se
      reparte entre los que haya.
- [ ] Balances: tocar una persona muestra el desglose por evento y "Saldar todo".

## 6. Archivos nuevos de esta fase (referencia)

**Backend:** `modules/friends/`, `modules/users/`, `modules/notifications/`,
`modules/ai-events/`, `infrastructure/prisma/amistad.prisma.repository.ts`,
`infrastructure/ai/event-generators.ts`, ports en `domain/repositories/`
(amistad, notifications, ai-events), tests `audit-regression.test.ts` y
`scrum14.test.ts`.

**Mobile:** `features/friends/` (repo, picker, pantalla), `features/auth/register_screen.dart`,
`features/events/data/ai_events_repository.dart`, `core/locale_provider.dart`.

**Infra:** `infra/Caddyfile`, `docker-compose.yml` (migrate + proxy),
`mobile/android/key.properties.example`.
