import { ActivityLogService } from '../src/modules/activity-log/activity-log.service';
import { ActivityType } from '../src/modules/activity-log/activity-log.types';
import { GroupsService } from '../src/modules/groups/groups.service';
import { InvitationsService } from '../src/modules/invitations/invitations.service';
import { TasksService } from '../src/modules/tasks/tasks.service';
import {
  FakeClock,
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

function armarTasks() {
  const participantes = new FakeParticipanteRepository();
  const eventos = new FakeEventoRepository(participantes);
  const tareas = new FakeTareaRepository();
  const logs = new FakeLogActividadRepository();
  const log = new ActivityLogService(logs, participantes, new FakeClock());

  return {
    service: new TasksService(tareas, eventos, participantes, log),
    participantes,
    eventos,
    tareas,
    logs,
  };
}

describe('TasksService — estados de tarea (Duda #4)', () => {
  it('una tarea nueva arranca sin asignar', async () => {
    const { service, eventos, participantes } = armarTasks();
    const evento = eventos.agregar();
    const p = participantes.agregar({ eventoId: evento.id });

    const tarea = await service.crear(evento.id, p.id, 'Comprar carne');

    expect(tarea.estado).toBe('no_asignado');
    expect(tarea.asignadoA).toBeNull();
  });

  it('tomarla la pasa a pendiente (HU-21)', async () => {
    const { service, eventos, participantes } = armarTasks();
    const evento = eventos.agregar();
    const p = participantes.agregar({ eventoId: evento.id });

    const tarea = await service.crear(evento.id, p.id, 'Comprar hielo');
    const asignada = await service.asignar(tarea.id, p.id, p.id);

    expect(asignada.estado).toBe('pendiente');
    expect(asignada.asignadoA).toBe(p.id);
  });

  it('se puede asignar a otro participante (HU-22)', async () => {
    const { service, eventos, participantes, logs } = armarTasks();
    const evento = eventos.agregar();
    const quienAsigna = participantes.agregar({ eventoId: evento.id });
    const asignado = participantes.agregar({ eventoId: evento.id, nombreDisplay: 'Sofía' });

    const tarea = await service.crear(evento.id, quienAsigna.id, 'Pedir pizzas');
    const resultado = await service.asignar(tarea.id, quienAsigna.id, asignado.id);

    expect(resultado.asignadoA).toBe(asignado.id);
    // El feed distingue "me la tomé" de "se la asigné a alguien".
    const entrada = logs.entradas.find((e) => e.tipo === ActivityType.tareaAsignada);
    expect(entrada?.payload).toMatchObject({ autoAsignada: false });
  });

  it('no deja asignar a alguien que no participa del evento', async () => {
    const { service, eventos, participantes } = armarTasks();
    const evento = eventos.agregar();
    const otroEvento = eventos.agregar();
    const p = participantes.agregar({ eventoId: evento.id });
    const ajeno = participantes.agregar({ eventoId: otroEvento.id });

    const tarea = await service.crear(evento.id, p.id, 'Traer hielo');

    await expect(service.asignar(tarea.id, p.id, ajeno.id)).rejects.toThrow(/no participa/);
  });

  it('completarla la cierra y no se puede completar dos veces (HU-23)', async () => {
    const { service, eventos, participantes } = armarTasks();
    const evento = eventos.agregar();
    const p = participantes.agregar({ eventoId: evento.id });

    const tarea = await service.crear(evento.id, p.id, 'Comprar pan');
    await service.asignar(tarea.id, p.id, p.id);

    const completada = await service.completar(tarea.id, p.id);
    expect(completada.estado).toBe('completado');

    await expect(service.completar(tarea.id, p.id)).rejects.toThrow(/ya está completada/);
  });

  it('no deja crear tareas en un evento cancelado', async () => {
    const { service, eventos, participantes } = armarTasks();
    const evento = eventos.agregar({ estado: 'cancelado' });
    const p = participantes.agregar({ eventoId: evento.id });

    await expect(service.crear(evento.id, p.id, 'Algo')).rejects.toThrow(/cancelado/);
  });

  it('exige un título', async () => {
    const { service, eventos, participantes } = armarTasks();
    const evento = eventos.agregar();
    const p = participantes.agregar({ eventoId: evento.id });

    await expect(service.crear(evento.id, p.id, '   ')).rejects.toThrow(/titulo/);
  });
});

function armarGroups() {
  const usuarios = new FakeUsuarioRepository();
  const grupos = new FakeGrupoRepository(usuarios);
  const participantes = new FakeParticipanteRepository();
  const eventos = new FakeEventoRepository(participantes);
  const tareas = new FakeTareaRepository();
  const gastos = new FakeGastoRepository();
  const logs = new FakeLogActividadRepository();
  const clock = new FakeClock();
  const log = new ActivityLogService(logs, participantes, clock);
  const invitaciones = new FakeInvitacionRepository();
  const invitations = new InvitationsService(invitaciones, eventos, new FakeIdGenerator(), clock);

  return {
    service: new GroupsService(
      grupos,
      eventos,
      usuarios,
      tareas,
      gastos,
      log,
      clock,
      participantes,
      invitations,
    ),
    grupos,
    eventos,
    usuarios,
    participantes,
    invitaciones,
    invitations,
    clock,
  };
}

describe('GroupsService — gestión de miembros (Duda #12.2)', () => {
  it('un miembro puede renombrar el grupo (HU-34)', async () => {
    const { service, grupos, usuarios } = armarGroups();
    const usuario = usuarios.agregar();
    const grupo = await grupos.create('Nombre viejo', [usuario.id]);

    const renombrado = await service.renombrar(grupo.id, usuario.id, 'Los Fibes');

    expect(renombrado.nombre).toBe('Los Fibes');
  });

  it('alguien de afuera no puede renombrar el grupo', async () => {
    const { service, grupos, usuarios } = armarGroups();
    const miembro = usuarios.agregar();
    const intruso = usuarios.agregar();
    const grupo = await grupos.create('Privado', [miembro.id]);

    await expect(service.renombrar(grupo.id, intruso.id, 'Hackeado')).rejects.toThrow(
      /miembro/,
    );
  });

  it('permite sumar un amigo registrado (HU-32)', async () => {
    const { service, grupos, usuarios } = armarGroups();
    const miembro = usuarios.agregar();
    const amigo = usuarios.agregar();
    const grupo = await grupos.create('Los Fibes', [miembro.id]);

    await service.agregarMiembro(grupo.id, miembro.id, amigo.id);

    expect(await grupos.esMiembro(grupo.id, amigo.id)).toBe(true);
  });

  it('no deja agregar dos veces a la misma persona', async () => {
    const { service, grupos, usuarios } = armarGroups();
    const miembro = usuarios.agregar();
    const amigo = usuarios.agregar();
    const grupo = await grupos.create('G', [miembro.id, amigo.id]);

    await expect(service.agregarMiembro(grupo.id, miembro.id, amigo.id)).rejects.toThrow(
      /ya es miembro/,
    );
  });

  it('no deja agregar a un usuario inexistente', async () => {
    const { service, grupos, usuarios } = armarGroups();
    const miembro = usuarios.agregar();
    const grupo = await grupos.create('G', [miembro.id]);

    await expect(
      service.agregarMiembro(grupo.id, miembro.id, 'usuario-fantasma'),
    ).rejects.toThrow(/no existe/);
  });

  it('permite abandonar el grupo si queda alguien más (HU-33)', async () => {
    const { service, grupos, usuarios } = armarGroups();
    const uno = usuarios.agregar();
    const otro = usuarios.agregar();
    const grupo = await grupos.create('G', [uno.id, otro.id]);

    await service.abandonar(grupo.id, uno.id);

    expect(await grupos.esMiembro(grupo.id, uno.id)).toBe(false);
    expect(await grupos.esMiembro(grupo.id, otro.id)).toBe(true);
  });

  it('impide abandonar si sos el único miembro (dejaría eventos huérfanos)', async () => {
    const { service, grupos, usuarios } = armarGroups();
    const solo = usuarios.agregar();
    const grupo = await grupos.create('G', [solo.id]);

    await expect(service.abandonar(grupo.id, solo.id)).rejects.toThrow(/único miembro/);
  });
});

describe('GroupsService — unirse por invitación con cuenta real (Item 2)', () => {
  it('un usuario registrado se une al grupo y queda participante del evento, no anónimo', async () => {
    const { service, grupos, eventos, usuarios, participantes, invitations } = armarGroups();
    const organizador = usuarios.agregar({ nombre: 'Marcos' });
    const invitado = usuarios.agregar({ nombre: 'Sofía' });
    const grupo = await grupos.create('Los Fibes', [organizador.id]);
    const evento = eventos.agregar({ grupoId: grupo.id, estado: 'planificacion' });

    const invitacion = await invitations.crear(evento.id);
    const resultado = await service.unirsePorInvitacion(invitacion.tokenUnico, invitado.id);

    expect(resultado).toEqual({ eventoId: evento.id, grupoId: grupo.id });
    expect(await grupos.esMiembro(grupo.id, invitado.id)).toBe(true);

    const participantesDelEvento = await participantes.listByEvento(evento.id);
    const propio = participantesDelEvento.find((p) => p.usuarioId === invitado.id);
    expect(propio).toBeDefined();
    expect(propio?.esAnonimo).toBe(false);
  });

  it('reusar el link cuando ya es miembro del grupo no falla (idempotente)', async () => {
    const { service, grupos, eventos, usuarios, invitations } = armarGroups();
    const organizador = usuarios.agregar({ nombre: 'Marcos' });
    const invitado = usuarios.agregar({ nombre: 'Sofía' });
    const grupo = await grupos.create('Los Fibes', [organizador.id]);
    const evento = eventos.agregar({ grupoId: grupo.id, estado: 'planificacion' });
    const invitacion = await invitations.crear(evento.id);

    await service.unirsePorInvitacion(invitacion.tokenUnico, invitado.id);
    await expect(
      service.unirsePorInvitacion(invitacion.tokenUnico, invitado.id),
    ).resolves.toEqual({ eventoId: evento.id, grupoId: grupo.id });
  });

  it('un token inexistente rechaza la unión', async () => {
    const { service, usuarios } = armarGroups();
    const invitado = usuarios.agregar({ nombre: 'Sofía' });

    await expect(
      service.unirsePorInvitacion('token-que-no-existe', invitado.id),
    ).rejects.toThrow(/no encontrada/);
  });
});

describe('GroupsService — badge "NUEVO" (Duda #2)', () => {
  it('marca el grupo como nuevo si tiene un evento reciente', async () => {
    const { service, grupos, eventos, usuarios, clock } = armarGroups();
    const usuario = usuarios.agregar();
    const grupo = await grupos.create('Los Fibes', [usuario.id]);
    eventos.agregar({ grupoId: grupo.id, createdAt: clock.now() });

    const resumen = await service.resumenPara(usuario.id);

    expect(resumen[0].tieneEventoNuevo).toBe(true);
  });

  it('deja de marcarlo pasadas 48 horas', async () => {
    const { service, grupos, eventos, usuarios, clock } = armarGroups();
    const usuario = usuarios.agregar();
    const grupo = await grupos.create('Los Fibes', [usuario.id]);
    eventos.agregar({ grupoId: grupo.id, createdAt: clock.now() });

    clock.avanzarHoras(49);
    const resumen = await service.resumenPara(usuario.id);

    expect(resumen[0].tieneEventoNuevo).toBe(false);
  });
});

describe('GroupsService — eventos del grupo en el resumen (Item 1)', () => {
  it('devuelve TODOS los eventos activos del grupo, no solo el próximo', async () => {
    const { service, grupos, eventos, usuarios } = armarGroups();
    const usuario = usuarios.agregar();
    const grupo = await grupos.create('Los Fibes', [usuario.id]);
    const asado = eventos.agregar({
      grupoId: grupo.id,
      nombre: 'Asado',
      estado: 'planificacion',
    });
    const futbol = eventos.agregar({
      grupoId: grupo.id,
      nombre: 'Fútbol 5',
      estado: 'confirmado',
    });

    const resumen = await service.resumenPara(usuario.id);

    const ids = resumen[0].eventos.map((e) => e.id).sort();
    expect(ids).toEqual([asado.id, futbol.id].sort());
  });

  it('no incluye eventos finalizados o cancelados', async () => {
    const { service, grupos, eventos, usuarios } = armarGroups();
    const usuario = usuarios.agregar();
    const grupo = await grupos.create('Los Fibes', [usuario.id]);
    eventos.agregar({ grupoId: grupo.id, nombre: 'Activo', estado: 'planificacion' });
    eventos.agregar({ grupoId: grupo.id, nombre: 'Viejo', estado: 'finalizado' });
    eventos.agregar({ grupoId: grupo.id, nombre: 'Cancelado', estado: 'cancelado' });

    const resumen = await service.resumenPara(usuario.id);

    expect(resumen[0].eventos.map((e) => e.nombre)).toEqual(['Activo']);
  });

  it('los eventos de un grupo distinto no se mezclan con los de otro', async () => {
    const { service, grupos, eventos, usuarios } = armarGroups();
    const usuario = usuarios.agregar();
    const grupoUno = await grupos.create('Los Fibes', [usuario.id]);
    const grupoDos = await grupos.create('La Facu', [usuario.id]);
    eventos.agregar({ grupoId: grupoUno.id, nombre: 'Asado', estado: 'planificacion' });
    eventos.agregar({ grupoId: grupoDos.id, nombre: 'Parcial', estado: 'planificacion' });

    const resumen = await service.resumenPara(usuario.id);

    const porGrupo = new Map(resumen.map((r) => [r.id, r.eventos.map((e) => e.nombre)]));
    expect(porGrupo.get(grupoUno.id)).toEqual(['Asado']);
    expect(porGrupo.get(grupoDos.id)).toEqual(['Parcial']);
  });
});
