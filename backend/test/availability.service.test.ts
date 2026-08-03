/**
 * Item 4 (segunda tanda de UX) — "No voy" debe excluir del heatmap grupal, y
 * volver a "Voy" debe reincorporar. La persistencia de la asistencia en sí
 * ya estaba cubierta en events.service.test.ts (sigue en verde) — acá se
 * cubre específicamente el cruce con el heatmap, que no existía.
 */
import { ActivityLogService } from '../src/modules/activity-log/activity-log.service';
import { AvailabilityService } from '../src/modules/availability/availability.service';
import { EventsService } from '../src/modules/events/events.service';
import {
  FakeClock,
  FakeDisponibilidadRepository,
  FakeEventoRepository,
  FakeGrupoRepository,
  FakeLogActividadRepository,
  FakeParticipanteRepository,
  FakeUsuarioRepository,
} from './fakes';

function armar() {
  const usuarios = new FakeUsuarioRepository();
  const grupos = new FakeGrupoRepository(usuarios);
  const participantes = new FakeParticipanteRepository();
  const eventos = new FakeEventoRepository(participantes);
  const disponibilidad = new FakeDisponibilidadRepository(participantes);
  const logs = new FakeLogActividadRepository();
  const clock = new FakeClock();
  const log = new ActivityLogService(logs, participantes, clock);
  const events = new EventsService(eventos, grupos, participantes, usuarios, log);
  const availability = new AvailabilityService(disponibilidad, eventos, events, log);

  return { availability, events, eventos, participantes, disponibilidad, clock };
}

describe('AvailabilityService — heatmap excluye a quien dijo "No voy" (Item 4)', () => {
  it('cuenta la disponibilidad de un participante sin responder o confirmado', async () => {
    const { availability, eventos, participantes, disponibilidad } = armar();
    const evento = eventos.agregar();
    const p1 = participantes.agregar({ eventoId: evento.id, estadoAsistencia: 'sin_confirmar' });
    const p2 = participantes.agregar({ eventoId: evento.id, estadoAsistencia: 'confirmado' });
    disponibilidad.slots.push(
      { eventoId: evento.id, participanteId: p1.id, diaSemana: 0, bloqueHora: 20 },
      { eventoId: evento.id, participanteId: p2.id, diaSemana: 0, bloqueHora: 20 },
    );

    const heatmap = await availability.heatmap(evento.id);

    expect(heatmap).toEqual([{ diaSemana: 0, bloqueHora: 20, disponibles: 2 }]);
  });

  it('excluye del conteo a quien respondió "No voy"', async () => {
    const { availability, eventos, participantes, disponibilidad } = armar();
    const evento = eventos.agregar();
    const va = participantes.agregar({ eventoId: evento.id, estadoAsistencia: 'confirmado' });
    const noVa = participantes.agregar({ eventoId: evento.id, estadoAsistencia: 'rechazado' });
    disponibilidad.slots.push(
      { eventoId: evento.id, participanteId: va.id, diaSemana: 2, bloqueHora: 21 },
      { eventoId: evento.id, participanteId: noVa.id, diaSemana: 2, bloqueHora: 21 },
    );

    const heatmap = await availability.heatmap(evento.id);

    expect(heatmap).toEqual([{ diaSemana: 2, bloqueHora: 21, disponibles: 1 }]);
  });

  it('un bloque donde solo hay disponibilidad de quien dijo "No voy" no aparece', async () => {
    const { availability, eventos, participantes, disponibilidad } = armar();
    const evento = eventos.agregar();
    const noVa = participantes.agregar({ eventoId: evento.id, estadoAsistencia: 'rechazado' });
    disponibilidad.slots.push({
      eventoId: evento.id,
      participanteId: noVa.id,
      diaSemana: 3,
      bloqueHora: 10,
    });

    const heatmap = await availability.heatmap(evento.id);

    expect(heatmap).toEqual([]);
  });

  it('al volver a "Voy" su disponibilidad se vuelve a contar', async () => {
    const { availability, eventos, participantes, disponibilidad, events } = armar();
    const evento = eventos.agregar();
    const persona = participantes.agregar({ eventoId: evento.id, estadoAsistencia: 'confirmado' });
    disponibilidad.slots.push({
      eventoId: evento.id,
      participanteId: persona.id,
      diaSemana: 1,
      bloqueHora: 9,
    });

    await events.responderAsistencia(persona.id, 'rechazado');
    expect(await availability.heatmap(evento.id)).toEqual([]);

    await events.responderAsistencia(persona.id, 'confirmado');
    expect(await availability.heatmap(evento.id)).toEqual([
      { diaSemana: 1, bloqueHora: 9, disponibles: 1 },
    ]);
  });
});
