/**
 * H-14 (disponibilidad de perfil), HU-B5 (ubicaciones favoritas).
 *
 * La vieja HU-B4 (coincidencias con TODOS los amigos) se eliminó en la
 * Tanda 6, Item 5: el heatmap agregado ahora vive scopeado a un grupo
 * puntual (`GroupsService.disponibilidadDeGrupo`), con sus propios tests en
 * `tasks-groups.service.test.ts`.
 */
import { ProfileAvailabilityService } from '../src/modules/profile/profile-availability.service';
import { LocationsService } from '../src/modules/profile/locations.service';
import { FakeLocationRepository, FakeProfileAvailabilityRepository, FakeUsuarioRepository } from './fakes';

function armar() {
  const usuarios = new FakeUsuarioRepository();
  const disponibilidadPerfil = new FakeProfileAvailabilityRepository();
  const ubicaciones = new FakeLocationRepository();
  return {
    availability: new ProfileAvailabilityService(disponibilidadPerfil),
    locations: new LocationsService(ubicaciones),
    usuarios,
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
