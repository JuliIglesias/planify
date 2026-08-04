# ADR 0002 — Horario del evento como rango, no como instante

**Estado:** Aceptado
**Fecha:** 2026-08-04
**Contexto:** Fase 5, Item 5 (pedido del usuario)

## Contexto

Hasta ahora `AvailabilityService.confirmarHorario` (HU-09) guardaba un único
`fechaHoraInicio` — el organizador tocaba un bloque del heatmap y ese
instante quedaba como "el horario del evento". En la práctica los eventos
duran varias horas (un asado de 19 a 23hs, no un instante a las 19hs), y el
heatmap solo marcaba con estrella ese único bloque, aunque el evento
ocupara varias horas reales.

El pedido: el organizador elige hora de inicio y hora de fin; todo ese
rango se pinta como "horario fijado" en el heatmap (no solo el primer
bloque); y la disponibilidad para el evento se calcula sobre el rango
completo (alguien libre 19-21 pero ocupado 21-23 no cuenta como disponible
para un evento de 19 a 23).

## Decisión

1. **`Evento` gana `fechaHoraFin: DateTime | null`**, junto al ya existente
   `fechaHoraInicio`. Nullable porque un evento en `planificacion` no tiene
   ninguno de los dos todavía, y porque los eventos confirmados antes de
   este cambio no tienen fin — se leen como si tuvieran un rango de una
   sola hora (mismo comportamiento visual que tenían antes, sin necesidad
   de backfill).

2. **`AvailabilityService.confirmarHorario` pasa a pedir `fechaHoraFin`**
   además de `fechaHoraInicio`, y valida `fechaHoraFin > fechaHoraInicio`.
   No se validó contra el rango de fechas del evento (Item 1) — ver
   "Alternativas consideradas".

3. **El heatmap pinta TODOS los bloques del rango como fijados.**
   `WeeklyAvailabilityGrid.slotFijado` (un `AvailabilitySlot?`) pasa a
   `slotsFijados` (un `Set<AvailabilitySlot>`), calculado en
   `EventConfigScreen._slotsFijados` como un bloque por cada hora entre
   `fechaHoraInicio.hour` y `fechaHoraFin.hour` (exclusivo).

4. **Nueva capacidad: "cuánta gente está libre en TODO el rango".** Se
   agrega `DisponibilidadRepository.disponiblesEnRango(eventoId, diaSemana,
   bloqueHoraInicio, bloqueHoraFin)`, que cuenta participantes que tienen
   **todos** los bloques del rango marcados como disponibles (intersección,
   no unión) — no alcanza con estar libre en un bloque suelto del rango.
   Mismo criterio de exclusión que el heatmap normal (Item 4: quien dijo
   "No voy" no cuenta). Expuesto por `GET
   /events/:id/availability/range?diaSemana=&horaInicio=&horaFin=`.
   El organizador la ve en vivo al elegir la hora de fin (después de tocar
   la hora de inicio en el heatmap), así decide con esa información en vez
   de a ciegas — es la forma en que "el cálculo de disponibilidad afecta
   qué slot recomendar" sin construir un motor de recomendación automática
   que nadie pidió explícitamente.

5. **Flujo mobile: tocar el heatmap sigue siendo el punto de entrada**, pero
   ahora abre un selector de hora de fin (diálogo con dropdown + el conteo
   de disponibilidad del punto 4) en vez de confirmar directo con un solo
   toque.

## Alternativas consideradas

- **Validar `fechaHoraInicio`/`fechaHoraFin` contra el `rangoInicio`/
  `rangoFin` del evento (Item 1):** se decidió NO agregar esta validación
  cruzada. El heatmap trabaja en día-de-semana + hora, no en fechas
  concretas — "la próxima ocurrencia de ese día de la semana" (cálculo ya
  existente en el mobile) cae casi siempre dentro del rango del evento
  porque el rango típico dura semanas, no días. Agregar la validación
  hubiera acoplado dos features que se pidieron y se implementan por
  separado, con alto riesgo de romper tests existentes que no configuran
  ningún rango de fechas explícito, para un beneficio marginal. Si en el
  futuro se junta con Item 1 en la misma rama, vale la pena reconsiderarlo.
- **Motor de "mejor horario recomendado":** descartado — el criterio de
  aceptación pide que el cálculo de disponibilidad "pueda afectar" la
  decisión, no que el sistema decida solo. `disponiblesEnRango` le da esa
  información al organizador mientras elige, que es más barato de construir
  y más fácil de auditar que una recomendación automática.
- **Guardar la duración en vez de la hora de fin:** descartado — guardar
  `fechaHoraFin` explícito es más simple de leer/mostrar en cualquier
  pantalla (no hay que sumar duración + inicio cada vez) y es el mismo
  patrón que usan la mayoría de los calendarios.

## Consecuencias

- Todo caller de `EventoRepository.confirmarHorario`/
  `AvailabilityService.confirmarHorario` que no pase `fechaHoraFin` deja de
  compilar — intencional.
- `WeeklyAvailabilityGrid` cambia su API pública (`slotFijado` →
  `slotsFijados`); el único consumidor productivo (`EventConfigScreen`) se
  actualiza en el mismo cambio.
- La UI de confirmar horario pasa de "un toque" a "tocar + elegir fin +
  confirmar" — más pasos, pero refleja que un evento real dura varias
  horas, que era exactamente el problema reportado.
