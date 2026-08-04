/**
 * Item 4 (Fase 5) — perfil de solo lectura de un amigo: disponibilidad
 * comparada (solo la dupla), y eventos/grupos en común.
 */
import { FriendProfileService } from '../src/modules/friends/friend-profile.service';
import {
  FakeAmistadRepository,
  FakeEventoRepository,
  FakeGrupoRepository,
  FakeParticipanteRepository,
  FakeProfileAvailabilityRepository,
  FakeUsuarioRepository,
} from './fakes';

function armar() {
  const usuarios = new FakeUsuarioRepository();
  const amistades = new FakeAmistadRepository(usuarios);
  const disponibilidad = new FakeProfileAvailabilityRepository();
  const grupos = new FakeGrupoRepository(usuarios);
  const participantes = new FakeParticipanteRepository();
  const eventos = new FakeEventoRepository(participantes);

  const service = new FriendProfileService(
    amistades,
    usuarios,
    disponibilidad,
    grupos,
    participantes,
    eventos,
  );

  return { service, usuarios, amistades, disponibilidad, grupos, participantes, eventos };
}

describe('FriendProfileService — autorización', () => {
  it('rechaza ver el perfil de alguien que no es amigo', async () => {
    const { service, usuarios } = armar();
    const yo = usuarios.agregar({ username: 'Julieta' });
    const otro = usuarios.agregar({ username: 'Desconocido' });

    await expect(service.obtener(yo.id, otro.id)).rejects.toThrow(/tus amigos/);
  });

  it('rechaza si la solicitud de amistad todavía está pendiente (no aceptada)', async () => {
    const { service, usuarios, amistades } = armar();
    const yo = usuarios.agregar({ username: 'Julieta' });
    const otro = usuarios.agregar({ username: 'Pendiente' });
    await amistades.crear(yo.id, otro.id); // queda 'pendiente'

    await expect(service.obtener(yo.id, otro.id)).rejects.toThrow(/tus amigos/);
  });

  it('permite ver el perfil sin importar quién inició la solicitud', async () => {
    const { service, usuarios, amistades } = armar();
    const yo = usuarios.agregar({ username: 'Julieta' });
    const amigo = usuarios.agregar({ username: 'Marcos', email: 'marcos@mail.com' });
    const amistad = await amistades.crear(amigo.id, yo.id); // amigo la inició
    await amistades.aceptar(amistad.id);

    const perfil = await service.obtener(yo.id, amigo.id);
    expect(perfil.persona.username).toBe('Marcos');
  });
});

describe('FriendProfileService — datos de la persona', () => {
  it('devuelve username, email y avatarUrl del amigo', async () => {
    const { service, usuarios, amistades } = armar();
    const yo = usuarios.agregar({ username: 'Julieta' });
    const amigo = usuarios.agregar({
      username: 'Marcos',
      email: 'marcos@mail.com',
      avatarUrl: 'https://cdn.test/marcos.png',
    });
    const amistad = await amistades.crear(yo.id, amigo.id);
    await amistades.aceptar(amistad.id);

    const perfil = await service.obtener(yo.id, amigo.id);

    expect(perfil.persona).toEqual({
      id: amigo.id,
      username: 'Marcos',
      email: 'marcos@mail.com',
      avatarUrl: 'https://cdn.test/marcos.png',
    });
  });
});

describe('FriendProfileService — heatmap comparado (Item 4)', () => {
  it('distingue coincidimos / solo yo / solo el amigo, y omite los bloques sin nadie libre', async () => {
    const { service, usuarios, amistades, disponibilidad } = armar();
    const yo = usuarios.agregar({ username: 'Julieta' });
    const amigo = usuarios.agregar({ username: 'Marcos' });
    const amistad = await amistades.crear(yo.id, amigo.id);
    await amistades.aceptar(amistad.id);

    // Lunes 20h: los dos libres → "ambos".
    disponibilidad.slots.push(
      { usuarioId: yo.id, diaSemana: 0, bloqueHora: 20 },
      { usuarioId: amigo.id, diaSemana: 0, bloqueHora: 20 },
    );
    // Martes 10h: solo yo → "soloYo".
    disponibilidad.slots.push({ usuarioId: yo.id, diaSemana: 1, bloqueHora: 10 });
    // Miércoles 15h: solo el amigo → "soloAmigo".
    disponibilidad.slots.push({ usuarioId: amigo.id, diaSemana: 2, bloqueHora: 15 });
    // Disponibilidad de un tercero cualquiera no debería filtrarse (regresión).
    const tercero = usuarios.agregar({ username: 'Sofía' });
    disponibilidad.slots.push({ usuarioId: tercero.id, diaSemana: 3, bloqueHora: 9 });

    const perfil = await service.obtener(yo.id, amigo.id);

    expect(perfil.heatmapComparado).toHaveLength(3);
    expect(perfil.heatmapComparado).toContainEqual({
      diaSemana: 0,
      bloqueHora: 20,
      estado: 'ambos',
    });
    expect(perfil.heatmapComparado).toContainEqual({
      diaSemana: 1,
      bloqueHora: 10,
      estado: 'soloYo',
    });
    expect(perfil.heatmapComparado).toContainEqual({
      diaSemana: 2,
      bloqueHora: 15,
      estado: 'soloAmigo',
    });
  });
});

describe('FriendProfileService — eventos y grupos en común (Item 4)', () => {
  it('lista solo los eventos donde ambos son participantes', async () => {
    const { service, usuarios, amistades, eventos, participantes } = armar();
    const yo = usuarios.agregar({ username: 'Julieta' });
    const amigo = usuarios.agregar({ username: 'Marcos' });
    const amistad = await amistades.crear(yo.id, amigo.id);
    await amistades.aceptar(amistad.id);

    const compartido = eventos.agregar({ nombre: 'Asado compartido' });
    participantes.agregar({ eventoId: compartido.id, usuarioId: yo.id });
    participantes.agregar({ eventoId: compartido.id, usuarioId: amigo.id });

    const soloMio = eventos.agregar({ nombre: 'Solo mío' });
    participantes.agregar({ eventoId: soloMio.id, usuarioId: yo.id });

    const soloDelAmigo = eventos.agregar({ nombre: 'Solo del amigo' });
    participantes.agregar({ eventoId: soloDelAmigo.id, usuarioId: amigo.id });

    const perfil = await service.obtener(yo.id, amigo.id);

    expect(perfil.eventosEnComun.map((e) => e.nombre)).toEqual(['Asado compartido']);
  });

  it('lista solo los grupos donde ambos son miembros', async () => {
    const { service, usuarios, amistades, grupos } = armar();
    const yo = usuarios.agregar({ username: 'Julieta' });
    const amigo = usuarios.agregar({ username: 'Marcos' });
    const amistad = await amistades.crear(yo.id, amigo.id);
    await amistades.aceptar(amistad.id);

    await grupos.create('Los Fibes', [yo.id, amigo.id]);
    await grupos.create('Solo mío', [yo.id]);
    await grupos.create('Solo del amigo', [amigo.id]);

    const perfil = await service.obtener(yo.id, amigo.id);

    expect(perfil.gruposEnComun.map((g) => g.nombre)).toEqual(['Los Fibes']);
  });
});
