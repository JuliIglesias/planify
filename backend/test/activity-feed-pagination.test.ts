/**
 * Tanda 6, Item 2 — paginación de a 20 en el feed de actividad reciente
 * (usado por Home y por la nueva pantalla de Notificaciones).
 */
import request from 'supertest';
import { ActivityLogService } from '../src/modules/activity-log/activity-log.service';
import { createApp } from '../src/app';
import { createTestContainer } from './test-container';
import { FakeClock, FakeLogActividadRepository, FakeParticipanteRepository } from './fakes';

function armar() {
  const participantes = new FakeParticipanteRepository();
  const logs = new FakeLogActividadRepository();
  const clock = new FakeClock();
  const service = new ActivityLogService(logs, participantes, clock);
  return { service, participantes, logs };
}

describe('ActivityLogService.recientesDe — paginación por cursor', () => {
  it('trae 20 por página y la siguiente página no repite entradas', async () => {
    const { service, participantes, logs } = armar();
    const usuarioId = 'user-1';
    participantes.agregar({ eventoId: 'evt-1', usuarioId });

    for (let i = 0; i < 25; i++) {
      await logs.create({ eventoId: 'evt-1', tipo: 'gasto_agregado', actorParticipanteId: 'p-otro' });
    }

    const primeraPagina = await service.recientesDe(usuarioId);
    expect(primeraPagina).toHaveLength(20);

    const cursor = primeraPagina[primeraPagina.length - 1].createdAt;
    const segundaPagina = await service.recientesDe(usuarioId, cursor);
    expect(segundaPagina).toHaveLength(5);

    // Ninguna entrada se repite entre páginas.
    const idsPrimera = new Set(primeraPagina.map((e) => e.id));
    expect(segundaPagina.every((e) => !idsPrimera.has(e.id))).toBe(true);

    // Todas las entradas de la segunda página son más viejas que el cursor.
    expect(segundaPagina.every((e) => e.createdAt.getTime() < cursor.getTime())).toBe(true);

    // No hay una tercera página.
    const cursor2 = segundaPagina[segundaPagina.length - 1].createdAt;
    expect(await service.recientesDe(usuarioId, cursor2)).toHaveLength(0);
  });
});

describe('GET /me/activity — paginación (Tanda 6, Item 2)', () => {
  const tokenDe = (usuarioId: string) => `Bearer ${JSON.stringify({ usuarioId, email: 'a@b.com' })}`;

  it('pagina de a 20 con el cursor `before`', async () => {
    const { container, repos } = createTestContainer();
    const app = createApp(container);

    const usuario = repos.usuarios.agregar({ username: 'Marcos' });
    const grupo = await repos.grupos.create('Los Fibes', [usuario.id]);
    const evento = repos.eventos.agregar({ grupoId: grupo.id });
    repos.participantes.agregar({ eventoId: evento.id, usuarioId: usuario.id });

    for (let i = 0; i < 22; i++) {
      await repos.logs.create({
        eventoId: evento.id,
        tipo: 'gasto_agregado',
        actorParticipanteId: 'otro-participante',
      });
    }

    const primera = await request(app)
      .get('/me/activity')
      .set('Authorization', tokenDe(usuario.id));
    expect(primera.status).toBe(200);
    expect(primera.body).toHaveLength(20);

    const cursor = primera.body[primera.body.length - 1].createdAt;
    const segunda = await request(app)
      .get('/me/activity')
      .query({ before: cursor })
      .set('Authorization', tokenDe(usuario.id));

    expect(segunda.status).toBe(200);
    expect(segunda.body).toHaveLength(2);
    const idsPrimera = new Set(primera.body.map((e: { id: string }) => e.id));
    expect(segunda.body.every((e: { id: string }) => !idsPrimera.has(e.id))).toBe(true);
  });

  it('un cursor inválido devuelve 400', async () => {
    const { container, repos } = createTestContainer();
    const app = createApp(container);
    const usuario = repos.usuarios.agregar({ username: 'Marcos' });

    const res = await request(app)
      .get('/me/activity')
      .query({ before: 'no-es-una-fecha' })
      .set('Authorization', tokenDe(usuario.id));

    expect(res.status).toBe(400);
  });
});
