import { AsistenciaEstado, Participante } from '../entities';

export interface CrearParticipanteAnonimoData {
  eventoId: string;
  username: string;
  tokenSesion: string;
}

export interface CrearParticipanteRegistradoData {
  eventoId: string;
  usuarioId: string;
  username: string;
}

export interface ParticipanteRepository {
  findById(id: string): Promise<Participante | null>;
  findByTokenSesion(token: string): Promise<Participante | null>;

  /** El participante que representa a un usuario registrado dentro de un evento. */
  findByEventoAndUsuario(eventoId: string, usuarioId: string): Promise<Participante | null>;

  /** Organizador del evento: el único que puede cancelar y cerrar gastos (Duda #6). */
  findOrganizador(eventoId: string): Promise<Participante | null>;

  listByEvento(eventoId: string): Promise<Participante[]>;
  listByUsuario(usuarioId: string): Promise<Participante[]>;

  createAnonimo(data: CrearParticipanteAnonimoData): Promise<Participante>;

  /**
   * Username único — HU-01/HU-27. Chequea contra TODOS los eventos (no solo
   * uno): un participante anónimo puede aparecer en varios eventos, pero acá
   * se busca si ALGUNA fila anónima ya usa ese username, para no chocar con
   * una cuenta registrada que se quiera crear con el mismo. Case-insensitive.
   */
  existsUsernameAnonimo(username: string): Promise<boolean>;

  /**
   * Materializa a un miembro registrado del grupo como participante del evento.
   * Idempotente: si ya participa, devuelve el participante existente (agregar a
   * alguien dos veces no debe duplicarlo ni explotar).
   */
  createParaUsuario(data: CrearParticipanteRegistradoData): Promise<Participante>;
  updateAsistencia(id: string, estado: AsistenciaEstado): Promise<Participante>;
  marcarLeido(id: string, cuando: Date): Promise<Participante>;

  /** Al cancelar un evento, los anónimos pierden el acceso (Duda #5). */
  invalidarSesionesAnonimas(eventoId: string): Promise<void>;
}
