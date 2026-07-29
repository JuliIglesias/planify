import { DeudaSimplificada, PersonaRef } from '../entities';

export interface DeudaConPersonas extends DeudaSimplificada {
  deudor: PersonaRef & { usuarioId: string | null };
  acreedor: PersonaRef & { usuarioId: string | null };
  eventoNombre: string;
}

export interface NuevaDeuda {
  deudorParticipanteId: string;
  acreedorParticipanteId: string;
  monto: string;
  estado: DeudaSimplificada['estado'];
  saldadoEn: Date | null;
}

export interface DeudaRepository {
  findById(id: string): Promise<DeudaSimplificada | null>;
  listByEvento(eventoId: string): Promise<DeudaConPersonas[]>;

  /** Deudas donde participa alguna de las identidades del usuario. */
  listByParticipantes(participanteIds: string[]): Promise<DeudaConPersonas[]>;

  /**
   * Reemplaza atómicamente todas las deudas del evento por el resultado del
   * recálculo. Qué deuda queda como "saldada" lo decide el servicio (es regla
   * de negocio), acá solo se persiste.
   */
  reemplazarEvento(eventoId: string, deudas: NuevaDeuda[]): Promise<DeudaSimplificada[]>;

  marcarSaldada(id: string, cuando: Date): Promise<DeudaSimplificada>;

  /**
   * Salda varias deudas de una sola vez, atómicamente.
   * Lo necesita la compensación cruzada (FR9): saldar con una persona cierra
   * todas las deudas que hay con ella, de todos los eventos, en un solo paso.
   */
  marcarSaldadasEnLote(ids: string[], cuando: Date): Promise<number>;

  contarPendientes(eventoId: string): Promise<number>;
  contarTotal(eventoId: string): Promise<number>;
}
