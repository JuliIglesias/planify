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
  const events = new EventsService(eventos, grupos, participantes, usuarios, log, clock);
  const availability = new AvailabilityService(disponibilidad, eventos, events, log);

  return { availability, events, eventos, participantes, disponibilidad, clock, usuarios, grupos };
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

describe('AvailabilityService — horario como rango, no como slot único (Item 5)', () => {
  it('confirmarHorario guarda inicio Y fin, y pasa el evento a confirmado', async () => {
    const { availability, events, usuarios, grupos } = armar();
    const usuario = usuarios.agregar();
    const grupo = await grupos.create('G', [usuario.id]);
    const { evento } = await events.crear(usuario.id, {
      nombre: 'Asado',
      lugarTexto: 'Casa',
      grupoId: grupo.id,
    });

    const confirmado = await availability.confirmarHorario(
      usuario.id,
      evento.id,
      new Date('2026-08-14T19:00:00Z'),
      new Date('2026-08-14T23:00:00Z'),
    );

    expect(confirmado.estado).toBe('confirmado');
    expect(confirmado.fechaHoraInicio).toEqual(new Date('2026-08-14T19:00:00Z'));
    expect(confirmado.fechaHoraFin).toEqual(new Date('2026-08-14T23:00:00Z'));
  });

  it('rechaza un fechaHoraFin anterior o igual a fechaHoraInicio', async () => {
    const { availability, events, usuarios, grupos } = armar();
    const usuario = usuarios.agregar();
    const grupo = await grupos.create('G', [usuario.id]);
    const { evento } = await events.crear(usuario.id, {
      nombre: 'Asado',
      lugarTexto: 'Casa',
      grupoId: grupo.id,
    });

    await expect(
      availability.confirmarHorario(
        usuario.id,
        evento.id,
        new Date('2026-08-14T23:00:00Z'),
        new Date('2026-08-14T19:00:00Z'),
      ),
    ).rejects.toThrow(/fechaHoraFin/);

    await expect(
      availability.confirmarHorario(
        usuario.id,
        evento.id,
        new Date('2026-08-14T19:00:00Z'),
        new Date('2026-08-14T19:00:00Z'),
      ),
    ).rejects.toThrow(/fechaHoraFin/);
  });

  it('disponiblesEnRango cuenta solo a quien está libre en TODOS los bloques del rango', async () => {
    const { availability, eventos, participantes, disponibilidad } = armar();
    const evento = eventos.agregar();
    // Libre 19,20,21,22 (todo "19 a 23hs").
    const libreTodo = participantes.agregar({ eventoId: evento.id, estadoAsistencia: 'confirmado' });
    // Libre solo 19 y 20: no cubre el rango completo.
    const libreParcial = participantes.agregar({ eventoId: evento.id, estadoAsistencia: 'confirmado' });

    for (const hora of [19, 20, 21, 22]) {
      disponibilidad.slots.push({
        eventoId: evento.id,
        participanteId: libreTodo.id,
        diaSemana: 4,
        bloqueHora: hora,
      });
    }
    for (const hora of [19, 20]) {
      disponibilidad.slots.push({
        eventoId: evento.id,
        participanteId: libreParcial.id,
        diaSemana: 4,
        bloqueHora: hora,
      });
    }

    const resultado = await availability.disponiblesEnRango(evento.id, 4, 19, 23);

    expect(resultado).toEqual({ disponibles: 1, total: 2 });
  });

  it('disponiblesEnRango excluye a quien dijo "No voy", igual que el heatmap', async () => {
    const { availability, eventos, participantes, disponibilidad } = armar();
    const evento = eventos.agregar();
    const noVa = participantes.agregar({ eventoId: evento.id, estadoAsistencia: 'rechazado' });
    for (const hora of [19, 20]) {
      disponibilidad.slots.push({
        eventoId: evento.id,
        participanteId: noVa.id,
        diaSemana: 1,
        bloqueHora: hora,
      });
    }

    const resultado = await availability.disponiblesEnRango(evento.id, 1, 19, 21);

    expect(resultado).toEqual({ disponibles: 0, total: 0 });
  });

  it('rechaza un rango horario inválido (fin <= inicio, o fuera de 0..24)', async () => {
    const { availability, eventos } = armar();
    const evento = eventos.agregar();

    await expect(availability.disponiblesEnRango(evento.id, 0, 20, 19)).rejects.toThrow(
      /rango horario/,
    );
    await expect(availability.disponiblesEnRango(evento.id, 0, -1, 5)).rejects.toThrow(
      /rango horario/,
    );
    await expect(availability.disponiblesEnRango(evento.id, 0, 20, 25)).rejects.toThrow(
      /rango horario/,
    );
  });
});
