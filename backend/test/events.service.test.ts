import { ActivityLogService } from '../src/modules/activity-log/activity-log.service';
import { ActivityType } from '../src/modules/activity-log/activity-log.types';
import { EventsService } from '../src/modules/events/events.service';
import {
  FakeClock,
  FakeEventoRepository,
  FakeGrupoRepository,
  FakeLogActividadRepository,
  FakeParticipanteRepository,
  FakeUsuarioRepository,
} from './fakes';

function armar() {
  const participantes = new FakeParticipanteRepository();
  const eventos = new FakeEventoRepository(participantes);
  const grupos = new FakeGrupoRepository();
  const usuarios = new FakeUsuarioRepository();
  const logs = new FakeLogActividadRepository();
  const log = new ActivityLogService(logs, participantes, new FakeClock());

  const service = new EventsService(eventos, grupos, participantes, usuarios, log);

  return { service, participantes, eventos, grupos, usuarios, logs };
}

describe('EventsService — creación (HU-06)', () => {
  it('crea el evento junto con su participante organizador', async () => {
    const { service, usuarios, grupos } = armar();
    const usuario = usuarios.agregar({ nombre: 'Julieta' });
    const grupo = await grupos.create('Los Fibes', [usuario.id]);

    const { evento, organizador } = await service.crear(usuario.id, {
      nombre: 'Asado',
      lugarTexto: 'Casa de Nacho',
      grupoId: grupo.id,
    });

    expect(evento.nombre).toBe('Asado');
    expect(evento.estado).toBe('planificacion');
    // La fecha se define después, desde el heatmap (Duda F4).
    expect(evento.fechaHoraInicio).toBeNull();
    expect(organizador.esOrganizador).toBe(true);
    expect(organizador.usuarioId).toBe(usuario.id);
  });

  it('crea un grupo nuevo cuando se eligen miembros sueltos (HU-04)', async () => {
    const { service, usuarios, grupos } = armar();
    const organizador = usuarios.agregar();
    const amigo = usuarios.agregar();

    await service.crear(organizador.id, {
      nombre: 'Cine',
      lugarTexto: 'Shopping',
      nuevoGrupoNombre: 'Salidas',
      miembroUsuarioIds: [amigo.id],
    });

    expect(grupos.grupos).toHaveLength(1);
    expect(grupos.grupos[0].nombre).toBe('Salidas');
    // El organizador queda incluido aunque no se lo pase explícitamente.
    expect(await grupos.esMiembro(grupos.grupos[0].id, organizador.id)).toBe(true);
    expect(await grupos.esMiembro(grupos.grupos[0].id, amigo.id)).toBe(true);
  });

  it('registra la creación en el log de actividad', async () => {
    const { service, usuarios, grupos, logs } = armar();
    const usuario = usuarios.agregar();
    const grupo = await grupos.create('G', [usuario.id]);

    await service.crear(usuario.id, {
      nombre: 'Asado',
      lugarTexto: 'Casa',
      grupoId: grupo.id,
    });

    expect(logs.tipos()).toContain(ActivityType.eventoCreado);
  });

  it('rechaza crear sin nombre o sin lugar', async () => {
    const { service, usuarios, grupos } = armar();
    const usuario = usuarios.agregar();
    const grupo = await grupos.create('G', [usuario.id]);

    await expect(
      service.crear(usuario.id, { nombre: '  ', lugarTexto: 'Casa', grupoId: grupo.id }),
    ).rejects.toThrow(/nombre/);

    await expect(
      service.crear(usuario.id, { nombre: 'Asado', lugarTexto: '', grupoId: grupo.id }),
    ).rejects.toThrow(/lugarTexto/);
  });

  it('rechaza crear sin grupo ni nombre de grupo nuevo (Duda #1)', async () => {
    const { service, usuarios } = armar();
    const usuario = usuarios.agregar();

    await expect(
      service.crear(usuario.id, { nombre: 'Asado', lugarTexto: 'Casa' }),
    ).rejects.toThrow(/grupoId/);
  });

  it('no deja crear un evento en un grupo del que no sos miembro', async () => {
    const { service, usuarios, grupos } = armar();
    const ajeno = usuarios.agregar();
    const intruso = usuarios.agregar();
    const grupo = await grupos.create('Privado', [ajeno.id]);

    await expect(
      service.crear(intruso.id, { nombre: 'Asado', lugarTexto: 'Casa', grupoId: grupo.id }),
    ).rejects.toThrow(/miembro/);
  });
});

describe('EventsService — cancelación (HU-11)', () => {
  it('solo el organizador puede cancelar (Duda #6)', async () => {
    const { service, usuarios, grupos, participantes } = armar();
    const organizador = usuarios.agregar();
    const otro = usuarios.agregar();
    const grupo = await grupos.create('G', [organizador.id, otro.id]);

    const { evento } = await service.crear(organizador.id, {
      nombre: 'Asado',
      lugarTexto: 'Casa',
      grupoId: grupo.id,
    });

    participantes.agregar({ eventoId: evento.id, usuarioId: otro.id });

    await expect(service.cancelar(otro.id, evento.id)).rejects.toThrow(/organizador/);
    await expect(service.cancelar(organizador.id, evento.id)).resolves.toMatchObject({
      estado: 'cancelado',
    });
  });

  it('al cancelar invalida las sesiones anónimas (Duda #5)', async () => {
    const { service, usuarios, grupos, participantes } = armar();
    const organizador = usuarios.agregar();
    const grupo = await grupos.create('G', [organizador.id]);
    const { evento } = await service.crear(organizador.id, {
      nombre: 'Asado',
      lugarTexto: 'Casa',
      grupoId: grupo.id,
    });

    const anonimo = participantes.agregar({
      eventoId: evento.id,
      esAnonimo: true,
      tokenSesion: 'token-abc',
    });

    await service.cancelar(organizador.id, evento.id);

    expect((await participantes.findById(anonimo.id))!.tokenSesion).toBeNull();
  });

  it('no se puede cancelar dos veces', async () => {
    const { service, usuarios, grupos } = armar();
    const organizador = usuarios.agregar();
    const grupo = await grupos.create('G', [organizador.id]);
    const { evento } = await service.crear(organizador.id, {
      nombre: 'Asado',
      lugarTexto: 'Casa',
      grupoId: grupo.id,
    });

    await service.cancelar(organizador.id, evento.id);
    await expect(service.cancelar(organizador.id, evento.id)).rejects.toThrow(/ya está cancelado/);
  });
});

describe('EventsService — asistencia (HU-10)', () => {
  it('cualquier participante puede confirmar o rechazar', async () => {
    const { service, participantes, eventos, logs } = armar();
    const evento = eventos.agregar();
    const participante = participantes.agregar({ eventoId: evento.id });

    const confirmado = await service.responderAsistencia(participante.id, 'confirmado');
    expect(confirmado.estadoAsistencia).toBe('confirmado');
    expect(logs.tipos()).toContain(ActivityType.asistenciaConfirmada);

    const rechazado = await service.responderAsistencia(participante.id, 'rechazado');
    expect(rechazado.estadoAsistencia).toBe('rechazado');
  });

  it('no se puede confirmar asistencia a un evento cancelado', async () => {
    const { service, participantes, eventos } = armar();
    const evento = eventos.agregar({ estado: 'cancelado' });
    const participante = participantes.agregar({ eventoId: evento.id });

    await expect(
      service.responderAsistencia(participante.id, 'confirmado'),
    ).rejects.toThrow(/cancelado/);
  });
});
