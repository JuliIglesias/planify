import { BadRequestError } from '../../common/errors';
import {
  AmistadRepository,
  ProfileAvailabilityRepository,
  SlotDisponibilidad,
  SlotHeatmap,
} from '../../domain/repositories';

const DIAS_SEMANA = 7;
const BLOQUES_POR_DIA = 24;

export interface CoincidenciasAmigos {
  /** El usuario + sus amigos aceptados. */
  totalPersonas: number;
  /** Por bloque, cuántos de esas personas están disponibles. */
  slots: SlotHeatmap[];
}

/**
 * H-14 — disponibilidad semanal de perfil (persistida en el backend).
 * HU-B4 — coincidencias de disponibilidad entre amigos, fuera de un evento.
 */
export class ProfileAvailabilityService {
  constructor(
    private readonly disponibilidad: ProfileAvailabilityRepository,
    private readonly amistades: AmistadRepository,
  ) {}

  async obtener(usuarioId: string): Promise<SlotDisponibilidad[]> {
    return this.disponibilidad.findByUsuario(usuarioId);
  }

  async guardar(usuarioId: string, slots: SlotDisponibilidad[]): Promise<void> {
    if (!Array.isArray(slots)) throw new BadRequestError('slots debe ser un array');
    for (const s of slots) {
      if (!Number.isInteger(s.diaSemana) || s.diaSemana < 0 || s.diaSemana >= DIAS_SEMANA) {
        throw new BadRequestError(`diaSemana inválido: ${s.diaSemana}`);
      }
      if (!Number.isInteger(s.bloqueHora) || s.bloqueHora < 0 || s.bloqueHora >= BLOQUES_POR_DIA) {
        throw new BadRequestError(`bloqueHora inválido: ${s.bloqueHora}`);
      }
    }
    await this.disponibilidad.replaceForUsuario(usuarioId, slots);
  }

  /** HU-B4 — heatmap de disponibilidad del usuario + sus amigos. */
  async coincidenciasConAmigos(usuarioId: string): Promise<CoincidenciasAmigos> {
    const amigos = await this.amistades.listAmigos(usuarioId);
    const ids = [usuarioId, ...amigos.map((a) => a.id)];

    const slots = await this.disponibilidad.slotsDeUsuarios(ids);

    const conteo = new Map<string, number>();
    for (const s of slots) {
      const clave = `${s.diaSemana}:${s.bloqueHora}`;
      conteo.set(clave, (conteo.get(clave) ?? 0) + 1);
    }

    return {
      totalPersonas: ids.length,
      slots: [...conteo.entries()].map(([clave, disponibles]) => {
        const [diaSemana, bloqueHora] = clave.split(':').map(Number);
        return { diaSemana, bloqueHora, disponibles };
      }),
    };
  }
}
