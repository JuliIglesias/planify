import { PersonaRef } from '../entities';

/**
 * F2 — una notificación que no está atada a ningún evento (a diferencia de
 * `LogActividad`/`EntradaLog`, que sí lo está y de hecho lo exige). Hoy la
 * única fuente es una solicitud de amistad recibida, pero el modelo es
 * genérico por diseño: cualquier aviso "para este usuario, de parte de este
 * otro usuario" que no tenga sentido colgar de un evento entra acá, sin
 * tocar el esquema de `LogActividad` (que sigue siendo estrictamente
 * "actividad DENTRO de un evento").
 */
export interface NotificacionPersonal {
  id: string;
  /** A quién le llega. */
  usuarioId: string;
  tipo: string;
  actorUsuarioId: string;
  payload: Record<string, unknown> | null;
  createdAt: Date;
}

export interface NotificacionPersonalConActor extends NotificacionPersonal {
  actor: PersonaRef;
}

export interface CrearNotificacionPersonalData {
  usuarioId: string;
  tipo: string;
  actorUsuarioId: string;
  payload?: Record<string, unknown>;
}

export interface NotificacionPersonalRepository {
  crear(data: CrearNotificacionPersonalData): Promise<NotificacionPersonal>;

  /**
   * Mismo contrato de paginación por cursor que
   * `LogActividadRepository.listRecientesPorEventos` (Tanda 6, Item 2):
   * [before] trae solo entradas estrictamente más viejas que esa fecha.
   */
  listRecientes(
    usuarioId: string,
    limite: number,
    before?: Date,
  ): Promise<NotificacionPersonalConActor[]>;
}
