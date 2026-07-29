import request from 'supertest';
import { createApp } from '../src/app';
import { createTestContainer } from './test-container';

/**
 * Tests de la API completa (rutas + guards + servicios) sin base de datos.
 * Es posible porque `createApp` recibe el container ya cableado.
 */
function armarApi() {
  const { container, repos } = createTestContainer();
  return { app: createApp(container), repos, container };
}

/** Token que produce el FakeTokenService para ese usuario. */
const tokenDe = (usuarioId: string, email = 'a@b.com') =>
  `Bearer ${JSON.stringify({ usuarioId, email })}`;

describe('GET /health', () => {
  it('responde ok', async () => {
    const { app } = armarApi();
    const res = await request(app).get('/health');

    expect(res.status).toBe(200);
    expect(res.body).toEqual({ status: 'ok' });
  });
});

describe('POST /auth/login (HU-41)', () => {
  it('devuelve token y usuario con credenciales válidas', async () => {
    const { app, repos } = armarApi();
    repos.usuarios.agregar({
      email: 'organizador@planify.test',
      passwordHash: 'hash(planify-mvp-2026)',
      nombre: 'Organizador Planify',
    });

    const res = await request(app)
      .post('/auth/login')
      .send({ email: 'organizador@planify.test', password: 'planify-mvp-2026' });

    expect(res.status).toBe(200);
    expect(res.body.token).toBeDefined();
    expect(res.body.usuario.nombre).toBe('Organizador Planify');
  });

  it('rechaza credenciales incorrectas sin revelar cuál falló', async () => {
    const { app, repos } = armarApi();
    repos.usuarios.agregar({ email: 'a@planify.test', passwordHash: 'hash(correcta)' });

    const malaPassword = await request(app)
      .post('/auth/login')
      .send({ email: 'a@planify.test', password: 'incorrecta' });

    const usuarioInexistente = await request(app)
      .post('/auth/login')
      .send({ email: 'nadie@planify.test', password: 'correcta' });

    expect(malaPassword.status).toBe(401);
    expect(usuarioInexistente.status).toBe(401);
    expect(malaPassword.body.error).toBe(usuarioInexistente.body.error);
  });

  it('pide email y password', async () => {
    const { app } = armarApi();
    const res = await request(app).post('/auth/login').send({ email: 'a@b.com' });
    expect(res.status).toBe(400);
  });
});

describe('Guards de autenticación', () => {
  it('rechaza crear un evento sin token de organizador (Duda #19)', async () => {
    const { app } = armarApi();
    const res = await request(app).post('/events').send({ nombre: 'Asado', lugarTexto: 'Casa' });
    expect(res.status).toBe(401);
  });

  it('rechaza un token inválido', async () => {
    const { app } = armarApi();
    const res = await request(app)
      .get('/events/upcoming')
      .set('Authorization', 'Bearer no-es-un-token');
    expect(res.status).toBe(401);
  });
});

describe('POST /events (HU-06)', () => {
  it('crea el evento con su organizador', async () => {
    const { app, repos } = armarApi();
    const usuario = repos.usuarios.agregar({ nombre: 'Julieta' });
    const grupo = await repos.grupos.create('Los Fibes', [usuario.id]);

    const res = await request(app)
      .post('/events')
      .set('Authorization', tokenDe(usuario.id))
      .send({ nombre: 'Asado', lugarTexto: 'Casa de Nacho', grupoId: grupo.id });

    expect(res.status).toBe(201);
    expect(res.body.evento.nombre).toBe('Asado');
    expect(res.body.organizador.esOrganizador).toBe(true);
  });

  it('devuelve 400 si faltan datos', async () => {
    const { app, repos } = armarApi();
    const usuario = repos.usuarios.agregar();

    const res = await request(app)
      .post('/events')
      .set('Authorization', tokenDe(usuario.id))
      .send({ nombre: 'Asado' });

    expect(res.status).toBe(400);
  });
});

describe('POST /participants/anonymous (HU-01)', () => {
  it('deja unirse a un evento abierto y devuelve el token de sesión', async () => {
    const { app, repos } = armarApi();
    const evento = repos.eventos.agregar();

    const res = await request(app)
      .post('/participants/anonymous')
      .send({ eventoId: evento.id, nombreDisplay: 'Sofía' });

    expect(res.status).toBe(201);
    expect(res.body.tokenSesion).toBeDefined();
    expect(repos.logs.tipos()).toContain('participante_se_unio');
  });

  it('no deja unirse a un evento cancelado (Duda #5)', async () => {
    const { app, repos } = armarApi();
    const evento = repos.eventos.agregar({ estado: 'cancelado' });

    const res = await request(app)
      .post('/participants/anonymous')
      .send({ eventoId: evento.id, nombreDisplay: 'Sofía' });

    expect(res.status).toBe(400);
  });

  it('devuelve 404 si el evento no existe', async () => {
    const { app } = armarApi();
    const res = await request(app)
      .post('/participants/anonymous')
      .send({ eventoId: 'no-existe', nombreDisplay: 'Sofía' });

    expect(res.status).toBe(404);
  });
});

