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
      username: 'organizador_planify',
    });

    const res = await request(app)
      .post('/auth/login')
      .send({ email: 'organizador@planify.test', password: 'planify-mvp-2026' });

    expect(res.status).toBe(200);
    expect(res.body.token).toBeDefined();
    expect(res.body.usuario.username).toBe('organizador_planify');
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
    const usuario = repos.usuarios.agregar({ username: 'Julieta' });
    const grupo = await repos.grupos.create('Los Fibes', [usuario.id]);

    const res = await request(app)
      .post('/events')
      .set('Authorization', tokenDe(usuario.id))
      .send({
        nombre: 'Asado',
        lugarTexto: 'Casa de Nacho',
        grupoId: grupo.id,
        rangoInicio: '2026-08-01T00:00:00Z',
        rangoFin: '2026-08-20T00:00:00Z',
      });

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
      .send({ eventoId: evento.id, username: 'Sofía' });

    expect(res.status).toBe(201);
    expect(res.body.tokenSesion).toBeDefined();
    expect(repos.logs.tipos()).toContain('participante_se_unio');
  });

  it('no deja unirse a un evento cancelado (Duda #5)', async () => {
    const { app, repos } = armarApi();
    const evento = repos.eventos.agregar({ estado: 'cancelado' });

    const res = await request(app)
      .post('/participants/anonymous')
      .send({ eventoId: evento.id, username: 'Sofía' });

    expect(res.status).toBe(400);
  });

  it('devuelve 404 si el evento no existe', async () => {
    const { app } = armarApi();
    const res = await request(app)
      .post('/participants/anonymous')
      .send({ eventoId: 'no-existe', username: 'Sofía' });

    expect(res.status).toBe(404);
  });
});

describe('Flujo completo del MVP', () => {
  it('crear evento → unirse por link → cargar disponibilidad → confirmar horario', async () => {
    const { app, repos } = armarApi();
    const organizador = repos.usuarios.agregar({ username: 'Julieta' });
    const grupo = await repos.grupos.create('Los Fibes', [organizador.id]);
    const auth = tokenDe(organizador.id);

    // 1. El organizador crea el evento (HU-06)
    const creado = await request(app)
      .post('/events')
      .set('Authorization', auth)
      .send({
        nombre: 'Asado',
        lugarTexto: 'Casa de Nacho',
        grupoId: grupo.id,
        rangoInicio: '2026-08-01T00:00:00Z',
        rangoFin: '2026-08-20T00:00:00Z',
      });
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
      .send({ eventoId, username: 'Sofía' });
    const tokenAnonimo = anonimo.body.tokenSesion;

    // 4. El anónimo carga su disponibilidad (HU-07)
    const disponibilidad = await request(app)
      .post(`/events/${eventoId}/availability`)
      .set('X-Participant-Token', tokenAnonimo)
      .send({ slots: [{ diaSemana: 4, bloqueHora: 21 }] });
    expect(disponibilidad.status).toBe(204);

    // 4b. El anónimo consulta su propia disponibilidad guardada
    const miDisponibilidad = await request(app)
      .get(`/events/${eventoId}/availability/me`)
      .set('X-Participant-Token', tokenAnonimo);
    expect(miDisponibilidad.status).toBe(200);
    expect(miDisponibilidad.body).toEqual([{ diaSemana: 4, bloqueHora: 21 }]);

    // 5. El heatmap muestra la coincidencia (HU-08)

    const heatmap = await request(app)
      .get(`/events/${eventoId}/availability/heatmap`)
      .set('Authorization', auth);
    expect(heatmap.body).toContainEqual({ diaSemana: 4, bloqueHora: 21, disponibles: 1 });

    // 6. El organizador confirma el horario, como rango (HU-09, Item 5)
    const confirmado = await request(app)
      .patch(`/events/${eventoId}/confirm`)
      .set('Authorization', auth)
      .send({
        fechaHoraInicio: '2026-08-14T21:00:00.000Z',
        fechaHoraFin: '2026-08-14T23:00:00.000Z',
      });

    expect(confirmado.status).toBe(200);
    expect(confirmado.body.estado).toBe('confirmado');
    expect(repos.logs.tipos()).toContain('horario_confirmado');
  });

  it('cargar gastos genera las deudas y saldarlas finaliza el evento', async () => {
    const { app, repos } = armarApi();
    const organizador = repos.usuarios.agregar({ username: 'Marcos' });
    const grupo = await repos.grupos.create('Los Fibes', [organizador.id]);
    const auth = tokenDe(organizador.id);

    const creado = await request(app)
      .post('/events')
      .set('Authorization', auth)
      .send({
        nombre: 'Asado',
        lugarTexto: 'Casa',
        grupoId: grupo.id,
        rangoInicio: '2026-08-01T00:00:00Z',
        rangoFin: '2026-08-20T00:00:00Z',
      });
    const eventoId = creado.body.evento.id;
    const marcosId = creado.body.organizador.id;

    // Se suma un anónimo para tener a alguien entre quien dividir.
    const anonimo = await request(app)
      .post('/participants/anonymous')
      .send({ eventoId, username: 'Sofía' });

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
    // Item 2 (Fase 4) — el nombre de la contraparte viaja en el payload,
    // para poder agrupar varios saldos seguidos en el log del evento.
    const entradaSaldado = repos.logs.entradas.find((e) => e.tipo === 'deuda_saldada');
    expect(entradaSaldado?.payload).toMatchObject({ contraparteNombre: 'Marcos' });
  });

  it('permite elegir deudores específicos al crear un gasto (dividirEntre)', async () => {
    const { app, repos } = armarApi();
    const organizador = repos.usuarios.agregar({ username: 'Marcos' });
    const grupo = await repos.grupos.create('Los Fibes', [organizador.id]);
    const auth = tokenDe(organizador.id);

    const creado = await request(app)
      .post('/events')
      .set('Authorization', auth)
      .send({
        nombre: 'Juntada',
        lugarTexto: 'Casa',
        grupoId: grupo.id,
        rangoInicio: '2026-08-01T00:00:00Z',
        rangoFin: '2026-08-20T00:00:00Z',
      });
    const eventoId = creado.body.evento.id;
    const marcosId = creado.body.organizador.id;

    const anonimo1 = await request(app)
      .post('/participants/anonymous')
      .send({ eventoId, username: 'Sofía' });
    const anonimo2 = await request(app)
      .post('/participants/anonymous')
      .send({ eventoId, username: 'Pedro' });
    expect(anonimo1.status).toBe(201);
    expect(anonimo2.status).toBe(201);

    // Marcos compra algo por $3000 solo para él y Sofía (excluye a Pedro)
    const pSofía = repos.participantes.participantes.find((p) => p.username === 'Sofía')!;
    const gasto = await request(app)
      .post(`/events/${eventoId}/expenses`)
      .set('Authorization', auth)
      .send({
        descripcion: 'Bebidas diet',
        montoTotal: '3000.00',
        acreedores: [{ participanteId: marcosId, monto: '3000.00' }],
        dividirEntre: [marcosId, pSofía.id],
      });
    expect(gasto.status).toBe(201);

    const deudas = await request(app)
      .get(`/events/${eventoId}/debts`)
      .set('Authorization', auth);
    expect(deudas.body).toHaveLength(1);
    expect(deudas.body[0].deudorParticipanteId).toBe(pSofía.id);
    expect(deudas.body[0].monto).toBe('1500.00');
  });
});


