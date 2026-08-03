import { Amistad, PersonaRef } from '../entities';

/** Una solicitud de amistad pendiente, con quién la envió. */
export interface SolicitudAmistad {
  amistadId: string;
  de: PersonaRef;
}

export interface AmistadRepository {
  /** HU-31 — crear una solicitud (queda `pendiente`). */
  crear(solicitanteId: string, receptorId: string): Promise<Amistad>;

  findById(id: string): Promise<Amistad | null>;

  /** La amistad entre dos usuarios, sin importar quién la inició. */
  findEntre(usuarioA: string, usuarioB: string): Promise<Amistad | null>;

  /** Aceptar una solicitud (pasa a `aceptada`). */
  aceptar(id: string): Promise<Amistad>;

  /** Amigos ya aceptados de un usuario (en cualquiera de los dos sentidos). */
  listAmigos(usuarioId: string): Promise<PersonaRef[]>;

  /** Solicitudes pendientes que recibió el usuario. */
  listSolicitudesRecibidas(usuarioId: string): Promise<SolicitudAmistad[]>;
}
