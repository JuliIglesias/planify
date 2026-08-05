/**
 * F2 — notificación al recibir una solicitud de amistad. In-app por ahora
 * (el usuario pidió arrancar así; push queda para más adelante), reutilizando
 * el mismo feed de "Actividad reciente"/Notificaciones vía
 * `ActivityLogService.recientesDe` — pero sin colgar de ningún evento
 * (`NotificacionPersonalRepository`, tabla separada de `LogActividad`).
 */
import { ActivityLogService } from '../src/modules/activity-log/activity-log.service';
import { ActivityType } from '../src/modules/activity-log/activity-log.types';
import { FriendsService } from '../src/modules/friends/friends.service';
import {
  FakeAmistadRepository,
  FakeClock,
  FakeLogActividadRepository,
  FakeNotificacionPersonalRepository,
  FakeParticipanteRepository,
  FakeUsuarioRepository,
} from './fakes';

function armar() {
  const usuarios = new FakeUsuarioRepository();
  const amistades = new FakeAmistadRepository(usuarios);
  const participantes = new FakeParticipanteRepository();
  const logs = new FakeLogActividadRepository();
  const notificacionesPersonales = new FakeNotificacionPersonalRepository(usuarios);
  const clock = new FakeClock();

  const activityLog = new ActivityLogService(
    logs,
    participantes,
    clock,
    undefined,
    notificacionesPersonales,
  );
  const friends = new FriendsService(amistades, usuarios, activityLog);

  return { friends, usuarios, activityLog, notificacionesPersonales };
}

describe('F2 — notificación de solicitud de amistad', () => {
  it('enviar una solicitud registra una notificación para el receptor', async () => {
    const { friends, usuarios, activityLog } = armar();
    const ana = usuarios.agregar({ username: 'Ana' });
    const bruno = usuarios.agregar({ username: 'Bruno' });

    await friends.enviarSolicitud(ana.id, bruno.id);

    const feedDeBruno = await activityLog.recientesDe(bruno.id);
    expect(feedDeBruno).toHaveLength(1);
    expect(feedDeBruno[0].tipo).toBe(ActivityType.solicitudAmistad);
    expect(feedDeBruno[0].actor.username).toBe('Ana');
    // No cuelga de ningún evento.
    expect(feedDeBruno[0].eventoId).toBeUndefined();
  });

  it('quien envió la solicitud no ve una notificación de eso en su propio feed', async () => {
    const { friends, usuarios, activityLog } = armar();
    const ana = usuarios.agregar({ username: 'Ana' });
    const bruno = usuarios.agregar({ username: 'Bruno' });

    await friends.enviarSolicitud(ana.id, bruno.id);

    expect(await activityLog.recientesDe(ana.id)).toHaveLength(0);
  });

  it('se mezcla en orden con la actividad de eventos del mismo usuario', async () => {
    const { friends, usuarios, activityLog, notificacionesPersonales } = armar();
    const ana = usuarios.agregar({ username: 'Ana' });
    const bruno = usuarios.agregar({ username: 'Bruno' });
    const carla = usuarios.agregar({ username: 'Carla' });

    // Dos solicitudes a Bruno, para que haya más de una notificación
    // personal que mezclar con lo que venga de eventos.
    await friends.enviarSolicitud(ana.id, bruno.id);
    await friends.enviarSolicitud(carla.id, bruno.id);

    const feed = await activityLog.recientesDe(bruno.id);
    expect(feed).toHaveLength(2);
    // La más reciente (Carla) va primero.
    expect(feed.map((f) => f.actor.username)).toEqual(['Carla', 'Ana']);
    expect(notificacionesPersonales.notificaciones).toHaveLength(2);
  });

  it('sin ActivityLogService inyectado, enviarSolicitud sigue funcionando (no rompe el flujo)', async () => {
    const usuarios = new FakeUsuarioRepository();
    const amistades = new FakeAmistadRepository(usuarios);
    const friends = new FriendsService(amistades, usuarios); // sin activityLog
    const ana = usuarios.agregar({ username: 'Ana' });
    const bruno = usuarios.agregar({ username: 'Bruno' });

    await expect(friends.enviarSolicitud(ana.id, bruno.id)).resolves.toBeUndefined();
  });
});
