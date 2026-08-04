import { BadRequestError } from '../../common/errors';
import { ProfileAvailabilityRepository, SlotDisponibilidad } from '../../domain/repositories';

const DIAS_SEMANA = 7;
const BLOQUES_POR_DIA = 24;

/**
 * H-14 — disponibilidad semanal de perfil (persistida en el backend).
 *
 * Es una preferencia individual (no "entre amigos"): además de guardarse acá,
 * alimenta el pre-llenado de la disponibilidad de un evento puntual
 * (event_config_screen). El heatmap agregado de varias personas (antes
 * "coincidencias con todos los amigos", HU-B4) ahora vive scopeado a un grupo
 * puntual en `GroupsService.disponibilidadDeGrupo` (Tanda 6, Item 5): ver
 * docs/05-fixes.md.
 */
export class ProfileAvailabilityService {
  constructor(private readonly disponibilidad: ProfileAvailabilityRepository) {}

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
}
