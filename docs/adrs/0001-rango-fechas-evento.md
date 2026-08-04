# ADR 0001 — Rango de fechas calendario del evento

**Estado:** Aceptado
**Fecha:** 2026-08-04
**Contexto:** Fase 5, Item 1 (pedido del usuario)

## Contexto

Hasta ahora `Evento` no tenía ningún límite calendario: la disponibilidad se
cargaba como un patrón semanal genérico (lunes a domingo) y se buscaba un
horario dentro de ese patrón de forma indefinida, sin acotarlo a fechas
concretas. Eso significa que el heatmap de un evento creado en agosto podía
"encontrar" coincidencias en un lunes cualquiera, sin que quedara claro si
ese lunes era el 3 de agosto o el 3 de noviembre.

El pedido: el organizador define un rango de fechas calendario (ej. 1/8 al
20/8) al crear el evento, y el heatmap semanal se interpreta dentro de ese
rango. Si el rango vence sin que se confirme un horario, se extiende solo
2 semanas más (con un tope, para no quedar extendiendo para siempre sin que
nadie se entere).

## Decisión

1. **`Evento` gana `rangoInicio: DateTime` y `rangoFin: DateTime`,
   obligatorios.** Se piden en la creación (`POST /events`), junto con
   nombre y lugar — no rompen el "2 pasos" de NFR#3 porque se agregan al
   mismo paso 1 del wizard, no a un paso nuevo.

2. **La disponibilidad semanal del participante NO cambia de forma:** sigue
   siendo `DisponibilidadSlot(diaSemana, bloqueHora)`, sin fecha concreta.
   La relación entre este patrón semanal y el rango del evento es
   conceptual, no de almacenamiento: el patrón se "proyecta" sobre cada
   semana calendario que cae dentro del rango. No se agregó una tabla de
   disponibilidad por fecha exacta — hubiera sido un cambio de modelo mucho
   más grande (y una carga mucho más pesada para el usuario: marcar
   disponibilidad fecha por fecha en vez de una vez por semana) para un
   beneficio que el pedido no pide explícitamente (el heatmap por
   día-de-semana+hora sigue siendo lo que se quiere ver).

3. **Extensión automática, lazy, sin cron.** Igual que el resto del
   proyecto (`listUpcomingForUsuario`/`listPastForUsuario` con H-09), no hay
   infraestructura de jobs. `EventsService.chequearExtensionRango(eventoId)`
   se llama desde la ruta `GET /events/:id` antes de armar el detalle: si
   `ahora > rangoFin` y el evento sigue en `planificacion`, extiende
   `rangoFin` 14 días y registra actividad (`rango_extendido`, notifica a
   los participantes vía el mismo `ActivityLogService` de siempre).

4. **Tope de 1 extensión automática** (confirmado con el usuario). Alcanzado
   el tope, no se extiende más solo: `EventsQueryService.detalle` calcula
   `necesitaDecisionRango: boolean` (no se persiste, se deriva en cada
   lectura) para que la UI avise que el organizador tiene que decidir a
   mano — confirmar un horario (ya posible con los controles existentes) o
   cancelar el evento (ya posible con el botón de cancelar existente). No
   hace falta ningún flujo/endpoint nuevo para "decidir": los controles que
   ya existían alcanzan.

5. **Migración con backfill.** Los eventos creados antes de este cambio no
   tenían rango. Se agregan las columnas nullable, se backfillea
   `rangoInicio = createdAt` y `rangoFin = createdAt + 14 días`, y recién
   después se marcan `NOT NULL` (`20260804090000_evento_rango_fechas`).

## Alternativas consideradas

- **Guardar disponibilidad por fecha exacta en vez de por día-de-semana:**
  descartada por ahora — es un cambio de modelo mucho mayor (afecta
  `DisponibilidadSlot`, el heatmap, el guardado de disponibilidad de
  perfil) para un beneficio que no pidió el usuario explícitamente; el
  patrón semanal + rango cumple el criterio de aceptación tal cual está
  redactado.
- **Cron real para extender el rango:** descartado por consistencia con el
  resto del proyecto (sin infraestructura de jobs) y porque el patrón lazy
  ya usado para "próximos vs. historial" (H-09) resuelve lo mismo sin
  infraestructura nueva.
- **Extensiones ilimitadas:** descartado — el usuario prefirió un tope de 1
  extensión para forzar una decisión humana en vez de que el evento quede
  extendiéndose para siempre sin que nadie lo note.

## Consecuencias

- `EventsService` pasa a depender de `Clock` (antes no lo necesitaba).
- Todo `CrearEventoInput`/`CrearEventoData` existente que no pase
  `rangoInicio`/`rangoFin` deja de compilar — es intencional, fuerza a
  actualizar cualquier caller nuevo.
- La UI de creación de evento gana un selector de rango de fechas en el
  paso 1 (`showDateRangePicker`), con un default razonable (hoy → hoy + 14
  días) para no bloquear al organizador que no quiere pensarlo.
