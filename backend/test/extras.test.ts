/**
 * H-14 (disponibilidad de perfil), HU-B4 (coincidencias entre amigos),
 * HU-B5 (ubicaciones favoritas).
 */
import { ProfileAvailabilityService } from '../src/modules/profile/profile-availability.service';
import { LocationsService } from '../src/modules/profile/locations.service';
import {
  FakeAmistadRepository,
  FakeLocationRepository,
  FakeProfileAvailabilityRepository,
  FakeUsuarioRepository,
} from './fakes';

function armar() {
  const usuarios = new FakeUsuarioRepository();
  const amistades = new FakeAmistadRepository(usuarios);
  const disponibilidadPerfil = new FakeProfileAvailabilityRepository();
  const ubicaciones = new FakeLocationRepository();
  return {
    availability: new ProfileAvailabilityService(disponibilidadPerfil, amistades),
    locations: new LocationsService(ubicaciones),
    usuarios,
    amistades,
  };
}

describe('H-14 — disponibilidad de perfil persistida', () => {
  it('guarda y devuelve los bloques, y valida rangos', async () => {
    const { availability, usuarios } = armar();
    const ana = usuarios.agregar({ username: 'Ana' });

    await availability.guardar(ana.id, [
      { diaSemana: 0, bloqueHora: 10 },
      { diaSemana: 2, bloqueHora: 20 },
    ]);
    const slots = await availability.obtener(ana.id);
    expect(slots).toHaveLength(2);

    // Guardar de nuevo reemplaza (no acumula).
    await availability.guardar(ana.id, [{ diaSemana: 1, bloqueHora: 12 }]);
    expect(await availability.obtener(ana.id)).toHaveLength(1);

    await expect(availability.guardar(ana.id, [{ diaSemana: 9, bloqueHora: 0 }])).rejects.toThrow(
      /diaSemana/,
    );
    await expect(availability.guardar(ana.id, [{ diaSemana: 0, bloqueHora: 99 }])).rejects.toThrow(
      /bloqueHora/,
    );
  });
});

describe('HU-B4 — coincidencias de disponibilidad entre amigos', () => {
  it('cuenta en cada bloque a cuántos (usuario + amigos) les queda libre', async () => {
    const { availability, usuarios, amistades } = armar();
    const ana = usuarios.agregar({ username: 'Ana' });
    const bruno = usuarios.agregar({ username: 'Bruno' });
    const carla = usuarios.agregar({ username: 'Carla' });

    // Ana y Bruno amigos; Ana y Carla amigos; Carla NO comparte bloque.
    amistades.amistades.push(
      { id: 'a1', usuarioId1: ana.id, usuarioId2: bruno.id, estado: 'aceptada', createdAt: new Date() },
      { id: 'a2', usuarioId1: ana.id, usuarioId2: carla.id, estado: 'aceptada', createdAt: new Date() },
    );

    await availability.guardar(ana.id, [{ diaSemana: 0, bloqueHora: 20 }]);
    await availability.guardar(bruno.id, [{ diaSemana: 0, bloqueHora: 20 }]);
    await availability.guardar(carla.id, [{ diaSemana: 3, bloqueHora: 10 }]);

    const res = await availability.coincidenciasConAmigos(ana.id);
    expect(res.totalPersonas).toBe(3); // Ana + 2 amigos

    const bloque = res.slots.find((s) => s.diaSemana === 0 && s.bloqueHora === 20);
    expect(bloque?.disponibles).toBe(2); // Ana y Bruno
  });
});

describe('HU-B5 — ubicaciones favoritas', () => {
  it('crea, lista y elimina; no deja borrar la de otro', async () => {
    const { locations, usuarios } = armar();
    const ana = usuarios.agregar({ username: 'Ana' });
    const otro = usuarios.agregar({ username: 'Otro' });

    const u = await locations.crear(ana.id, 'Casa', 'Casa de Ana, Palermo');
    expect((await locations.listar(ana.id))).toHaveLength(1);

    await expect(locations.eliminar(otro.id, u.id)).rejects.toThrow(/No es tu ubicación/);
    await locations.eliminar(ana.id, u.id);
    expect(await locations.listar(ana.id)).toHaveLength(0);

    await expect(locations.crear(ana.id, '', 'algo')).rejects.toThrow(/etiqueta/);
  });
});
