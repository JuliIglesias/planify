/**
 * SCRUM-14 — Autenticación completa (registro, recuperación), amigos y perfil.
 */
import { AuthService } from '../src/modules/auth/auth.service';
import { FriendsService } from '../src/modules/friends/friends.service';
import { UsersService } from '../src/modules/users/users.service';
import {
  FakeAmistadRepository,
  FakeParticipanteRepository,
  FakePasswordHasher,
  FakeTokenService,
  FakeUsuarioRepository,
} from './fakes';

function armar() {
  const usuarios = new FakeUsuarioRepository();
  const amistades = new FakeAmistadRepository(usuarios);
  const participantes = new FakeParticipanteRepository();
  const hasher = new FakePasswordHasher();
  const tokens = new FakeTokenService();

  return {
    auth: new AuthService(usuarios, participantes, hasher, tokens),
    friends: new FriendsService(amistades, usuarios),
    users: new UsersService(usuarios),
    usuarios,
    amistades,
    participantes,
  };
}

describe('SCRUM-14 — registro y login (HU-27/HU-28)', () => {
  it('registra un usuario y permite loguearse con esas credenciales', async () => {
    const { auth, usuarios } = armar();

    const reg = await auth.register('ana', 'ANA@Mail.com', 'secreto1');
    expect(reg.usuario.email).toBe('ana@mail.com'); // normaliza a minúsculas
    expect(reg.usuario.username).toBe('ana');
    expect(usuarios.usuarios).toHaveLength(1);

    const login = await auth.login('ana@mail.com', 'secreto1');
    expect(login.usuario.id).toBe(reg.usuario.id);

    // También se puede loguear con el username en vez del email.
    const loginPorUsername = await auth.login('ana', 'secreto1');
    expect(loginPorUsername.usuario.id).toBe(reg.usuario.id);
  });

  it('rechaza email duplicado, username duplicado, username/email inválido y contraseña corta', async () => {
    const { auth } = armar();
    await auth.register('ana', 'ana@mail.com', 'secreto1');

    await expect(auth.register('otra', 'ana@mail.com', 'secreto1')).rejects.toThrow(/Ya existe/);
    await expect(auth.register('ana', 'otra@mail.com', 'secreto1')).rejects.toThrow(/username ya está/);
    await expect(auth.register('xx', 'valido@mail.com', 'secreto1')).rejects.toThrow(/username inválido/);
    await expect(auth.register('valido_user', 'no-es-mail', 'secreto1')).rejects.toThrow(/email/);
    await expect(auth.register('otrovalido', 'x@mail.com', '123')).rejects.toThrow(/contraseña/);
  });

  it('rechaza el registro si el username ya lo usa un participante anónimo', async () => {
    const { auth, participantes } = armar();
    participantes.agregar({ username: 'fantasma', esAnonimo: true });

    await expect(auth.register('fantasma', 'nuevo@mail.com', 'secreto1')).rejects.toThrow(
      /username ya está/,
    );
  });
});

describe('SCRUM-14 — recuperación de contraseña (HU-29)', () => {
  it('con el token de reset se cambia la contraseña y se puede loguear', async () => {
    const { auth } = armar();
    await auth.register('ana', 'ana@mail.com', 'viejo123');

    const { token } = await auth.solicitarReset('ana@mail.com');
    expect(token).not.toBeNull();

    await auth.confirmarReset(token!, 'nuevo456');

    await expect(auth.login('ana@mail.com', 'viejo123')).rejects.toThrow(/inválidas/);
    await expect(auth.login('ana@mail.com', 'nuevo456')).resolves.toMatchObject({
      usuario: { email: 'ana@mail.com' },
    });
  });

  it('no revela si el email existe (token null) y no explota', async () => {
    const { auth } = armar();
    const { token } = await auth.solicitarReset('fantasma@mail.com');
    expect(token).toBeNull();
  });
});

describe('SCRUM-14 — amigos (HU-31)', () => {
  it('flujo completo: buscar, solicitar, aceptar y listar', async () => {
    const { friends, usuarios } = armar();
    const ana = usuarios.agregar({ username: 'Ana', email: 'ana@mail.com' });
    const bruno = usuarios.agregar({ username: 'Bruno', email: 'bruno@mail.com' });

    // Buscar por username encuentra a Bruno (excluye a Ana).
    const encontrados = await friends.buscar(ana.id, 'bru');
    expect(encontrados.map((p) => p.username)).toEqual(['Bruno']);
    // Item 3 (Fase 4) — el email viaja para desambiguar usernames repetidos.
    expect(encontrados[0].email).toBe('bruno@mail.com');

    // También se puede buscar directo por email.
    const porEmail = await friends.buscar(ana.id, 'bruno@mail');
    expect(porEmail.map((p) => p.username)).toEqual(['Bruno']);

    await friends.enviarSolicitud(ana.id, bruno.id);

    // Todavía no son amigos: está pendiente.
    expect(await friends.listar(ana.id)).toHaveLength(0);
    const solicitudes = await friends.solicitudesPendientes(bruno.id);
    expect(solicitudes).toHaveLength(1);

    await friends.aceptar(bruno.id, solicitudes[0].amistadId);

    // Ahora son amigos, en ambos sentidos.
    expect((await friends.listar(ana.id)).map((p) => p.username)).toEqual(['Bruno']);
    expect((await friends.listar(bruno.id)).map((p) => p.username)).toEqual(['Ana']);
  });

  it('no permite agregarse a uno mismo ni duplicar la solicitud', async () => {
    const { friends, usuarios } = armar();
    const ana = usuarios.agregar({ username: 'Ana' });
    const bruno = usuarios.agregar({ username: 'Bruno' });

    await expect(friends.enviarSolicitud(ana.id, ana.id)).rejects.toThrow(/vos mismo/);

    await friends.enviarSolicitud(ana.id, bruno.id);
    await expect(friends.enviarSolicitud(ana.id, bruno.id)).rejects.toThrow(/pendiente/);
  });

  it('solo el receptor puede aceptar la solicitud', async () => {
    const { friends, usuarios } = armar();
    const ana = usuarios.agregar({ username: 'Ana' });
    const bruno = usuarios.agregar({ username: 'Bruno' });
    const carla = usuarios.agregar({ username: 'Carla' });

    await friends.enviarSolicitud(ana.id, bruno.id);
    const sol = (await friends.solicitudesPendientes(bruno.id))[0];

    await expect(friends.aceptar(carla.id, sol.amistadId)).rejects.toThrow(/No podés aceptar/);
  });
});

describe('SCRUM-14 — perfil (HU-30)', () => {
  it('actualiza username e idioma y valida el idioma', async () => {
    const { users, usuarios } = armar();
    const ana = usuarios.agregar({ username: 'Ana', idiomaPreferido: 'es' });

    const actualizado = await users.actualizar(ana.id, { username: 'Ana María', idiomaPreferido: 'en' });
    expect(actualizado.username).toBe('Ana María');
    expect(actualizado.idiomaPreferido).toBe('en');

    await expect(users.actualizar(ana.id, { idiomaPreferido: 'fr' })).rejects.toThrow(/Idioma/);
    await expect(users.actualizar(ana.id, { username: '   ' })).rejects.toThrow(/vacío/);
  });

  it('rechaza cambiar el username a uno que ya usa otra cuenta', async () => {
    const { users, usuarios } = armar();
    usuarios.agregar({ username: 'bruno' });
    const ana = usuarios.agregar({ username: 'ana' });

    await expect(users.actualizar(ana.id, { username: 'bruno' })).rejects.toThrow(/ya está en uso/);
  });
});
