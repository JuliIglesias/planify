/**
 * G1 — identidad anónima única por evento. Ver
 * docs/adrs/0003-identidad-anonima-por-evento.md para el diseño completo.
 *
 * Reemplaza el viejo comportamiento de auto-sufijar en cualquier colisión
 * (documentado antes en docs/05-fixes.md): ahora un anónimo define un PIN
 * al unirse, puede recuperar la MISMA identidad reingresando con las
 * mismas credenciales al MISMO evento, y una colisión con OTRO evento
 * activo se rechaza (con una sugerencia) en vez de auto-sufijarse.
 */
import { ActivityLogService } from '../src/modules/activity-log/activity-log.service';
import { ParticipantsService } from '../src/modules/participants/participants.service';
import {
  FakeClock,
  FakeDeudaRepository,
  FakeEventoRepository,
  FakeIdGenerator,
  FakeLogActividadRepository,
  FakeParticipanteRepository,
  FakePasswordHasher,
  FakeUsuarioRepository,
} from './fakes';

function armar() {
  const usuarios = new FakeUsuarioRepository();
  const participantes = new FakeParticipanteRepository();
  const eventos = new FakeEventoRepository(participantes);
  const deudas = new FakeDeudaRepository(participantes);
  const logs = new FakeLogActividadRepository();
  const log = new ActivityLogService(logs, participantes, new FakeClock());
  const hasher = new FakePasswordHasher();
  const service = new ParticipantsService(
    participantes,
    usuarios,
    eventos,
    new FakeIdGenerator(),
    log,
    hasher,
    deudas,
  );

  const evento = eventos.agregar();

  return { service, usuarios, participantes, eventos, deudas, evento };
}

