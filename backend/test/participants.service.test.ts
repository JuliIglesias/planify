/**
 * Username único para logueados y anónimos — ver docs/05-fixes.md.
 *
 * A diferencia del registro (que rechaza un username repetido), un anónimo
 * nunca se bloquea: si el que pidió ya está tomado (por un usuario
 * registrado o por otro anónimo, en cualquier evento), se le agrega un
 * sufijo numérico hasta encontrar uno libre.
 */
import { ActivityLogService } from '../src/modules/activity-log/activity-log.service';
import { ParticipantsService } from '../src/modules/participants/participants.service';
import {
  FakeClock,
  FakeEventoRepository,
  FakeIdGenerator,
  FakeLogActividadRepository,
  FakeParticipanteRepository,
  FakeUsuarioRepository,
} from './fakes';

function armar() {
  const usuarios = new FakeUsuarioRepository();
  const participantes = new FakeParticipanteRepository();
  const eventos = new FakeEventoRepository(participantes);
  const logs = new FakeLogActividadRepository();
  const log = new ActivityLogService(logs, participantes, new FakeClock());
  const service = new ParticipantsService(participantes, usuarios, eventos, new FakeIdGenerator(), log);

  const evento = eventos.agregar();

  return { service, usuarios, participantes, evento };
}

describe('ParticipantsService.unirseComoAnonimo — username único (HU-01)', () => {
  it('deja el username tal cual si no está tomado', async () => {
    const { service, participantes, evento } = armar();

    await service.unirseComoAnonimo(evento.id, 'Sofía');

    expect(participantes.participantes.map((p) => p.username)).toEqual(['Sofía']);
  });

  it('le agrega un sufijo numérico si otro anónimo ya lo usa', async () => {
    const { service, participantes, evento } = armar();
    participantes.agregar({ eventoId: evento.id, username: 'Sofía', esAnonimo: true });

    await service.unirseComoAnonimo(evento.id, 'Sofía');

    const usernames = participantes.participantes.map((p) => p.username);
    expect(usernames).toEqual(['Sofía', 'Sofía2']);
  });

  it('el chequeo de colisión es global: un anónimo de OTRO evento también cuenta', async () => {
    const { service, participantes, evento } = armar();
    participantes.agregar({ eventoId: 'evt-otro', username: 'Pedro', esAnonimo: true });

    await service.unirseComoAnonimo(evento.id, 'Pedro');

    const enEsteEvento = participantes.participantes.filter((p) => p.eventoId === evento.id);
    expect(enEsteEvento.map((p) => p.username)).toEqual(['Pedro2']);
  });

  it('sigue sumando el sufijo hasta encontrar uno libre', async () => {
    const { service, participantes, evento } = armar();
    participantes.agregar({ eventoId: evento.id, username: 'Pedro', esAnonimo: true });
    participantes.agregar({ eventoId: evento.id, username: 'Pedro2', esAnonimo: true });

    await service.unirseComoAnonimo(evento.id, 'Pedro');

    const usernames = participantes.participantes.map((p) => p.username);
    expect(usernames).toEqual(['Pedro', 'Pedro2', 'Pedro3']);
  });

  it('también se auto-sufija si el username ya lo tiene una cuenta registrada', async () => {
    const { service, usuarios, participantes, evento } = armar();
    usuarios.agregar({ username: 'marcos' });

    await service.unirseComoAnonimo(evento.id, 'marcos');

    expect(participantes.participantes.map((p) => p.username)).toEqual(['marcos2']);
  });

  it('la comparación de colisión no distingue mayúsculas de minúsculas', async () => {
    const { service, usuarios, participantes, evento } = armar();
    usuarios.agregar({ username: 'marcos' });

    await service.unirseComoAnonimo(evento.id, 'MARCOS');

    expect(participantes.participantes.map((p) => p.username)).toEqual(['MARCOS2']);
  });

  it('nunca rechaza el pedido: siempre devuelve una sesión válida', async () => {
    const { service, participantes, evento } = armar();
    participantes.agregar({ eventoId: evento.id, username: 'Ana', esAnonimo: true });

    const sesion = await service.unirseComoAnonimo(evento.id, 'Ana');

    expect(sesion.participanteId).toBeDefined();
    expect(sesion.tokenSesion).not.toBe('');
  });

  it('la respuesta incluye el username final, para avisar si cambió por colisión', async () => {
    const { service, participantes, evento } = armar();
    participantes.agregar({ eventoId: evento.id, username: 'Ana', esAnonimo: true });

    const libre = await service.unirseComoAnonimo(evento.id, 'Bruno');
    expect(libre.username).toBe('Bruno');

    const conColision = await service.unirseComoAnonimo(evento.id, 'Ana');
    expect(conColision.username).toBe('Ana2');
  });
});
