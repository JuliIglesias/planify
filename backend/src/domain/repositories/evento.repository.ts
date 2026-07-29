import { Evento, EventoEstado, Participante } from '../entities';

export interface CrearEventoData {
  grupoId: string;
  nombre: string;
  lugarTexto: string;
  organizadorUsuarioId: string;
  organizadorNombre: string;
}

/** Evento + datos derivados que las pantallas de listado necesitan. */
export interface EventoConResumen extends Evento {
  grupoNombre: string;
  participantes: Pick<Participante, 'id' | 'nombreDisplay' | 'estadoAsistencia'>[];
  confirmados: number;
}

export interface EventoRepository {
  findById(id: string): Promise<Evento | null>;

  /**
   * Crea el evento y su participante organizador de forma atómica: un evento
   * sin organizador sería un estado inválido (nadie podría cancelarlo).
   */
  createWithOrganizer(data: CrearEventoData): Promise<{ evento: Evento; organizador: Participante }>;

  updateEstado(id: string, estado: EventoEstado): Promise<Evento>;
  confirmarHorario(id: string, fechaHoraInicio: Date): Promise<Evento>;

  /** Próximos eventos del usuario (planificación o confirmados). */
  listUpcomingForUsuario(usuarioId: string): Promise<EventoConResumen[]>;

  /** Eventos ya cerrados o cancelados, para el historial. */
  listPastForUsuario(usuarioId: string): Promise<EventoConResumen[]>;

  listByGrupo(grupoId: string): Promise<Evento[]>;
}
