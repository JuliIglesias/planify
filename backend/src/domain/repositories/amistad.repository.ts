import { Amistad } from '../entities';

/**
 * Amistades entre usuarios registrados (FR13). Una amistad es simétrica pero se
 * guarda en una sola fila (usuarioId1 = quien la solicitó, usuarioId2 = quien la
 * recibe). Por eso las búsquedas "de un usuario" miran ambas columnas.
 */
export interface AmistadRepository {
  findById(id: string): Promise<Amistad | null>;
  /** La amistad entre dos usuarios, sin importar quién la haya iniciado. */
  findEntre(usuarioA: string, usuarioB: string): Promise<Amistad | null>;

  create(solicitanteId: string, destinatarioId: string): Promise<Amistad>;
  aceptar(id: string): Promise<Amistad>;
  eliminar(id: string): Promise<void>;

  /** Amistades aceptadas donde el usuario participa (en cualquiera de los dos lados). */
  listAceptadasDe(usuarioId: string): Promise<Amistad[]>;
  /** Solicitudes pendientes que le llegaron al usuario (él es el destinatario). */
  listPendientesRecibidas(usuarioId: string): Promise<Amistad[]>;
}