describe('Flujo completo del MVP', () => {
  it('crear evento → unirse por link → cargar disponibilidad → confirmar horario', async () => {
    const { app, repos } = armarApi();
    const organizador = repos.usuarios.agregar({ nombre: 'Julieta' });
    const grupo = await repos.grupos.create('Los Fibes', [organizador.id]);
    const auth = tokenDe(organizador.id);

    // 1. El organizador crea el evento (HU-06)
    const creado = await request(app)
      .post('/events')
      .set('Authorization', auth)
      .send({ nombre: 'Asado', lugarTexto: 'Casa de Nacho', grupoId: grupo.id });
    const eventoId = creado.body.evento.id;

    // 2. Genera el link de invitación (HU-02)
    const invitacion = await request(app)
      .post('/invitations')
      .set('Authorization', auth)
      .send({ eventoId });
    expect(invitacion.status).toBe(201);

    // 3. Un anónimo lo abre y se une (HU-01/HU-03)
    const resuelta = await request(app).get(`/invitations/${invitacion.body.tokenUnico}`);
    expect(resuelta.body.eventoId).toBe(eventoId);

    const anonimo = await request(app)
      .post('/participants/anonymous')
      .send({ eventoId, nombreDisplay: 'Sofía' });
    const tokenAnonimo = anonimo.body.tokenSesion;

    // 4. El anónimo carga su disponibilidad (HU-07)
    const disponibilidad = await request(app)
      .post(`/events/${eventoId}/availability`)
      .set('X-Participant-Token', tokenAnonimo)
      .send({ slots: [{ diaSemana: 4, bloqueHora: 21 }] });
    expect(disponibilidad.status).toBe(204);

    // 5. El heatmap muestra la coincidencia (HU-08)
    const heatmap = await request(app)
      .get(`/events/${eventoId}/availability/heatmap`)
      .set('Authorization', auth);
    expect(heatmap.body).toContainEqual({ diaSemana: 4, bloqueHora: 21, disponibles: 1 });

    // 6. El organizador confirma el horario (HU-09)
    const confirmado = await request(app)
      .patch(`/events/${eventoId}/confirm`)
      .set('Authorization', auth)
      .send({ fechaHoraInicio: '2026-08-14T21:00:00.000Z' });

    expect(confirmado.status).toBe(200);
    expect(confirmado.body.estado).toBe('confirmado');
    expect(repos.logs.tipos()).toContain('horario_confirmado');
  });

  it('cargar gastos genera las deudas y saldarlas finaliza el evento', async () => {
    const { app, repos } = armarApi();
    const organizador = repos.usuarios.agregar({ nombre: 'Marcos' });
    const grupo = await repos.grupos.create('Los Fibes', [organizador.id]);
    const auth = tokenDe(organizador.id);

    const creado = await request(app)
      .post('/events')
      .set('Authorization', auth)
      .send({ nombre: 'Asado', lugarTexto: 'Casa', grupoId: grupo.id });
    const eventoId = creado.body.evento.id;
    const marcosId = creado.body.organizador.id;

    // Se suma un anónimo para tener a alguien entre quien dividir.
    const anonimo = await request(app)
      .post('/participants/anonymous')
      .send({ eventoId, nombreDisplay: 'Sofía' });

    // Marcos paga $4500 de carne y se divide entre los dos (HU-13/HU-14).
    const gasto = await request(app)
      .post(`/events/${eventoId}/expenses`)
      .set('Authorization', auth)
      .send({
        descripcion: 'Carne',
        montoTotal: '4500.00',
        acreedores: [{ participanteId: marcosId, monto: '4500.00' }],
      });
    expect(gasto.status).toBe(201);

    // El motor generó la deuda de Sofía hacia Marcos (HU-15).
    const deudas = await request(app)
      .get(`/events/${eventoId}/debts`)
      .set('Authorization', auth);
    expect(deudas.body).toHaveLength(1);
    expect(deudas.body[0].monto).toBe('2250.00');
    expect(deudas.body[0].acreedorParticipanteId).toBe(marcosId);

    // Marcos ve que le deben $2250 (HU-16/HU-17).
    const balance = await request(app).get('/me/balance').set('Authorization', auth);
    expect(balance.body.meDeben).toBe('2250.00');
    expect(balance.body.balanceNeto).toBe('2250.00');

    // Sofía salda la deuda (HU-18) y el evento se finaliza (Duda #5).
    const saldada = await request(app)
      .patch(`/events/${eventoId}/debts/${deudas.body[0].id}/settle`)
      .set('X-Participant-Token', anonimo.body.tokenSesion);
    expect(saldada.status).toBe(200);

    expect(repos.eventos.eventos.find((e) => e.id === eventoId)!.estado).toBe('finalizado');
    expect(repos.logs.tipos()).toContain('deuda_saldada');
  });
});

describe('Endpoints todavía no implementados', () => {
  it('SCRUM-15 y SCRUM-17 devuelven 501 indicando su épica', async () => {
    const { app } = armarApi();

    const notificaciones = await request(app).post('/notifications/register-device');
    const ia = await request(app).post('/events/generate-from-text');

    expect(notificaciones.status).toBe(501);
    expect(notificaciones.body.epica).toBe('SCRUM-15');
    expect(ia.status).toBe(501);
    expect(ia.body.epica).toBe('SCRUM-17');
  });
});
