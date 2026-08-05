# ADR 0003 — Identidad anónima única por evento (username + PIN)

**Estado:** Aceptado
**Fecha:** 2026-08-05
**Contexto:** Tanda 7, Item G1 (pedido del usuario)

## Contexto

Este es el **tercer** paso sobre el mismo tema, y quedó pendiente de
documentar en las dos vueltas anteriores:

1. **Tanda 1, item 5** (ver `docs/05-fixes.md`, hallazgo H-08 en
   `docs/04-auditoria.md`): se confirmó que "Continuar como Anónimo" ya
   exige un link de invitación a un evento — no existe (ni existió nunca
   en este código) un camino anónimo genérico "sin evento".
2. **Tanda 2, item 1** (commit `175fe16`, "Add unique username for
   registered and anonymous users"): reemplazó `Participante.nombreDisplay`
   por un único campo `username`. Para anónimos, la unicidad se resolvía
   **auto-sufijando en silencio** (`Sofía` → `Sofía2` si ya estaba tomado)
   contra **cualquier** anónimo de **cualquier** evento, para siempre — el
   pedido nunca se rechazaba.

Ese diseño (2) es exactamente lo que este ADR reemplaza. Tenía dos
problemas para el caso de uso real:

- **No hay forma de "volver a entrar".** Si alguien perdía el `tokenSesion`
  guardado en el dispositivo (reinstaló la app, cambió de teléfono, borró
  el storage), no había manera de recuperar su identidad en ESE evento — el
  sistema literalmente no distinguía "soy la misma Sofía de antes" de
  "soy una Sofía nueva que casualmente eligió el mismo nombre".
- **La unicidad era demasiado agresiva.** Un username quedaba "quemado"
  para siempre en toda la app apenas alguien lo usaba una vez en un evento
  cualquiera, aunque ese evento hubiera terminado hace meses.

## Decisión

### Regla 1 — solo se entra por link de invitación a un evento puntual

**Sin cambios respecto de antes** (ya lo confirmó la Tanda 1): no existe, y
no se agrega, un camino para "continuar como anónimo" sin pasar primero por
la invitación a un evento específico. `LoginScreen._continuarComoAnonimo`
sigue pidiendo el link + el username (y ahora también el PIN, regla 2) en
un solo diálogo.

### Regla 2 — username + PIN son las credenciales; reingresar recupera la MISMA identidad

Al unirse por primera vez, el anónimo define un **PIN** (mínimo 4
caracteres) además del username. `Participante` gana `pinHash` (bcrypt,
igual que las contraseñas de cuentas registradas — mismo puerto
`PasswordHasher`, sin agregar una dependencia nueva).

`ParticipantsService.unirseComoAnonimo(eventoId, username, pin)`:

1. Busca si YA existe una fila anónima con ese `username` **en ese mismo
   evento** (`findAnonimoPorEventoYUsername`, case-insensitive).
2. **Si existe:** es un reingreso. Compara el PIN con el hash guardado
   (`PasswordHasher.compare`). Si coincide, devuelve la fila existente —
   mismo `participanteId`, mismo historial (tareas asignadas, gastos,
   disponibilidad cargada, todo) — con un `tokenSesion` **nuevo** (se
   regenera en cada reingreso, mismo criterio que un login: un token viejo
   filtrado no debe seguir sirviendo para siempre). Si el PIN no coincide,
   rechaza con 401 sin decir explícitamente cuál de las dos cosas falló
   (mismo criterio de no-filtrado que `AuthService.login`).
3. **Si no existe en ese evento:** es un alta nueva. Antes de crear, valida
   que el username esté libre (regla 3) — y si lo está, crea la fila con el
   PIN hasheado.

**Por qué PIN y no otra cosa (pregunta a) —** un username solo, sin ningún
secreto, es trivialmente suplantable: cualquiera que supiera el nombre de
otro participante podría "entrar como él" y ver/tocar lo que esa persona
ve. Un PIN corto (no una contraseña completa: sigue siendo un flujo
liviano, pensado para gente sin cuenta) alcanza para que reingresar
"pruebe" que sos quien decís ser, sin la fricción de un registro completo.

### Regla 3 — el mismo username no sirve para OTRO evento mientras el primero sigue "activo"

`ParticipantsService.exigirUsernameLibre` (solo corre en el alta nueva,
paso 3 de arriba) rechaza — **sin auto-sufijar**, a diferencia del diseño
viejo — si:

- El username ya lo tiene una **cuenta registrada** (sin cambios respecto
  de antes: sigue siendo un bloqueo permanente, para siempre, sin importar
  el estado de ningún evento — ver "Alternativas descartadas" más abajo).
- El username lo tiene un anónimo de **otro evento** que todavía no
  "liberó" ese username (regla siguiente).

El mensaje de rechazo **sugiere una alternativa disponible** (pregunta c),
ej.: `El username "Sofía" ya está en uso en otro evento activo. Probá con
"Sofía2".` — mismo algoritmo de sufijo numérico que antes se aplicaba en
silencio, ahora usado solo para sugerir, nunca para decidir por la persona.

**Cuándo se libera un evento (pregunta b) —**
`ParticipantsService.puedeLiberarUsername(evento)`:

```
evento.estado ∈ {finalizado, cancelado}  Y  deudas.contarPendientes(evento.id) === 0
```

Ambas condiciones son necesarias. Un evento `finalizado` (que además, por
`DebtsService.actualizarEstadoEvento`, YA es el estado que el sistema pone
automáticamente en cuanto las deudas de ese evento quedan en cero) confirma
que no queda nada de plata pendiente entre los participantes. Un evento
`cancelado` puede igualmente tener gastos cargados antes de cancelarse —
por eso también se exige `contarPendientes === 0`, no alcanza con el
estado solo. Mientras haya una sola deuda `pendiente` de ese evento, el
username sigue reservado — el usuario lo pidió explícitamente: "hasta que
no se resuelvan los gastos no se eliminan los anónimos ya que deben saldar
gastos con los otros users".

Importante: esto es **independiente** de `invalidarSesionesAnonimas`
(ya existía, se dispara al cancelar un evento) — esa función solo anula el
`tokenSesion` para que la persona pierda el acceso al evento cancelado; NO
libera el username para otro evento. Son dos conceptos distintos: "perder
acceso a este evento" vs. "el username queda libre para otro evento".

### Regla 4 — el username es fijo mientras el evento sigue activo (pregunta d)

No hay ningún endpoint para que un anónimo cambie su username dentro de un
mismo evento. Es intencional: el username **es** la credencial (junto con
el PIN) — cambiarlo a mitad de camino rompería la identidad que ya está
enlazada a tareas asignadas, gastos cargados, disponibilidad, etc. Si el
username "no le gustó", la única vía es esperar a que el evento termine y
se libere (regla 3), o simplemente elegir uno distinto la primera vez.

## Alternativas descartadas

- **Liberar también el bloqueo contra cuentas registradas cuando el evento
  del anónimo termina.** Se descartó: una cuenta registrada es una
  identidad permanente: sería raro que un username de cuenta real quedara
  "en juego" según el estado de un evento anónimo ajeno. El bloqueo contra
  `Usuario.username` sigue siendo, como ya era, total y permanente.
- **Reusar `tokenSesion` tal cual en un reingreso**, en vez de regenerarlo.
  Se descartó por seguridad: un token viejo filtrado (log, dispositivo
  compartido) seguiría sirviendo para siempre. Regenerar en cada reingreso
  es el mismo costo que un login normal y cierra esa ventana.
- **Devolver la sugerencia de username como campo estructurado en el JSON
  de error**, en vez de en el texto del mensaje. El `errorHandler` central
  de la API solo serializa `{ error: mensaje }` para TODOS los errores;
  ramificar el contrato de error solo para este caso hubiera sido un
  cambio más grande e innecesario — el texto ya resuelve el pedido
  ("recomendar uno que esté disponible") sin tocar el contrato general.

## Consecuencias

- **Schema:** `Participante.pinHash` (nullable — solo aplica a
  `esAnonimo: true`), migración `20260805100000_participante_pin_anonimo`.
- **Backend:** `ParticipantsService` reescrito (ver
  `src/modules/participants/participants.service.ts`); gana dos
  dependencias (`PasswordHasher`, `DeudaRepository`). `POST
  /participants/anonymous` ahora exige `pin` en el body.
- **Mobile:** el diálogo de "Continuar como Anónimo" (`login_screen.dart`)
  suma un campo de PIN, obligatorio (mínimo 4 caracteres) antes de poder
  confirmar. A diferencia de antes (nunca fallaba), ahora el pedido puede
  ser rechazado — el mensaje específico del backend se muestra tal cual
  (trae la sugerencia de username incluida).
- **Ya no se auto-sufija nunca.** `resolverUsernameUnico`/`estaTomado` (el
  mecanismo viejo) se eliminaron del todo — `docs/05-fixes.md` documentaba
  ese comportamiento como el esperado; queda superado por este ADR.
