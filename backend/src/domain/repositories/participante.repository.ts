import { AsistenciaEstado, Participante } from '../entities';

export interface CrearParticipanteAnonimoData {
  eventoId: string;
  username: string;
  tokenSesion: string;
  /** G1 (ADR 0003) — hash del PIN que el anónimo define al unirse. */
  pinHash: string;
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
   * Username único — HU-01/HU-27. Chequea contra TODOS los eventos, pasados o
   * presentes (a propósito — ver ADR 0003 §"Por qué no reusa esto G1"): se
   * usa para que un username anónimo nunca choque con el de una cuenta
   * REGISTRADA, que es una identidad permanente y no debería "liberarse"
   * nunca por más que el evento del anónimo haya terminado. Case-insensitive.
   */
  existsUsernameAnonimo(username: string): Promise<boolean>;

  /**
   * G1 (ADR 0003) — la fila anónima de ESE username en ESE evento puntual
   * (case-insensitive), si existe. Es la base para "recuperar la misma
   * cuenta" al volver a entrar con las mismas credenciales.
   */
  findAnonimoPorEventoYUsername(eventoId: string, username: string): Promise<Participante | null>;

  /**
   * G1 (ADR 0003) — todas las filas anónimas (en cualquier evento) que usan
   * este username, case-insensitive. `ParticipantsService` decide, evento
   * por evento, si cada una todavía "reserva" el username o si ya se
   * liberó (evento finalizado/cancelado + deudas saldadas) — el
   * repositorio no sabe nada de esas reglas de negocio, solo devuelve las
   * filas candidatas.
   */
  listAnonimosPorUsername(username: string): Promise<Participante[]>;

  /**
   * G1 (ADR 0003) — al recuperar una sesión anónima existente (mismo
   * evento + username + PIN correcto), se emite un token de sesión nuevo
   * en vez de reusar el viejo: mismo criterio que un login normal, para
   * que un token viejo filtrado no siga sirviendo para siempre.
   */
  regenerarTokenSesion(id: string, tokenSesion: string): Promise<Participante>;

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
