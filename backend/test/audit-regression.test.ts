/**
 * Tests de regresión de la auditoría (docs/04-auditoria.md → docs/05-fixes.md).
 * Cada bloque referencia el ID del hallazgo que cubre, para que no vuelva a
 * romperse.
 */
import { ActivityLogService } from '../src/modules/activity-log/activity-log.service';
import { EventsService } from '../src/modules/events/events.service';
import { EventsQueryService } from '../src/modules/events/events.queries';
import { GroupsService } from '../src/modules/groups/groups.service';
import { InvitationsService } from '../src/modules/invitations/invitations.service';
import {
  FakeClock,
  FakeDeudaRepository,
  FakeEventoRepository,
  FakeGastoRepository,
  FakeGrupoRepository,
  FakeIdGenerator,
  FakeInvitacionRepository,
  FakeLogActividadRepository,
  FakeParticipanteRepository,
  FakeTareaRepository,
  FakeUsuarioRepository,
} from './fakes';

function armar() {
  const usuarios = new FakeUsuarioRepository();
  const participantes = new FakeParticipanteRepository();
  const eventos = new FakeEventoRepository(participantes);
  const grupos = new FakeGrupoRepository(usuarios);
  const tareas = new FakeTareaRepository();
  const gastos = new FakeGastoRepository();
  const deudas = new FakeDeudaRepository(participantes);
  const logs = new FakeLogActividadRepository();
  const invitaciones = new FakeInvitacionRepository();
  const clock = new FakeClock();
  const ids = new FakeIdGenerator();
  const log = new ActivityLogService(logs, participantes, clock);

  const events = new EventsService(eventos, grupos, participantes, usuarios, log);
  const eventsQuery = new EventsQueryService(eventos, participantes, deudas, tareas, gastos, clock);
  const invitations = new InvitationsService(invitaciones, eventos, ids, clock);
  const groups = new GroupsService(
    grupos,
    eventos,
    usuarios,
    tareas,
    gastos,
    log,
    clock,
    participantes,
    invitations,
  );

  return {
    events,
    eventsQuery,
    groups,
    invitations,
    usuarios,
    participantes,
    eventos,
    grupos,
    clock,
  };
}

describe('H-01 — los miembros del grupo se vuelven participantes del evento', () => {
  it('al crear un evento reutilizando un grupo, todos sus miembros participan', async () => {
    const { events, usuarios, grupos, participantes } = armar();
    const orga = usuarios.agregar({ nombre: 'Marcos' });
    const sofia = usuarios.agregar({ nombre: 'Sofía' });
    const pedro = usuarios.agregar({ nombre: 'Pedro' });
    const grupo = await grupos.create('Los Fibes', [orga.id, sofia.id, pedro.id]);

    const { evento } = await events.crear(orga.id, {
      nombre: 'Asado',
      lugarTexto: 'Casa',
      grupoId: grupo.id,
    });

    const enEvento = await participantes.listByEvento(evento.id);
    const nombres = enEvento.map((p) => p.nombreDisplay).sort();
    // Antes del fix, acá solo estaba 'Marcos' (el organizador).
    expect(nombres).toEqual(['Marcos', 'Pedro', 'Sofía']);
    // Los no-organizadores arrancan sin confirmar.
    const sofiaPart = enEvento.find((p) => p.nombreDisplay === 'Sofía')!;
    expect(sofiaPart.esOrganizador).toBe(false);
    expect(sofiaPart.usuarioId).toBe(sofia.id);
    expect(sofiaPart.estadoAsistencia).toBe('sin_confirmar');
  });

  it('al crear con miembros sueltos (HU-04), esos miembros también participan', async () => {
    const { events, usuarios, participantes } = armar();
    const orga = usuarios.agregar({ nombre: 'Ana' });
    const luis = usuarios.agregar({ nombre: 'Luis' });

    const { evento } = await events.crear(orga.id, {
      nombre: 'Cine',
      lugarTexto: 'Shopping',
      nuevoGrupoNombre: 'Salidas',
      miembroUsuarioIds: [luis.id],
    });

    const nombres = (await participantes.listByEvento(evento.id))
      .map((p) => p.nombreDisplay)
      .sort();
    expect(nombres).toEqual(['Ana', 'Luis']);
  });

  it('sumar un amigo al grupo lo vuelve participante de los eventos activos (Duda #12.2)', async () => {
    const { events, groups, usuarios, participantes, grupos } = armar();
    const orga = usuarios.agregar({ nombre: 'Ana' });
    const nuevo = usuarios.agregar({ nombre: 'Bruno' });

    const { evento } = await events.crear(orga.id, {
      nombre: 'Juntada',
      lugarTexto: 'Casa',
      nuevoGrupoNombre: 'G',
    });

    // Antes de agregarlo, Bruno no participa.
    expect((await participantes.listByEvento(evento.id)).map((p) => p.nombreDisplay)).toEqual([
      'Ana',
    ]);

    const grupoId = (await grupos.listByUsuario(orga.id))[0].id;
    await groups.agregarMiembro(grupoId, orga.id, nuevo.id);

    const nombres = (await participantes.listByEvento(evento.id))
      .map((p) => p.nombreDisplay)
      .sort();
    expect(nombres).toEqual(['Ana', 'Bruno']);
  });

  it('no duplica participantes si el amigo ya participaba (idempotente)', async () => {
    const { groups, usuarios, participantes, eventos, grupos } = armar();
    const orga = usuarios.agregar({ nombre: 'Ana' });
    const bruno = usuarios.agregar({ nombre: 'Bruno' });
    const grupo = await grupos.create('G', [orga.id]);
    const evento = eventos.agregar({ grupoId: grupo.id, estado: 'confirmado' });
    participantes.agregar({ eventoId: evento.id, usuarioId: bruno.id, nombreDisplay: 'Bruno' });

    await groups.agregarMiembro(grupo.id, orga.id, bruno.id);

    const deBruno = (await participantes.listByEvento(evento.id)).filter(
      (p) => p.usuarioId === bruno.id,
    );
    expect(deBruno).toHaveLength(1);
  });
});