describe('SCRUM-15 · notificaciones (HU-35)', () => {
  it('registra el device y notifica a los otros participantes ante una actividad', async () => {
    const { app, repos } = armarApi();
    const organizador = repos.usuarios.agregar({ username: 'Marcos' });
    const grupo = await repos.grupos.create('Los Fibes', [organizador.id]);
    const auth = tokenDe(organizador.id);

    const creado = await request(app)
      .post('/events')
      .set('Authorization', auth)
      .send({
        nombre: 'Asado',
        lugarTexto: 'Casa',
        grupoId: grupo.id,
        rangoInicio: '2026-08-01T00:00:00Z',
        rangoFin: '2026-08-20T00:00:00Z',
      });
    const eventoId = creado.body.evento.id;

    // El organizador registra su device.
    const reg = await request(app)
      .post('/notifications/register-device')
      .set('Authorization', auth)
      .send({ deviceToken: 'device-abc' });
    expect(reg.status).toBe(201);

    // Un anónimo se une y confirma asistencia → dispara actividad; el
    // organizador (otro participante con device) recibe el push.
    const anonimo = await request(app)
      .post('/participants/anonymous')
      .send({ eventoId, username: 'Sofía' });
    await request(app)
      .patch(`/events/${eventoId}/attendance`)
      .set('X-Participant-Token', anonimo.body.tokenSesion)
      .send({ estado: 'confirmado' });

    expect(repos.push.enviados.length).toBeGreaterThan(0);
    expect(repos.push.enviados.some((e) => e.tokens.includes('device-abc'))).toBe(true);
  });

  it('sin autenticación, register-device da 401', async () => {
    const { app } = armarApi();
    const res = await request(app)
      .post('/notifications/register-device')
      .send({ deviceToken: 'x' });
    expect(res.status).toBe(401);
  });
});

