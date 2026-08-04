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

// FakeClock arranca en 2026-07-28T12:00:00Z (ver fakes.ts) — este rango
// siempre cae después de "ahora" en los tests de este archivo.
const RANGO = {
  rangoInicio: new Date('2026-08-01T00:00:00Z'),
  rangoFin: new Date('2026-08-20T00:00:00Z'),
};

function armar() {
  const participantes = new FakeParticipanteRepository();
  const eventos = new FakeEventoRepository(participantes);
  const grupos = new FakeGrupoRepository();
  const usuarios = new FakeUsuarioRepository();
  const logs = new FakeLogActividadRepository();
  const clock = new FakeClock();
  const log = new ActivityLogService(logs, participantes, clock);

  const service = new EventsService(eventos, grupos, participantes, usuarios, log, clock);

  return { service, participantes, eventos, grupos, usuarios, logs, clock };
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
      ...RANGO,
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
      ...RANGO,
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
      ...RANGO,
    });

    expect(logs.tipos()).toContain(ActivityType.eventoCreado);
  });

  it('rechaza crear sin nombre o sin lugar', async () => {
    const { service, usuarios, grupos } = armar();
    const usuario = usuarios.agregar();
    const grupo = await grupos.create('G', [usuario.id]);

    await expect(
      service.crear(usuario.id, { nombre: '  ', lugarTexto: 'Casa', grupoId: grupo.id, ...RANGO }),
    ).rejects.toThrow(/nombre/);

    await expect(
      service.crear(usuario.id, { nombre: 'Asado', lugarTexto: '', grupoId: grupo.id, ...RANGO }),
    ).rejects.toThrow(/lugarTexto/);
  });

  it('rechaza crear sin grupo ni nombre de grupo nuevo (Duda #1)', async () => {
    const { service, usuarios } = armar();
    const usuario = usuarios.agregar();

    await expect(
      service.crear(usuario.id, { nombre: 'Asado', lugarTexto: 'Casa', ...RANGO }),
    ).rejects.toThrow(/grupoId/);
  });

  it('no deja crear un evento en un grupo del que no sos miembro', async () => {
    const { service, usuarios, grupos } = armar();
    const ajeno = usuarios.agregar();
    const intruso = usuarios.agregar();
    const grupo = await grupos.create('Privado', [ajeno.id]);

    await expect(
      service.crear(intruso.id, { nombre: 'Asado', lugarTexto: 'Casa', grupoId: grupo.id, ...RANGO }),
    ).rejects.toThrow(/miembro/);
  });

  it('rechaza un rango de fechas inválido (Item 1)', async () => {
    const { service, usuarios, grupos } = armar();
    const usuario = usuarios.agregar();
    const grupo = await grupos.create('G', [usuario.id]);

    await expect(
      service.crear(usuario.id, {
        nombre: 'Asado',
        lugarTexto: 'Casa',
        grupoId: grupo.id,
        rangoInicio: new Date('2026-08-20T00:00:00Z'),
        rangoFin: new Date('2026-08-01T00:00:00Z'),
      }),
    ).rejects.toThrow(/rangoInicio/);

    await expect(
      service.crear(usuario.id, {
        nombre: 'Asado',
        lugarTexto: 'Casa',
        grupoId: grupo.id,
        rangoInicio: new Date('2026-01-01T00:00:00Z'),
        rangoFin: new Date('2026-01-10T00:00:00Z'),
      }),
    ).rejects.toThrow(/rangoFin/);
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
      ...RANGO,
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
      ...RANGO,
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
      ...RANGO,
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

describe('EventsService — extensión automática del rango (Item 1)', () => {
  it('no toca el rango si todavía no venció', async () => {
    const { service, eventos } = armar();
    const evento = eventos.agregar({
      rangoInicio: new Date('2026-07-01T00:00:00Z'),
      rangoFin: new Date('2026-08-15T00:00:00Z'), // FakeClock está en 2026-07-28
    });

    const resultado = await service.chequearExtensionRango(evento.id);

    expect(resultado.rangoFin).toEqual(new Date('2026-08-15T00:00:00Z'));
    expect(resultado.extensionesRango).toBe(0);
  });

  it('extiende 14 días y notifica cuando el rango venció sin horario confirmado', async () => {
    const { service, eventos, logs } = armar();
    const evento = eventos.agregar({
      rangoInicio: new Date('2026-07-01T00:00:00Z'),
      rangoFin: new Date('2026-07-27T00:00:00Z'), // ya venció (FakeClock: 2026-07-28)
      creadoPor: 'part-organizador',
    });

    const resultado = await service.chequearExtensionRango(evento.id);

    expect(resultado.rangoFin).toEqual(new Date('2026-08-10T00:00:00Z'));
    expect(resultado.extensionesRango).toBe(1);
    expect(logs.tipos()).toContain(ActivityType.rangoExtendido);
    expect(logs.entradas[0]).toMatchObject({
      eventoId: evento.id,
      actorParticipanteId: 'part-organizador',
    });
  });

  it('no extiende un evento ya confirmado, aunque el rango haya vencido', async () => {
    const { service, eventos } = armar();
    const evento = eventos.agregar({
      estado: 'confirmado',
      rangoFin: new Date('2026-07-27T00:00:00Z'),
    });

    const resultado = await service.chequearExtensionRango(evento.id);

    expect(resultado.extensionesRango).toBe(0);
  });

  it('deja de extender solo después del tope (Item 1, tope 1)', async () => {
    const { service, eventos, logs } = armar();
    const evento = eventos.agregar({
      rangoFin: new Date('2026-07-27T00:00:00Z'),
      extensionesRango: 1, // ya usó la única extensión permitida
    });

    const resultado = await service.chequearExtensionRango(evento.id);

    expect(resultado.rangoFin).toEqual(new Date('2026-07-27T00:00:00Z'));
    expect(resultado.extensionesRango).toBe(1);
    expect(logs.tipos()).not.toContain(ActivityType.rangoExtendido);
  });
});
