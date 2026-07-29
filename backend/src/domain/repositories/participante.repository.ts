import { AsistenciaEstado, Participante } from '../entities';

export interface CrearParticipanteAnonimoData {
  eventoId: string;
  nombreDisplay: string;
  tokenSesion: string;
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
  updateAsistencia(id: string, estado: AsistenciaEstado): Promise<Participante>;
  marcarLeido(id: string, cuando: Date): Promise<Participante>;

  /** Al cancelar un evento, los anónimos pierden el acceso (Duda #5). */
  invalidarSesionesAnonimas(eventoId: string): Promise<void>;
}