describe('ParticipantsService.unirseComoAnonimo — G1', () => {
  it('crear: un username libre con PIN válido crea el participante', async () => {
    const { service, participantes, evento } = armar();

    const sesion = await service.unirseComoAnonimo(evento.id, 'Sofía', 'pin1234');

    expect(participantes.participantes.map((p) => p.username)).toEqual(['Sofía']);
    expect(sesion.username).toBe('Sofía');
    expect(sesion.tokenSesion).not.toBe('');
    // El PIN nunca se guarda en texto plano.
    expect(participantes.participantes[0].pinHash).not.toBe('pin1234');
  });

  it('rechaza sin PIN o con un PIN demasiado corto', async () => {
    const { service, evento } = armar();

    await expect(service.unirseComoAnonimo(evento.id, 'Sofía', '')).rejects.toThrow(/PIN/);
    await expect(service.unirseComoAnonimo(evento.id, 'Sofía', 'abc')).rejects.toThrow(/PIN/);
  });

  it('rechaza username vacío', async () => {
    const { service, evento } = armar();
    await expect(service.unirseComoAnonimo(evento.id, '  ', 'pin1234')).rejects.toThrow(
      /username/,
    );
  });

  describe('regla 2 — reingresar al mismo evento recupera la MISMA identidad', () => {
    it('mismo username + mismo PIN devuelve el mismo participanteId (no crea uno nuevo)', async () => {
      const { service, participantes, evento } = armar();

      const primera = await service.unirseComoAnonimo(evento.id, 'Sofía', 'pin1234');
      const segunda = await service.unirseComoAnonimo(evento.id, 'Sofía', 'pin1234');

      expect(segunda.participanteId).toBe(primera.participanteId);
      expect(participantes.participantes).toHaveLength(1); // no duplicó la fila.
    });

    it('el token de sesión se renueva en cada reingreso (no reusa el viejo)', async () => {
      const { service, evento } = armar();

      const primera = await service.unirseComoAnonimo(evento.id, 'Sofía', 'pin1234');
      const segunda = await service.unirseComoAnonimo(evento.id, 'Sofía', 'pin1234');

      expect(segunda.tokenSesion).not.toBe(primera.tokenSesion);
    });

    it('mismo username con PIN incorrecto se rechaza (no expone si el PIN es el problema)', async () => {
      const { service, evento } = armar();
      await service.unirseComoAnonimo(evento.id, 'Sofía', 'pin1234');

      await expect(
        service.unirseComoAnonimo(evento.id, 'Sofía', 'otro-pin'),
      ).rejects.toThrow(/PIN/);
    });

    it('la comparación de username para reingresar no distingue mayúsculas', async () => {
      const { service, evento } = armar();
      const primera = await service.unirseComoAnonimo(evento.id, 'Sofía', 'pin1234');

      const segunda = await service.unirseComoAnonimo(evento.id, 'SOFÍA', 'pin1234');
      expect(segunda.participanteId).toBe(primera.participanteId);
    });
  });

  describe('regla 3 — el mismo username no sirve para OTRO evento mientras el primero siga activo', () => {
    it('rechaza (sin auto-sufijar) si el username está en uso en otro evento sin terminar', async () => {
      const { service, eventos, evento } = armar();
      const otroEvento = eventos.agregar({ estado: 'planificacion' });
      await service.unirseComoAnonimo(evento.id, 'Sofía', 'pin1234');

      await expect(
        service.unirseComoAnonimo(otroEvento.id, 'Sofía', 'otroPin1'),
      ).rejects.toThrow(/ya está en uso/);
    });

    it('el mensaje de rechazo sugiere una alternativa disponible', async () => {
      const { service, eventos, evento } = armar();
      const otroEvento = eventos.agregar({ estado: 'planificacion' });
      await service.unirseComoAnonimo(evento.id, 'Sofía', 'pin1234');

      await expect(
        service.unirseComoAnonimo(otroEvento.id, 'Sofía', 'otroPin1'),
      ).rejects.toThrow(/"Sofía2"/);
    });

    it('se libera cuando el primer evento termina (finalizado) y no quedan deudas pendientes', async () => {
      const { service, eventos, deudas, evento } = armar();
      const otroEvento = eventos.agregar({ estado: 'planificacion' });
      await service.unirseComoAnonimo(evento.id, 'Sofía', 'pin1234');

      // Evento finalizado, pero con una deuda todavía pendiente: sigue bloqueado.
      eventos.eventos.find((e) => e.id === evento.id)!.estado = 'finalizado';
      deudas.agregar({ eventoId: evento.id, estado: 'pendiente' });
      await expect(
        service.unirseComoAnonimo(otroEvento.id, 'Sofía', 'otroPin1'),
      ).rejects.toThrow(/ya está en uso/);

      // Se salda la deuda: ahora sí se libera.
      deudas.deudas[0].estado = 'saldado';
      const sesion = await service.unirseComoAnonimo(otroEvento.id, 'Sofía', 'otroPin1');
      expect(sesion.username).toBe('Sofía');
    });

    it('se libera cuando el primer evento se cancela y no quedan deudas pendientes', async () => {
      const { service, eventos, evento } = armar();
      const otroEvento = eventos.agregar({ estado: 'planificacion' });
      await service.unirseComoAnonimo(evento.id, 'Sofía', 'pin1234');

      eventos.eventos.find((e) => e.id === evento.id)!.estado = 'cancelado';
      const sesion = await service.unirseComoAnonimo(otroEvento.id, 'Sofía', 'otroPin1');
      expect(sesion.username).toBe('Sofía');
    });

    it('un evento sin terminar (confirmado) sigue bloqueando aunque tenga cero deudas', async () => {
      const { service, eventos, evento } = armar();
      const otroEvento = eventos.agregar({ estado: 'planificacion' });
      await service.unirseComoAnonimo(evento.id, 'Sofía', 'pin1234');
      eventos.eventos.find((e) => e.id === evento.id)!.estado = 'confirmado';

      await expect(
        service.unirseComoAnonimo(otroEvento.id, 'Sofía', 'otroPin1'),
      ).rejects.toThrow(/ya está en uso/);
    });
  });

  it('sigue bloqueado (sin auto-sufijar) si el username ya lo tiene una cuenta registrada', async () => {
    const { service, usuarios, evento } = armar();
    usuarios.agregar({ username: 'marcos' });

    await expect(
      service.unirseComoAnonimo(evento.id, 'marcos', 'pin1234'),
    ).rejects.toThrow(/ya está en uso/);
  });

  it('no deja unirse a un evento cancelado o finalizado', async () => {
    const { service, eventos } = armar();
    const cancelado = eventos.agregar({ estado: 'cancelado' });
    const finalizado = eventos.agregar({ estado: 'finalizado' });

    await expect(service.unirseComoAnonimo(cancelado.id, 'Sofía', 'pin1234')).rejects.toThrow();
    await expect(service.unirseComoAnonimo(finalizado.id, 'Sofía', 'pin1234')).rejects.toThrow();
  });
});
