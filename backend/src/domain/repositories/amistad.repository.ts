import { Amistad, PersonaBusqueda } from '../entities';

/** Una solicitud de amistad pendiente, con quién la envió. */
export interface SolicitudAmistad {
  amistadId: string;
  de: PersonaBusqueda;
}

/**
 * F1 — una solicitud de amistad pendiente que envié yo, con a quién.
 * Mismo shape que `SolicitudAmistad` salvo el nombre del campo (`para` en
 * vez de `de`): son conceptualmente distintas (quién la mandó vs. a quién
 * se la mandaron) aunque miren la misma tabla desde el otro lado.
 */
export interface SolicitudEnviada {
  amistadId: string;
  para: PersonaBusqueda;
}

export interface AmistadRepository {
  /** HU-31 — crear una solicitud (queda `pendiente`). */
  crear(solicitanteId: string, receptorId: string): Promise<Amistad>;

  findById(id: string): Promise<Amistad | null>;

  /** La amistad entre dos usuarios, sin importar quién la inició. */
  findEntre(usuarioA: string, usuarioB: string): Promise<Amistad | null>;

  /** Aceptar una solicitud (pasa a `aceptada`). */
  aceptar(id: string): Promise<Amistad>;

  /**
   * Amigos ya aceptados de un usuario (en cualquiera de los dos sentidos).
   * Item 3 — lleva el email para que cualquier lista de amigos pueda
   * mostrarlo junto al username, no solo los resultados de búsqueda.
   */
  listAmigos(usuarioId: string): Promise<PersonaBusqueda[]>;

  /** Solicitudes pendientes que recibió el usuario. */
  listSolicitudesRecibidas(usuarioId: string): Promise<SolicitudAmistad[]>;

  /** F1 — solicitudes pendientes que envió el usuario (todavía sin aceptar). */
  listSolicitudesEnviadas(usuarioId: string): Promise<SolicitudEnviada[]>;
}