describe('H-04 — soyOrganizador se decide por quién mira, no por la lista', () => {
  it('el organizador ve soyOrganizador=true; un anónimo del mismo evento, false', async () => {
    const { events, eventsQuery, usuarios, participantes } = armar();
    const orga = usuarios.agregar({ nombre: 'Marcos' });
    const { evento, organizador } = await events.crear(orga.id, {
      nombre: 'Asado',
      lugarTexto: 'Casa',
      nuevoGrupoNombre: 'G',
    });
    const anonimo = participantes.agregar({
      eventoId: evento.id,
      esAnonimo: true,
      nombreDisplay: 'Sofía',
    });

    const vistaOrga = await eventsQuery.detalle(evento.id, organizador.id);
    expect(vistaOrga.soyOrganizador).toBe(true);
    expect(vistaOrga.miParticipanteId).toBe(organizador.id);

    const vistaAnon = await eventsQuery.detalle(evento.id, anonimo.id);
    expect(vistaAnon.soyOrganizador).toBe(false);
    expect(vistaAnon.miParticipanteId).toBe(anonimo.id);
  });
});

describe('H-09 — Próximos/Historial se parten por fecha, no solo por estado', () => {
  it('un confirmado con fecha pasada va a Historial; con fecha futura, a Próximos', async () => {
    const { events, eventsQuery, usuarios, eventos } = armar();
    const orga = usuarios.agregar({ nombre: 'Ana' }); // el clock del fake = 2026-07-28

    const { evento: pasado } = await events.crear(orga.id, {
      nombre: 'Asado de julio',
      lugarTexto: 'X',
      nuevoGrupoNombre: 'G1',
    });
    await eventos.confirmarHorario(pasado.id, new Date('2026-07-01T20:00:00Z'));

    const { evento: futuro } = await events.crear(orga.id, {
      nombre: 'Asado de agosto',
      lugarTexto: 'Y',
      nuevoGrupoNombre: 'G2',
    });
    await eventos.confirmarHorario(futuro.id, new Date('2026-08-15T20:00:00Z'));

    // Y uno todavía en planificación (sin fecha): siempre próximo.
    await events.crear(orga.id, {
      nombre: 'Sin fecha',
      lugarTexto: 'Z',
      nuevoGrupoNombre: 'G3',
    });

    const proximos = (await eventsQuery.proximosDe(orga.id)).map((e) => e.nombre).sort();
    const historial = (await eventsQuery.historialDe(orga.id)).map((e) => e.nombre);

    expect(proximos).toEqual(['Asado de agosto', 'Sin fecha']);
    expect(historial).toContain('Asado de julio');
    // El evento futuro NO aparece también en historial (era el bug H-09).
    expect(historial).not.toContain('Asado de agosto');
  });
});