describe('SCRUM-17 · IA generar evento (HU-42/43/44b)', () => {
  it('devuelve un borrador con nombre, lugar, tareas y amigos matcheados', async () => {
    const { app, repos } = armarApi();
    const organizador = repos.usuarios.agregar({ username: 'Marcos' });
    const sofia = repos.usuarios.agregar({ username: 'Sofía' });
    // Marcos y Sofía son amigos (aceptada).
    repos.amistades.amistades.push({
      id: 'ami-1',
      usuarioId1: organizador.id,
      usuarioId2: sofia.id,
      estado: 'aceptada',
      createdAt: new Date(),
    });

    const res = await request(app)
      .post('/events/generate-from-text')
      .set('Authorization', tokenDe(organizador.id))
      .send({ descripcion: 'Quiero organizar un asado en casa de Juli con Sofía y Pedro' });

    expect(res.status).toBe(200);
    expect(res.body.nombre.toLowerCase()).toContain('asado');
    expect(res.body.lugar.toLowerCase()).toContain('juli');
    expect(res.body.tareasSugeridas.length).toBeGreaterThan(0);
    // Sofía matchea con un amigo; Pedro no.
    expect(res.body.amigosSugeridos.map((a: { username: string }) => a.username)).toContain('Sofía');
    expect(res.body.nombresSinMatch).toContain('Pedro');
  });

  it('exige una descripción', async () => {
    const { app, repos } = armarApi();
    const organizador = repos.usuarios.agregar({ username: 'Marcos' });
    const res = await request(app)
      .post('/events/generate-from-text')
      .set('Authorization', tokenDe(organizador.id))
      .send({});
    expect(res.status).toBe(400);
  });
});

describe('POST /groups/:id/avatar — foto de grupo desde galería (Tanda 6, Item 5)', () => {
  it('sube la imagen (multipart) y devuelve el grupo con el avatarUrl nuevo', async () => {
    const { app, repos } = armarApi();
    const usuario = repos.usuarios.agregar({ username: 'Marcos' });
    const grupo = await repos.grupos.create('Los Fibes', [usuario.id]);

    const res = await request(app)
      .post(`/groups/${grupo.id}/avatar`)
      .set('Authorization', tokenDe(usuario.id))
      .attach('imagen', Buffer.from('fake-jpg-bytes'), {
        filename: 'foto.jpg',
        contentType: 'image/jpeg',
      });

    expect(res.status).toBe(200);
    expect(res.body.avatarUrl).toContain(`grupos/${grupo.id}`);
  });

  it('exige el archivo', async () => {
    const { app, repos } = armarApi();
    const usuario = repos.usuarios.agregar({ username: 'Marcos' });
    const grupo = await repos.grupos.create('Los Fibes', [usuario.id]);

    const res = await request(app)
      .post(`/groups/${grupo.id}/avatar`)
      .set('Authorization', tokenDe(usuario.id));

    expect(res.status).toBe(400);
  });
});

describe('GET /groups/:id/availability-matches (Tanda 6, Item 5)', () => {
  it('devuelve el heatmap scopeado a los miembros de ese grupo', async () => {
    const { app, repos } = armarApi();
    const ana = repos.usuarios.agregar({ username: 'Ana' });
    const bruno = repos.usuarios.agregar({ username: 'Bruno' });
    const grupo = await repos.grupos.create('Los Fibes', [ana.id, bruno.id]);

    await request(app)
      .put('/me/availability')
      .set('Authorization', tokenDe(ana.id))
      .send({ slots: [{ diaSemana: 0, bloqueHora: 20 }] });
    await request(app)
      .put('/me/availability')
      .set('Authorization', tokenDe(bruno.id))
      .send({ slots: [{ diaSemana: 0, bloqueHora: 20 }] });

    const res = await request(app)
      .get(`/groups/${grupo.id}/availability-matches`)
      .set('Authorization', tokenDe(ana.id));

    expect(res.status).toBe(200);
    expect(res.body.totalPersonas).toBe(2);
    expect(res.body.slots).toEqual([{ diaSemana: 0, bloqueHora: 20, disponibles: 2 }]);
  });

  it('alguien de afuera del grupo no puede consultarla', async () => {
    const { app, repos } = armarApi();
    const miembro = repos.usuarios.agregar({ username: 'Ana' });
    const intruso = repos.usuarios.agregar({ username: 'Intruso' });
    const grupo = await repos.grupos.create('Privado', [miembro.id]);

    const res = await request(app)
      .get(`/groups/${grupo.id}/availability-matches`)
      .set('Authorization', tokenDe(intruso.id));

    expect(res.status).toBe(403);
  });
});
