import { SlotDisponibilidad } from './disponibilidad.repository';

/** Un slot de disponibilidad de perfil junto con de quién es (para HU-B4). */
export interface SlotDeUsuario extends SlotDisponibilidad {
  usuarioId: string;
}

/**
 * Disponibilidad semanal de perfil (por usuario, no por evento) — H-14.
 * Alimenta el pre-llenado del evento y las coincidencias entre amigos (HU-B4).
 */
export interface ProfileAvailabilityRepository {
  /** Reemplaza toda la disponibilidad de perfil del usuario. */
  replaceForUsuario(usuarioId: string, slots: SlotDisponibilidad[]): Promise<void>;

  findByUsuario(usuarioId: string): Promise<SlotDisponibilidad[]>;

  /** Todos los slots de un conjunto de usuarios (para el heatmap de amigos). */
  slotsDeUsuarios(usuarioIds: string[]): Promise<SlotDeUsuario[]>;
}
