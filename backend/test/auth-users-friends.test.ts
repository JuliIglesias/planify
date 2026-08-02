import request from 'supertest';
import { createApp } from '../src/app';
import { createTestContainer } from './test-container';

function armarApi() {
  const { container, repos } = createTestContainer();
  return { app: createApp(container), repos };
}

const tokenDe = (usuarioId: string, email = 'a@b.com') =>
  `Bearer ${JSON.stringify({ usuarioId, email })}`;

describe('POST /auth/register (FR11 · HU-27)', () => {
  it('crea la cuenta y devuelve token + usuario', async () => {
    const { app, repos } = armarApi();

    const res = await request(app)
      .post('/auth/register')
      .send({ nombre: 'Julieta', email: 'juli@planify.test', password: 'secreto123' });

    expect(res.status).toBe(201);
    expect(res.body.token).toBeDefined();
    expect(res.body.usuario.email).toBe('juli@planify.test');
    expect(repos.usuarios.usuarios).toHaveLength(1);
    // Nunca se devuelve el hash de la contraseña.
    expect(res.body.usuario.passwordHash).toBeUndefined();
  });

  it('rechaza un email ya registrado con 409', async () => {
    const { app, repos } = armarApi();
    repos.usuarios.agregar({ email: 'juli@planify.test' });

    const res = await request(app)
      .post('/auth/register')
      .send({ nombre: 'Otra', email: 'juli@planify.test', password: 'secreto123' });

    expect(res.status).toBe(409);
  });

  it('rechaza contraseñas cortas y emails inválidos con 400', async () => {
    const { app } = armarApi();

    const corta = await request(app)
      .post('/auth/register')
      .send({ nombre: 'Juli', email: 'juli@planify.test', password: '123' });
    const emailMal = await request(app)
      .post('/auth/register')
      .send({ nombre: 'Juli', email: 'no-es-email', password: 'secreto123' });

    expect(corta.status).toBe(400);
    expect(emailMal.status).toBe(400);
  });

  it('la cuenta creada puede loguearse (FR11 → HU-41)', async () => {
    const { app } = armarApi();
    await request(app)
      .post('/auth/register')
      .send({ nombre: 'Juli', email: 'juli@planify.test', password: 'secreto123' });

    const login = await request(app)
      .post('/auth/login')
      .send({ email: 'juli@planify.test', password: 'secreto123' });

    expect(login.status).toBe(200);
    expect(login.body.token).toBeDefined();
  });
});

describe('Perfil (FR12 · HU-30)', () => {
  it('GET /me devuelve el perfil sin el hash', async () => {
    const { app, repos } = armarApi();
    const u = repos.usuarios.agregar({ nombre: 'Juli', email: 'juli@planify.test' });

    const res = await request(app).get('/me').set('Authorization', tokenDe(u.id));

    expect(res.status).toBe(200);
    expect(res.body.nombre).toBe('Juli');
    expect(res.body.idiomaPreferido).toBe('es');
    expect(res.body.passwordHash).toBeUndefined();
  });

  it('PATCH /me/profile actualiza nombre e idioma', async () => {
    const { app, repos } = armarApi();
    const u = repos.usuarios.agregar({ nombre: 'Juli' });

    const res = await request(app)
      .patch('/me/profile')
      .set('Authorization', tokenDe(u.id))
      .send({ nombre: 'Julieta', idiomaPreferido: 'en' });

    expect(res.status).toBe(200);
    expect(res.body.nombre).toBe('Julieta');
    expect(res.body.idiomaPreferido).toBe('en');
  });

  it('rechaza un idioma no soportado', async () => {
    const { app, repos } = armarApi();
    const u = repos.usuarios.agregar();

    const res = await request(app)
      .patch('/me/profile')
      .set('Authorization', tokenDe(u.id))
      .send({ idiomaPreferido: 'fr' });

    expect(res.status).toBe(400);
  });
});

describe('Amigos (FR13 · HU-31)', () => {
  it('flujo completo: buscar → solicitar → aparecer pendiente → aceptar → ser amigos', async () => {
    const { app, repos } = armarApi();
    const juli = repos.usuarios.agregar({ nombre: 'Julieta', email: 'juli@planify.test' });
    const nacho = repos.usuarios.agregar({ nombre: 'Nacho', email: 'nacho@planify.test' });

    // Juli busca a Nacho: todavía no hay relación.
    const busqueda = await request(app)
      .get('/users/search?q=nacho')
      .set('Authorization', tokenDe(juli.id));
    expect(busqueda.body).toHaveLength(1);
    expect(busqueda.body[0].relacion).toBe('ninguno');

    // Juli le manda la solicitud.
    const solicitud = await request(app)
      .post('/friends')
      .set('Authorization', tokenDe(juli.id))
      .send({ usuarioId: nacho.id });
    expect(solicitud.status).toBe(201);

    // A Nacho le figura pendiente.
    const pendientes = await request(app)
      .get('/friends/requests')
      .set('Authorization', tokenDe(nacho.id));
    expect(pendientes.body).toHaveLength(1);
    expect(pendientes.body[0].solicitante.nombre).toBe('Julieta');
    const amistadId = pendientes.body[0].amistadId;

    // Nacho acepta.
    const aceptar = await request(app)
      .post(`/friends/${amistadId}/accept`)
      .set('Authorization', tokenDe(nacho.id));
    expect(aceptar.status).toBe(204);

    // Ahora son amigos, visible desde ambos lados.
    const amigosDeJuli = await request(app).get('/friends').set('Authorization', tokenDe(juli.id));
    const amigosDeNacho = await request(app)
      .get('/friends')
      .set('Authorization', tokenDe(nacho.id));
    expect(amigosDeJuli.body[0].nombre).toBe('Nacho');
    expect(amigosDeNacho.body[0].nombre).toBe('Julieta');
  });

  it('no deja mandarse una solicitud a uno mismo', async () => {
    const { app, repos } = armarApi();
    const juli = repos.usuarios.agregar();

    const res = await request(app)
      .post('/friends')
      .set('Authorization', tokenDe(juli.id))
      .send({ usuarioId: juli.id });

    expect(res.status).toBe(400);
  });

  it('no deja duplicar una solicitud existente (409)', async () => {
    const { app, repos } = armarApi();
    const juli = repos.usuarios.agregar();
    const nacho = repos.usuarios.agregar();
    repos.amistades.amistades.push({
      id: 'ami-1',
      usuarioId1: juli.id,
      usuarioId2: nacho.id,
      estado: 'pendiente',
      createdAt: new Date(),
    });

    const res = await request(app)
      .post('/friends')
      .set('Authorization', tokenDe(juli.id))
      .send({ usuarioId: nacho.id });

    expect(res.status).toBe(409);
  });

  it('solo el destinatario puede aceptar la solicitud', async () => {
    const { app, repos } = armarApi();
    const juli = repos.usuarios.agregar();
    const nacho = repos.usuarios.agregar();
    repos.amistades.amistades.push({
      id: 'ami-1',
      usuarioId1: juli.id,
      usuarioId2: nacho.id,
      estado: 'pendiente',
      createdAt: new Date(),
    });

    // Juli (la solicitante) no puede aceptar su propia solicitud.
    const res = await request(app)
      .post('/friends/ami-1/accept')
      .set('Authorization', tokenDe(juli.id));

    expect(res.status).toBe(403);
  });
});
